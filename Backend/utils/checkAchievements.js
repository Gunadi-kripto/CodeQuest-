const User = require('../models/User');
const Achievement = require('../models/Achievement');
const UserProgress = require('../models/UserProgress');
const Module = require('../models/Module');

async function checkAndUnlockAchievements(userId) {
  const user = await User.findById(userId);

  if (!user) {
    return [];
  }

  if (!user.unlocked_achievements) {
    user.unlocked_achievements = [];
  }

  const unlockedIds = user.unlocked_achievements.map((id) => id.toString());

  const achievements = await Achievement.find({
    is_active: true,
  });

  const newAchievements = [];

  for (const achievement of achievements) {
    const achievementId = achievement._id.toString();

    if (unlockedIds.includes(achievementId)) {
      continue;
    }

    let isEligible = false;

    if (achievement.syarat_tipe === 'progress_belajar') {
      const languageId = achievement.language_id?.toString();

      if (!languageId) continue;

      const modules = await Module.find({
        id_bahasa: languageId,
      }).select('_id');

      const moduleIds = modules.map((m) => m._id);

      const completedCount = await UserProgress.countDocuments({
        user_id: userId,
        module_id: { $in: moduleIds },
        tipe_progress: 'materi',
        is_completed: true,
      });

      if (completedCount >= achievement.syarat_nilai) {
        isEligible = true;
      }
    }

    if (achievement.syarat_tipe === 'xp_reward') {
      const totalXp = user.total_xp || 0;

      if (totalXp >= achievement.syarat_nilai) {
        isEligible = true;
      }
    }

    if (achievement.syarat_tipe === 'quiz_master') {
      const completedQuizCount = await UserProgress.countDocuments({
        user_id: userId,
        tipe_progress: 'quiz',
        is_completed: true,
      });

      if (completedQuizCount >= achievement.syarat_nilai) {
        isEligible = true;
      }
    }

    if (isEligible) {
      user.unlocked_achievements.push(achievement._id);

      const reward = achievement.xp_reward || 0;
      user.total_xp = (user.total_xp || 0) + reward;

      newAchievements.push(achievement);
    }
  }

  user.level = Math.floor((user.total_xp || 0) / 100) + 1;

  await user.save();

  return newAchievements;
}

module.exports = checkAndUnlockAchievements;
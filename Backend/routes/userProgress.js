const express = require('express');
const router = express.Router();

const UserProgress = require('../models/UserProgress');
const Module = require('../models/Module');
const User = require('../models/User');
const checkAndUnlockAchievements = require('../utils/checkAchievements');

// ==========================================
// SELESAIKAN MATERI
// POST /api/progress/complete-module
// ==========================================
router.post('/complete-module', async (req, res) => {
  try {
    const { user_id, module_id } = req.body;

    if (!user_id || !module_id) {
      return res.status(400).json({
        success: false,
        message: 'user_id dan module_id wajib dikirim',
      });
    }

    const module = await Module.findById(module_id);

    if (!module) {
      return res.status(404).json({
        success: false,
        message: 'Materi tidak ditemukan',
      });
    }

    let progress = await UserProgress.findOne({
      user_id,
      module_id,
      tipe_progress: 'materi',
    });

    let alreadyCompleted = false;

    if (progress) {
      alreadyCompleted = progress.is_completed === true;

      if (!progress.is_completed) {
        progress.is_completed = true;
        await progress.save();
      }
    } else {
      progress = await UserProgress.create({
        user_id,
        module_id,
        quiz_id: null,
        tipe_progress: 'materi',
        is_completed: true,
        status_benar: false,
      });
    }

    // PENTING:
    // Tetap cek achievement walaupun materi sudah pernah selesai.
    // Ini supaya kalau admin update syarat achievement,
    // user tetap bisa dapat achievement saat endpoint ini terpanggil lagi.
    const newAchievements = await checkAndUnlockAchievements(user_id);

    const updatedUser = await User.findById(user_id)
      .select('-password')
      .populate('unlocked_achievements');

    return res.status(200).json({
      success: true,
      message: alreadyCompleted
        ? 'Materi sudah pernah diselesaikan, achievement dicek ulang'
        : 'Materi berhasil diselesaikan',
      progress,
      new_achievements: newAchievements,
      user: updatedUser,
    });
  } catch (error) {
    console.error('COMPLETE MODULE ERROR:', error);

    return res.status(500).json({
      success: false,
      message: 'Gagal menyelesaikan materi',
      error: error.message,
    });
  }
});

// ==========================================
// AMBIL PROGRESS USER
// GET /api/progress/user/:userId
// ==========================================
router.get('/user/:userId', async (req, res) => {
  try {
    const progress = await UserProgress.find({
      user_id: req.params.userId,
    })
      .populate('module_id')
      .populate('quiz_id')
      .sort({ tanggal_selesai: -1 });

    return res.status(200).json({
      success: true,
      data: progress,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil progress user',
      error: error.message,
    });
  }
});

module.exports = router;
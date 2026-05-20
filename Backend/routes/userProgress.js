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

      progress.is_completed = true;
      progress.status_benar = false;
      progress.tipe_progress = 'materi';
      progress.module_id = module_id;
      progress.quiz_id = null;

      // kalau model UserProgress kamu sudah punya language_id
      progress.language_id = module.id_bahasa || null;

      await progress.save();
    } else {
      progress = await UserProgress.create({
        user_id,
        language_id: module.id_bahasa || null,
        module_id,
        quiz_id: null,
        tipe_progress: 'materi',
        is_completed: true,
        status_benar: false,
        skor: 0,
      });
    }

    // ==========================================
    // HITUNG ULANG TOTAL MATERI SELESAI
    // ==========================================
    const completedMateriCount = await UserProgress.countDocuments({
      user_id,
      tipe_progress: 'materi',
      is_completed: true,
    });

    await User.findByIdAndUpdate(user_id, {
      total_materi_dibaca: completedMateriCount,
    });

    // ==========================================
    // CEK ACHIEVEMENT
    // ==========================================
    const newAchievements = await checkAndUnlockAchievements(user_id);

    // Ambil user terbaru setelah total_materi_dibaca dan achievement diupdate
    const updatedUser = await User.findById(user_id)
      .select('-password -password_hash')
      .populate('unlocked_achievements');

    return res.status(200).json({
      success: true,
      message: alreadyCompleted
        ? 'Materi sudah pernah diselesaikan, achievement dicek ulang'
        : 'Materi berhasil diselesaikan',
      progress,
      total_materi_dibaca: completedMateriCount,
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
    console.error('GET USER PROGRESS ERROR:', error);

    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil progress user',
      error: error.message,
    });
  }
});

// ==========================================
// AMBIL PROGRESS MATERI USER SAJA
// GET /api/progress/user/:userId/modules
// ==========================================
router.get('/user/:userId/modules', async (req, res) => {
  try {
    const progress = await UserProgress.find({
      user_id: req.params.userId,
      tipe_progress: 'materi',
      is_completed: true,
    })
      .populate('module_id')
      .sort({ tanggal_selesai: -1 });

    return res.status(200).json({
      success: true,
      data: progress,
    });
  } catch (error) {
    console.error('GET USER MODULE PROGRESS ERROR:', error);

    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil progress materi user',
      error: error.message,
    });
  }
});

// ==========================================
// AMBIL PROGRESS QUIZ USER SAJA
// GET /api/progress/user/:userId/quizzes
// ==========================================
router.get('/user/:userId/quizzes', async (req, res) => {
  try {
    const progress = await UserProgress.find({
      user_id: req.params.userId,
      tipe_progress: 'quiz',
      is_completed: true,
    })
      .populate('quiz_id')
      .populate('module_id')
      .sort({ tanggal_selesai: -1 });

    return res.status(200).json({
      success: true,
      data: progress,
    });
  } catch (error) {
    console.error('GET USER QUIZ PROGRESS ERROR:', error);

    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil progress quiz user',
      error: error.message,
    });
  }
});

module.exports = router;
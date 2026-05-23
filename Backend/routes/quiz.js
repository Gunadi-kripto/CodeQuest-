const express = require('express');
const router = express.Router();

const Quiz = require('../models/Quiz');
const Module = require('../models/Module');
const User = require('../models/User');
const UserProgress = require('../models/UserProgress');
const checkAndUnlockAchievements = require('../utils/checkAchievements');
const calculateLevel = require('../utils/calculateLevel');

const { upload } = require('../config/cloudinary');

// ==========================================
// 1. SUBMIT / SELESAIKAN QUIZ USER
// POST /api/quizzes/submit
// ==========================================
router.post('/submit', async (req, res) => {
  console.log('🔥 SUBMIT QUIZ MASUK:', req.body);

  try {
    const { user_id, quiz_id, skor } = req.body;

    if (!user_id || !quiz_id) {
      return res.status(400).json({
        success: false,
        message: 'user_id dan quiz_id wajib dikirim',
      });
    }

    const quiz = await Quiz.findById(quiz_id);

    if (!quiz) {
      return res.status(404).json({
        success: false,
        message: 'Quiz tidak ditemukan',
      });
    }

    const user = await User.findById(user_id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User tidak ditemukan',
      });
    }

    const module = await Module.findById(quiz.module_id);

    if (!module) {
      return res.status(404).json({
        success: false,
        message: 'Materi dari quiz ini tidak ditemukan',
      });
    }

    let progress = await UserProgress.findOne({
      user_id,
      quiz_id,
      tipe_progress: 'quiz',
    });

    const alreadyCompleted = progress && progress.is_completed === true;

    if (progress) {
      progress.module_id = quiz.module_id;
      progress.quiz_id = quiz_id;
      progress.tipe_progress = 'quiz';
      progress.is_completed = true;
      progress.status_benar = true;
      progress.skor = skor || 0;

      if ('language_id' in progress) {
        progress.language_id = module.id_bahasa || null;
      }

      await progress.save();
    } else {
      progress = await UserProgress.create({
        user_id,
        language_id: module.id_bahasa || null,
        module_id: quiz.module_id,
        quiz_id,
        tipe_progress: 'quiz',
        is_completed: true,
        status_benar: true,
        skor: skor || 0,
      });
    }

    let xpAdded = 0;

    // XP quiz hanya ditambah kalau quiz belum pernah selesai
    if (!alreadyCompleted) {
      xpAdded = Number(quiz.xp_reward || 0);
      user.total_xp = (user.total_xp || 0) + xpAdded;
    }

    // Hitung ulang total quiz selesai dari UserProgress
    const completedQuizCount = await UserProgress.countDocuments({
      user_id,
      tipe_progress: 'quiz',
      is_completed: true,
    });

    user.total_kuis_selesai = completedQuizCount;
    user.level = calculateLevel(user.total_xp || 0);

    await user.save();

    // Setelah progress quiz tersimpan, baru cek achievement
    const newAchievements = await checkAndUnlockAchievements(user_id);

    const updatedUser = await User.findById(user_id)
      .select('-password -password_hash')
      .populate('unlocked_achievements');

    return res.status(200).json({
      success: true,
      message: alreadyCompleted
        ? 'Quiz sudah pernah dikerjakan, XP tidak bertambah'
        : 'Quiz berhasil diselesaikan',
      already_completed: alreadyCompleted,
      xp_added: xpAdded,
      total_kuis_selesai: completedQuizCount,
      progress,
      new_achievements: newAchievements,
      user: updatedUser,
    });
  } catch (error) {
    console.error('SUBMIT QUIZ ERROR:', error);

    return res.status(500).json({
      success: false,
      message: 'Gagal submit quiz',
      error: error.message,
    });
  }
});

// ==========================================
// 2. AMBIL KUIS BERDASARKAN ID MATERI
// GET /api/quizzes/:moduleId
// ==========================================
router.get('/:moduleId', async (req, res) => {
  try {
    const moduleId = req.params.moduleId;

    const module = await Module.findById(moduleId);

    if (!module) {
      return res.status(404).json({
        message: 'Materi tidak ditemukan atau sudah dihapus',
        data: [],
      });
    }

    const quizzes = await Quiz.find({
      module_id: moduleId,
    });

    return res.status(200).json(quizzes);
  } catch (error) {
    return res.status(500).json({
      message: 'Gagal mengambil kuis',
      error: error.message,
    });
  }
});

// ==========================================
// 3. TAMBAH KUIS PILIHAN GANDA ADMIN
// POST /api/quizzes
// ==========================================
router.post('/', upload.any(), async (req, res) => {
  try {
    const { module_id, daftar_soal, xp_reward } = req.body;

    if (!module_id || !daftar_soal) {
      return res.status(400).json({
        success: false,
        message: 'module_id dan daftar_soal wajib dikirim',
      });
    }

    let parsedSoal;

    try {
      parsedSoal = JSON.parse(daftar_soal);
    } catch (error) {
      return res.status(400).json({
        success: false,
        message: 'Format daftar_soal tidak valid',
      });
    }

    if (req.files && req.files.length > 0) {
      req.files.forEach((file) => {
        const match = file.fieldname.match(/^gambar_soal_(\d+)$/);

        if (match) {
          const index = parseInt(match[1]);

          if (parsedSoal[index]) {
            parsedSoal[index].gambar_url = file.path;
          }
        }
      });
    }

    const newQuiz = new Quiz({
      module_id,
      daftar_soal: parsedSoal,
      xp_reward: Number(xp_reward || 0),
    });

    await newQuiz.save();

    return res.status(201).json({
      success: true,
      message: 'Quiz berhasil ditambahkan',
      data: newQuiz,
    });
  } catch (error) {
    console.error('ADD QUIZ ERROR:', error);

    return res.status(500).json({
      success: false,
      message: 'Gagal menambahkan quiz',
      error: error.message,
    });
  }
});

// ==========================================
// 4. EDIT KUIS ADMIN
// PUT /api/quizzes/:id
// ==========================================
router.put('/:id', upload.any(), async (req, res) => {
  try {
    const { daftar_soal, xp_reward } = req.body;

    if (!daftar_soal) {
      return res.status(400).json({
        success: false,
        message: 'daftar_soal wajib dikirim',
      });
    }

    let parsedSoal;

    try {
      parsedSoal = JSON.parse(daftar_soal);
    } catch (error) {
      return res.status(400).json({
        success: false,
        message: 'Format daftar_soal tidak valid',
      });
    }

    if (req.files && req.files.length > 0) {
      req.files.forEach((file) => {
        const match = file.fieldname.match(/^gambar_soal_(\d+)$/);

        if (match) {
          const index = parseInt(match[1]);

          if (parsedSoal[index]) {
            parsedSoal[index].gambar_url = file.path;
          }
        }
      });
    }

    const updatedQuiz = await Quiz.findByIdAndUpdate(
      req.params.id,
      {
        daftar_soal: parsedSoal,
        xp_reward: Number(xp_reward || 0),
      },
      { new: true }
    );

    if (!updatedQuiz) {
      return res.status(404).json({
        success: false,
        message: 'Quiz tidak ditemukan',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Quiz berhasil diupdate',
      data: updatedQuiz,
    });
  } catch (error) {
    console.error('UPDATE QUIZ ERROR:', error);

    return res.status(500).json({
      success: false,
      message: 'Gagal update quiz',
      error: error.message,
    });
  }
});

// ==========================================
// 5. HAPUS KUIS ADMIN
// DELETE /api/quizzes/:id
// ==========================================
router.delete('/:id', async (req, res) => {
  try {
    const deletedQuiz = await Quiz.findByIdAndDelete(req.params.id);

    if (!deletedQuiz) {
      return res.status(404).json({
        success: false,
        message: 'Kuis tidak ditemukan',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Kuis berhasil dihapus',
    });
  } catch (error) {
    console.error('DELETE QUIZ ERROR:', error);

    return res.status(500).json({
      success: false,
      message: 'Gagal menghapus kuis',
      error: error.message,
    });
  }
});

module.exports = router;
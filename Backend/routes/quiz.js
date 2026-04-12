const express = require('express');
const router = express.Router();
const Quiz = require('../models/Quiz');

// 1. TAMBAH KUIS BARU (POST)
router.post('/', async (req, res) => {
  try {
    const { module_id, pertanyaan, kunci_jawaban, hint, xp_reward } = req.body;
    
    const newQuiz = new Quiz({
      module_id,
      pertanyaan,
      kunci_jawaban,
      hint,
      xp_reward
    });

    await newQuiz.save();
    res.status(201).json({ message: 'Kuis berhasil ditambahkan!', data: newQuiz });
  } catch (error) {
    console.error('Error tambah kuis:', error);
    res.status(500).json({ message: 'Gagal menambahkan kuis.' });
  }
});

// 2. AMBIL KUIS BERDASARKAN ID MATERI (GET)
// Contoh URL: /api/quizzes/module/65f1a2b3c4d5...
router.get('/module/:moduleId', async (req, res) => {
  try {
    const quizzes = await Quiz.find({ module_id: req.params.moduleId });
    res.status(200).json(quizzes);
  } catch (error) {
    res.status(500).json({ message: 'Gagal mengambil data kuis.' });
  }
});

module.exports = router;
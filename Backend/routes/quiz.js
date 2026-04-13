const express = require('express');
const router = express.Router();
const Quiz = require('../models/Quiz');

// 1. AMBIL KUIS BERDASARKAN ID MATERI
router.get('/:moduleId', async (req, res) => {
  try {
    const quizzes = await Quiz.find({ module_id: req.params.moduleId });
    res.status(200).json(quizzes);
  } catch (error) {
    res.status(500).json({ message: 'Gagal mengambil data kuis' });
  }
});

// 2. TAMBAH KUIS BARU (ADMIN)
router.post('/', async (req, res) => {
  try {
    const { module_id, pertanyaan, kunci_jawaban, hint, xp_reward } = req.body;
    const newQuiz = new Quiz({ module_id, pertanyaan, kunci_jawaban, hint, xp_reward });
    await newQuiz.save();
    res.status(201).json({ message: 'Kuis berhasil ditambahkan!', quiz: newQuiz });
  } catch (error) {
    res.status(500).json({ message: 'Gagal menambahkan kuis' });
  }
});

// 3. EDIT KUIS (ADMIN)
router.put('/:id', async (req, res) => {
  try {
    const { pertanyaan, kunci_jawaban, hint, xp_reward } = req.body;
    const updatedQuiz = await Quiz.findByIdAndUpdate(
      req.params.id,
      { pertanyaan, kunci_jawaban, hint, xp_reward },
      { returnDocument: 'after' }
    );
    res.status(200).json({ message: 'Kuis diperbarui!', quiz: updatedQuiz });
  } catch (error) {
    res.status(500).json({ message: 'Gagal memperbarui kuis' });
  }
});

// 4. HAPUS KUIS (ADMIN)
router.delete('/:id', async (req, res) => {
  try {
    await Quiz.findByIdAndDelete(req.params.id);
    res.status(200).json({ message: 'Kuis dihapus!' });
  } catch (error) {
    res.status(500).json({ message: 'Gagal menghapus kuis' });
  }
});

module.exports = router;
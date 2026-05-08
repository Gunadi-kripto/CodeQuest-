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

// 2. TAMBAH KUIS PILIHAN GANDA (ADMIN)
router.post('/', async (req, res) => {
  try {
    const { module_id, pertanyaan, opsi, jawaban_benar, hint, xp_reward } = req.body;
    
    // Validasi sederhana: pastikan opsi ada 4
    if (!opsi || opsi.length < 4) {
      return res.status(400).json({ message: 'Harus ada 4 opsi jawaban!' });
    }

    const newQuiz = new Quiz({ 
      module_id, 
      pertanyaan, 
      opsi, 
      jawaban_benar, 
      hint, 
      xp_reward 
    });

    await newQuiz.save();
    res.status(201).json({ message: 'Kuis pilihan ganda berhasil ditambahkan!', quiz: newQuiz });
  } catch (error) {
    console.error("Gagal tambah kuis:", error);
    res.status(500).json({ message: 'Gagal menambahkan kuis' });
  }
});

// 3. EDIT KUIS (ADMIN)
router.put('/:id', async (req, res) => {
  try {
    const { pertanyaan, opsi, jawaban_benar, hint, xp_reward } = req.body;
    const updatedQuiz = await Quiz.findByIdAndUpdate(
      req.params.id,
      { pertanyaan, opsi, jawaban_benar, hint, xp_reward },
      { new: true } // Mengembalikan data setelah diupdate
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
    res.status(200).json({ message: 'Kuis berhasil dihapus!' });
  } catch (error) {
    res.status(500).json({ message: 'Gagal menghapus kuis' });
  }
});

module.exports = router;
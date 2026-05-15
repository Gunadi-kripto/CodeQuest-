const express = require('express');
const router = express.Router();
const Quiz = require('../models/Quiz');
const Module = require('../models/Module');
const { upload } = require('../config/cloudinary');

// 1. AMBIL KUIS BERDASARKAN ID MATERI
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

    res.status(200).json(quizzes);
  } catch (error) {
    res.status(500).json({
      message: 'Gagal mengambil kuis',
      error: error.message,
    });
  }
});

// 2. TAMBAH KUIS PILIHAN GANDA (ADMIN)
router.post('/', upload.any(), async (req, res) => {
  try {
    const { module_id, daftar_soal, xp_reward } = req.body;

    let parsedSoal = JSON.parse(daftar_soal);

    req.files.forEach((file) => {
      const match = file.fieldname.match(/^gambar_soal_(\d+)$/);

      if (match) {
        const index = parseInt(match[1]);

        if (parsedSoal[index]) {
          parsedSoal[index].gambar_url = file.path;
        }
      }
    });

    const newQuiz = new Quiz({
      module_id,
      daftar_soal: parsedSoal,
      xp_reward,
    });

    await newQuiz.save();

    res.status(201).json({
      message: 'Quiz berhasil ditambahkan',
      data: newQuiz,
    });
  } catch (error) {
    res.status(500).json({
      message: 'Gagal menambahkan quiz',
      error: error.message,
    });
  }
});

// 3. EDIT KUIS (ADMIN)
router.put('/:id', upload.any(), async (req, res) => {
  try {
    const { daftar_soal, xp_reward } = req.body;

    let parsedSoal = JSON.parse(daftar_soal);

    req.files.forEach((file) => {
      const match = file.fieldname.match(/^gambar_soal_(\d+)$/);

      if (match) {
        const index = parseInt(match[1]);

        if (parsedSoal[index]) {
          parsedSoal[index].gambar_url = file.path;
        }
      }
    });

    const updatedQuiz = await Quiz.findByIdAndUpdate(
      req.params.id,
      {
        daftar_soal: parsedSoal,
        xp_reward,
      },
      { new: true }
    );

    if (!updatedQuiz) {
      return res.status(404).json({
        message: 'Quiz tidak ditemukan',
      });
    }

    res.status(200).json({
      message: 'Quiz berhasil diupdate',
      data: updatedQuiz,
    });
  } catch (error) {
    res.status(500).json({
      message: 'Gagal update quiz',
      error: error.message,
    });
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
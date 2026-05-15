const express = require('express');
const router = express.Router();
const Language = require('../models/Language');
const { upload } = require('../config/cloudinary'); // Menggunakan config yang sudah ada
const Module = require('../models/Module');
const Quiz = require('../models/Quiz');

// 1. TAMBAH BAHASA BARU (Admin mengunggah logo + nama + warna)
router.post('/', upload.single('icon_file'), async (req, res) => {
  try {
    const { nama_bahasa, warna_tema } = req.body;

    if (!nama_bahasa) {
      return res.status(400).json({
        message: 'Nama bahasa wajib diisi!',
      });
    }

    if (!req.file) {
      return res.status(400).json({
        message: 'Mohon unggah icon bahasa!',
      });
    }

    const newLanguage = new Language({
      nama_bahasa,
      warna_tema,
      icon_url: req.file.path, // URL dari Cloudinary
    });

    await newLanguage.save();

    res.status(201).json({
      message: 'Bahasa berhasil ditambahkan!',
      data: newLanguage,
    });
  } catch (error) {
    res.status(500).json({
      message: 'Gagal menambah bahasa',
      error: error.message,
    });
  }
});

// 2. AMBIL SEMUA DAFTAR BAHASA (Untuk tampilan Grid di Flutter)
router.get('/', async (req, res) => {
  try {
    const languages = await Language.find();

    res.status(200).json(languages);
  } catch (error) {
    res.status(500).json({
      message: 'Gagal mengambil data bahasa',
      error: error.message,
    });
  }
});

// 3. UPDATE BAHASA
// PUT /api/language/:id
router.put('/:id', upload.single('icon_file'), async (req, res) => {
  try {
    const { nama_bahasa, warna_tema } = req.body;

    const updateData = {};

    if (nama_bahasa) {
      updateData.nama_bahasa = nama_bahasa;
    }

    if (warna_tema) {
      updateData.warna_tema = warna_tema;
    }

    // Kalau admin upload icon baru, update icon_url juga
    if (req.file) {
      updateData.icon_url = req.file.path;
    }

    const updatedLanguage = await Language.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true }
    );

    if (!updatedLanguage) {
      return res.status(404).json({
        message: 'Bahasa tidak ditemukan',
      });
    }

    res.status(200).json({
      message: 'Bahasa berhasil diupdate!',
      data: updatedLanguage,
    });
  } catch (error) {
    res.status(500).json({
      message: 'Gagal update bahasa',
      error: error.message,
    });
  }
});

// 4. HAPUS BAHASA
// DELETE /api/language/:id
router.delete('/:id', async (req, res) => {
  try {
    const languageId = req.params.id;

    const language = await Language.findById(languageId);

    if (!language) {
      return res.status(404).json({
        message: 'Bahasa tidak ditemukan',
      });
    }

    // Ambil semua module/materi yang memakai bahasa ini
    const modules = await Module.find({ id_bahasa: languageId });

    const moduleIds = modules.map((module) => module._id);

    // Hapus semua quiz yang terhubung dengan module/materi bahasa ini
    await Quiz.deleteMany({
      module_id: { $in: moduleIds },
    });

    // Hapus semua module/materi bahasa ini
    await Module.deleteMany({
      id_bahasa: languageId,
    });

    // Hapus bahasa
    await Language.findByIdAndDelete(languageId);

    res.status(200).json({
      message: 'Bahasa, materi, dan kuis terkait berhasil dihapus',
    });
  } catch (error) {
    res.status(500).json({
      message: 'Gagal menghapus bahasa',
      error: error.message,
    });
  }
});

module.exports = router;
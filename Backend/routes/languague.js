const express = require('express');
const router = express.Router();
const Language = require('../models/Language');
const { upload } = require('../config/cloudinary'); // Menggunakan config yang sudah ada

// 1. TAMBAH BAHASA BARU (Admin mengunggah logo + nama + warna)
router.post('/', upload.single('icon_file'), async (req, res) => {
  try {
    const { nama_bahasa, warna_tema } = req.body;

    if (!req.file) {
      return res.status(400).json({ message: 'Mohon unggah icon bahasa!' });
    }

    const newLanguage = new Language({
      nama_bahasa,
      warna_tema,
      icon_url: req.file.path, // URL dari Cloudinary
    });

    await newLanguage.save();
    res.status(201).json({ message: 'Bahasa berhasil ditambahkan!', data: newLanguage });
  } catch (error) {
    res.status(500).json({ message: 'Gagal menambah bahasa', error: error.message });
  }
});

// 2. AMBIL SEMUA DAFTAR BAHASA (Untuk tampilan Grid di Flutter)
router.get('/', async (req, res) => {
  try {
    const languages = await Language.find();
    res.status(200).json(languages);
  } catch (error) {
    res.status(500).json({ message: 'Gagal mengambil data bahasa' });
  }
});

module.exports = router;
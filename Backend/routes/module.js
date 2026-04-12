const express = require('express');
const router = express.Router();
const Module = require('../models/Module'); // Memanggil cetak biru Module

// 1. TAMBAH MATERI BARU (POST)
router.post('/', async (req, res) => {
  try {
    const { judul_modul, deskripsi, materi_isi, urutan, is_published } = req.body;
    
    const newModule = new Module({
      judul_modul,
      deskripsi,
      materi_isi,
      urutan,
      is_published
    });

    await newModule.save();
    res.status(201).json({ message: 'Materi berhasil ditambahkan!', data: newModule });
  } catch (error) {
    console.error('Error tambah materi:', error);
    res.status(500).json({ message: 'Gagal menambahkan materi.' });
  }
});

// 2. AMBIL SEMUA MATERI (GET)
router.get('/', async (req, res) => {
  try {
    // Mengambil semua materi dan diurutkan berdasarkan kolom "urutan" (1 = Ascending / Naik)
    const modules = await Module.find().sort({ urutan: 1 });
    res.status(200).json(modules);
  } catch (error) {
    res.status(500).json({ message: 'Gagal mengambil data materi.' });
  }
});

module.exports = router;
const express = require('express');
const router = express.Router();
const Module = require('../models/Module'); // Memanggil cetak biru Module

// 1. TAMBAH MATERI BARU (POST) - DENGAN AUTO-INCREMENT
router.post('/', async (req, res) => {
  try {
    const { judul_modul, deskripsi, materi_isi, is_published } = req.body;
    
    // Cari materi dengan angka urutan paling besar
    const lastModule = await Module.findOne().sort({ urutan: -1 });
    const nextUrutan = lastModule ? lastModule.urutan + 1 : 1; // Kalau kosong, mulai dari 1

    const newModule = new Module({
      judul_modul,
      deskripsi,
      materi_isi,
      urutan: nextUrutan, // <-- Otomatis terisi agar MongoDB tidak error
      is_published: is_published !== undefined ? is_published : true
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

// 3. API ADMIN: EDIT MATERI (PUT)
router.put('/:id', async (req, res) => {
  try {
    const { judul_modul, deskripsi, materi_isi } = req.body;
    
    // Cari materi berdasarkan ID dan langsung update isinya
    const updatedModule = await Module.findByIdAndUpdate(
      req.params.id,
      { judul_modul, deskripsi, materi_isi },
      { returnDocument: 'after' } // <-- Mencegah warning deprecated dari Mongoose
    );

    if (!updatedModule) {
      return res.status(404).json({ message: 'Materi tidak ditemukan' });
    }

    res.status(200).json({ message: 'Materi berhasil diperbarui!', module: updatedModule });
  } catch (error) {
    console.error('Error update materi:', error);
    res.status(500).json({ message: 'Gagal memperbarui materi' });
  }
});

// 4. API ADMIN: HAPUS MATERI (DELETE)
router.delete('/:id', async (req, res) => {
  try {
    await Module.findByIdAndDelete(req.params.id);
    res.status(200).json({ message: 'Materi berhasil dihapus!' });
  } catch (error) {
    console.error('Error hapus materi:', error);
    res.status(500).json({ message: 'Gagal menghapus materi' });
  }
});

module.exports = router;
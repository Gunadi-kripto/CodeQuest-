const express = require('express');
const router = express.Router();
const Module = require('../models/Module'); 
const { upload } = require('../config/cloudinary'); 

// ==========================================
// 1. TAMBAH/UPDATE MATERI (POST) - MULTI-KONTEN
// ==========================================
router.post('/', upload.any(), async (req, res) => {
  try {
    const { id_bahasa, judul_modul, deskripsi, total_items } = req.body;
    
    if (!id_bahasa) {
      return res.status(400).json({ message: 'id_bahasa wajib diisi!' });
    }

    // Tentukan urutan otomatis
    const lastModule = await Module.findOne({ id_bahasa }).sort({ urutan: -1 });
    const nextUrutan = lastModule ? lastModule.urutan + 1 : 1;

    let materi_isi = [];

    // Looping untuk mengambil semua konten (Teks atau Gambar) dari Flutter
    for (let i = 0; i < parseInt(total_items); i++) {
      const type = req.body[`type_${i}`];
      
      if (type === 'text') {
        materi_isi.push({
          tipe: 'text',
          content: req.body[`content_${i}`] || ""
        });
      } else if (type === 'image') {
        // Cek apakah ada file baru yang diupload untuk index ini
        const file = req.files.find(f => f.fieldname === `file_${i}`);
        if (file) {
          materi_isi.push({
            tipe: 'image',
            content: file.path, // URL Cloudinary
            cloudinary_id: file.filename
          });
        } else if (req.body[`content_${i}`]) {
          // Jika gambar lama (saat edit), ambil URL yang sudah ada
          materi_isi.push({
            tipe: 'image',
            content: req.body[`content_${i}`]
          });
        }
      }
    }

    const newModule = new Module({
      id_bahasa,
      judul_modul,
      deskripsi,
      materi_isi,
      urutan: nextUrutan,
      is_published: true
    });

    await newModule.save();
    res.status(201).json({ success: true, message: 'Materi berhasil disimpan!', module: newModule });
  } catch (error) {
    console.error("Error Post Module:", error);
    res.status(500).json({ message: 'Gagal menyimpan materi.', error: error.message });
  }
});

// ==========================================
// 2. AMBIL MATERI BERDASARKAN BAHASA
// ==========================================
router.get('/bahasa/:id_bahasa', async (req, res) => {
  try {
    const modules = await Module.find({ id_bahasa: req.params.id_bahasa }).sort({ urutan: 1 });
    res.status(200).json(modules);
  } catch (error) {
    res.status(500).json({ message: 'Gagal mengambil data materi.' });
  }
});

// ==========================================
// 3. AMBIL SEMUA MATERI
// ==========================================
router.get('/', async (req, res) => {
  try {
    const modules = await Module.find().sort({ urutan: 1 });
    res.status(200).json(modules);
  } catch (error) {
    res.status(500).json({ message: 'Gagal mengambil semua materi.' });
  }
});

// ==========================================
// 4. HAPUS MATERI
// ==========================================
router.delete('/:id', async (req, res) => {
  try {
    const deletedModule = await Module.findByIdAndDelete(req.params.id);
    if (!deletedModule) return res.status(404).json({ message: 'Materi tidak ditemukan' });
    res.status(200).json({ message: 'Materi berhasil dihapus!' });
  } catch (error) {
    res.status(500).json({ message: 'Gagal menghapus materi.' });
  }
});

module.exports = router;
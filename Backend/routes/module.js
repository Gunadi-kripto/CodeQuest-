const express = require('express');
const router = express.Router();
const Module = require('../models/Module'); 
const { upload } = require('../config/cloudinary'); 

// 1. TAMBAH MATERI BARU (POST) - DENGAN id_bahasa
router.post('/', upload.single('materi_file'), async (req, res) => {
  try {
    // 👇 TAMBAHAN PENTING: id_bahasa wajib ditangkap dari frontend
    const { id_bahasa, judul_modul, deskripsi, tipe, materi_teks, caption, is_published } = req.body;
    
    if (!id_bahasa) {
      return res.status(400).json({ message: 'id_bahasa wajib diisi!' });
    }

    // 👇 TAMBAHAN PENTING: Cari urutan khusus untuk bahasa ini saja
    const lastModule = await Module.findOne({ id_bahasa }).sort({ urutan: -1 });
    const nextUrutan = lastModule ? lastModule.urutan + 1 : 1;

    let isiKonten = "";
    let cloudId = null;

    if (tipe === 'text') {
      isiKonten = materi_teks;
    } else if (tipe === 'image') {
      if (!req.file) {
        return res.status(400).json({ message: 'File gambar wajib diunggah!' });
      }
      isiKonten = req.file.path; 
      cloudId = req.file.filename; 
    } else {
      return res.status(400).json({ message: 'Tipe materi tidak valid.' });
    }

    const newModule = new Module({
      id_bahasa, // 👈 Disimpan ke MongoDB
      judul_modul,
      deskripsi,
      materi_isi: [{
        tipe,
        content: isiKonten,
        cloudinary_id: cloudId,
        caption
      }],
      urutan: nextUrutan,
      is_published: is_published !== undefined ? is_published : true
    });

    await newModule.save();
    res.status(201).json({ message: 'Materi berhasil ditambahkan!', data: newModule });
  } catch (error) {
    console.error('Error tambah materi:', error);
    res.status(500).json({ message: 'Gagal menambahkan materi.', error: error.message });
  }
});

// 2. AMBIL MATERI KHUSUS UNTUK BAHASA TERTENTU (GET)
// Frontend akan memanggil: /api/modules/bahasa/ID_PYTHON
router.get('/bahasa/:id_bahasa', async (req, res) => {
  try {
    const modules = await Module.find({ id_bahasa: req.params.id_bahasa }).sort({ urutan: 1 });
    res.status(200).json(modules);
  } catch (error) {
    res.status(500).json({ message: 'Gagal mengambil data materi.' });
  }
});

// 3. AMBIL SEMUA MATERI (Bila sewaktu-waktu butuh)
router.get('/', async (req, res) => {
  try {
    const modules = await Module.find().sort({ urutan: 1 });
    res.status(200).json(modules);
  } catch (error) {
    res.status(500).json({ message: 'Gagal mengambil data materi.' });
  }
});

// 4. API ADMIN: EDIT MATERI (PUT) 
router.put('/:id', async (req, res) => {
  try {
    const { judul_modul, deskripsi, materi_isi } = req.body;
    
    const updatedModule = await Module.findByIdAndUpdate(
      req.params.id,
      { judul_modul, deskripsi, materi_isi },
      { new: true } 
    );

    if (!updatedModule) {
      return res.status(404).json({ message: 'Materi tidak ditemukan' });
    }

    res.status(200).json({ message: 'Materi berhasil diperbarui!', module: updatedModule });
  } catch (error) {
    res.status(500).json({ message: 'Gagal memperbarui materi' });
  }
});

// 5. API ADMIN: HAPUS MATERI (DELETE)
router.delete('/:id', async (req, res) => {
  try {
    await Module.findByIdAndDelete(req.params.id);
    res.status(200).json({ message: 'Materi berhasil dihapus!' });
  } catch (error) {
    res.status(500).json({ message: 'Gagal menghapus materi' });
  }
});

module.exports = router;
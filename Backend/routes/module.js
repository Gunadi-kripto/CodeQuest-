const express = require('express');
const router = express.Router();

const Module = require('../models/Module');
const Quiz = require('../models/Quiz');
const { upload } = require('../config/cloudinary');

// ==========================================
// 1. TAMBAH MATERI - MULTI-KONTEN
// POST /api/modules
// ==========================================
router.post('/', upload.any(), async (req, res) => {
  try {
    const { id_bahasa, judul_modul, deskripsi, total_items } = req.body;

    if (!id_bahasa) {
      return res.status(400).json({
        success: false,
        message: 'id_bahasa wajib diisi!',
      });
    }

    if (!judul_modul) {
      return res.status(400).json({
        success: false,
        message: 'judul_modul wajib diisi!',
      });
    }

    const totalItems = parseInt(total_items || '0');

    if (totalItems <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Minimal harus ada 1 konten materi.',
      });
    }

    // Tentukan urutan otomatis
    const lastModule = await Module.findOne({ id_bahasa }).sort({
      urutan: -1,
    });

    const nextUrutan = lastModule ? lastModule.urutan + 1 : 1;

    const materi_isi = [];

    for (let i = 0; i < totalItems; i++) {
      const type = req.body[`type_${i}`];

      if (type === 'text') {
        materi_isi.push({
          tipe: 'text',
          content: req.body[`content_${i}`] || '',
        });
      }

      if (type === 'image') {
        const file = req.files.find((f) => f.fieldname === `file_${i}`);

        if (file) {
          materi_isi.push({
            tipe: 'image',
            content: file.path,
            cloudinary_id: file.filename,
          });
        } else if (req.body[`content_${i}`]) {
          materi_isi.push({
            tipe: 'image',
            content: req.body[`content_${i}`],
          });
        }
      }
    }

    const newModule = new Module({
      id_bahasa,
      judul_modul,
      deskripsi: deskripsi || '',
      materi_isi,
      urutan: nextUrutan,
      is_published: true,
    });

    await newModule.save();

    res.status(201).json({
      success: true,
      message: 'Materi berhasil disimpan!',
      module: newModule,
    });
  } catch (error) {
    console.error('Error Post Module:', error);

    res.status(500).json({
      success: false,
      message: 'Gagal menyimpan materi.',
      error: error.message,
    });
  }
});

// ==========================================
// 2. UPDATE MATERI - MULTI-KONTEN
// PUT /api/modules/:id
// ==========================================
router.put('/:id', upload.any(), async (req, res) => {
  try {
    const moduleId = req.params.id;

    const existingModule = await Module.findById(moduleId);

    if (!existingModule) {
      return res.status(404).json({
        success: false,
        message: 'Materi tidak ditemukan',
      });
    }

    const { id_bahasa, judul_modul, deskripsi, total_items } = req.body;

    if (!judul_modul) {
      return res.status(400).json({
        success: false,
        message: 'judul_modul wajib diisi!',
      });
    }

    const totalItems = parseInt(total_items || '0');

    if (totalItems <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Minimal harus ada 1 konten materi.',
      });
    }

    const materi_isi = [];

    for (let i = 0; i < totalItems; i++) {
      const type = req.body[`type_${i}`];

      if (type === 'text') {
        materi_isi.push({
          tipe: 'text',
          content: req.body[`content_${i}`] || '',
        });
      }

      if (type === 'image') {
        const file = req.files.find((f) => f.fieldname === `file_${i}`);

        if (file) {
          materi_isi.push({
            tipe: 'image',
            content: file.path,
            cloudinary_id: file.filename,
          });
        } else if (req.body[`content_${i}`]) {
          // gambar lama dari Cloudinary tetap dipakai
          materi_isi.push({
            tipe: 'image',
            content: req.body[`content_${i}`],
          });
        }
      }
    }

    existingModule.id_bahasa = id_bahasa || existingModule.id_bahasa;
    existingModule.judul_modul = judul_modul;
    existingModule.deskripsi = deskripsi || '';
    existingModule.materi_isi = materi_isi;
    existingModule.is_published = true;

    await existingModule.save();

    res.status(200).json({
      success: true,
      message: 'Materi berhasil diupdate!',
      module: existingModule,
    });
  } catch (error) {
    console.error('Error Update Module:', error);

    res.status(500).json({
      success: false,
      message: 'Gagal update materi.',
      error: error.message,
    });
  }
});

// ==========================================
// 3. AMBIL MATERI BERDASARKAN BAHASA
// GET /api/modules/bahasa/:id_bahasa
// ==========================================
router.get('/bahasa/:id_bahasa', async (req, res) => {
  try {
    const modules = await Module.find({
      id_bahasa: req.params.id_bahasa,
    }).sort({ urutan: 1 });

    res.status(200).json(modules);
  } catch (error) {
    res.status(500).json({
      message: 'Gagal mengambil data materi.',
      error: error.message,
    });
  }
});

// ==========================================
// 4. AMBIL SEMUA MATERI
// GET /api/modules
// ==========================================
router.get('/', async (req, res) => {
  try {
    const modules = await Module.find().sort({ urutan: 1 });

    res.status(200).json(modules);
  } catch (error) {
    res.status(500).json({
      message: 'Gagal mengambil semua materi.',
      error: error.message,
    });
  }
});

// ==========================================
// 5. HAPUS MATERI
// DELETE /api/modules/:id
// ==========================================
router.delete('/:id', async (req, res) => {
  try {
    const moduleId = req.params.id;

    const module = await Module.findById(moduleId);

    if (!module) {
      return res.status(404).json({
        message: 'Materi tidak ditemukan',
      });
    }

    // Hapus quiz yang terhubung dengan materi ini
    await Quiz.deleteMany({
      module_id: moduleId,
    });

    // Hapus materi
    await Module.findByIdAndDelete(moduleId);

    res.status(200).json({
      message: 'Materi dan kuis terkait berhasil dihapus',
    });
  } catch (error) {
    res.status(500).json({
      message: 'Gagal menghapus materi',
      error: error.message,
    });
  }
});

module.exports = router;
const express = require('express');
const router = express.Router();

const Achievement = require('../models/Achievement');
const { upload } = require('../config/cloudinary');

// ==========================================
// 1. GET ALL ACHIEVEMENTS
// GET /api/achievements
// ==========================================
router.get('/', async (req, res) => {
  try {
    const achievements = await Achievement.find()
      .populate('language_id')
      .sort({ createdAt: -1 });

    res.status(200).json(achievements);
  } catch (error) {
    console.error('GET ACHIEVEMENTS ERROR:', error);

    res.status(500).json({
      success: false,
      message: 'Gagal mengambil achievement',
      error: error.message,
    });
  }
});

// ==========================================
// 2. ADD ACHIEVEMENT
// POST /api/achievements
// ==========================================
router.post('/', upload.single('icon_file'), async (req, res) => {
  try {
    console.log('BODY ACHIEVEMENT:', req.body);
    console.log('FILE ACHIEVEMENT:', req.file);

    const {
      language_id,
      judul,
      deskripsi,
      syarat_tipe,
      syarat_nilai,
      xp_reward,
      rarity,
    } = req.body;

    if (!judul || !deskripsi || !syarat_tipe || !syarat_nilai || !xp_reward) {
      return res.status(400).json({
        success: false,
        message: 'Semua field wajib diisi',
      });
    }

    const allowedTypes = ['progress_belajar', 'quiz_master', 'xp_reward'];

    if (!allowedTypes.includes(syarat_tipe)) {
      return res.status(400).json({
        success: false,
        message: 'Tipe achievement tidak valid',
      });
    }

    if (syarat_tipe === 'progress_belajar' && !language_id) {
      return res.status(400).json({
        success: false,
        message: 'Bahasa wajib dipilih untuk Progress Belajar',
      });
    }

    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Badge achievement wajib diupload',
      });
    }

    const newAchievement = new Achievement({
      language_id:
        syarat_tipe === 'progress_belajar' && language_id
          ? language_id
          : null,

      judul,
      deskripsi,
      syarat_tipe,
      syarat_nilai: Number(syarat_nilai),
      xp_reward: Number(xp_reward),
      rarity: rarity || 'Common',
      icon_url: req.file.path,
      cloudinary_id: req.file.filename,
      is_active: true,
    });

    await newAchievement.save();

    res.status(201).json({
      success: true,
      message: 'Achievement berhasil ditambahkan',
      data: newAchievement,
    });
  } catch (error) {
    console.error('ADD ACHIEVEMENT ERROR:', error);

    res.status(500).json({
      success: false,
      message: 'Gagal menambah achievement',
      error: error.message,
    });
  }
});

// ==========================================
// 3. UPDATE ACHIEVEMENT
// PUT /api/achievements/:id
// ==========================================
router.put('/:id', upload.single('icon_file'), async (req, res) => {
  try {
    console.log('UPDATE BODY ACHIEVEMENT:', req.body);
    console.log('UPDATE FILE ACHIEVEMENT:', req.file);

    const achievementId = req.params.id;

    const existingAchievement = await Achievement.findById(achievementId);

    if (!existingAchievement) {
      return res.status(404).json({
        success: false,
        message: 'Achievement tidak ditemukan',
      });
    }

    const {
      language_id,
      judul,
      deskripsi,
      syarat_tipe,
      syarat_nilai,
      xp_reward,
      rarity,
      existing_icon,
    } = req.body;

    if (!judul || !deskripsi || !syarat_tipe || !syarat_nilai || !xp_reward) {
      return res.status(400).json({
        success: false,
        message: 'Semua field wajib diisi',
      });
    }

    const allowedTypes = ['progress_belajar', 'quiz_master', 'xp_reward'];

    if (!allowedTypes.includes(syarat_tipe)) {
      return res.status(400).json({
        success: false,
        message: 'Tipe achievement tidak valid',
      });
    }

    if (syarat_tipe === 'progress_belajar' && !language_id) {
      return res.status(400).json({
        success: false,
        message: 'Bahasa wajib dipilih untuk Progress Belajar',
      });
    }

    existingAchievement.language_id =
      syarat_tipe === 'progress_belajar' && language_id
        ? language_id
        : null;

    existingAchievement.judul = judul;
    existingAchievement.deskripsi = deskripsi;
    existingAchievement.syarat_tipe = syarat_tipe;
    existingAchievement.syarat_nilai = Number(syarat_nilai);
    existingAchievement.xp_reward = Number(xp_reward);
    existingAchievement.rarity = rarity || existingAchievement.rarity;
    existingAchievement.is_active = true;

    if (req.file) {
      existingAchievement.icon_url = req.file.path;
      existingAchievement.cloudinary_id = req.file.filename;
    } else if (existing_icon) {
      existingAchievement.icon_url = existing_icon;
    }

    await existingAchievement.save();

    res.status(200).json({
      success: true,
      message: 'Achievement berhasil diupdate',
      data: existingAchievement,
    });
  } catch (error) {
    console.error('UPDATE ACHIEVEMENT ERROR:', error);

    res.status(500).json({
      success: false,
      message: 'Gagal update achievement',
      error: error.message,
    });
  }
});

// ==========================================
// 4. DELETE ACHIEVEMENT
// DELETE /api/achievements/:id
// ==========================================
router.delete('/:id', async (req, res) => {
  try {
    const deletedAchievement = await Achievement.findByIdAndDelete(
      req.params.id
    );

    if (!deletedAchievement) {
      return res.status(404).json({
        success: false,
        message: 'Achievement tidak ditemukan',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Achievement berhasil dihapus',
    });
  } catch (error) {
    console.error('DELETE ACHIEVEMENT ERROR:', error);

    res.status(500).json({
      success: false,
      message: 'Gagal menghapus achievement',
      error: error.message,
    });
  }
});

module.exports = router;
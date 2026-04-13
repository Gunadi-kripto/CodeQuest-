// routes/user.js
const express = require('express');
const router = express.Router();
const User = require('../models/User');
const { upload } = require('../config/cloudinary');

// API untuk Menambah XP User setelah lulus Kuis
router.post('/add-xp', async (req, res) => {
  try {
    const { userId, xpToAdd } = req.body;
    
    // Cari user berdasarkan ID
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'User tidak ditemukan' });
    }

    // Tambahkan XP
    user.total_xp += xpToAdd;

    // Logika Naik Level Otomatis (Setiap 100 XP = Naik 1 Level)
    user.level = Math.floor(user.total_xp / 100) + 1;

    // Simpan ke database
    await user.save();
    
    res.status(200).json({ 
      message: 'XP berhasil ditambahkan!', 
      total_xp: user.total_xp, 
      level: user.level 
    });
  } catch (error) {
    console.error('Error Add XP:', error);
    res.status(500).json({ message: 'Gagal menambahkan XP.' });
  }
});

// API Update Profil (Nama, Bio, dan Avatar)
router.put('/update-profile/:userId', upload.single('avatar'), async (req, res) => {
  try {
    const { userId } = req.params;
    const { nama_lengkap, bio } = req.body;
    
    let updateData = { nama_lengkap, bio };

    // Jika ada file gambar yang diupload, ambil URL-nya dari Cloudinary
    if (req.file) {
      updateData.avatar_url = req.file.path;
    }

    const updatedUser = await User.findByIdAndUpdate(userId, updateData, { new: true });

    res.status(200).json({
      message: 'Profil berhasil diperbarui!',
      user: updatedUser
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Gagal memperbarui profil.' });
  }
});

// API Hapus Akun
router.delete('/delete-account/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    await User.findByIdAndDelete(userId);
    res.status(200).json({ message: 'Akun berhasil dihapus selamanya.' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Gagal menghapus akun.' });
  }
});

module.exports = router;
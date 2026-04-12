const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const User = require('../models/User'); // Memanggil cetak biru database User

// ==========================================
// 1. API REGISTER (BUAT AKUN BARU)
// ==========================================
router.post('/register', async (req, res) => {
  try {
    // Menangkap data yang dikirim dari Flutter/Frontend
    const { nama_lengkap, email, password } = req.body;

    // Cek apakah email sudah terdaftar sebelumnya
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'Email sudah terdaftar! Gunakan email lain.' });
    }

    // Mengacak (Hasing) password agar aman di database
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Membuat user baru menggunakan model
    const newUser = new User({
      nama_lengkap,
      email,
      password_hash: hashedPassword, // Simpan password yang sudah diacak
    });

    // Simpan ke database MongoDB
    await newUser.save();
    
    res.status(201).json({ message: 'Registrasi berhasil! Silakan login.' });
  } catch (error) {
    console.error('Error saat Register:', error);
    res.status(500).json({ message: 'Terjadi kesalahan pada server.' });
  }
});

// ==========================================
// 2. API LOGIN (MASUK AKUN)
// ==========================================
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Cari user berdasarkan email
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: 'Email tidak ditemukan!' });
    }

    // Cek apakah password cocok
    const isPasswordValid = await bcrypt.compare(password, user.password_hash);
    if (!isPasswordValid) {
      return res.status(400).json({ message: 'Password salah!' });
    }

    // Jika sukses, buatkan Token JWT (KTP Digital)
    // Token ini berisi ID dan Role user, berlaku selama 7 hari
    const token = jwt.sign(
      { userId: user._id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    // Kirim token dan data user ke Flutter
    res.status(200).json({
      message: 'Login Berhasil!',
      token: token,
      user: {
        id: user._id,
        nama_lengkap: user.nama_lengkap,
        email: user.email,
        role: user.role,
        level: user.level,
        total_xp: user.total_xp,
        avatar_url: user.avatar_url
      }
    });
  } catch (error) {
    console.error('Error saat Login:', error);
    res.status(500).json({ message: 'Terjadi kesalahan pada server.' });
  }
});

module.exports = router;
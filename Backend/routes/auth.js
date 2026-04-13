//routes/auth.js
const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const User = require('../models/User'); // Memanggil cetak biru database User

// ==========================================
// 1. API REGISTER (DAFTAR AKUN)
// ==========================================
router.post('/register', async (req, res) => {
  try {
    const { nama_lengkap, email, password } = req.body;

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'Email sudah terdaftar! Gunakan email lain.' });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const newUser = new User({
      nama_lengkap,
      email,
      password_hash: hashedPassword,
    });

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

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: 'Email tidak ditemukan!' });
    }

    const isPasswordValid = await bcrypt.compare(password, user.password_hash);
    if (!isPasswordValid) {
      return res.status(400).json({ message: 'Password salah!' });
    }

    const token = jwt.sign(
      { userId: user._id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

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
        bio: user.bio,               // <--- Bio sudah masuk dengan aman
        avatar_url: user.avatar_url  // <--- Avatar sudah masuk dengan aman
      }
    });
  } catch (error) {
    console.error('Error saat Login:', error);
    res.status(500).json({ message: 'Terjadi kesalahan pada server.' });
  }
});

module.exports = router;
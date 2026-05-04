// routes/auth.js
const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { OAuth2Client } = require('google-auth-library'); // TAMBAH: Library Google
const User = require('../models/User'); 

// TAMBAH: Setup Google Client (Pastikan CLIENT_ID di-set di .env nanti)
// Ganti string kosong dengan Client ID Google Cloud milikmu jika belum ada di .env
const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID || "GANTI_DENGAN_CLIENT_ID_GOOGLE_KAMU");

// ==========================================
// 1. API REGISTER (MANUAL)
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
// 2. API LOGIN (MANUAL)
// ==========================================
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: 'Email tidak ditemukan!' });
    }

    // CEK: Jika user ini daftar pakai Google (tidak punya password_hash), larang login manual
    if (!user.password_hash) {
        return res.status(400).json({ message: 'Akun ini terdaftar menggunakan Google. Silakan login via Google.'});
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
        bio: user.bio,              
        avatar_url: user.avatar_url 
      }
    });
  } catch (error) {
    console.error('Error saat Login:', error);
    res.status(500).json({ message: 'Terjadi kesalahan pada server.' });
  }
});

// ==========================================
// 3. API GOOGLE SIGN-IN (TAMBAHAN BARU)
// ==========================================
router.post('/google', async (req, res) => {
    try {
        const { idToken } = req.body; // Token yang dikirim dari Flutter

        if (!idToken) {
            return res.status(400).json({ message: 'Token Google tidak ditemukan!' });
        }

        // 1. Verifikasi token ke Google
        const ticket = await client.verifyIdToken({
            idToken: idToken,
            audience: process.env.GOOGLE_CLIENT_ID || "GANTI_DENGAN_CLIENT_ID_GOOGLE_KAMU", 
        });

        // 2. Ambil data user (payload) dari token Google
        const payload = ticket.getPayload();
        const email = payload['email'];
        const nama_lengkap = payload['name'];
        const avatar_url = payload['picture'];
        const googleId = payload['sub']; // ID unik dari Google

        // 3. Cek apakah user sudah ada di database CodeQuest
        let user = await User.findOne({ email });

        if (user) {
            // JIKA SUDAH ADA: Update googleId atau avatar (opsional) dan anggap Login
            if (!user.googleId) {
                user.googleId = googleId;
                await user.save();
            }
        } else {
            // JIKA BELUM ADA: Otomatis buatkan akun baru (Register via Google)
            user = new User({
                nama_lengkap: nama_lengkap,
                email: email,
                avatar_url: avatar_url, // Pakai foto profil dari Google
                googleId: googleId,
                // password_hash dikosongkan karena login via Google
            });
            await user.save();
        }

        // 4. Buat JWT Token untuk sesi aplikasi (Sama seperti login manual)
        const token = jwt.sign(
            { userId: user._id, role: user.role },
            process.env.JWT_SECRET,
            { expiresIn: '7d' }
        );

        // 5. Kembalikan respons sukses ke Flutter
        res.status(200).json({
            message: 'Login Google Berhasil!',
            token: token,
            user: {
              id: user._id,
              nama_lengkap: user.nama_lengkap,
              email: user.email,
              role: user.role,
              level: user.level,
              total_xp: user.total_xp,
              bio: user.bio,              
              avatar_url: user.avatar_url 
            }
        });

    } catch (error) {
        console.error('Error saat verifikasi Google:', error);
        res.status(401).json({ message: 'Otentikasi Google gagal atau token tidak valid.' });
    }
});

module.exports = router;
const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer'); // Library pengirim email
const { OAuth2Client } = require('google-auth-library');
const User = require('../models/User'); 

const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID || "GANTI_DENGAN_CLIENT_ID_GOOGLE_KAMU");

// =======================================================
// SETTING EMAIL TUMBAL (NODEMAILER)
// =======================================================
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    // ⚠️ MASUKKAN EMAIL TUMBAL DAN APP PASSWORD DI SINI ⚠️
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  }, 
});

// Fungsi pembuat OTP 6 digit dan set kedaluwarsa 2 Menit
const generateOTP = () => {
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  const expiresAt = new Date(Date.now() + 2 * 60 * 1000); // Waktu sekarang + 2 Menit
  return { otp, expiresAt };
};

// ==========================================
// 1. API REGISTER (MANUAL) - MENGIRIM OTP
// ==========================================
router.post('/register', async (req, res) => {
  try {
    const { nama_lengkap, email, password } = req.body;

    let user = await User.findOne({ email });
    
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);
    const { otp, expiresAt } = generateOTP();

    if (user) {
      if (user.is_verified) {
        return res.status(400).json({ message: 'Email sudah terdaftar dan terverifikasi! Silakan login.' });
      }
      // Jika belum diverifikasi, timpa data dengan yang baru dan kirim ulang OTP
      user.nama_lengkap = nama_lengkap;
      user.password_hash = hashedPassword;
      user.otp = otp;
      user.otp_expires_at = expiresAt;
      await user.save();
    } else {
      user = new User({
        nama_lengkap, email, password_hash: hashedPassword,
        otp, otp_expires_at: expiresAt, is_verified: false
      });
      await user.save();
    }

    // Kirim Email OTP
    await transporter.sendMail({
      from: '"CodeQuest Security" <no-reply@codequest.com>',
      to: email,
      subject: 'Verifikasi Akun CodeQuest',
      html: `<h3>Halo ${nama_lengkap}!</h3><p>Kode OTP kamu adalah: <strong>${otp}</strong></p><p>Kode ini hanya berlaku selama 2 menit. Jangan berikan kode ini kepada siapapun.</p>`
    });

    res.status(200).json({ message: 'OTP telah dikirim ke emailmu! Cek kotak masuk atau spam.' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Gagal memproses registrasi.' });
  }
});

// ==========================================
// 2. API VERIFIKASI OTP REGISTRASI
// ==========================================
router.post('/verify-register', async (req, res) => {
  try {
    const { email, otp } = req.body;
    const user = await User.findOne({ email });

    if (!user) return res.status(404).json({ message: 'User tidak ditemukan.' });
    if (user.is_verified) return res.status(400).json({ message: 'Akun ini sudah terverifikasi.' });
    if (user.otp !== otp) return res.status(400).json({ message: 'Kode OTP salah!' });
    if (user.otp_expires_at < new Date()) return res.status(400).json({ message: 'Kode OTP sudah kedaluwarsa (lewat 2 menit)!' });

    // Lolos semua syarat!
    user.is_verified = true;
    user.otp = null;
    user.otp_expires_at = null;
    await user.save();

    res.status(200).json({ message: 'Verifikasi berhasil! Silakan masuk dengan akunmu.' });
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server.' });
  }
});

// ==========================================
// 3. API KIRIM ULANG OTP
// ==========================================
router.post('/resend-otp', async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ email });

    if (!user) return res.status(404).json({ message: 'User tidak ditemukan.' });
    if (user.is_verified && !user.password_hash) return res.status(400).json({ message: 'Gunakan login Google!' });

    const { otp, expiresAt } = generateOTP();
    user.otp = otp;
    user.otp_expires_at = expiresAt;
    await user.save();

    await transporter.sendMail({
      from: '"CodeQuest Security" <no-reply@codequest.com>',
      to: email,
      subject: 'Kirim Ulang OTP CodeQuest',
      html: `<p>Kode OTP baru kamu adalah: <strong>${otp}</strong> (Berlaku 2 Menit)</p>`
    });

    res.status(200).json({ message: 'OTP baru berhasil dikirim!' });
  } catch (error) {
    res.status(500).json({ message: 'Gagal mengirim ulang OTP.' });
  }
});

// ==========================================
// 4. API LOGIN MANUAL (DENGAN CEGATAN VERIFIKASI)
// ==========================================
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });

    if (!user) return res.status(404).json({ message: 'Email tidak ditemukan!' });
    if (!user.password_hash) return res.status(400).json({ message: 'Akun ini terdaftar via Google. Gunakan tombol Google.'});
    
    // Cegat jika belum verifikasi OTP!
    if (!user.is_verified) {
      return res.status(403).json({ message: 'Akun belum diverifikasi! Silakan daftar ulang untuk meminta OTP.', unverified: true });
    }

    const isPasswordValid = await bcrypt.compare(password, user.password_hash);
    if (!isPasswordValid) return res.status(400).json({ message: 'Password salah!' });

    const token = jwt.sign({ userId: user._id, role: user.role }, process.env.JWT_SECRET, { expiresIn: '7d' });
    res.status(200).json({
      message: 'Login Berhasil!', token: token,
      user: { id: user._id, nama_lengkap: user.nama_lengkap, email: user.email, role: user.role, level: user.level, total_xp: user.total_xp, bio: user.bio, avatar_url: user.avatar_url }
    });
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan pada server.' });
  }
});

// ==========================================
// 5. API LUPA PASSWORD (MINTA OTP)
// ==========================================
router.post('/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ email });

    if (!user) return res.status(404).json({ message: 'Email tidak terdaftar!' });
    if (user.googleId || !user.password_hash) return res.status(400).json({ message: 'Akun Google tidak bisa reset password.' });

    const { otp, expiresAt } = generateOTP();
    user.otp = otp;
    user.otp_expires_at = expiresAt;
    await user.save();

    await transporter.sendMail({
      from: '"CodeQuest Security" <no-reply@codequest.com>',
      to: email,
      subject: 'Reset Password CodeQuest',
      html: `<p>Kode OTP untuk reset password kamu: <strong>${otp}</strong> (Berlaku 2 Menit)</p>`
    });

    res.status(200).json({ message: 'OTP Reset Password dikirim ke emailmu!' });
  } catch (error) {
    res.status(500).json({ message: 'Gagal mengirim email reset password.' });
  }
});

// ==========================================
// 6. API RESET PASSWORD (VALIDASI OTP & UBAH PW)
// ==========================================
router.post('/reset-password', async (req, res) => {
  try {
    const { email, otp, newPassword } = req.body;
    const user = await User.findOne({ email });

    if (!user) return res.status(404).json({ message: 'User tidak ditemukan.' });
    if (user.otp !== otp) return res.status(400).json({ message: 'Kode OTP salah!' });
    if (user.otp_expires_at < new Date()) return res.status(400).json({ message: 'Kode OTP sudah kedaluwarsa (lewat 2 menit)!' });

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);

    user.password_hash = hashedPassword;
    user.otp = null;
    user.otp_expires_at = null;
    await user.save();

    res.status(200).json({ message: 'Password berhasil direset! Silakan login.' });
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan saat mereset password.' });
  }
});

// ==========================================
// 7. API GOOGLE SIGN-IN
// ==========================================
router.post('/google', async (req, res) => {
    try {
        const { idToken } = req.body; 
        if (!idToken) return res.status(400).json({ message: 'Token Google tidak ditemukan!' });

        const ticket = await client.verifyIdToken({ idToken: idToken, audience: process.env.GOOGLE_CLIENT_ID || "GANTI_DENGAN_CLIENT_ID_GOOGLE_KAMU" });
        const payload = ticket.getPayload();
        const email = payload['email'];
        const nama_lengkap = payload['name'];
        const avatar_url = payload['picture'];
        const googleId = payload['sub']; 

        let user = await User.findOne({ email });

        if (user) {
            if (!user.googleId) {
                user.googleId = googleId;
                user.is_verified = true; // Langsung verifikasi kalau Google
                await user.save();
            }
        } else {
            user = new User({
                nama_lengkap, email, avatar_url, googleId, is_verified: true
            });
            await user.save();
        }

        const token = jwt.sign({ userId: user._id, role: user.role }, process.env.JWT_SECRET, { expiresIn: '7d' });
        res.status(200).json({
            message: 'Login Google Berhasil!', token: token,
            user: { id: user._id, nama_lengkap: user.nama_lengkap, email: user.email, role: user.role, level: user.level, total_xp: user.total_xp, bio: user.bio, avatar_url: user.avatar_url }
        });
    } catch (error) {
        res.status(401).json({ message: 'Otentikasi Google gagal.' });
    }
});

module.exports = router;
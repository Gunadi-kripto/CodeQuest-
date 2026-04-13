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

// 1. Cari Pengguna (Berdasarkan Nama)
router.get('/search', async (req, res) => {
  try {
    const { query, currentUserId } = req.query; 
    
    // Cari user yang namanya mengandung kata kunci pencarian (mengabaikan huruf besar/kecil)
    // dan pastikan TIDAK memunculkan akun diri sendiri
    const users = await User.find({
      _id: { $ne: currentUserId }, // $ne = Not Equal (bukan ID saya)
      nama_lengkap: { $regex: query, $options: 'i' } 
    }).select('nama_lengkap email avatar_url level total_xp'); // Hanya ambil data aman

    res.status(200).json(users);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Gagal mencari pengguna' });
  }
});

// 2. Kirim Permintaan Pertemanan (Add Friend)
router.post('/request-friend', async (req, res) => {
  try {
    const { senderId, targetId } = req.body;
    
    const targetUser = await User.findById(targetId);
    
    // Validasi: Apakah sudah berteman?
    if (targetUser.friends.includes(senderId)) {
      return res.status(400).json({ message: 'Kalian sudah berteman.' });
    }
    // Validasi: Apakah sudah pernah ngirim request sebelumnya?
    if (targetUser.friend_requests.includes(senderId)) {
      return res.status(400).json({ message: 'Permintaan sudah terkirim, tunggu dia accept.' });
    }

    // Masukkan ID kita ke kotak masuk (friend_requests) target
    targetUser.friend_requests.push(senderId);
    await targetUser.save();

    res.status(200).json({ message: 'Permintaan pertemanan berhasil dikirim!' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Gagal mengirim permintaan pertemanan.' });
  }
});

// 3. Terima Permintaan (Accept Friend)
router.post('/accept-friend', async (req, res) => {
  try {
    const { userId, senderId } = req.body; // userId = kita (yang nerima), senderId = yang ngirim

    const user = await User.findById(userId);
    const sender = await User.findById(senderId);

    // Hapus ID pengirim dari kotak friend_requests kita
    user.friend_requests = user.friend_requests.filter(id => id.toString() !== senderId);
    
    // Tambahkan ID ke daftar teman masing-masing (Saling follow/berteman)
    if (!user.friends.includes(senderId)) user.friends.push(senderId);
    if (!sender.friends.includes(userId)) sender.friends.push(userId);

    await user.save();
    await sender.save();

    res.status(200).json({ message: 'Permintaan diterima! Kalian sekarang berteman.' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Gagal menerima pertemanan.' });
  }
});

// 4. Ambil Daftar Teman & Permintaan Masuk untuk Layar Profil
router.get('/:userId/social', async (req, res) => {
  try {
    const { userId } = req.params;
    
    // Gunakan fungsi .populate() bawaan Mongoose untuk mengubah ID menjadi Data Profil Lengkap
    const user = await User.findById(userId)
      .populate('friends', 'nama_lengkap avatar_url level total_xp bio')
      .populate('friend_requests', 'nama_lengkap avatar_url level');

    if (!user) return res.status(404).json({ message: 'User tidak ditemukan' });

    res.status(200).json({
      friends: user.friends,
      friendRequests: user.friend_requests
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Gagal mengambil data sosial.' });
  }
});

router.get('/leaderboard', async (req, res) => {
  try {
    // Ambil top 10 user dengan XP tertinggi
    // sort({ total_xp: -1 }) artinya diurutkan menurun (Descending)
    const topUsers = await User.find()
      .sort({ total_xp: -1 })
      .limit(10)
      .select('nama_lengkap level total_xp avatar_url'); // Hanya ambil data yang perlu ditampilkan

    res.status(200).json(topUsers);
  } catch (error) {
    console.error('Error Get Leaderboard:', error);
    res.status(500).json({ message: 'Gagal mengambil data leaderboard.' });
  }
});

router.get('/all-users', async (req, res) => {
  try {
    // Ambil semua data user, urutkan dari yang terbaru, dan SEMBUNYIKAN password
    const users = await User.find()
      .select('-password_hash') 
      .sort({ created_at: -1 }); 

    res.status(200).json(users);
  } catch (error) {
    console.error('Error Get All Users:', error);
    res.status(500).json({ message: 'Gagal mengambil data seluruh pengguna.' });
  }
});

module.exports = router;
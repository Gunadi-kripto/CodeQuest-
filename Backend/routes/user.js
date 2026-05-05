const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const User = require('../models/User');
const Achievement = require('../models/Achievement'); 
const { upload } = require('../config/cloudinary');

// =========================================================
// API untuk Menambah XP & TRIGGER ACHIEVEMENT
// =========================================================
router.post('/add-xp', async (req, res) => {
  try {
    const { userId, xpToAdd } = req.body;
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: 'User tidak ditemukan' });

    user.total_xp += xpToAdd;
    user.total_kuis_selesai = (user.total_kuis_selesai || 0) + 1; 
    user.level = Math.floor(user.total_xp / 100) + 1;

    const allAchievements = await Achievement.find();
    let newlyUnlocked = [];

    if (!user.unlocked_achievements) user.unlocked_achievements = [];

    for (let ach of allAchievements) {
      if (user.unlocked_achievements.includes(ach._id)) continue;

      let isUnlocked = false;
      if (ach.syarat_tipe === 'capai_xp' && user.total_xp >= ach.syarat_nilai) isUnlocked = true;
      if (ach.syarat_tipe === 'selesai_kuis' && user.total_kuis_selesai >= ach.syarat_nilai) isUnlocked = true;

      if (isUnlocked) {
        user.unlocked_achievements.push(ach._id);
        newlyUnlocked.push(ach); 
      }
    }

    await user.save();
    
    res.status(200).json({ 
      message: 'XP berhasil ditambahkan!', 
      total_xp: user.total_xp, 
      level: user.level,
      new_achievements: newlyUnlocked 
    });
  } catch (error) {
    console.error('Error Add XP:', error);
    res.status(500).json({ message: 'Gagal menambahkan XP.' });
  }
});

// API Get Profil Spesifik
router.get('/profile/:userId', async (req, res) => {
  try {
    const user = await User.findById(req.params.userId);
    res.status(200).json(user);
  } catch(e) { 
    res.status(500).json({message: 'Gagal mengambil profil'}); 
  }
});

// API Update Profil
router.put('/update-profile/:userId', upload.single('avatar'), async (req, res) => {
  try {
    const { userId } = req.params;
    const { nama_lengkap, bio } = req.body;
    let updateData = { nama_lengkap, bio };
    if (req.file) updateData.avatar_url = req.file.path;
    const updatedUser = await User.findByIdAndUpdate(userId, updateData, { new: true });
    res.status(200).json({ message: 'Profil berhasil diperbarui!', user: updatedUser });
  } catch (error) { res.status(500).json({ message: 'Gagal memperbarui profil.' }); }
});

// =========================================================
// API HAPUS AKUN (DENGAN BYPASS GOOGLE)
// =========================================================
router.post('/delete-account/:userId', async (req, res) => {
  try {
    const { password } = req.body;
    const user = await User.findById(req.params.userId);
    
    if (!user) return res.status(404).json({ message: 'User tidak ditemukan' });

    // Cek apakah ini Akun Google (tidak punya password_hash / ada googleId)
    if (!user.password_hash || user.googleId) {
      if (password !== 'HAPUS') {
        return res.status(400).json({ message: 'Ini adalah akun Google. Ketik kata "HAPUS" untuk mengonfirmasi.' });
      }
    } else {
      // Jika akun biasa, cek password
      const isMatch = await bcrypt.compare(password, user.password_hash);
      if (!isMatch) {
        return res.status(400).json({ message: 'Password salah! Akun gagal dihapus.' });
      }
    }

    await User.findByIdAndDelete(req.params.userId);
    res.status(200).json({ message: 'Akun berhasil dihapus selamanya.' });
  } catch (error) { 
    console.error(error);
    res.status(500).json({ message: 'Terjadi kesalahan server.' }); 
  }
});

// Cari Pengguna - TANPA ADMIN
router.get('/search', async (req, res) => {
  try {
    const { query, currentUserId } = req.query; 
    const users = await User.find({ _id: { $ne: currentUserId }, role: { $ne: 'admin' }, nama_lengkap: { $regex: query, $options: 'i' } }).select('nama_lengkap email avatar_url level total_xp'); 
    res.status(200).json(users);
  } catch (error) { res.status(500).json({ message: 'Gagal mencari pengguna' }); }
});

// Kirim Permintaan Pertemanan
router.post('/request-friend', async (req, res) => {
  try {
    const { senderId, targetId } = req.body;
    const targetUser = await User.findById(targetId);
    if (targetUser.friends.includes(senderId)) return res.status(400).json({ message: 'Kalian sudah berteman.' });
    if (targetUser.friend_requests.includes(senderId)) return res.status(400).json({ message: 'Permintaan sudah terkirim.' });
    targetUser.friend_requests.push(senderId);
    await targetUser.save();
    res.status(200).json({ message: 'Permintaan pertemanan berhasil dikirim!' });
  } catch (error) { res.status(500).json({ message: 'Gagal mengirim permintaan pertemanan.' }); }
});

// Terima Permintaan
router.post('/accept-friend', async (req, res) => {
  try {
    const { userId, senderId } = req.body; 
    const user = await User.findById(userId);
    const sender = await User.findById(senderId);
    user.friend_requests = user.friend_requests.filter(id => id.toString() !== senderId);
    if (!user.friends.includes(senderId)) user.friends.push(senderId);
    if (!sender.friends.includes(userId)) sender.friends.push(userId);
    await user.save();
    await sender.save();
    res.status(200).json({ message: 'Permintaan diterima! Kalian sekarang berteman.' });
  } catch (error) { res.status(500).json({ message: 'Gagal menerima pertemanan.' }); }
});

// Ambil Daftar Teman
router.get('/:userId/social', async (req, res) => {
  try {
    const user = await User.findById(req.params.userId).populate('friends', 'nama_lengkap avatar_url level total_xp bio').populate('friend_requests', 'nama_lengkap avatar_url level');
    if (!user) return res.status(404).json({ message: 'User tidak ditemukan' });
    res.status(200).json({ friends: user.friends, friendRequests: user.friend_requests });
  } catch (error) { res.status(500).json({ message: 'Gagal mengambil data sosial.' }); }
});

// Leaderboard - TANPA ADMIN
router.get('/leaderboard', async (req, res) => {
  try {
    const topUsers = await User.find({ role: { $ne: 'admin' } }).sort({ total_xp: -1 }).limit(10).select('nama_lengkap level total_xp avatar_url'); 
    res.status(200).json(topUsers);
  } catch (error) { res.status(500).json({ message: 'Gagal mengambil data leaderboard.' }); }
});

router.get('/all-users', async (req, res) => {
  try {
    const users = await User.find().select('-password_hash').sort({ created_at: -1 }); 
    res.status(200).json(users);
  } catch (error) { res.status(500).json({ message: 'Gagal mengambil data seluruh pengguna.' }); }
});

// API ADMIN: HAPUS USER PAKSA 
router.delete('/admin/force-delete/:userId', async (req, res) => {
  try {
    await User.findByIdAndDelete(req.params.userId);
    res.status(200).json({ message: 'User berhasil dihapus paksa oleh Admin.' });
  } catch (error) { res.status(500).json({ message: 'Gagal menghapus user.' }); }
});

module.exports = router;
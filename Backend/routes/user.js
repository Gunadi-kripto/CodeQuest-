const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');

const User = require('../models/User');
const UserProgress = require('../models/UserProgress');
const { upload } = require('../config/cloudinary');
const checkAndUnlockAchievements = require('../utils/checkAchievements');
const calculateLevel = require('../utils/calculateLevel');

// ==========================================
// TAMBAH XP USER + CEK ACHIEVEMENT XP
// POST /api/users/add-xp
// ==========================================
router.post('/add-xp', async (req, res) => {
  try {
    const { userId, xpToAdd } = req.body;

    if (!userId || xpToAdd === undefined) {
      return res.status(400).json({
        success: false,
        message: 'userId dan xpToAdd wajib dikirim',
      });
    }

    const xpNumber = Number(xpToAdd);

    if (Number.isNaN(xpNumber) || xpNumber <= 0) {
      return res.status(400).json({
        success: false,
        message: 'XP harus berupa angka lebih dari 0',
      });
    }

    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User tidak ditemukan',
      });
    }

    user.total_xp = (user.total_xp || 0) + xpNumber;
    user.level = calculateLevel(user.total_xp || 0);

    await user.save();

    const newAchievements = await checkAndUnlockAchievements(userId);

    const updatedUser = await User.findById(userId)
      .select('-password_hash')
      .populate('unlocked_achievements');

    return res.status(200).json({
      success: true,
      message: 'XP berhasil ditambahkan',
      total_xp: updatedUser.total_xp,
      level: updatedUser.level,
      new_achievements: newAchievements,
      user: updatedUser,
    });
  } catch (error) {
    console.error('ADD XP ERROR:', error);

    return res.status(500).json({
      success: false,
      message: 'Gagal menambahkan XP',
      error: error.message,
    });
  }
});

// ==========================================
// GET PROFIL USER
// GET /api/users/profile/:userId
// ==========================================
router.get('/profile/:userId', async (req, res) => {
  try {
    const user = await User.findById(req.params.userId)
      .select('-password_hash')
      .populate('unlocked_achievements');

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User tidak ditemukan',
      });
    }

    return res.status(200).json(user);
  } catch (error) {
    console.error('GET PROFILE ERROR:', error);

    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil profil',
      error: error.message,
    });
  }
});

// ==========================================
// UPDATE PROFIL USER
// PUT /api/users/update-profile/:userId
// ==========================================
router.put('/update-profile/:userId', upload.single('avatar'), async (req, res) => {
  try {
    const { userId } = req.params;
    const { nama_lengkap, bio } = req.body;

    const updateData = {
      nama_lengkap,
      bio,
    };

    if (req.file) {
      updateData.avatar_url = req.file.path;
    }

    const updatedUser = await User.findByIdAndUpdate(userId, updateData, {
      new: true,
    })
      .select('-password_hash')
      .populate('unlocked_achievements');

    if (!updatedUser) {
      return res.status(404).json({
        success: false,
        message: 'User tidak ditemukan',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Profil berhasil diperbarui!',
      user: updatedUser,
    });
  } catch (error) {
    console.error('UPDATE PROFILE ERROR:', error);

    return res.status(500).json({
      success: false,
      message: 'Gagal memperbarui profil.',
      error: error.message,
    });
  }
});

// ==========================================
// HAPUS AKUN USER SENDIRI
// POST /api/users/delete-account/:userId
// ==========================================
router.post('/delete-account/:userId', async (req, res) => {
  try {
    const { password } = req.body;
    const { userId } = req.params;

    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User tidak ditemukan',
      });
    }

    if (!user.password_hash || user.googleId) {
      if (password !== 'HAPUS') {
        return res.status(400).json({
          success: false,
          message:
            'Ini adalah akun Google. Ketik kata "HAPUS" untuk mengonfirmasi.',
        });
      }
    } else {
      const isMatch = await bcrypt.compare(password, user.password_hash);

      if (!isMatch) {
        return res.status(400).json({
          success: false,
          message: 'Password salah! Akun gagal dihapus.',
        });
      }
    }

    await UserProgress.deleteMany({ user_id: userId });
    await User.findByIdAndDelete(userId);

    return res.status(200).json({
      success: true,
      message: 'Akun berhasil dihapus selamanya.',
    });
  } catch (error) {
    console.error('DELETE ACCOUNT ERROR:', error);

    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan server.',
      error: error.message,
    });
  }
});

// ==========================================
// CARI PENGGUNA - TANPA ADMIN
// GET /api/users/search?query=...&currentUserId=...
// ==========================================
router.get('/search', async (req, res) => {
  try {
    const { query = '', currentUserId } = req.query;

    const users = await User.find({
      _id: { $ne: currentUserId },
      role: { $ne: 'admin' },
      $or: [
        { nama_lengkap: { $regex: query, $options: 'i' } },
        { email: { $regex: query, $options: 'i' } },
      ],
    }).select('nama_lengkap email avatar_url level total_xp bio');

    return res.status(200).json(users);
  } catch (error) {
    console.error('SEARCH USER ERROR:', error);

    return res.status(500).json({
      success: false,
      message: 'Gagal mencari pengguna',
      error: error.message,
    });
  }
});

// ==========================================
// KIRIM PERMINTAAN PERTEMANAN
// POST /api/users/request-friend
// ==========================================
router.post('/request-friend', async (req, res) => {
  try {
    const { senderId, targetId } = req.body;

    if (!senderId || !targetId) {
      return res.status(400).json({
        success: false,
        message: 'senderId dan targetId wajib dikirim',
      });
    }

    const targetUser = await User.findById(targetId);

    if (!targetUser) {
      return res.status(404).json({
        success: false,
        message: 'Target user tidak ditemukan',
      });
    }

    if (targetUser.friends.includes(senderId)) {
      return res.status(400).json({
        success: false,
        message: 'Kalian sudah berteman.',
      });
    }

    if (targetUser.friend_requests.includes(senderId)) {
      return res.status(400).json({
        success: false,
        message: 'Permintaan sudah terkirim.',
      });
    }

    targetUser.friend_requests.push(senderId);
    await targetUser.save();

    return res.status(200).json({
      success: true,
      message: 'Permintaan pertemanan berhasil dikirim!',
    });
  } catch (error) {
    console.error('REQUEST FRIEND ERROR:', error);

    return res.status(500).json({
      success: false,
      message: 'Gagal mengirim permintaan pertemanan.',
      error: error.message,
    });
  }
});

// ==========================================
// TERIMA PERMINTAAN TEMAN
// POST /api/users/accept-friend
// ==========================================
router.post('/accept-friend', async (req, res) => {
  try {
    const { userId, senderId } = req.body;

    const user = await User.findById(userId);
    const sender = await User.findById(senderId);

    if (!user || !sender) {
      return res.status(404).json({
        success: false,
        message: 'User tidak ditemukan',
      });
    }

    user.friend_requests = user.friend_requests.filter(
      (id) => id.toString() !== senderId
    );

    if (!user.friends.includes(senderId)) {
      user.friends.push(senderId);
    }

    if (!sender.friends.includes(userId)) {
      sender.friends.push(userId);
    }

    await user.save();
    await sender.save();

    return res.status(200).json({
      success: true,
      message: 'Permintaan diterima! Kalian sekarang berteman.',
    });
  } catch (error) {
    console.error('ACCEPT FRIEND ERROR:', error);

    return res.status(500).json({
      success: false,
      message: 'Gagal menerima pertemanan.',
      error: error.message,
    });
  }
});

// ==========================================
// TOLAK PERMINTAAN TEMAN
// POST /api/users/reject-friend
// ==========================================
router.post('/reject-friend', async (req, res) => {
  try {
    const { userId, senderId } = req.body;

    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User tidak ditemukan',
      });
    }

    user.friend_requests = user.friend_requests.filter(
      (id) => id.toString() !== senderId
    );

    await user.save();

    return res.status(200).json({
      success: true,
      message: 'Permintaan pertemanan ditolak.',
    });
  } catch (error) {
    console.error('REJECT FRIEND ERROR:', error);

    return res.status(500).json({
      success: false,
      message: 'Gagal menolak permintaan.',
      error: error.message,
    });
  }
});

// ==========================================
// HAPUS TEMAN
// POST /api/users/remove-friend
// ==========================================
router.post('/remove-friend', async (req, res) => {
  try {
    const { userId, friendId } = req.body;

    const user = await User.findById(userId);
    const friend = await User.findById(friendId);

    if (!user || !friend) {
      return res.status(404).json({
        success: false,
        message: 'User tidak ditemukan',
      });
    }

    user.friends = user.friends.filter((id) => id.toString() !== friendId);
    friend.friends = friend.friends.filter((id) => id.toString() !== userId);

    await user.save();
    await friend.save();

    return res.status(200).json({
      success: true,
      message: 'Berhasil menghapus pertemanan.',
    });
  } catch (error) {
    console.error('REMOVE FRIEND ERROR:', error);

    return res.status(500).json({
      success: false,
      message: 'Gagal menghapus pertemanan.',
      error: error.message,
    });
  }
});

// ==========================================
// AMBIL DATA SOSIAL USER
// GET /api/users/:userId/social
// ==========================================
router.get('/:userId/social', async (req, res) => {
  try {
    const user = await User.findById(req.params.userId)
      .populate('friends', 'nama_lengkap avatar_url level total_xp bio')
      .populate('friend_requests', 'nama_lengkap avatar_url level');

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User tidak ditemukan',
      });
    }

    return res.status(200).json({
      success: true,
      friends: user.friends,
      friendRequests: user.friend_requests,
    });
  } catch (error) {
    console.error('GET SOCIAL ERROR:', error);

    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil data sosial.',
      error: error.message,
    });
  }
});

// ==========================================
// LEADERBOARD - TANPA ADMIN
// GET /api/users/leaderboard
// ==========================================
router.get('/leaderboard', async (req, res) => {
  try {
    const topUsers = await User.find({
      role: { $ne: 'admin' },
    })
      .sort({ total_xp: -1 })
      .limit(10)
      .select('nama_lengkap level total_xp avatar_url');

    return res.status(200).json(topUsers);
  } catch (error) {
    console.error('GET LEADERBOARD ERROR:', error);

    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil data leaderboard.',
      error: error.message,
    });
  }
});

// ==========================================
// ADMIN: AMBIL SEMUA USER + HITUNG PROGRESS REALTIME
// GET /api/users/all-users
// ==========================================
router.get('/all-users', async (req, res) => {
  try {
    const users = await User.find()
      .select('-password_hash')
      .sort({ created_at: -1 })
      .lean();

    const usersWithProgress = await Promise.all(
      users.map(async (user) => {
        const totalMateri = await UserProgress.countDocuments({
          user_id: user._id,
          tipe_progress: 'materi',
          is_completed: true,
        });

        const totalKuis = await UserProgress.countDocuments({
          user_id: user._id,
          tipe_progress: 'quiz',
          is_completed: true,
        });

        return {
          ...user,
          total_materi_dibaca: totalMateri,
          total_kuis_selesai: totalKuis,
        };
      })
    );

    return res.status(200).json(usersWithProgress);
  } catch (error) {
    console.error('GET ALL USERS ERROR:', error);

    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil data seluruh pengguna.',
      error: error.message,
    });
  }
});

// ==========================================
// ADMIN: HAPUS USER PAKSA + HAPUS PROGRESS
// DELETE /api/users/admin/force-delete/:userId
// ==========================================
router.delete('/admin/force-delete/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    await UserProgress.deleteMany({ user_id: userId });
    await User.findByIdAndDelete(userId);

    return res.status(200).json({
      success: true,
      message: 'User dan progress berhasil dihapus paksa oleh Admin.',
    });
  } catch (error) {
    console.error('FORCE DELETE USER ERROR:', error);

    return res.status(500).json({
      success: false,
      message: 'Gagal menghapus user.',
      error: error.message,
    });
  }
});

// ==========================================
// ADMIN: STATISTIK DASHBOARD USER
// GET /api/users/admin/stats
// ==========================================
router.get('/admin/stats', async (req, res) => {
  try {
    const totalUsers = await User.countDocuments();

    const xpResult = await User.aggregate([
      {
        $group: {
          _id: null,
          totalXp: { $sum: '$total_xp' },
        },
      },
    ]);

    const totalQuiz = await UserProgress.countDocuments({
      tipe_progress: 'quiz',
      is_completed: true,
    });

    const totalMateri = await UserProgress.countDocuments({
      tipe_progress: 'materi',
      is_completed: true,
    });

    return res.status(200).json({
      success: true,
      data: {
        total_users: totalUsers,
        total_xp: xpResult.length > 0 ? xpResult[0].totalXp : 0,
        total_quiz: totalQuiz,
        total_materi: totalMateri,
      },
    });
  } catch (error) {
    console.error('ADMIN STATS ERROR:', error);

    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil statistik admin',
      error: error.message,
    });
  }
});

// ==========================================
// ADMIN: DETAIL MATERI USER
// GET /api/users/admin/:userId/materials
// ==========================================
router.get('/admin/:userId/materials', async (req, res) => {
  try {
    const data = await UserProgress.find({
      user_id: req.params.userId,
      tipe_progress: 'materi',
      is_completed: true,
    })
      .populate({
        path: 'module_id',
        populate: {
          path: 'id_bahasa',
        },
      })
      .sort({ tanggal_selesai: -1 });

    return res.status(200).json({
      success: true,
      data,
    });
  } catch (error) {
    console.error('ADMIN USER MATERIALS ERROR:', error);

    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil materi user',
      error: error.message,
    });
  }
});

// ==========================================
// ADMIN: DETAIL QUIZ USER
// GET /api/users/admin/:userId/quizzes
// ==========================================
router.get('/admin/:userId/quizzes', async (req, res) => {
  try {
    const data = await UserProgress.find({
      user_id: req.params.userId,
      tipe_progress: 'quiz',
      is_completed: true,
    })
      .populate({
        path: 'quiz_id',
        populate: {
          path: 'module_id',
        },
      })
      .populate('module_id')
      .sort({ tanggal_selesai: -1 });

    return res.status(200).json({
      success: true,
      data,
    });
  } catch (error) {
    console.error('ADMIN USER QUIZZES ERROR:', error);

    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil quiz user',
      error: error.message,
    });
  }
});

// ==========================================
// ADMIN: DETAIL ACHIEVEMENT USER
// GET /api/users/admin/:userId/achievements
// ==========================================
router.get('/admin/:userId/achievements', async (req, res) => {
  try {
    const user = await User.findById(req.params.userId)
      .select('unlocked_achievements')
      .populate('unlocked_achievements');

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User tidak ditemukan',
      });
    }

    return res.status(200).json({
      success: true,
      data: user.unlocked_achievements || [],
    });
  } catch (error) {
    console.error('ADMIN USER ACHIEVEMENTS ERROR:', error);

    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil achievement user',
      error: error.message,
    });
  }
});

module.exports = router;
// models/User.js
const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  nama_lengkap: { 
    type: String, 
    required: true 
  },
  email: { 
    type: String, 
    required: true, 
    unique: true 
  },
  // UBAH: password_hash tidak lagi wajib, karena user Google tidak punya password
  password_hash: { 
    type: String, 
    required: false 
  },
  // TAMBAH: Penanda login via Google
  googleId: { 
    type: String, 
    required: false,
    unique: true, // Opsional: pastikan 1 ID Google hanya untuk 1 akun
    sparse: true  // Mengizinkan nilai null/undefined (untuk user manual)
  },
  avatar_url: { 
    type: String, 
    default: "" 
  },
  bio: { 
    type: String, 
    default: '' 
  },
  role: { 
    type: String, 
    default: "user" 
  },
  total_xp: { 
    type: Number, 
    default: 0 
  },
  level: { 
    type: Number, 
    default: 1 
  },
  achievement: { 
    type: Boolean, 
    default: false 
  },
  friends: [{ 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User' 
  }],
  friend_requests: [{ 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User' 
  }]
}, {
  timestamps: { createdAt: 'created_at', updatedAt: false }
});

module.exports = mongoose.model('User', userSchema);
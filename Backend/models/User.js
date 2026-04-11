const mongoose = require('mongoose');

// Membuat rancangan (blueprint) untuk data Pengguna
const userSchema = new mongoose.Schema({
  nama_lengkap: { 
    type: String, 
    required: true 
  },
  email: { 
    type: String, 
    required: true, 
    unique: true // Email tidak boleh ada yang sama
  },
  password_hash: { 
    type: String, 
    required: true 
  },
  avatar_url: { 
    type: String, 
    default: "" // Kosong secara default sampai diisi dari Cloudinary
  },
  role: { 
    type: String, 
    default: "user" // Defaultnya pengguna biasa, bukan admin
  },
  total_xp: { 
    type: Number, 
    default: 0 
  },
  level: { 
    type: Number, 
    default: 1 // Level awal selalu 1
  },
  achievement: { 
    type: Boolean, 
    default: false 
  }
}, {
  // Otomatis membuat kolom created_at
  timestamps: { createdAt: 'created_at', updatedAt: false }
});

// Mengekspor model agar bisa dipakai di file lain
module.exports = mongoose.model('User', userSchema);
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
  password_hash: { 
    type: String, 
    required: false 
  },
  googleId: { 
    type: String, 
    required: false,
    unique: true, 
    sparse: true  
  },
  // === TAMBAHAN UNTUK SISTEM OTP ===
  is_verified: {
    type: Boolean,
    default: false
  },
  otp: {
    type: String,
    default: null
  },
  otp_expires_at: {
    type: Date,
    default: null
  },
  // =================================
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

  daily_chat_count: { 
    type: Number, default: 0 
  },
  last_chat_date: { 
    type: Date, default: Date.now
   },
  total_materi_dibaca: { 
    type: Number, 
    default: 0 
  },
  total_kuis_selesai: { 
    type: Number, 
    default: 0 
  },
  unlocked_achievements: [{ 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Achievement' 
  }],
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
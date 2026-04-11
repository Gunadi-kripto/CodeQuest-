const mongoose = require('mongoose');

const userProgressSchema = new mongoose.Schema({
  user_id: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', // Relasi ke pengguna
    required: true 
  },
  quiz_id: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Quiz', // Relasi ke kuis yang dikerjakan
    required: true 
  },
  status_benar: { 
    type: Boolean, 
    default: false 
  }
}, {
  // Kita custom agar nama timestamp-nya sesuai dengan tabel CP-300 kamu
  timestamps: { createdAt: 'tanggal_selesai', updatedAt: false }
});

module.exports = mongoose.model('UserProgress', userProgressSchema);
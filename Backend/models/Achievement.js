const mongoose = require('mongoose');

const achievementSchema = new mongoose.Schema({
  judul: { 
    type: String, 
    required: true 
  },
  deskripsi: { 
    type: String, 
    required: true 
  },
  syarat_tipe: { 
    type: String, 
    enum: ['baca_materi', 'selesai_kuis', 'capai_xp', 'tambah_teman'], 
    required: true 
  },
  syarat_nilai: { 
    type: Number, 
    required: true 
  },
  icon: { 
    type: String, 
    default: 'emoji_events' // Nama default icon bawaan material flutter
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('Achievement', achievementSchema);
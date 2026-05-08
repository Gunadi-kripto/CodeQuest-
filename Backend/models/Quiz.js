const mongoose = require('mongoose');

const quizSchema = new mongoose.Schema({
  module_id: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Module', // Relasi ke koleksi Modules
    required: true 
  },
  pertanyaan: { 
    type: String, 
    required: true 
  },
  // TAMBAHAN: Menyimpan 4 pilihan jawaban
  opsi: [
    { type: String, required: true }
  ],
  // SEKARANG: Berupa angka index (0 = A, 1 = B, 2 = C, 3 = D)
  jawaban_benar: { 
    type: Number, 
    required: true 
  },
  hint: { 
    type: String, 
    default: "" 
  },
  xp_reward: { 
    type: Number, 
    required: true,
    default: 10
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('Quiz', quizSchema);
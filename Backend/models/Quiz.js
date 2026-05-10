const mongoose = require('mongoose');

const quizSchema = new mongoose.Schema({
  module_id: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Module', // Relasi ke koleksi Modules
    required: true 
  },
  // Menggunakan Array untuk menampung banyak soal dalam satu kuis
  daftar_soal: [
    {
      pertanyaan: { 
        type: String, 
        required: true 
      },
      opsi: { 
        type: [String], // ArrayOfString untuk 4 pilihan (A, B, C, D)
        required: true,
        validate: [arrayLimit, '{PATH} harus memiliki 4 pilihan jawaban']
      },
      jawaban_benar: { 
        type: Number, // Menyimpan index jawaban (0, 1, 2, atau 3)
        required: true 
      },
      hint: { 
        type: String, 
        default: "" 
      }
    }
  ],
  xp_reward: { 
    type: Number, 
    required: true,
    default: 20 // XP biasanya lebih besar karena satu kuis punya banyak soal
  }
}, {
  timestamps: true
});

// Fungsi validasi agar opsi selalu berjumlah 4
function arrayLimit(val) {
  return val.length === 4;
}

module.exports = mongoose.model('Quiz', quizSchema);
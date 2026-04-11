const mongoose = require('mongoose');

const quizSchema = new mongoose.Schema({
  module_id: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Module', // Relasi ke koleksi Modules (Foreign Key)
    required: true 
  },
  pertanyaan: { 
    type: String, 
    required: true 
  },
  kunci_jawaban: { 
    type: String, 
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
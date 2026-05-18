const mongoose = require('mongoose');

const userProgressSchema = new mongoose.Schema(
  {
    user_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },

    // Untuk progress materi
    module_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Module',
      default: null,
    },

    // Untuk progress kuis
    quiz_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Quiz',
      default: null,
    },

    // jenis progress: materi atau quiz
    tipe_progress: {
      type: String,
      enum: ['materi', 'quiz'],
      required: true,
    },

    // Untuk materi: true kalau user sudah selesai baca materi
    is_completed: {
      type: Boolean,
      default: false,
    },

    // Untuk quiz: true kalau jawaban / hasil quiz benar atau lulus
    status_benar: {
      type: Boolean,
      default: false,
    },

    // Optional, kalau nanti kamu mau simpan nilai quiz
    skor: {
      type: Number,
      default: 0,
    },
  },
  {
    timestamps: {
      createdAt: 'tanggal_selesai',
      updatedAt: false,
    },
  }
);

// Supaya 1 user tidak bisa menyelesaikan materi yang sama berkali-kali
userProgressSchema.index(
  { user_id: 1, module_id: 1, tipe_progress: 1 },
  {
    unique: true,
    partialFilterExpression: {
      tipe_progress: 'materi',
      module_id: { $type: 'objectId' },
    },
  }
);

// Supaya 1 user tidak dobel progress untuk quiz yang sama
userProgressSchema.index(
  { user_id: 1, quiz_id: 1, tipe_progress: 1 },
  {
    unique: true,
    partialFilterExpression: {
      tipe_progress: 'quiz',
      quiz_id: { $type: 'objectId' },
    },
  }
);

module.exports = mongoose.model('UserProgress', userProgressSchema);
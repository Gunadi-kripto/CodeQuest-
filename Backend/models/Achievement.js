const mongoose = require('mongoose');

const achievementSchema = new mongoose.Schema(
  {
    // Untuk Progress Belajar: wajib ada language_id
    // Untuk Quiz Master dan XP Reward: boleh null karena global
    language_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Language',
      required: false,
      default: null,
    },

    judul: {
      type: String,
      required: true,
      trim: true,
    },

    deskripsi: {
      type: String,
      required: true,
      trim: true,
    },

    // Disamakan dengan value dari Flutter:
    // progress_belajar, quiz_master, xp_reward
    syarat_tipe: {
      type: String,
      enum: ['progress_belajar', 'quiz_master', 'xp_reward'],
      required: true,
    },

    syarat_nilai: {
      type: Number,
      required: true,
      default: 1,
    },

    xp_reward: {
      type: Number,
      required: true,
      default: 0,
    },

    rarity: {
      type: String,
      enum: ['Common', 'Rare', 'Epic', 'Legendary'],
      default: 'Common',
    },

    // URL gambar badge dari Cloudinary
    icon_url: {
      type: String,
      default: '',
    },

    // ID file di Cloudinary, berguna kalau nanti mau hapus file dari Cloudinary
    cloudinary_id: {
      type: String,
      default: '',
    },

    is_active: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Achievement', achievementSchema);
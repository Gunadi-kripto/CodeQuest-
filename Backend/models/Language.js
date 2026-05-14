const mongoose = require('mongoose');

const languageSchema = new mongoose.Schema({
  nama_bahasa: {
    type: String,
    required: true,
    unique: true
  },
  icon_url: {
    type: String,
    required: true
  },
  warna_tema: {
    type: String,
    default: '#4CAF50'
  }
}, { timestamps: true });

module.exports = mongoose.model('Language', languageSchema);
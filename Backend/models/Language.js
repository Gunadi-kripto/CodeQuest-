const mongoose = require('mongoose');

const languageSchema = new mongoose.Schema({
  nama_bahasa: { 
    type: String, 
    required: true,
    unique: true 
  },
  icon_url: { 
    type: String, // URL dari Cloudinary untuk logo Python/Java
    required: true 
  },
  warna_tema: { 
    type: String, // Kode Hex Warna (misal: #4CAF50)
    default: '#4CAF50' 
  }
}, { timestamps: true });

module.exports = mongoose.model('Language', languageSchema);
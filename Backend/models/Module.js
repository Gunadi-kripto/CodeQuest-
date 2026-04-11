const mongoose = require('mongoose');

const moduleSchema = new mongoose.Schema({
  judul_modul: { 
    type: String, 
    required: true 
  },
  deskripsi: { 
    type: String, 
    required: true 
  },
  materi_isi: { 
    type: String, 
    required: true // Tambahan baru dari tabelmu!
  },
  urutan: { 
    type: Number, 
    required: true 
  },
  is_published: { 
    type: Boolean, 
    default: false // Secara default disembunyikan sampai admin siap
  }
}, {
  timestamps: true // Otomatis membuat createdAt dan updatedAt
});

module.exports = mongoose.model('Module', moduleSchema);
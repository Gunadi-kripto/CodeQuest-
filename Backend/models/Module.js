const mongoose = require('mongoose');

const moduleSchema = new mongoose.Schema({
  // TAMBAHAN BARU: Relasi ke tabel Language (Bahasa)
  id_bahasa: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Language',
    required: true // Wajib diisi agar kita tahu modul ini milik Python, Java, dll.
  },
  judul_modul: { 
    type: String, 
    required: true 
  },
  deskripsi: { 
    type: String, 
    required: true 
  },
  // Gunakan struktur Array of Objects agar fleksibel (Teks dan Gambar)
  materi_isi: [
    {
      tipe: { 
        type: String, 
        enum: ['text', 'image'], // Video sudah dihapus
        required: true 
      },
      content: { 
        type: String, 
        required: true 
      }, 
      // Tambahkan public_id agar file di Cloudinary bisa dihapus nanti jika tidak terpakai
      cloudinary_id: {
        type: String
      },
      caption: { 
        type: String 
      }
    }
  ],
  urutan: { 
    type: Number, 
    required: true 
  },
  is_published: { 
    type: Boolean, 
    default: false 
  }
}, {
  timestamps: true 
});

module.exports = mongoose.model('Module', moduleSchema);
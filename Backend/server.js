// Memuat variabel lingkungan dari file .env
require('dotenv').config();

const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

// Inisialisasi aplikasi Express
const app = express();

// Middleware
app.use(cors()); // Mengizinkan frontend (Flutter) untuk mengakses backend ini
app.use(express.json()); // Mengizinkan backend untuk menerima data berformat JSON

// Mengambil port dan URL database dari file .env
const PORT = process.env.PORT || 5000;
const dbURI = process.env.MONGO_URI;

// Mencoba terhubung ke MongoDB Atlas
mongoose.connect(dbURI)
  .then(() => {
    console.log('✅ Berhasil terhubung ke MongoDB Atlas!');
    // Setelah sukses terhubung ke database, jalankan server
    app.listen(PORT, () => {
      console.log(`🚀 Server berjalan pada port ${PORT}`);
    });
  })
  .catch((err) => {
    console.error('❌ Gagal terhubung ke MongoDB:', err);
  });

// Rute dasar untuk mengetes server
app.get('/', (req, res) => {
  res.send('Selamat datang di API CodeQuest!');
});
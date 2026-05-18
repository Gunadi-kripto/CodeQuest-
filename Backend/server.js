//Backend/server.js
// Memuat variabel lingkungan dari file .env
require('dotenv').config();

const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const userProgressRoutes = require('./routes/userProgress');

// Inisialisasi aplikasi Express
const app = express();

// Middleware (Cukup ditulis sekali di atas)
app.use(cors()); 
app.use(express.json()); 

// Menyambungkan rute API Authentication
const authRoutes = require('./routes/auth');
app.use('/api/auth', authRoutes); 
app.use('/api/progress', userProgressRoutes);
const moduleRoutes = require('./routes/module');
const quizRoutes = require('./routes/quiz');
const userRoutes = require('./routes/user');
const chatRoutes = require('./routes/chat');
const languageRoutes = require('./routes/languague');

const achievementRoutes = require('./routes/achievement'); 
app.use('/api/achievements', achievementRoutes);           

app.use('/api/modules', moduleRoutes);
app.use('/api/quizzes', quizRoutes);
app.use('/api/users', userRoutes);
app.use('/api/chats', chatRoutes);
app.use('/api/language',languageRoutes)

// Mengambil port dan URL database dari file .env
const PORT = process.env.PORT || 5000;
const dbURI = process.env.MONGO_URI;

// Rute dasar untuk mengetes server
app.get('/', (req, res) => {
  res.send('Selamat datang di API CodeQuest!');
});

// Mencoba terhubung ke MongoDB Atlas & Menjalankan Server
mongoose.connect(dbURI)
  .then(() => {
    console.log('✅ Berhasil terhubung ke MongoDB Atlas!');
    app.listen(PORT, () => {
      console.log(`🚀 Server berjalan pada port ${PORT}`);
    });
  })
  .catch((err) => {
    console.error('❌ Gagal terhubung ke MongoDB:', err);
  });
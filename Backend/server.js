require('dotenv').config();

const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const app = express();

app.use(cors());
app.use(express.json());

// Routes
const authRoutes = require('./routes/auth');
const userProgressRoutes = require('./routes/userProgress');
const moduleRoutes = require('./routes/module');
const quizRoutes = require('./routes/quiz');
const userRoutes = require('./routes/user');
const chatRoutes = require('./routes/chat');
const languageRoutes = require('./routes/languague');
const achievementRoutes = require('./routes/achievement');

app.use('/api/auth', authRoutes);
app.use('/api/progress', userProgressRoutes);
app.use('/api/modules', moduleRoutes);
app.use('/api/quizzes', quizRoutes);
app.use('/api/quiz', quizRoutes);
app.use('/api/users', userRoutes);
app.use('/api/chats', chatRoutes);
app.use('/api/language', languageRoutes);
app.use('/api/achievements', achievementRoutes);

// Route dasar
app.get('/', (req, res) => {
  res.send('Selamat datang di API CodeQuest!');
});

// Koneksi MongoDB
const dbURI = process.env.MONGO_URI;

mongoose.connect(dbURI)
  .then(() => {
    console.log('✅ Berhasil terhubung ke MongoDB Atlas!');
  })
  .catch((err) => {
    console.error('❌ Gagal terhubung ke MongoDB:', err);
  });

  
module.exports = app;
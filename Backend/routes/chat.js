const express = require('express');
const router = express.Router();
const Message = require('../models/Message');
const User = require('../models/User');

// === IMPORT KEDUA LIBRARY SENSOR ===
const Filter = require('bad-words'); // Sensor Bahasa Inggris (Versi Stabil)
const indoBadwords = require('indonesian-badwords'); // Sensor Bahasa Indonesia (Bisa baca huruf alay)

const filter = new Filter(); 

// 1. API Kirim Pesan
router.post('/send', async (req, res) => {
  try {
    const { senderId, receiverId, text } = req.body;
    const user = await User.findById(senderId);

    // Cek Ganti Hari untuk Reset Limit
    const today = new Date().setHours(0, 0, 0, 0);
    const lastChatDay = new Date(user.last_chat_date).setHours(0, 0, 0, 0);
    
    if (lastChatDay < today) {
      user.daily_chat_count = 0;
      user.last_chat_date = new Date();
    }

    // Blokir kalau udah limit
    if (user.daily_chat_count >= 15) {
      return res.status(403).json({ message: 'Limit harian chat telah Habis silakan tunggu besok hari' });
    }

    // === PROSES SENSOR GANDA (ENGLISH + INDO) ===
    // 1. Bersihkan kata bahasa Inggris (fuck, shit, dll)
    let cleanText = filter.clean(text);
    // 2. Bersihkan kata bahasa Indonesia (anjing, 4nj1ng, dll)
    cleanText = indoBadwords.censor(cleanText);

    // Simpan pesan yang sudah disensor ke database
    const newMessage = new Message({ senderId, receiverId, text: cleanText });
    await newMessage.save();

    // Tambah Limit
    user.daily_chat_count += 1;
    await user.save();

    // SISTEM SAPU OTOMATIS (Maks 20 Chat)
    const chatFilter = {
      $or: [ { senderId, receiverId }, { senderId: receiverId, receiverId: senderId } ]
    };
    const chatCount = await Message.countDocuments(chatFilter);
    
    if (chatCount > 20) {
      // Cari chat paling tua dan hapus
      const oldestMessage = await Message.findOne(chatFilter).sort({ timestamp: 1 });
      if (oldestMessage) await Message.findByIdAndDelete(oldestMessage._id);
    }

    res.status(200).json({ message: 'Terkirim', daily_count: user.daily_chat_count });
  } catch (error) {
    res.status(500).json({ message: 'Gagal mengirim pesan' });
  }
});

// 2. API Ambil Riwayat Pesan
router.get('/:userId/:friendId', async (req, res) => {
  try {
    const { userId, friendId } = req.params;
    const user = await User.findById(userId);

    // Reset hitungan kalau ganti hari (waktu dia buka layar chat)
    const today = new Date().setHours(0, 0, 0, 0);
    const lastChatDay = new Date(user.last_chat_date).setHours(0, 0, 0, 0);
    if (lastChatDay < today) {
      user.daily_chat_count = 0;
      user.last_chat_date = new Date();
      await user.save();
    }

    const messages = await Message.find({
      $or: [
        { senderId: userId, receiverId: friendId },
        { senderId: friendId, receiverId: userId }
      ]
    }).sort({ timestamp: 1 }); // Urutkan dari yang paling lama ke baru

    res.status(200).json({ 
      messages, 
      dailyCount: user.daily_chat_count,
      canChat: user.daily_chat_count < 15
    });
  } catch (error) {
    res.status(500).json({ message: 'Gagal memuat pesan' });
  }
});

module.exports = router;
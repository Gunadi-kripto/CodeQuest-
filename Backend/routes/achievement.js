const express = require('express');
const router = express.Router();
const Achievement = require('../models/Achievement');

// 1. GET: Ambil Semua Achievement (Untuk Layar Admin & User)
router.get('/', async (req, res) => {
  try {
    const achievements = await Achievement.find().sort({ syarat_nilai: 1 });
    res.status(200).json(achievements);
  } catch (error) {
    res.status(500).json({ message: 'Gagal mengambil data pencapaian' });
  }
});

// 2. POST: Tambah Achievement Baru (KHUSUS ADMIN)
router.post('/', async (req, res) => {
  try {
    const newAchievement = new Achievement(req.body);
    await newAchievement.save();
    res.status(201).json({ message: 'Achievement berhasil dibuat!', data: newAchievement });
  } catch (error) {
    res.status(500).json({ message: 'Gagal membuat achievement' });
  }
});

// 3. PUT: Edit Achievement (KHUSUS ADMIN)
router.put('/:id', async (req, res) => {
  try {
    const updated = await Achievement.findByIdAndUpdate(req.params.id, req.body, { new: true });
    res.status(200).json({ message: 'Achievement berhasil diperbarui!', data: updated });
  } catch (error) {
    res.status(500).json({ message: 'Gagal memperbarui achievement' });
  }
});

// 4. DELETE: Hapus Achievement (KHUSUS ADMIN)
router.delete('/:id', async (req, res) => {
  try {
    await Achievement.findByIdAndDelete(req.params.id);
    res.status(200).json({ message: 'Achievement berhasil dihapus!' });
  } catch (error) {
    res.status(500).json({ message: 'Gagal menghapus achievement' });
  }
});

module.exports = router;
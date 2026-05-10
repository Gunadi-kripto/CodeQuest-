// lib/screens/materi_detail_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart'; // Untuk fitur salin kode jika nanti dibutuhkan
import 'quiz_screen.dart';

class MateriDetailScreen extends StatefulWidget {
  final Map<String, dynamic> module;

  const MateriDetailScreen({super.key, required this.module});

  @override
  _MateriDetailScreenState createState() => _MateriDetailScreenState();
}

class _MateriDetailScreenState extends State<MateriDetailScreen> {
  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  Future<void> _markAsRead() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userStr = prefs.getString('user_data');
    if (userStr != null) {
      Map<String, dynamic> userData = jsonDecode(userStr);
      String userId = userData['id'] ?? userData['_id'] ?? '';
      String moduleId = widget.module['_id'];
      await prefs.setBool('read_${userId}_$moduleId', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> isiMateri = widget.module['materi_isi'] ?? [];
    final String judulMateri = widget.module['judul_modul'] ?? 'Detail Materi';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          judulMateri,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // --- PROGRESS BAR MATERI ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    "Materi Belajar",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12),
                  ),
                  const Spacer(),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: const LinearProgressIndicator(
                        value: 0.8, // Ini bisa dibuat dinamis nanti
                        backgroundColor: Colors.white,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                        minHeight: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- ISI KONTEN ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Apa itu ${widget.module['judul_modul']}?",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.module['deskripsi']?.toString() ?? '',
                    style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.5),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    "Penjelasan Materi:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 15),

                  // RENDERING ISI MATERI DINAMIS
                  ...isiMateri.map((item) {
                    if (item['tipe'] == 'text') {
                      // CEK APAKAH INI KODE ATAU TEKS BIASA
                      bool isCode = item['content'].toString().contains('print(') || item['content'].toString().contains('=');
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: isCode 
                          ? _buildCodeBlock(item['content']) // Jika terdeteksi kode, gunakan style kode
                          : Text(
                              item['content'] ?? '',
                              style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                            ),
                      );
                    } else if (item['tipe'] == 'image') {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: CachedNetworkImage(
                            imageUrl: item['content'] ?? '',
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50),
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  }).toList(),

                  // --- TIPS BOX (Opsional, agar mirip Gambar 1) ---
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.green.withOpacity(0.1)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb, color: Colors.orange, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Tips", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              SizedBox(height: 4),
                              Text(
                                "Pahami konsep dasarnya sebelum lanjut ke kuis agar mendapatkan skor XP maksimal!",
                                style: TextStyle(fontSize: 14, color: Colors.black54),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          // --- TOMBOL NAVIGASI DI BAWAH ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: const BorderSide(color: Colors.green),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Sebelumnya", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => QuizScreen(moduleId: widget.module['_id'])),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Mulai Kuis", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET HELPER UNTUK TAMPILAN KODE (Mirip Gambar 1)
  Widget _buildCodeBlock(String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Warna dark mode VS Code
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Kode disalin!")),
                  );
                },
                child: const Row(
                  children: [
                    Icon(Icons.copy, color: Colors.white54, size: 14),
                    SizedBox(width: 4),
                    Text("Salin", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            code,
            style: const TextStyle(
              color: Color(0xFF9CDCFE), // Warna biru muda ala Python/VSCode
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
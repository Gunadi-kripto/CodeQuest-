import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    // Ambil materi_isi (array dari MongoDB)
    final List<dynamic> isiMateri = widget.module['materi_isi'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.module['judul_modul'] ?? 'Detail Materi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.module['judul_modul']?.toString() ?? '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 12),
            Text(
              widget.module['deskripsi']?.toString() ?? '',
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
            const Divider(height: 40, thickness: 1, color: Colors.green),
            
            // RENDERING ISI MATERI DINAMIS (TEKS & GAMBAR)
            ...isiMateri.map((item) {
              if (item['tipe'] == 'text') {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    item['content'] ?? '',
                    style: const TextStyle(fontSize: 17, height: 1.6, color: Colors.black87),
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
            
            const SizedBox(height: 50),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => QuizScreen(moduleId: widget.module['_id'])),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('Lanjut Kerjakan Kuis', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
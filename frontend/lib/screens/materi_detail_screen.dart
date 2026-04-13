import 'dart:convert'; // Wajib ditambah untuk decode user_data
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // Fungsi mencatat bahwa materi ini sudah dibaca SPESIFIK untuk User yang login
  Future<void> _markAsRead() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Ambil ID User yang sedang login
    String? userStr = prefs.getString('user_data');
    if (userStr != null) {
      Map<String, dynamic> userData = jsonDecode(userStr);
      String userId = userData['id'] ?? userData['_id'] ?? '';
      
      String moduleId = widget.module['_id'];
      
      // Simpan dengan kunci: read_IDUSER_IDMATERI
      await prefs.setBool('read_${userId}_$moduleId', true); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.module['judul_modul']?.toString() ?? 'Materi', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.module['judul_modul']?.toString() ?? 'Tanpa Judul',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 12),
            Text(
              widget.module['deskripsi']?.toString() ?? '',
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
            const Divider(height: 40, thickness: 1, color: Colors.green),
            
            Text(
              widget.module['materi_isi']?.toString() ?? 'Isi materi kosong.',
              style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
            ),
            
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
import 'package:flutter/material.dart';

class MateriScreen extends StatelessWidget {
  const MateriScreen({super.key});

  final List<Map<String, dynamic>> modules = const [
    {
      "judul": "Bab 1: Pengenalan Algoritma",
      "deskripsi": "Pahami dasar-dasar logika dan cara komputer berpikir sebelum mulai menulis kode.",
      "icon": Icons.lightbulb_outline,
      "color": Colors.orange,
    },
    {
      "judul": "Bab 2: Dasar Variabel",
      "deskripsi": "Belajar cara menyimpan data ke dalam memori komputer layaknya sebuah kotak penyimpanan.",
      "icon": Icons.memory,
      "color": Colors.blue,
    },
    {
      "judul": "Bab 3: Logika Looping (For & While)",
      "deskripsi": "Mengulang perintah secara otomatis tanpa harus menulis kode berkali-kali.",
      "icon": Icons.loop,
      "color": Colors.green,
    },
    {
      "judul": "Bab 4: Struktur Kontrol (If/Else)",
      "deskripsi": "Membuat program yang bisa mengambil keputusan sendiri berdasarkan kondisi tertentu.",
      "icon": Icons.call_split,
      "color": Colors.purple,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Modul Pembelajaran',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: modules.length,
        itemBuilder: (context, index) {
          final module = modules[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Membuka materi ${module["judul"]}...'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (module["color"] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(module["icon"], color: module["color"], size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            module["judul"],
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            module["deskripsi"],
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
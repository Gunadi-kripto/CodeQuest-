import 'package:flutter/material.dart';

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  // Data Dummy untuk Peta Kuis
  final List<Map<String, dynamic>> quizPath = const [
    {"level": "1", "title": "Misi 1.1: Variabel", "isLocked": false, "color": Colors.blue},
    {"level": "2", "title": "Misi 1.2: Tipe Data", "isLocked": false, "color": Colors.blue},
    {"level": "3", "title": "Misi 1.3: Logika Dasar", "isLocked": true, "color": Colors.grey},
    {"level": "4", "title": "Ujian Bab 1", "isLocked": true, "color": Colors.grey},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD), // Biru muda ala langit game
      appBar: AppBar(
        title: const Text('Peta Jalan Kuis', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        itemCount: quizPath.length,
        itemBuilder: (context, index) {
          final quiz = quizPath[index];
          bool isLocked = quiz["isLocked"];

          return Column(
            children: [
              // Kartu Node Kuis
              GestureDetector(
                onTap: () {
                  if (isLocked) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Selesaikan misi sebelumnya untuk membuka kuis ini!')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Memulai ${quiz["title"]}...')),
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isLocked ? Colors.grey : quiz["color"],
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Ikon Status (Gembok atau Play)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isLocked ? Colors.grey[200] : (quiz["color"] as Color).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isLocked ? Icons.lock : Icons.play_arrow_rounded,
                          color: isLocked ? Colors.grey : quiz["color"],
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Teks Kuis
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Level ${quiz["level"]}",
                              style: TextStyle(
                                color: isLocked ? Colors.grey : quiz["color"],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              quiz["title"],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isLocked ? Colors.grey : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Garis penghubung antar node (kecuali item terakhir)
              if (index != quizPath.length - 1)
                Container(
                  height: 40,
                  width: 4,
                  color: isLocked ? Colors.grey[300] : Colors.blue,
                ),
            ],
          );
        },
      ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class QuizScreen extends StatefulWidget {
  final String? moduleId;

  const QuizScreen({super.key, this.moduleId});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<dynamic> quizzes = [];
  Map<int, String> userAnswers = {}; // Menyimpan jawaban user per nomor soal
  bool isLoading = true;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.moduleId != null) {
      _loadQuizzes();
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadQuizzes() async {
    final data = await ApiService.getQuizzes(widget.moduleId!);
    setState(() {
      quizzes = data;
      isLoading = false;
    });
  }

  // FUNGSI LOGIKA PENILAIAN (BOS UTAMA)
  void _submitQuiz() async {
    setState(() => isSubmitting = true);

    int correctCount = 0;
    int totalXpEarned = 0;

    // 1. Cek Jawaban
    for (int i = 0; i < quizzes.length; i++) {
      String userAnswer = (userAnswers[i] ?? '').trim().toLowerCase();
      String correctAnswer = (quizzes[i]['kunci_jawaban'] ?? '').trim().toLowerCase();

      // Cek kecocokan teks (huruf besar/kecil diabaikan)
      if (userAnswer == correctAnswer && userAnswer.isNotEmpty) {
        correctCount++;
        totalXpEarned += (quizzes[i]['xp_reward'] as int? ?? 10); // Default 10 XP jika kosong
      }
    }

    // 2. Hitung Nilai (Skala 100)
    double score = quizzes.isEmpty ? 0 : (correctCount / quizzes.length) * 100;

    // 3. Evaluasi KKM (80)
    if (score >= 80) {
      // LULUS! Ambil ID User dan kirim XP ke Backend
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userStr = prefs.getString('user_data');
      if (userStr != null) {
        Map<String, dynamic> userData = jsonDecode(userStr);
        String userId = userData['id'] ?? userData['_id'];
        
        await ApiService.addXp(userId, totalXpEarned);
      }

      _showResultDialog(
        title: 'Luar Biasa! 🎉',
        message: 'Nilai kamu: ${score.toInt()}.\nKamu berhasil menjawab $correctCount dari ${quizzes.length} soal.\n\nKamu mendapatkan +$totalXpEarned XP!',
        isSuccess: true,
      );
    } else {
      // GAGAL KKM
      _showResultDialog(
        title: 'Jangan Menyerah! 💪',
        message: 'Nilai kamu: ${score.toInt()} (KKM: 80).\nKamu baru benar $correctCount dari ${quizzes.length} soal.\n\nSilakan pelajari lagi materi dan Coba Ulang.',
        isSuccess: false,
      );
    }

    setState(() => isSubmitting = false);
  }

  // Pop-up Hasil
  void _showResultDialog({required String title, required String message, required bool isSuccess}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: TextStyle(color: isSuccess ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isSuccess ? Colors.green : Colors.orange),
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              if (isSuccess) {
                Navigator.pop(context); // Kembali ke halaman Materi
              }
            },
            child: Text(isSuccess ? 'Kembali' : 'Coba Ulang', style: const TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.moduleId == null) {
      return const Scaffold(
        body: Center(child: Text('Pilih materi dari tab Materi terlebih dahulu.', style: TextStyle(color: Colors.grey))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Kuis Materi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : quizzes.isEmpty
              ? const Center(child: Text('Belum ada kuis untuk materi ini.', style: TextStyle(color: Colors.grey)))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: quizzes.length,
                        itemBuilder: (context, index) {
                          final quiz = quizzes[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: Colors.green,
                                        child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 14)),
                                      ),
                                      const SizedBox(width: 10),
                                      Text('${quiz['xp_reward']} XP', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    quiz['pertanyaan'] ?? '',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 16),
                                  // Kolom Input Jawaban
                                  TextField(
                                    onChanged: (value) {
                                      userAnswers[index] = value;
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Ketik jawabanmu di sini...',
                                      hintStyle: TextStyle(color: Colors.grey[400]),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.green), borderRadius: BorderRadius.circular(10)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (quiz['hint'] != null && quiz['hint'].toString().isNotEmpty)
                                    Row(
                                      children: [
                                        const Icon(Icons.lightbulb, color: Colors.amber, size: 16),
                                        const SizedBox(width: 4),
                                        Expanded(child: Text('Hint: ${quiz['hint']}', style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic, fontSize: 12))),
                                      ],
                                    )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // TOMBOL SUBMIT
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSubmitting ? null : _submitQuiz,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: isSubmitting 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Kumpulkan Jawaban', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    )
                  ],
                ),
    );
  }
}
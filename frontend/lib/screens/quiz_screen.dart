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
  Map<int, String> userAnswers = {}; 
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

  void _submitQuiz() async {
    setState(() => isSubmitting = true);
    int correctCount = 0;
    int totalXpEarned = 0;

    for (int i = 0; i < quizzes.length; i++) {
      String userAnswer = (userAnswers[i] ?? '').trim().toLowerCase();
      String correctAnswer = (quizzes[i]['kunci_jawaban'] ?? '').trim().toLowerCase();
      if (userAnswer == correctAnswer && userAnswer.isNotEmpty) {
        correctCount++;
        totalXpEarned += (quizzes[i]['xp_reward'] as int? ?? 10); 
      }
    }

    double score = quizzes.isEmpty ? 0 : (correctCount / quizzes.length) * 100;

    if (score >= 80) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userStr = prefs.getString('user_data');
      if (userStr != null) {
        Map<String, dynamic> userData = jsonDecode(userStr);
        String userId = userData['id'] ?? userData['_id'];
        
        // Panggil fungsi addXP yang sekarang mengembalikan piala baru!
        final result = await ApiService.addXp(userId, totalXpEarned);
        
        // Tampilkan Popup Nilai dulu, dan tunggu sampai ditutup
        await _showResultDialog(
          title: 'Luar Biasa! 🎉',
          message: 'Nilai kamu: ${score.toInt()}.\nBerhasil menjawab $correctCount dari ${quizzes.length} soal.\n\nDapat +$totalXpEarned XP!',
          isSuccess: true,
        );

        // SETELAH POPUP DITUTUP, MUNCULKAN NOTIFIKASI ACHIEVEMENT (JIKA ADA)
        if (result['success'] == true && result['new_achievements'] != null) {
          List newAchievements = result['new_achievements'];
          for (var ach in newAchievements) {
            _showAchievementNotification(ach['judul'], ach['deskripsi']);
          }
        }
      }
    } else {
      await _showResultDialog(
        title: 'Jangan Menyerah! 💪',
        message: 'Nilai kamu: ${score.toInt()} (KKM: 80).\nBaru benar $correctCount dari ${quizzes.length} soal.\n\nPelajari lagi materi dan Coba Ulang.',
        isSuccess: false,
      );
    }
    setState(() => isSubmitting = false);
  }

  // FUNGSI MEMUNCULKAN NOTIFIKASI PIALA (TARGET 5)
  void _showAchievementNotification(String judul, String deskripsi) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 40),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('PENCAPAIAN TERBUKA!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 12)),
                  Text(judul, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                  Text(deskripsi, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[900], // Warna hijau gelap biar elegan
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
      )
    );
  }

  Future<void> _showResultDialog({required String title, required String message, required bool isSuccess}) async {
    // Tambahkan 'return showDialog' agar sistem menunggu user menekan tombol
    return showDialog(
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
              Navigator.pop(context); 
              if (isSuccess) Navigator.pop(context); 
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
      return const Scaffold(body: Center(child: Text('Pilih materi dari tab Materi terlebih dahulu.', style: TextStyle(color: Colors.grey))));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text('Kuis Materi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: Colors.green, iconTheme: const IconThemeData(color: Colors.white)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : quizzes.isEmpty
              ? const Center(child: Text('Belum ada kuis.', style: TextStyle(color: Colors.grey)))
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
                                      CircleAvatar(radius: 14, backgroundColor: Colors.green, child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 14))),
                                      const SizedBox(width: 10),
                                      Text('${quiz['xp_reward']} XP', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(quiz['pertanyaan'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 16),
                                  TextField(
                                    onChanged: (value) => userAnswers[index] = value,
                                    decoration: InputDecoration(hintText: 'Ketik jawabanmu di sini...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      color: Colors.white,
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSubmitting ? null : _submitQuiz,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                          child: isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Kumpulkan Jawaban', style: TextStyle(fontSize: 18, color: Colors.white)),
                        ),
                      ),
                    )
                  ],
                ),
    );
  }
}
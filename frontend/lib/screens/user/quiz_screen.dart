import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class QuizScreen extends StatefulWidget {
  final String? moduleId;
  const QuizScreen({super.key, this.moduleId});
  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<dynamic> quizzes = [];
  Map<int, int> userAnswers = {};
  bool isLoading = true;
  bool isSubmitting = false;
  bool hasFinished = false; // Status apakah sudah pernah mengerjakan

  @override
  void initState() {
    super.initState();
    _checkStatusAndLoad();
  }

  Future<void> _checkStatusAndLoad() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userStr = prefs.getString('user_data');
    if (userStr != null && widget.moduleId != null) {
      Map<String, dynamic> userData = jsonDecode(userStr);
      String userId = userData['id'] ?? userData['_id'];
      // Cek apakah sudah pernah selesai
      setState(() {
        hasFinished = prefs.getBool('quiz_done_${userId}_${widget.moduleId}') ?? false;
      });
    }
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    final data = await ApiService.getQuizzes(widget.moduleId!);
    setState(() { quizzes = data; isLoading = false; });
  }

  void _submitQuiz() async {
    if (userAnswers.length < quizzes.length) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jawab semua soal dulu King!')));
      return;
    }

    setState(() => isSubmitting = true);
    int correctCount = 0;
    int totalXpEarned = 0;

    for (int i = 0; i < quizzes.length; i++) {
      int correctIdx = (quizzes[i]['jawaban_benar'] as num).toInt();
      if (userAnswers[i] == correctIdx) {
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
        
        await ApiService.addXp(userId, totalXpEarned);
        
        // SIMPAN STATUS: Kuis ini sudah selesai
        await prefs.setBool('quiz_done_${userId}_${widget.moduleId}', true);

        await _showResultDialog(
          title: 'Luar Biasa! 🎉',
          message: 'Nilai: ${score.toInt()}\nXP: +$totalXpEarned\nStatus: SELESAI',
          isSuccess: true
        );
      }
    } else {
      await _showResultDialog(
        title: 'Coba Lagi! 💪',
        message: 'Nilai: ${score.toInt()} (KKM 80).\nKamu belum lulus.',
        isSuccess: false
      );
    }
    setState(() => isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kuis Pilihan Ganda"), backgroundColor: Colors.green, foregroundColor: Colors.white),
      body: isLoading ? const Center(child: CircularProgressIndicator()) : Column(
        children: [
          if (hasFinished) 
            Container(
              width: double.infinity,
              color: Colors.amber[100],
              padding: const EdgeInsets.all(10),
              child: const Text("⚠️ Kamu sudah mengerjakan kuis ini. Skor tidak akan bertambah lagi.", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                final q = quizzes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Soal ${index + 1}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text(q['pertanyaan'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        ...List.generate(4, (i) => _buildOption(index, i, q['opsi'][i])),
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
            child: SizedBox(width: double.infinity, child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: hasFinished ? Colors.grey : Colors.green),
              onPressed: (isSubmitting || hasFinished) ? null : _submitQuiz,
              child: Text(hasFinished ? "Kuis Sudah Selesai" : "Kumpulkan Jawaban", style: const TextStyle(color: Colors.white)),
            )),
          )
        ],
      ),
    );
  }

  Widget _buildOption(int qIdx, int oIdx, String text) {
    bool isSelected = userAnswers[qIdx] == oIdx;
    return GestureDetector(
      onTap: hasFinished ? null : () => setState(() => userAnswers[qIdx] = oIdx),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withOpacity(0.1) : Colors.white,
          border: Border.all(color: isSelected ? Colors.green : Colors.grey[300]!, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(radius: 12, backgroundColor: isSelected ? Colors.green : Colors.grey[300], child: Text(String.fromCharCode(65 + oIdx), style: const TextStyle(color: Colors.white, fontSize: 12))),
            const SizedBox(width: 15),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }

  Future<void> _showResultDialog({required String title, required String message, required bool isSuccess}) async {
    return showDialog(context: context, barrierDismissible: false, builder: (context) => AlertDialog(
      title: Text(title), content: Text(message), actions: [
        TextButton(onPressed: () { Navigator.pop(context); if (isSuccess) Navigator.pop(context); }, child: Text(isSuccess ? "Selesai" : "Coba Lagi"))
      ]));
  }
}
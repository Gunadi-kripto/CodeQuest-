import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class QuizScreen extends StatefulWidget {
  final String? moduleId;

  const QuizScreen({
    super.key,
    this.moduleId,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Map<String, dynamic>> questions = [];

  Map<int, int> userAnswers = {};

  bool isLoading = true;
  bool isSubmitting = false;
  bool hasFinished = false;
  bool moduleDeleted = false;

  int quizXpReward = 0;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // =====================================================
  // LOAD DATA FRESH DARI BACKEND
  // =====================================================

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
      moduleDeleted = false;
      questions = [];
      userAnswers.clear();
    });

    if (widget.moduleId == null || widget.moduleId!.isEmpty) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        moduleDeleted = true;
        errorMessage = 'Materi tidak ditemukan.';
      });

      return;
    }

    final bool stillExists = await _checkModuleStillExists();

    if (!mounted) return;

    if (!stillExists) {
      setState(() {
        isLoading = false;
        moduleDeleted = true;
        errorMessage = 'Materi ini sudah dihapus oleh admin.';
      });

      return;
    }

    await _checkFinishedStatus();
    await _loadQuizzes();

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  Future<bool> _checkModuleStillExists() async {
    try {
      final modules = await ApiService.getModules();

      return modules.any((module) {
        final id = module['_id']?.toString();
        return id == widget.moduleId;
      });
    } catch (e) {
      return false;
    }
  }

  Future<void> _checkFinishedStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user_data');

      if (userStr != null && widget.moduleId != null) {
        final Map<String, dynamic> userData = jsonDecode(userStr);
        final String userId = userData['id'] ?? userData['_id'];

        hasFinished =
            prefs.getBool('quiz_done_${userId}_${widget.moduleId}') ?? false;
      }
    } catch (e) {
      hasFinished = false;
    }
  }

  Future<void> _loadQuizzes() async {
    try {
      final data = await ApiService.getQuizzes(widget.moduleId!);

      if (!mounted) return;

      if (data.isEmpty) {
        questions = [];
        quizXpReward = 0;
        return;
      }

      _parseQuizData(data);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Gagal mengambil data kuis.';
      });
    }
  }

  // =====================================================
  // PARSE QUIZ
  // Support:
  // 1. Struktur baru admin:
  //    [
  //      {
  //        "_id": "...",
  //        "module_id": "...",
  //        "xp_reward": 50,
  //        "daftar_soal": [
  //          {
  //            "pertanyaan": "...",
  //            "opsi": {"A": "...", "B": "...", "C": "...", "D": "..."},
  //            "jawaban_benar": "A"
  //          }
  //        ]
  //      }
  //    ]
  //
  // 2. Struktur lama:
  //    [
  //      {
  //        "pertanyaan": "...",
  //        "opsi": ["...", "...", "...", "..."],
  //        "jawaban_benar": 0,
  //        "xp_reward": 10
  //      }
  //    ]
  // =====================================================

  void _parseQuizData(List<dynamic> data) {
    final List<Map<String, dynamic>> parsedQuestions = [];

    final firstQuiz = data.first;

    if (firstQuiz is Map && firstQuiz['xp_reward'] != null) {
      quizXpReward = _toInt(firstQuiz['xp_reward']);
    }

    if (firstQuiz is Map && firstQuiz['daftar_soal'] is List) {
      final List soalList = firstQuiz['daftar_soal'];

      for (final item in soalList) {
        if (item is Map) {
          parsedQuestions.add(_normalizeQuestion(Map<String, dynamic>.from(item)));
        }
      }
    } else {
      for (final item in data) {
        if (item is Map) {
          final normalized = _normalizeQuestion(Map<String, dynamic>.from(item));
          parsedQuestions.add(normalized);

          if (quizXpReward == 0 && item['xp_reward'] != null) {
            quizXpReward = _toInt(item['xp_reward']);
          }
        }
      }
    }

    if (quizXpReward <= 0) {
      quizXpReward = 10;
    }

    questions = parsedQuestions;
  }

  Map<String, dynamic> _normalizeQuestion(Map<String, dynamic> raw) {
    final String pertanyaan =
        raw['pertanyaan']?.toString() ?? raw['question']?.toString() ?? '';

    final dynamic opsiRaw = raw['opsi'] ?? raw['pilihan'];

    final List<String> opsiList = _normalizeOptions(opsiRaw);

    final int correctIndex = _normalizeCorrectAnswer(raw['jawaban_benar'] ??
        raw['correct_answer'] ??
        raw['correctAnswer']);

    return {
      'pertanyaan': pertanyaan,
      'opsi': opsiList,
      'jawaban_benar': correctIndex,
      'xp_reward': _toInt(raw['xp_reward'] ?? raw['xp'] ?? quizXpReward),
    };
  }

  List<String> _normalizeOptions(dynamic opsiRaw) {
    if (opsiRaw is List) {
      return List.generate(4, (index) {
        if (index < opsiRaw.length) {
          return opsiRaw[index]?.toString() ?? '';
        }
        return '';
      });
    }

    if (opsiRaw is Map) {
      return [
        opsiRaw['A']?.toString() ?? '',
        opsiRaw['B']?.toString() ?? '',
        opsiRaw['C']?.toString() ?? '',
        opsiRaw['D']?.toString() ?? '',
      ];
    }

    return ['', '', '', ''];
  }

  int _normalizeCorrectAnswer(dynamic answer) {
    if (answer is int) {
      if (answer >= 0 && answer <= 3) return answer;
    }

    if (answer is num) {
      final value = answer.toInt();
      if (value >= 0 && value <= 3) return value;
    }

    final String answerString = answer?.toString().toUpperCase().trim() ?? 'A';

    switch (answerString) {
      case 'A':
        return 0;
      case 'B':
        return 1;
      case 'C':
        return 2;
      case 'D':
        return 3;
      default:
        return 0;
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  // =====================================================
  // SUBMIT QUIZ
  // =====================================================

  Future<void> _submitQuiz() async {
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kuis belum tersedia.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (userAnswers.length < questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jawab semua soal dulu.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (hasFinished) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kuis ini sudah pernah kamu selesaikan.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isSubmitting = true);

    int correctCount = 0;

    for (int i = 0; i < questions.length; i++) {
      final int correctIdx = questions[i]['jawaban_benar'] as int;

      if (userAnswers[i] == correctIdx) {
        correctCount++;
      }
    }

    final double score =
        questions.isEmpty ? 0 : (correctCount / questions.length) * 100;

    final int totalXpEarned = score >= 80 ? quizXpReward : 0;

    if (score >= 80) {
      await _handleQuizSuccess(score, totalXpEarned);
    } else {
      await _showResultDialog(
        title: 'Coba Lagi! 💪',
        message: 'Nilai: ${score.toInt()} / 100\nKKM: 80\nKamu belum lulus.',
        isSuccess: false,
      );
    }

    if (!mounted) return;

    setState(() => isSubmitting = false);
  }

  Future<void> _handleQuizSuccess(double score, int totalXpEarned) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user_data');

      if (userStr != null && widget.moduleId != null) {
        final Map<String, dynamic> userData = jsonDecode(userStr);
        final String userId = userData['id'] ?? userData['_id'];

        await ApiService.addXp(userId, totalXpEarned);

        await prefs.setBool(
          'quiz_done_${userId}_${widget.moduleId}',
          true,
        );

        if (!mounted) return;

        setState(() {
          hasFinished = true;
        });

        await _showResultDialog(
          title: 'Luar Biasa! 🎉',
          message:
              'Nilai: ${score.toInt()} / 100\nXP: +$totalXpEarned\nStatus: SELESAI',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan hasil kuis.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Kuis Pilihan Ganda',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.green,
              ),
            )
          : moduleDeleted
              ? _deletedState()
              : questions.isEmpty
                  ? _emptyQuizState()
                  : RefreshIndicator(
                      color: Colors.green,
                      onRefresh: _loadData,
                      child: Column(
                        children: [
                          if (hasFinished) _finishedBanner(),
                          _quizInfoHeader(),
                          Expanded(
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              itemCount: questions.length,
                              itemBuilder: (context, index) {
                                final q = questions[index];

                                return _questionCard(index, q);
                              },
                            ),
                          ),
                          _submitButton(),
                        ],
                      ),
                    ),
    );
  }

  Widget _deletedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 42,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Materi Sudah Dihapus',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage.isEmpty
                    ? 'Materi ini sudah tidak tersedia.'
                    : errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Kembali',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyQuizState() {
    return RefreshIndicator(
      color: Colors.green,
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.quiz_outlined,
                    color: Colors.orange,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Kuis Belum Tersedia',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage.isEmpty
                      ? 'Kuis untuk materi ini belum tersedia atau sudah dihapus admin.'
                      : errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loadData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Muat Ulang',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _finishedBanner() {
    return Container(
      width: double.infinity,
      color: Colors.amber[100],
      padding: const EdgeInsets.all(12),
      child: const Text(
        '⚠️ Kamu sudah mengerjakan kuis ini. XP tidak akan bertambah lagi.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _quizInfoHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.quiz_rounded,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '${questions.length} Soal • $quizXpReward XP',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _questionCard(int index, Map<String, dynamic> q) {
    final List<String> opsi = List<String>.from(q['opsi']);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Soal ${index + 1}',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            q['pertanyaan'] ?? '',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(4, (i) {
            return _buildOption(index, i, opsi[i]);
          }),
        ],
      ),
    );
  }

  Widget _buildOption(int qIdx, int oIdx, String text) {
    final bool isSelected = userAnswers[qIdx] == oIdx;

    return GestureDetector(
      onTap: hasFinished
          ? null
          : () {
              setState(() {
                userAnswers[qIdx] = oIdx;
              });
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: isSelected ? Colors.green : Colors.grey.shade300,
              child: Text(
                String.fromCharCode(65 + oIdx),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _submitButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: hasFinished ? Colors.grey : Colors.green,
            disabledBackgroundColor: Colors.grey.shade300,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: (isSubmitting || hasFinished) ? null : _submitQuiz,
          child: isSubmitting
              ? const CircularProgressIndicator(
                  color: Colors.white,
                )
              : Text(
                  hasFinished ? 'Kuis Sudah Selesai' : 'Kumpulkan Jawaban',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _showResultDialog({
    required String title,
    required String message,
    required bool isSuccess,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5F6F8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSuccess ? Colors.green : Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              if (isSuccess) {
                Navigator.pop(context, true);
              }
            },
            child: Text(
              isSuccess ? 'Selesai' : 'Coba Lagi',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
    );
  }
}
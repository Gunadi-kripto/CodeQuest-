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
  String currentQuizId = '';
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // =====================================================
  // LOAD DATA
  // =====================================================

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
      moduleDeleted = false;
      questions = [];
      userAnswers.clear();
      currentQuizId = '';
      quizXpReward = 0;
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
        final String userId =
            (userData['id'] ?? userData['_id'] ?? '').toString();

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
        currentQuizId = '';
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
  // =====================================================

  void _parseQuizData(List<dynamic> data) {
    final List<Map<String, dynamic>> parsedQuestions = [];

    final firstQuiz = data.first;

    if (firstQuiz is Map && firstQuiz['_id'] != null) {
      currentQuizId = firstQuiz['_id'].toString();
    }

    if (firstQuiz is Map && firstQuiz['xp_reward'] != null) {
      quizXpReward = _toInt(firstQuiz['xp_reward']);
    }

    if (firstQuiz is Map && firstQuiz['daftar_soal'] is List) {
      final List soalList = firstQuiz['daftar_soal'];

      for (final item in soalList) {
        if (item is Map) {
          parsedQuestions.add(
            _normalizeQuestion(Map<String, dynamic>.from(item)),
          );
        }
      }
    } else {
      for (final item in data) {
        if (item is Map) {
          if (currentQuizId.isEmpty && item['_id'] != null) {
            currentQuizId = item['_id'].toString();
          }

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

    print('CURRENT QUIZ ID: $currentQuizId');
    print('QUIZ XP REWARD: $quizXpReward');
    print('TOTAL QUESTIONS: ${questions.length}');
  }

  Map<String, dynamic> _normalizeQuestion(Map<String, dynamic> raw) {
    final String pertanyaan =
        raw['pertanyaan']?.toString() ?? raw['question']?.toString() ?? '';

    final dynamic opsiRaw = raw['opsi'] ?? raw['pilihan'];

    final List<String> opsiList = _normalizeOptions(opsiRaw);

    final int correctIndex = _normalizeCorrectAnswer(
      raw['jawaban_benar'] ?? raw['correct_answer'] ?? raw['correctAnswer'],
    );

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
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  // =====================================================
  // SUBMIT QUIZ
  // =====================================================

  Future<void> _submitQuiz() async {
    if (questions.isEmpty) {
      _showSnackBar('Kuis belum tersedia.', Colors.red);
      return;
    }

    if (userAnswers.length < questions.length) {
      _showSnackBar('Jawab semua soal dulu.', Colors.red);
      return;
    }

    if (currentQuizId.isEmpty) {
      _showSnackBar('ID quiz tidak ditemukan.', Colors.red);
      return;
    }

    if (!mounted) return;

    setState(() {
      isSubmitting = true;
    });

    int correctCount = 0;

    for (int i = 0; i < questions.length; i++) {
      final int correctIdx = questions[i]['jawaban_benar'] as int;

      if (userAnswers[i] == correctIdx) {
        correctCount++;
      }
    }

    final double score =
        questions.isEmpty ? 0 : (correctCount / questions.length) * 100;

    if (score >= 80) {
      await _handleQuizSuccess(score);
    } else {
      await _showResultDialog(
        title: 'Coba Lagi! 💪',
        message: 'Nilai: ${score.toInt()} / 100\nKKM: 80\nKamu belum lulus.',
        isSuccess: false,
      );
    }

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });
  }

  Future<void> _handleQuizSuccess(double score) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user_data');

      if (userStr == null || widget.moduleId == null) {
        _showSnackBar('Data user tidak ditemukan.', Colors.red);
        return;
      }

      final Map<String, dynamic> userData = jsonDecode(userStr);
      final String userId =
          (userData['id'] ?? userData['_id'] ?? '').toString();

      if (userId.isEmpty) {
        _showSnackBar('ID user tidak valid.', Colors.red);
        return;
      }

      final result = await ApiService.submitQuiz(
        userId: userId,
        quizId: currentQuizId,
        skor: score.toInt(),
      );

      if (!mounted) return;

      if (result['success'] != true) {
        _showSnackBar(
          result['message']?.toString() ?? 'Gagal submit quiz.',
          Colors.red,
        );
        return;
      }

      await prefs.setBool(
        'quiz_done_${userId}_${widget.moduleId}',
        true,
      );

      final List<dynamic> newAchievements =
          result['new_achievements'] is List
              ? result['new_achievements']
              : [];

      final int xpAdded = _toInt(result['xp_added'] ?? 0);
      final bool alreadyCompleted = result['already_completed'] == true;

      if (!mounted) return;

      setState(() {
        hasFinished = true;
      });

      await _showResultDialog(
        title: alreadyCompleted ? 'Quiz Sudah Selesai' : 'Luar Biasa! 🎉',
        message: alreadyCompleted
            ? 'Nilai: ${score.toInt()} / 100\nQuiz ini sudah pernah diselesaikan.\nXP tidak bertambah.'
            : 'Nilai: ${score.toInt()} / 100\nXP: +$xpAdded\nStatus: SELESAI',
        isSuccess: true,
      );

      if (!mounted) return;

      if (newAchievements.isNotEmpty) {
        await _showAchievementUnlockedDialog(newAchievements);
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showSnackBar('Gagal menyimpan hasil kuis: $e', Colors.red);
    }
  }

  // =====================================================
  // ACHIEVEMENT DIALOG
  // =====================================================

  Future<void> _showAchievementUnlockedDialog(
    List<dynamic> achievements,
  ) async {
    for (final achievement in achievements) {
      if (!mounted) return;

      final String title =
          (achievement['judul'] ?? 'Achievement Baru').toString();

      final String description =
          (achievement['deskripsi'] ?? '').toString();

      final int xpReward = _toInt(achievement['xp_reward'] ?? 0);

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Achievement Unlocked!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.orange,
                    size: 58,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  '+$xpReward XP',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text(
                  'Mantap!',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
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
        '⚠️ Kamu sudah mengerjakan kuis ini. Backend akan tetap mengecek progress dan achievement.',
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
      onTap: () {
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
            backgroundColor: Colors.green,
            disabledBackgroundColor: Colors.grey.shade300,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: isSubmitting ? null : _submitQuiz,
          child: isSubmitting
              ? const CircularProgressIndicator(
                  color: Colors.white,
                )
              : Text(
                  hasFinished ? 'Cek Ulang Progress Quiz' : 'Kumpulkan Jawaban',
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
      builder: (dialogContext) {
        return AlertDialog(
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
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                isSuccess ? 'Lanjut' : 'Coba Lagi',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }
}
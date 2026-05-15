import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'materi_detail_screen.dart';
import 'quiz_screen.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  List<dynamic> modules = [];
  List<dynamic> languages = [];

  bool isLoading = true;
  SharedPreferences? prefs;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  // LOAD DATA TERBARU DARI BACKEND

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      modules = [];
    });

    prefs = await SharedPreferences.getInstance();

    final String? userStr = prefs!.getString('user_data');

    if (userStr != null) {
      final Map<String, dynamic> userData = jsonDecode(userStr);
      currentUserId = userData['id'] ?? userData['_id'];
    }

    final fetchedLanguages = await ApiService.getLanguages();
    final fetchedModules = await ApiService.getModules();

    final validModules = await _filterValidQuizModules(
      fetchedModules,
      fetchedLanguages,
    );

    if (!mounted) return;

    setState(() {
      languages = fetchedLanguages;
      modules = validModules;
      isLoading = false;
    });
  }

  // =====================================================
  // FILTER DATA BIAR CARD YANG SUDAH DIHAPUS ADMIN HILANG
  // =====================================================

  Future<List<dynamic>> _filterValidQuizModules(
    List<dynamic> fetchedModules,
    List<dynamic> fetchedLanguages,
  ) async {
    final Set<String> validLanguageIds = fetchedLanguages
        .map((lang) => lang['_id']?.toString())
        .whereType<String>()
        .toSet();

    final List<dynamic> validModules = [];

    for (final module in fetchedModules) {
      final String? moduleId = module['_id']?.toString();

      if (moduleId == null || moduleId.isEmpty) {
        continue;
      }

      final String? languageId = _getModuleLanguageId(module);

      // Kalau module masih nyangkut tapi bahasa sudah dihapus admin,
      // jangan tampilkan card kuisnya.
      if (languageId != null &&
          languageId.isNotEmpty &&
          !validLanguageIds.contains(languageId)) {
        await _clearLocalReadStatus(moduleId);
        continue;
      }

      // Cek apakah module ini masih punya kuis aktif.
      final quizzes = await ApiService.getQuizzes(moduleId);

      if (quizzes.isEmpty) {
        await _clearLocalReadStatus(moduleId);
        continue;
      }

      validModules.add(module);
    }

    return validModules;
  }

  String? _getModuleLanguageId(dynamic module) {
    final dynamic rawLanguage =
        module['id_bahasa'] ?? module['language_id'] ?? module['bahasa_id'];

    if (rawLanguage == null) {
      return null;
    }

    if (rawLanguage is Map) {
      return rawLanguage['_id']?.toString();
    }

    return rawLanguage.toString();
  }

  Future<void> _clearLocalReadStatus(String moduleId) async {
    if (prefs == null || currentUserId == null) {
      return;
    }

    await prefs!.remove('read_${currentUserId}_$moduleId');
    await prefs!.remove('quiz_done_${currentUserId}_$moduleId');
  }

  bool _isUnlocked(String moduleId) {
    if (prefs == null || currentUserId == null) {
      return false;
    }

    return prefs!.getBool('read_${currentUserId}_$moduleId') ?? false;
  }

  // =====================================================
  // CEK ULANG SAAT CARD DIKLIK
  // =====================================================

  Future<bool> _isModuleStillValid(String moduleId) async {
    final latestLanguages = await ApiService.getLanguages();
    final latestModules = await ApiService.getModules();

    final Set<String> validLanguageIds = latestLanguages
        .map((lang) => lang['_id']?.toString())
        .whereType<String>()
        .toSet();

    dynamic foundModule;

    try {
      foundModule = latestModules.firstWhere(
        (module) => module['_id']?.toString() == moduleId,
      );
    } catch (_) {
      foundModule = null;
    }

    if (foundModule == null) {
      await _clearLocalReadStatus(moduleId);
      return false;
    }

    final String? languageId = _getModuleLanguageId(foundModule);

    if (languageId != null &&
        languageId.isNotEmpty &&
        !validLanguageIds.contains(languageId)) {
      await _clearLocalReadStatus(moduleId);
      return false;
    }

    final quizzes = await ApiService.getQuizzes(moduleId);

    if (quizzes.isEmpty) {
      await _clearLocalReadStatus(moduleId);
      return false;
    }

    return true;
  }

  Future<void> _openQuiz(dynamic mod, String moduleId) async {
    final bool stillValid = await _isModuleStillValid(moduleId);

    if (!mounted) return;

    if (!stillValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kuis atau materi ini sudah dihapus oleh admin.'),
          backgroundColor: Colors.red,
        ),
      );

      await _loadData();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(moduleId: moduleId),
      ),
    ).then((_) => _loadData());
  }

  Future<void> _openMateri(dynamic mod, String moduleId) async {
    final bool stillValid = await _isModuleStillValid(moduleId);

    if (!mounted) return;

    if (!stillValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Materi ini sudah dihapus oleh admin.'),
          backgroundColor: Colors.red,
        ),
      );

      await _loadData();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MateriDetailScreen(module: mod),
      ),
    ).then((_) => _loadData());
  }

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              'assets/coding_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.green,
                          ),
                        )
                      : modules.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _loadData,
                              color: Colors.green,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                itemCount: modules.length,
                                itemBuilder: (context, index) {
                                  final mod = modules[index];
                                  final String moduleId =
                                      mod['_id']?.toString() ?? '';
                                  final bool isUnlocked =
                                      _isUnlocked(moduleId);

                                  return _buildQuizCard(
                                    mod,
                                    moduleId,
                                    isUnlocked,
                                  );
                                },
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quiz',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Baca materi dulu untuk membuka kuis',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: Colors.green,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.quiz_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Kuis belum tersedia.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kuis yang dihapus admin tidak akan tampil di sini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Muat Ulang',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(dynamic mod, String moduleId, bool isUnlocked) {
    return GestureDetector(
      onTap: () {
        if (moduleId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data materi tidak valid.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        if (isUnlocked) {
          _openQuiz(mod, moduleId);
        } else {
          _showLockedDialog(mod, moduleId);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isUnlocked
              ? Colors.white.withOpacity(0.95)
              : Colors.grey.shade200.withOpacity(0.90),
          borderRadius: BorderRadius.circular(18),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? Colors.green.withOpacity(0.12)
                      : Colors.grey.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isUnlocked ? Icons.extension_rounded : Icons.lock_rounded,
                  color: isUnlocked ? Colors.green : Colors.grey.shade400,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kuis: ${mod['judul_modul'] ?? 'Tanpa Judul'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isUnlocked
                            ? Colors.black87
                            : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isUnlocked
                              ? Icons.check_circle_rounded
                              : Icons.info_outline_rounded,
                          size: 13,
                          color:
                              isUnlocked ? Colors.green : Colors.red.shade300,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            isUnlocked
                                ? 'Terbuka! Siap dikerjakan.'
                                : 'Baca materinya terlebih dahulu.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isUnlocked
                                  ? Colors.green.shade600
                                  : Colors.red.shade300,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                isUnlocked
                    ? Icons.play_circle_fill_rounded
                    : Icons.menu_book_rounded,
                color: isUnlocked ? Colors.green : Colors.grey.shade400,
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLockedDialog(Map<String, dynamic> mod, String moduleId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.lock_rounded,
              color: Colors.red,
            ),
            SizedBox(width: 8),
            Text(
              'Kuis Terkunci',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Kamu belum membaca "${mod['judul_modul'] ?? 'materi ini'}".\n\nBaca materinya terlebih dahulu untuk membuka kuis ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Nanti saja',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _openMateri(mod, moduleId);
            },
            child: const Text(
              'Baca Materi',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
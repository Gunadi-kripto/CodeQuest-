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
  List<dynamic> progressData = [];

  bool isLoading = true;
  SharedPreferences? prefs;
  String? currentUserId;
  String? selectedLanguageId;

  final Set<String> completedMaterialIds = {};
  final Set<String> completedQuizModuleIds = {};

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
      modules = [];
      languages = [];
      progressData = [];
      completedMaterialIds.clear();
      completedQuizModuleIds.clear();
    });

    prefs = await SharedPreferences.getInstance();

    final String? userStr = prefs!.getString('user_data');

    if (userStr != null) {
      try {
        final Map<String, dynamic> userData = jsonDecode(userStr);
        currentUserId = (userData['id'] ?? userData['_id'] ?? '').toString();
      } catch (e) {
        currentUserId = null;
      }
    }

    try {
      final results = await Future.wait([
        ApiService.getLanguages(),
        ApiService.getModules(),
        if (currentUserId != null && currentUserId!.isNotEmpty)
          ApiService.getUserProgress(currentUserId!)
        else
          Future.value([]),
      ]);

      final List<dynamic> fetchedLanguages = results[0] as List<dynamic>;
      final List<dynamic> fetchedModules = results[1] as List<dynamic>;
      progressData = results[2] as List<dynamic>;

      _parseProgressData(progressData);

      final validModules = await _filterValidQuizModules(
        fetchedModules,
        fetchedLanguages,
      );

      if (!mounted) return;

      final List<dynamic> languagesWithQuiz = _filterLanguagesWithQuiz(
        fetchedLanguages,
        validModules,
      );

      setState(() {
        languages = languagesWithQuiz;
        modules = validModules;

        if (selectedLanguageId == null ||
            !languages.any(
              (lang) => lang['_id']?.toString() == selectedLanguageId,
            )) {
          selectedLanguageId = languages.isNotEmpty
              ? languages.first['_id']?.toString()
              : null;
        }

        isLoading = false;
      });
    } catch (e) {
      debugPrint('LOAD QUIZ LIST ERROR: $e');

      if (!mounted) return;

      setState(() {
        languages = [];
        modules = [];
        progressData = [];
        isLoading = false;
      });
    }
  }

  void _parseProgressData(List<dynamic> progress) {
    for (final item in progress) {
      final String type = (item['tipe_progress'] ?? '').toString();
      final bool isCompleted = item['is_completed'] == true;

      if (!isCompleted) continue;

      if (type == 'materi') {
        final dynamic module = item['module_id'];
        final String moduleId = _extractId(module);

        if (moduleId.isNotEmpty) {
          completedMaterialIds.add(moduleId);
        }
      }

      if (type == 'quiz') {
        final dynamic module = item['module_id'];
        final String moduleId = _extractId(module);

        if (moduleId.isNotEmpty) {
          completedQuizModuleIds.add(moduleId);
        }
      }
    }
  }

  String _extractId(dynamic value) {
    if (value == null) return '';

    if (value is Map) {
      return (value['_id'] ?? value['id'] ?? '').toString();
    }

    return value.toString();
  }

  bool _isDeletedModule(dynamic module) {
    return module['is_deleted'] == true ||
        module['deleted'] == true ||
        module['deleted_at'] != null ||
        module['is_active'] == false ||
        module['status'] == 'deleted' ||
        module['status'] == 'inactive';
  }

  // =====================================================
  // FILTER MODULE YANG PUNYA QUIZ
  // SUDAH DIPERCEPAT PAKAI Future.wait
  // =====================================================

  Future<List<dynamic>> _filterValidQuizModules(
    List<dynamic> fetchedModules,
    List<dynamic> fetchedLanguages,
  ) async {
    final Set<String> validLanguageIds = fetchedLanguages
        .map((lang) => lang['_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    final List<Map<String, dynamic>> candidateModules = [];

    for (final module in fetchedModules) {
      if (module is! Map) continue;

      final Map<String, dynamic> moduleMap = Map<String, dynamic>.from(module);

      final String moduleId = (moduleMap['_id'] ?? '').toString();
      final String? languageId = _getModuleLanguageId(moduleMap);

      if (moduleId.isEmpty) {
        continue;
      }

      if (languageId == null || languageId.isEmpty) {
        await _clearLocalReadStatus(moduleId);
        continue;
      }

      if (!validLanguageIds.contains(languageId)) {
        await _clearLocalReadStatus(moduleId);
        continue;
      }

      if (_isDeletedModule(moduleMap)) {
        await _clearLocalReadStatus(moduleId);
        continue;
      }

      candidateModules.add(moduleMap);
    }

    final List<Future<Map<String, dynamic>?>> quizChecks =
        candidateModules.map((module) async {
      final String moduleId = (module['_id'] ?? '').toString();

      try {
        final quizzes = await ApiService.getQuizzes(moduleId);

        if (quizzes.isEmpty) {
          await _clearLocalReadStatus(moduleId);
          return null;
        }

        return module;
      } catch (e) {
        debugPrint('CHECK QUIZ ERROR $moduleId: $e');
        return null;
      }
    }).toList();

    final List<Map<String, dynamic>?> checkedModules =
        await Future.wait(quizChecks);

    final List<Map<String, dynamic>> validModules =
        checkedModules.whereType<Map<String, dynamic>>().toList();

    validModules.sort((a, b) {
      final String langA = _getModuleLanguageId(a) ?? '';
      final String langB = _getModuleLanguageId(b) ?? '';

      final int langCompare = langA.compareTo(langB);
      if (langCompare != 0) return langCompare;

      final int orderA = _toInt(a['urutan']);
      final int orderB = _toInt(b['urutan']);

      if (orderA != orderB) return orderA.compareTo(orderB);

      final String titleA = (a['judul_modul'] ?? '').toString();
      final String titleB = (b['judul_modul'] ?? '').toString();

      return titleA.compareTo(titleB);
    });

    return validModules;
  }

  List<dynamic> _filterLanguagesWithQuiz(
    List<dynamic> fetchedLanguages,
    List<dynamic> validModules,
  ) {
    final Set<String> languageIdsWithQuiz = validModules
        .map((module) => _getModuleLanguageId(module))
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    final filtered = fetchedLanguages.where((lang) {
      final String id = (lang['_id'] ?? '').toString();

      final bool isDeleted =
          lang['is_deleted'] == true ||
          lang['deleted'] == true ||
          lang['deleted_at'] != null ||
          lang['is_active'] == false ||
          lang['status'] == 'deleted' ||
          lang['status'] == 'inactive';

      return id.isNotEmpty && languageIdsWithQuiz.contains(id) && !isDeleted;
    }).toList();

    filtered.sort((a, b) {
      final String nameA = (a['nama_bahasa'] ?? '').toString();
      final String nameB = (b['nama_bahasa'] ?? '').toString();
      return nameA.compareTo(nameB);
    });

    return filtered;
  }

  String? _getModuleLanguageId(dynamic module) {
    final dynamic rawLanguage =
        module['id_bahasa'] ?? module['language_id'] ?? module['bahasa_id'];

    if (rawLanguage == null) {
      return null;
    }

    if (rawLanguage is Map) {
      return (rawLanguage['_id'] ?? rawLanguage['id'] ?? '').toString();
    }

    return rawLanguage.toString();
  }

  String _getLanguageName(dynamic language) {
    if (language == null) return '';

    if (language is Map) {
      return (language['nama_bahasa'] ?? 'Bahasa').toString();
    }

    return 'Bahasa';
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  Future<void> _clearLocalReadStatus(String moduleId) async {
    if (prefs == null || currentUserId == null) {
      return;
    }

    await prefs!.remove('read_${currentUserId}_$moduleId');
    await prefs!.remove('quiz_done_${currentUserId}_$moduleId');
  }

  bool _isMaterialCompleted(String moduleId) {
    if (completedMaterialIds.contains(moduleId)) {
      return true;
    }

    if (prefs == null || currentUserId == null) {
      return false;
    }

    return prefs!.getBool('read_${currentUserId}_$moduleId') ?? false;
  }

  bool _isQuizCompleted(String moduleId) {
    if (completedQuizModuleIds.contains(moduleId)) {
      return true;
    }

    if (prefs == null || currentUserId == null) {
      return false;
    }

    return prefs!.getBool('quiz_done_${currentUserId}_$moduleId') ?? false;
  }

  List<dynamic> _getSelectedLanguageModules() {
    if (selectedLanguageId == null) return [];

    return modules.where((module) {
      final String? languageId = _getModuleLanguageId(module);
      return languageId == selectedLanguageId;
    }).toList();
  }

  int _getReadyQuizCount() {
    return _getSelectedLanguageModules().where((module) {
      final String moduleId = (module['_id'] ?? '').toString();
      return _isMaterialCompleted(moduleId) && !_isQuizCompleted(moduleId);
    }).length;
  }

  int _getDoneQuizCount() {
    return _getSelectedLanguageModules().where((module) {
      final String moduleId = (module['_id'] ?? '').toString();
      return _isQuizCompleted(moduleId);
    }).length;
  }

  // =====================================================
  // CEK ULANG SAAT CARD DIKLIK
  // =====================================================

  Future<bool> _isModuleStillValid(String moduleId) async {
    final results = await Future.wait([
      ApiService.getLanguages(),
      ApiService.getModules(),
      ApiService.getQuizzes(moduleId),
    ]);

    final List<dynamic> latestLanguages = results[0] as List<dynamic>;
    final List<dynamic> latestModules = results[1] as List<dynamic>;
    final List<dynamic> quizzes = results[2] as List<dynamic>;

    final Set<String> validLanguageIds = latestLanguages
        .map((lang) => lang['_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
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

    if (_isDeletedModule(foundModule)) {
      await _clearLocalReadStatus(moduleId);
      return false;
    }

    final String? languageId = _getModuleLanguageId(foundModule);

    if (languageId == null ||
        languageId.isEmpty ||
        !validLanguageIds.contains(languageId)) {
      await _clearLocalReadStatus(moduleId);
      return false;
    }

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
      _showSnackBar(
        'Kuis atau materi ini sudah dihapus oleh admin.',
        Colors.red,
      );

      await _loadData();
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(moduleId: moduleId),
      ),
    );

    await _loadData();
  }

  Future<void> _openMateri(dynamic mod, String moduleId) async {
    final bool stillValid = await _isModuleStillValid(moduleId);

    if (!mounted) return;

    if (!stillValid) {
      _showSnackBar(
        'Materi ini sudah dihapus oleh admin.',
        Colors.red,
      );

      await _loadData();
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MateriDetailScreen(module: mod),
      ),
    );

    await _loadData();
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

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final List<dynamic> selectedModules = _getSelectedLanguageModules();

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
                const SizedBox(height: 14),
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
                              child: ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  24,
                                ),
                                children: [
                                  _buildLanguageChips(),
                                  const SizedBox(height: 14),
                                  _buildProgressOverview(),
                                  const SizedBox(height: 18),
                                  _buildSectionTitle(),
                                  const SizedBox(height: 10),
                                  if (selectedModules.isEmpty)
                                    _buildNoQuizInLanguage()
                                  else
                                    ...selectedModules.map((mod) {
                                      final String moduleId =
                                          (mod['_id'] ?? '').toString();

                                      final bool materialDone =
                                          _isMaterialCompleted(moduleId);
                                      final bool quizDone =
                                          _isQuizCompleted(moduleId);

                                      return _buildQuizCard(
                                        mod: mod,
                                        moduleId: moduleId,
                                        materialDone: materialDone,
                                        quizDone: quizDone,
                                      );
                                    }),
                                ],
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
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih bahasa, baca materi, lalu taklukkan kuisnya.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: languages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final language = languages[index];
          final String id = (language['_id'] ?? '').toString();
          final String name = _getLanguageName(language);
          final bool selected = id == selectedLanguageId;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedLanguageId = id;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: selected ? Colors.green : Colors.white.withOpacity(0.88),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: selected ? Colors.green : Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(selected ? 0.08 : 0.035),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                name,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressOverview() {
    final int total = _getSelectedLanguageModules().length;
    final int ready = _getReadyQuizCount();
    final int done = _getDoneQuizCount();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildMiniStat(
            icon: Icons.quiz_rounded,
            color: Colors.green,
            value: '$total',
            label: 'Total Kuis',
          ),
          _buildDivider(),
          _buildMiniStat(
            icon: Icons.play_circle_fill_rounded,
            color: Colors.orange,
            value: '$ready',
            label: 'Siap',
          ),
          _buildDivider(),
          _buildMiniStat(
            icon: Icons.check_circle_rounded,
            color: Colors.blue,
            value: '$done',
            label: 'Selesai',
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 42,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildSectionTitle() {
    String languageName = 'Quiz';

    try {
      final lang = languages.firstWhere(
        (item) => item['_id']?.toString() == selectedLanguageId,
      );

      languageName = _getLanguageName(lang);
    } catch (_) {}

    return Row(
      children: [
        Text(
          '$languageName Quiz',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 19,
            color: Colors.black87,
          ),
        ),
        const Spacer(),
        Text(
          '${_getDoneQuizCount()}/${_getSelectedLanguageModules().length} selesai',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildNoQuizInLanguage() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(
            Icons.quiz_outlined,
            color: Colors.grey.shade400,
            size: 56,
          ),
          const SizedBox(height: 10),
          Text(
            'Belum ada kuis untuk bahasa ini.',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.bold,
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

  Widget _buildQuizCard({
    required dynamic mod,
    required String moduleId,
    required bool materialDone,
    required bool quizDone,
  }) {
    final bool isUnlocked = materialDone;
    final Color mainColor = quizDone
        ? Colors.blue
        : isUnlocked
            ? Colors.green
            : Colors.grey;

    final IconData leadingIcon = quizDone
        ? Icons.check_circle_rounded
        : isUnlocked
            ? Icons.play_arrow_rounded
            : Icons.lock_rounded;

    final String statusText = quizDone
        ? 'Sudah selesai'
        : isUnlocked
            ? 'Siap dikerjakan'
            : 'Selesaikan materi dulu';

    final String subtitle = quizDone
        ? 'Kamu sudah menaklukkan kuis ini.'
        : isUnlocked
            ? 'Materi sudah dibaca, kuis sudah terbuka.'
            : 'Baca materi ini dulu untuk membuka kuis.';

    return GestureDetector(
      onTap: () {
        if (moduleId.isEmpty) {
          _showSnackBar('Data materi tidak valid.', Colors.red);
          return;
        }

        if (isUnlocked) {
          _openQuiz(mod, moduleId);
        } else {
          _showLockedDialog(mod, moduleId);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(isUnlocked ? 0.96 : 0.84),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: quizDone
                ? Colors.blue.withOpacity(0.25)
                : isUnlocked
                    ? Colors.green.withOpacity(0.25)
                    : Colors.grey.withOpacity(0.14),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isUnlocked ? 0.055 : 0.025),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: mainColor.withOpacity(isUnlocked ? 0.14 : 0.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                leadingIcon,
                color: isUnlocked ? mainColor : Colors.grey.shade400,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mod['judul_modul'] ?? 'Tanpa Judul',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: isUnlocked ? Colors.black87 : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      color: isUnlocked
                          ? Colors.grey.shade600
                          : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: mainColor.withOpacity(isUnlocked ? 0.10 : 0.08),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: isUnlocked ? mainColor : Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              isUnlocked
                  ? Icons.arrow_forward_ios_rounded
                  : Icons.menu_book_rounded,
              color: isUnlocked ? mainColor : Colors.grey.shade400,
              size: isUnlocked ? 18 : 26,
            ),
          ],
        ),
      ),
    );
  }

  void _showLockedDialog(Map<String, dynamic> mod, String moduleId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
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
            onPressed: () => Navigator.pop(dialogContext),
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
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              _openMateri(mod, moduleId);
            },
            child: const Text(
              'Baca Materi',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// lib/screens/home_screen.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../../utils/xp_level_helper.dart';
import 'leaderboard_screen.dart';
import 'materi_detail_screen.dart';
import 'materi_screen.dart'; // Tetap di-import untuk jaga-jaga

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? userData;
  Map<String, dynamic>? nextModule;

  List<dynamic> leaderboard = [];
  bool isLoading = true;
  bool isContinueLoading = true;

  // --- PERUBAHAN 1: Menambahkan 'languageName' sebagai kunci pencarian ---
  final List<Map<String, String>> _allQuests = [
    {'title': 'Misi Harian:\nPython Loop', 'image': 'assets/python.png', 'languageName': 'Python'},
    {'title': 'Misi Harian:\nJava Variable', 'image': 'assets/java.png', 'languageName': 'Java'},
    {'title': 'Misi Harian:\nC++ Basics', 'image': 'assets/cpp.png', 'languageName': 'C++'},
    {'title': 'Misi Harian:\nHTML Tags', 'image': 'assets/html.png', 'languageName': 'HTML'},
  ];

  int _questIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startQuestTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startQuestTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;

      setState(() {
        _questIndex = (_questIndex + 1) % _allQuests.length;
      });
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      isContinueLoading = true;
    });

    await _loadUserData();

    final fetchedLeaderboard = await ApiService.getLeaderboard();

    await _loadContinueLearning();

    if (!mounted) return;

    setState(() {
      leaderboard = fetchedLeaderboard;
      isLoading = false;
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userStr = prefs.getString('user_data');

    if (userStr != null) {
      try {
        userData = jsonDecode(userStr);
      } catch (e) {
        userData = null;
      }
    }
  }

  // =====================================================
  // LANJUT BELAJAR
  // =====================================================

  Future<void> _loadContinueLearning() async {
    try {
      if (userData == null) {
        if (!mounted) return;

        setState(() {
          nextModule = null;
          isContinueLoading = false;
        });

        return;
      }

      final String userId =
          (userData?['id'] ?? userData?['_id'] ?? '').toString();

      if (userId.isEmpty) {
        if (!mounted) return;

        setState(() {
          nextModule = null;
          isContinueLoading = false;
        });

        return;
      }

      final List<dynamic> allModules = await ApiService.getModules();
      final List<dynamic> allLanguages = await ApiService.getLanguages();
      final List<dynamic> progressData =
          await ApiService.getUserProgress(userId);

      final Set<String> validLanguageIds = allLanguages
          .map((lang) => (lang['_id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();

      final Set<String> completedModuleIds = progressData
          .where((item) {
            return item['tipe_progress'] == 'materi' &&
                item['is_completed'] == true &&
                item['module_id'] != null;
          })
          .map<String>((item) {
            final module = item['module_id'];

            if (module is Map && module['_id'] != null) {
              return module['_id'].toString();
            }

            return module.toString();
          })
          .where((id) => id.isNotEmpty)
          .toSet();

      final List<Map<String, dynamic>> validModules = allModules
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .where((module) {
            final String moduleId = (module['_id'] ?? '').toString();
            final String languageId = _getModuleLanguageId(module);

            final bool isDeleted =
                module['is_deleted'] == true ||
                module['deleted'] == true ||
                module['deleted_at'] != null ||
                module['is_active'] == false ||
                module['status'] == 'deleted' ||
                module['status'] == 'inactive';

            if (moduleId.isEmpty) return false;
            if (languageId.isEmpty) return false;
            if (!validLanguageIds.contains(languageId)) return false;
            if (isDeleted) return false;

            return true;
          })
          .toList();

      validModules.sort((a, b) {
        final String langA = _getModuleLanguageId(a);
        final String langB = _getModuleLanguageId(b);

        final int langCompare = langA.compareTo(langB);
        if (langCompare != 0) return langCompare;

        final int orderA = _toInt(a['urutan']);
        final int orderB = _toInt(b['urutan']);

        if (orderA != orderB) return orderA.compareTo(orderB);

        final String titleA = (a['judul_modul'] ?? '').toString();
        final String titleB = (b['judul_modul'] ?? '').toString();

        return titleA.compareTo(titleB);
      });

      final Map<String, List<Map<String, dynamic>>> modulesByLanguage = {};

      for (final module in validModules) {
        final String languageId = _getModuleLanguageId(module);

        modulesByLanguage.putIfAbsent(languageId, () => []);
        modulesByLanguage[languageId]!.add(module);
      }

      Map<String, dynamic>? found;

      for (final entry in modulesByLanguage.entries) {
        final List<Map<String, dynamic>> languageModules = entry.value;

        languageModules.sort((a, b) {
          final int orderA = _toInt(a['urutan']);
          final int orderB = _toInt(b['urutan']);

          if (orderA != orderB) return orderA.compareTo(orderB);

          final String titleA = (a['judul_modul'] ?? '').toString();
          final String titleB = (b['judul_modul'] ?? '').toString();

          return titleA.compareTo(titleB);
        });

        for (int i = 0; i < languageModules.length; i++) {
          final module = languageModules[i];
          final String moduleId = (module['_id'] ?? '').toString();

          if (moduleId.isEmpty) continue;

          final bool alreadyCompleted = completedModuleIds.contains(moduleId);

          if (alreadyCompleted) continue;

          final bool isFirstModule = i == 0;

          if (isFirstModule) {
            found = module;
            break;
          }

          final previousModule = languageModules[i - 1];
          final String previousModuleId =
              (previousModule['_id'] ?? '').toString();

          final bool previousCompleted =
              completedModuleIds.contains(previousModuleId);

          if (previousCompleted) {
            found = module;
            break;
          }
        }

        if (found != null) break;
      }

      if (!mounted) return;

      setState(() {
        nextModule = found;
        isContinueLoading = false;
      });
    } catch (e) {
      debugPrint('LOAD CONTINUE LEARNING ERROR: $e');

      if (!mounted) return;

      setState(() {
        nextModule = null;
        isContinueLoading = false;
      });
    }
  }

  Future<void> _openContinueLearning() async {
    if (nextModule == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const MateriScreen(),
        ),
      );

      await _loadData();
      return;
    }

    final String moduleId = (nextModule?['_id'] ?? '').toString();

    if (moduleId.isEmpty) {
      await _loadData();
      return;
    }

    final List<dynamic> latestModules = await ApiService.getModules();
    final List<dynamic> latestLanguages = await ApiService.getLanguages();

    final Set<String> validLanguageIds = latestLanguages
        .map((lang) => (lang['_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();

    final bool stillExists = latestModules.any((module) {
      final String id = (module['_id'] ?? '').toString();

      final dynamic rawLanguage =
          module['id_bahasa'] ?? module['language_id'] ?? module['bahasa_id'];

      String languageId = '';

      if (rawLanguage is Map) {
        languageId = (rawLanguage['_id'] ?? rawLanguage['id'] ?? '').toString();
      } else if (rawLanguage != null) {
        languageId = rawLanguage.toString();
      }

      final bool isDeleted =
          module['is_deleted'] == true ||
          module['deleted'] == true ||
          module['deleted_at'] != null ||
          module['is_active'] == false ||
          module['status'] == 'deleted' ||
          module['status'] == 'inactive';

      return id == moduleId &&
          !isDeleted &&
          languageId.isNotEmpty &&
          validLanguageIds.contains(languageId);
    });

    if (!stillExists) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Materi ini sudah dihapus oleh admin. Memuat ulang...'),
          backgroundColor: Colors.red,
        ),
      );

      await _loadData();
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MateriDetailScreen(module: nextModule!),
      ),
    );

    await _loadData();
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  String _getModuleLanguageId(Map<String, dynamic> module) {
    final dynamic language =
        module['id_bahasa'] ?? module['language_id'] ?? module['bahasa_id'];

    if (language == null) return '';

    if (language is Map) {
      return (language['_id'] ?? language['id'] ?? '').toString();
    }

    return language.toString();
  }

  String _formatXp(int xp) {
    if (xp >= 1000000) {
      final double value = xp / 1000000;
      return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}M';
    }

    if (xp >= 1000) {
      final double value = xp / 1000;
      return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}K';
    }

    return xp.toString();
  }

  @override
  Widget build(BuildContext context) {
    final int currentXp = _toInt(userData?['total_xp']);
    final XpLevelInfo xpInfo = XpLevelHelper.calculate(currentXp);

    return Scaffold(
      body: userData == null || isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.green),
            )
          : SizedBox.expand(
              child: Stack(
                children: [
                  SizedBox.expand(
                    child: Image.asset(
                      'assets/coding_bg.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                  RefreshIndicator(
                    onRefresh: _loadData,
                    color: Colors.green,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(currentXp, xpInfo),
                          const SizedBox(height: 20),
                          _buildContinueLearning(),
                          const SizedBox(height: 25),
                          _buildCurrentQuests(),
                          const SizedBox(height: 25),
                          _buildWeeklyLeaderboard(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(int currentXp, XpLevelInfo xpInfo) {
    final String avatarUrl = (userData?['avatar_url'] ?? '').toString();
    final String name = (userData?['nama_lengkap'] ?? 'Coder').toString();

    final String levelText =
        xpInfo.isPro ? 'Level Pro' : 'Level ${xpInfo.level}';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
      decoration: const BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white,
                backgroundImage:
                    avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.isEmpty
                    ? const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.green,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          levelText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.local_fire_department,
                          color: Colors.orangeAccent,
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              Text(
                '${_formatXp(currentXp)} XP',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  xpInfo.nextLabel,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: xpInfo.isPro ? 1.0 : xpInfo.progress.clamp(0.02, 1.0),
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.orangeAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueLearning() {
    final String title = nextModule == null
        ? 'Semua Materi Selesai'
        : (nextModule?['judul_modul'] ?? 'Materi Berikutnya').toString();

    final String subtitle = nextModule == null
        ? 'Buka daftar materi untuk belajar topik lain'
        : 'Lanjutkan pelajaran yang tersedia';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: isContinueLoading ? null : _openContinueLearning,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2C3E50).withOpacity(0.92),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: nextModule == null ? Colors.green : Colors.orangeAccent,
                  shape: BoxShape.circle,
                ),
                child: isContinueLoading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        nextModule == null
                            ? Icons.check_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: isContinueLoading
                    ? const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lanjut Belajar',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Mencari pelajaran berikutnya...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lanjut Belajar',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: 8),
              Icon(
                nextModule == null
                    ? Icons.menu_book_rounded
                    : Icons.arrow_forward_ios,
                color: Colors.white,
                size: nextModule == null ? 22 : 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentQuests() {
    final firstQuest = _allQuests[_questIndex];
    final secondQuest = _allQuests[(_questIndex + 1) % _allQuests.length];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Current Quests',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 800),
                  transitionBuilder: (child, animation) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.2, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  ),
                  child: _buildQuestCard(
                    firstQuest['title']!,
                    firstQuest['image']!,
                    firstQuest['languageName']!, // Parsing languageName
                    key: ValueKey('q1_$_questIndex'),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 800),
                  transitionBuilder: (child, animation) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.2, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  ),
                  child: _buildQuestCard(
                    secondQuest['title']!,
                    secondQuest['image']!,
                    secondQuest['languageName']!, // Parsing languageName
                    key: ValueKey('q2_$_questIndex'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- PERUBAHAN 2: Fungsi untuk mencari bahasa di API dan melempar ke StudentModuleListScreen ---
  Widget _buildQuestCard(String title, String imagePath, String languageNameTarget, {Key? key}) {
    return GestureDetector(
      key: key,
      onTap: () async {
        // 1. Tampilkan loading sebentar (opsional tapi bagus untuk UX)
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.green)),
        );

        try {
          // 2. Tarik daftar semua bahasa dari API
          final List<dynamic> languages = await ApiService.getLanguages();
          
          // 3. Cari bahasa yang cocok dengan 'languageNameTarget' (misal: "Python")
          final targetLang = languages.firstWhere(
            (lang) => (lang['nama_bahasa'] ?? '').toString().toLowerCase() == languageNameTarget.toLowerCase(),
            orElse: () => null,
          );

          // Tutup loading
          Navigator.pop(context);

          // 4. Jika bahasanya ketemu, lempar langsung ke StudentModuleListScreen
          if (targetLang != null) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentModuleListScreen(
                  languageId: (targetLang['_id'] ?? '').toString(),
                  languageName: (targetLang['nama_bahasa'] ?? '').toString(),
                  iconUrl: (targetLang['icon_url'] ?? '').toString(),
                ),
              ),
            );
          } else {
            // Jika bahasa tidak ada di database, lemparkan ke materi utama saja
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Bahasa $languageNameTarget belum tersedia!'), backgroundColor: Colors.orange),
            );
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MateriScreen()),
            );
          }
        } catch (e) {
          Navigator.pop(context); // Tutup loading jika error
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MateriScreen()),
          );
        }

        await _loadData();
      },
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.88),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyLeaderboard() {
    final List<dynamic> topThree = leaderboard.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.88),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Peringkat Mingguan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LeaderboardScreen(
                          leaderboard: leaderboard,
                        ),
                      ),
                    );
                  },
                  child: const Text('Lihat Semua'),
                ),
              ],
            ),
            const Divider(),
            if (topThree.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Belum ada data leaderboard',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...topThree.asMap().entries.map((entry) {
                final int index = entry.key;
                final dynamic data = entry.value;

                final Color rankColor = index == 0
                    ? Colors.orangeAccent
                    : (index == 1
                        ? Colors.blueGrey.shade300
                        : Colors.brown.shade400);

                final String avatarUrl = (data['avatar_url'] ?? '').toString();
                final int totalXp = _toInt(data['total_xp']);
                final XpLevelInfo rankXpInfo =
                    XpLevelHelper.calculate(totalXp);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text(
                            '#${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: rankColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.green.shade100,
                          backgroundImage: avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  color: Colors.green,
                                  size: 20,
                                )
                              : null,
                        ),
                      ],
                    ),
                    title: Text(
                      data['nama_lengkap'] ?? 'User',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      rankXpInfo.isPro
                          ? 'Level Pro'
                          : 'Level ${rankXpInfo.level}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_formatXp(totalXp)} XP',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
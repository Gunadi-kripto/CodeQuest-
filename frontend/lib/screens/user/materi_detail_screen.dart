// lib/screens/user/materi_detail_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import 'quiz_screen.dart';

class MateriDetailScreen extends StatefulWidget {
  final Map<String, dynamic> module;

  const MateriDetailScreen({
    super.key,
    required this.module,
  });

  @override
  State<MateriDetailScreen> createState() => _MateriDetailScreenState();
}

class _MateriDetailScreenState extends State<MateriDetailScreen> {
  bool isCompletingModule = false;
  bool isCheckingAccess = true;
  bool hasAccess = false;
  bool hasMarkedComplete = false;

  String currentUserId = '';
  String previousModuleTitle = 'materi sebelumnya';

  Set<String> completedModuleIds = {};

  @override
  void initState() {
    super.initState();
    _loadUserAndCheckAccess();
  }

  Future<void> _loadUserAndCheckAccess() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userStr = prefs.getString('user_data');

    if (userStr == null) {
      if (!mounted) return;

      setState(() {
        isCheckingAccess = false;
        hasAccess = false;
      });

      return;
    }

    final Map<String, dynamic> userData = jsonDecode(userStr);

    final String userId = (userData['id'] ?? userData['_id'] ?? '').toString();
    final String moduleId = (widget.module['_id'] ?? '').toString();

    if (userId.isEmpty || moduleId.isEmpty) {
      if (!mounted) return;

      setState(() {
        isCheckingAccess = false;
        hasAccess = false;
      });

      return;
    }

    currentUserId = userId;

    try {
      final progressData = await ApiService.getUserProgress(userId);

      completedModuleIds = progressData
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
          .toSet();

      final bool alreadyCompleted = completedModuleIds.contains(moduleId);

      final bool allowed = await _checkModuleAccess(
        currentModuleId: moduleId,
      );

      if (!mounted) return;

      setState(() {
        hasAccess = allowed;
        hasMarkedComplete = alreadyCompleted;
        isCheckingAccess = false;
      });
    } catch (e) {
      debugPrint('CHECK MODULE ACCESS ERROR: $e');

      if (!mounted) return;

      setState(() {
        isCheckingAccess = false;
        hasAccess = false;
      });
    }
  }

  Future<bool> _checkModuleAccess({
    required String currentModuleId,
  }) async {
    final String languageId = _getModuleLanguageId(widget.module);

    if (languageId.isEmpty) {
      // Kalau languageId tidak kebaca, jangan langsung buka bebas.
      return false;
    }

    final List<dynamic> languageModules =
        await ApiService.getModulesByLanguage(languageId);

    languageModules.sort((a, b) {
      final int orderA = _toInt(a['urutan']);
      final int orderB = _toInt(b['urutan']);

      if (orderA != orderB) return orderA.compareTo(orderB);

      final String titleA = (a['judul_modul'] ?? '').toString();
      final String titleB = (b['judul_modul'] ?? '').toString();

      return titleA.compareTo(titleB);
    });

    final int currentIndex = languageModules.indexWhere((module) {
      return (module['_id'] ?? '').toString() == currentModuleId;
    });

    if (currentIndex == -1) {
      return false;
    }

    // Bab 1 selalu terbuka.
    if (currentIndex == 0) {
      return true;
    }

    final previousModule = languageModules[currentIndex - 1];
    final String previousModuleId = (previousModule['_id'] ?? '').toString();

    previousModuleTitle =
        (previousModule['judul_modul'] ?? 'materi sebelumnya').toString();

    return completedModuleIds.contains(previousModuleId);
  }

  String _getModuleLanguageId(dynamic module) {
    final dynamic rawLanguage =
        module['id_bahasa'] ?? module['language_id'] ?? module['bahasa_id'];

    if (rawLanguage == null) return '';

    if (rawLanguage is Map) {
      return (rawLanguage['_id'] ?? rawLanguage['id'] ?? '').toString();
    }

    return rawLanguage.toString();
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  Future<void> _completeModuleAndOpenQuiz() async {
    final String moduleId = (widget.module['_id'] ?? '').toString();

    if (!hasAccess) {
      _showSnackBar(
        'Materi ini masih terkunci. Selesaikan "$previousModuleTitle" dulu.',
        Colors.red,
      );
      return;
    }

    if (currentUserId.isEmpty || moduleId.isEmpty) {
      _showSnackBar(
        'Data user atau materi tidak valid',
        Colors.red,
      );
      return;
    }

    if (isCompletingModule) return;

    setState(() {
      isCompletingModule = true;
    });

    try {
      final bool allowed = await _checkModuleAccess(
        currentModuleId: moduleId,
      );

      if (!allowed) {
        if (!mounted) return;

        setState(() {
          hasAccess = false;
          isCompletingModule = false;
        });

        _showSnackBar(
          'Materi ini masih terkunci. Selesaikan "$previousModuleTitle" dulu.',
          Colors.red,
        );
        return;
      }

      final result = await ApiService.completeModule(
        userId: currentUserId,
        moduleId: moduleId,
      );

      if (!mounted) return;

      setState(() {
        isCompletingModule = false;
      });

      if (result['success'] != true) {
        _showSnackBar(
          result['message']?.toString() ?? 'Gagal menyelesaikan materi',
          Colors.red,
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('read_${currentUserId}_$moduleId', true);

      setState(() {
        hasMarkedComplete = true;
      });

      final List<dynamic> newAchievements =
          result['new_achievements'] is List
              ? result['new_achievements']
              : [];

      if (newAchievements.isNotEmpty) {
        await _showAchievementUnlockedDialog(newAchievements);
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizScreen(
            moduleId: moduleId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isCompletingModule = false;
      });

      _showSnackBar(
        e.toString().replaceAll('Exception: ', ''),
        Colors.red,
      );
    }
  }

  Future<void> _showAchievementUnlockedDialog(List<dynamic> achievements) async {
    final achievement = achievements.first;

    final String title =
        (achievement['judul'] ?? 'Achievement Baru').toString();

    final String description =
        (achievement['deskripsi'] ?? '').toString();

    final String iconUrl =
        (achievement['icon_url'] ?? achievement['icon'] ?? '').toString();

    final int xpReward = int.tryParse(
          (achievement['xp_reward'] ?? 0).toString(),
        ) ??
        0;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
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
              width: 92,
              height: 92,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: _achievementImage(iconUrl),
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
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '+$xpReward XP',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Mantap!',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _achievementImage(String iconUrl) {
    final bool isNetworkImage =
        iconUrl.startsWith('http://') || iconUrl.startsWith('https://');

    if (!isNetworkImage) {
      return const Icon(
        Icons.emoji_events_rounded,
        color: Colors.orange,
        size: 58,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: CachedNetworkImage(
        imageUrl: iconUrl,
        fit: BoxFit.contain,
        errorWidget: (_, __, ___) => const Icon(
          Icons.emoji_events_rounded,
          color: Colors.orange,
          size: 58,
        ),
        placeholder: (_, __) => const Center(
          child: CircularProgressIndicator(
            color: Colors.orange,
            strokeWidth: 2,
          ),
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    final List<dynamic> isiMateri = widget.module['materi_isi'] ?? [];
    final String judulMateri =
        (widget.module['judul_modul'] ?? 'Detail Materi').toString();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          judulMateri,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.bookmark_border,
              color: Colors.black,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: isCheckingAccess
          ? const Center(
              child: CircularProgressIndicator(color: Colors.green),
            )
          : !hasAccess
              ? _buildLockedContent(judulMateri)
              : _buildUnlockedContent(
                  isiMateri: isiMateri,
                  judulMateri: judulMateri,
                ),
    );
  }

  Widget _buildLockedContent(String judulMateri) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Colors.red,
                      size: 46,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Materi Masih Terkunci',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 21,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Kamu belum bisa membaca "$judulMateri".\n\nSelesaikan "$previousModuleTitle" terlebih dahulu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Kembali ke Daftar Materi',
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
                        vertical: 13,
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
    );
  }

  Widget _buildUnlockedContent({
    required List<dynamic> isiMateri,
    required String judulMateri,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.stars,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Materi Belajar',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: hasMarkedComplete ? 1.0 : 0.8,
                      backgroundColor: Colors.white,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.green,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apa itu $judulMateri?',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.module['deskripsi']?.toString() ?? '',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 25),
                const Text(
                  'Penjelasan Materi:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 15),
                ...isiMateri.map((item) {
                  final String type = (item['tipe'] ?? '').toString();
                  final String content = (item['content'] ?? '').toString();

                  if (type == 'text') {
                    final bool isCode =
                        content.contains('print(') || content.contains('=');

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: isCode
                          ? _buildCodeBlock(content)
                          : Text(
                              content,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: Colors.black87,
                              ),
                            ),
                    );
                  }

                  if (type == 'image') {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: CachedNetworkImage(
                          imageUrl: content,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                color: Colors.green,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return const SizedBox();
                }).toList(),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.1),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb,
                        color: Colors.orange,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tips',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Pahami konsep dasarnya sebelum lanjut ke kuis agar mendapatkan skor XP maksimal!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: const BorderSide(color: Colors.green),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Sebelumnya',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      isCompletingModule ? null : _completeModuleAndOpenQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: isCompletingModule
                      ? const SizedBox(
                          height: 19,
                          width: 19,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Mulai Kuis',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              size: 18,
                              color: Colors.white,
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCodeBlock(String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(text: code),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kode disalin!'),
                    ),
                  );
                },
                child: const Row(
                  children: [
                    Icon(
                      Icons.copy,
                      color: Colors.white54,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Salin',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            code,
            style: const TextStyle(
              color: Color(0xFF9CDCFE),
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import 'materi_detail_screen.dart';

class MateriScreen extends StatefulWidget {
  const MateriScreen({super.key});

  @override
  State<MateriScreen> createState() => _MateriScreenState();
}

class _MateriScreenState extends State<MateriScreen> {
  List<dynamic> languages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLanguages();
  }

  Future<void> _loadLanguages() async {
    setState(() {
      isLoading = true;
    });

    final fetchedLanguages = await ApiService.getLanguages();

    if (mounted) {
      setState(() {
        languages = fetchedLanguages;
        isLoading = false;
      });
    }
  }

  Widget _buildLanguageCard(dynamic lang) {
    final String languageId = (lang['_id'] ?? '').toString();
    final String languageName = (lang['nama_bahasa'] ?? '').toString();
    final String iconUrl = (lang['icon_url'] ?? '').toString();

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentModuleListScreen(
              languageId: languageId,
              languageName: languageName,
              iconUrl: iconUrl,
            ),
          ),
        );

        await _loadLanguages();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CachedNetworkImage(
              imageUrl: iconUrl,
              height: 70,
              placeholder: (context, url) =>
                  const CircularProgressIndicator(strokeWidth: 2),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.code, size: 40),
            ),
            const SizedBox(height: 12),
            Text(
              languageName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakBox() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8EA).withOpacity(0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.local_fire_department, color: Colors.green, size: 35),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bangun Streak Belajarmu!',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Dapatkan XP lebih banyak hari ini!',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  )
                : RefreshIndicator(
                    onRefresh: _loadLanguages,
                    color: Colors.green,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Image.asset(
                            'assets/Software Engineer.jpg',
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Pilih Bahasa\nPemrograman',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 25),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: languages.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 18,
                              mainAxisSpacing: 18,
                              childAspectRatio: 0.9,
                            ),
                            itemBuilder: (context, index) {
                              final lang = languages[index];
                              return _buildLanguageCard(lang);
                            },
                          ),
                          const SizedBox(height: 30),
                          _buildStreakBox(),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class StudentModuleListScreen extends StatefulWidget {
  final String languageId;
  final String languageName;
  final String iconUrl;

  const StudentModuleListScreen({
    super.key,
    required this.languageId,
    required this.languageName,
    required this.iconUrl,
  });

  @override
  State<StudentModuleListScreen> createState() =>
      _StudentModuleListScreenState();
}

class _StudentModuleListScreenState extends State<StudentModuleListScreen> {
  List<dynamic> modules = [];
  Set<String> completedModuleIds = {};

  bool isLoading = true;
  int completedCount = 0;
  int totalXp = 0;

  @override
  void initState() {
    super.initState();
    _loadModulesAndProgress();
  }

  Future<void> _loadModulesAndProgress() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    final moduleData = await ApiService.getModulesByLanguage(widget.languageId);

    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user_data');

    Set<String> finishedIds = {};
    int userXp = 0;

    if (userStr != null) {
      try {
        final Map<String, dynamic> userData = jsonDecode(userStr);

        final String userId =
            (userData['id'] ?? userData['_id'] ?? '').toString();

        userXp = int.tryParse((userData['total_xp'] ?? 0).toString()) ?? 0;

        if (userId.isNotEmpty) {
          final progressData = await ApiService.getUserProgress(userId);

          finishedIds = progressData
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
        }
      } catch (e) {
        print('LOAD USER PROGRESS ERROR: $e');
        finishedIds = {};
      }
    }

    final int filteredCompleted = moduleData.where((module) {
      final moduleId = (module['_id'] ?? '').toString();
      return finishedIds.contains(moduleId);
    }).length;

    if (mounted) {
      setState(() {
        modules = moduleData;
        completedModuleIds = finishedIds;
        completedCount = filteredCompleted;
        totalXp = userXp;
        isLoading = false;
      });
    }
  }

  bool _isModuleCompleted(dynamic mod) {
    final moduleId = (mod['_id'] ?? '').toString();
    return completedModuleIds.contains(moduleId);
  }

  bool _isModuleLocked(int index) {
    if (index == 0) return false;

    final previousModule = modules[index - 1];
    final previousModuleId = (previousModule['_id'] ?? '').toString();

    return !completedModuleIds.contains(previousModuleId);
  }

  Future<void> _openModule(dynamic mod) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MateriDetailScreen(module: mod),
      ),
    );

    await _loadModulesAndProgress();
  }

  Widget _buildStatCard(
    String title,
    String value,
    bool showProgress,
    double progress,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!showProgress)
                  const Icon(Icons.stars, color: Colors.orange, size: 18),
              ],
            ),
            if (showProgress) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress.clamp(0, 1),
                  backgroundColor: Colors.grey[200],
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.green),
                  minHeight: 6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModuleItem(
    int number,
    dynamic mod,
    bool isDone,
    bool isLocked,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFF1F9F1) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDone ? Colors.green.withOpacity(0.3) : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDone
              ? Colors.green
              : (isLocked ? Colors.grey[300] : Colors.black87),
          radius: 14,
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          mod['judul_modul'] ?? '',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          mod['deskripsi'] ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Icon(
          isDone
              ? Icons.check_circle
              : (isLocked ? Icons.lock : Icons.arrow_forward_ios),
          color: isDone ? Colors.green : Colors.grey[400],
          size: 20,
        ),
        onTap: isLocked ? null : () => _openModule(mod),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.languageName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.green),
            )
          : RefreshIndicator(
              color: Colors.green,
              onRefresh: _loadModulesAndProgress,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    CachedNetworkImage(
                      imageUrl: widget.iconUrl,
                      height: 80,
                      errorWidget: (context, url, error) => const Icon(
                        Icons.code,
                        size: 80,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Belajar ${widget.languageName} dari dasar hingga\nbisa membuat program sendiri!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        _buildStatCard(
                          'Progress Kamu',
                          '$completedCount/${modules.length} Materi',
                          true,
                          modules.isNotEmpty
                              ? completedCount / modules.length
                              : 0,
                        ),
                        const SizedBox(width: 15),
                        _buildStatCard(
                          'XP Didapat',
                          '$totalXp XP',
                          false,
                          0,
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Materi Dasar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: modules.length,
                      itemBuilder: (context, index) {
                        final mod = modules[index];

                        final bool isDone = _isModuleCompleted(mod);
                        final bool isLocked = _isModuleLocked(index);

                        return _buildModuleItem(
                          index + 1,
                          mod,
                          isDone,
                          isLocked,
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'materi_detail_screen.dart';
import 'quiz_screen.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  _QuizListScreenState createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  List<dynamic> modules = [];
  bool isLoading = true;
  SharedPreferences? prefs;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    prefs = await SharedPreferences.getInstance();
    String? userStr = prefs!.getString('user_data');
    if (userStr != null) {
      Map<String, dynamic> userData = jsonDecode(userStr);
      currentUserId = userData['id'] ?? userData['_id'];
    }
    final fetchedModules = await ApiService.getModules();
    if (mounted) {
      setState(() {
        modules = fetchedModules;
        isLoading = false;
      });
    }
  }

  bool _isUnlocked(String moduleId) {
    if (prefs == null || currentUserId == null) return false;
    return prefs!.getBool('read_${currentUserId}_$moduleId') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Background coding ──
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
                // Header
                Padding(
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
                            fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // List
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.green))
                      : modules.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.quiz_outlined,
                                      size: 64,
                                      color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text('Kuis belum tersedia.',
                                      style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 16)),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadData,
                              color: Colors.green,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                itemCount: modules.length,
                                itemBuilder: (context, index) {
                                  final mod = modules[index];
                                  final String moduleId = mod['_id'];
                                  final bool isUnlocked = _isUnlocked(moduleId);
                                  return _buildQuizCard(mod, moduleId, isUnlocked);
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

  Widget _buildQuizCard(dynamic mod, String moduleId, bool isUnlocked) {
    return GestureDetector(
      onTap: () {
        if (isUnlocked) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => QuizScreen(moduleId: moduleId)),
          );
        } else {
          _showLockedDialog(mod);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isUnlocked
              ? Colors.white.withValues(alpha: 0.95)
              : Colors.grey.shade200.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(18),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
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
              // Icon lingkaran
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? Colors.green.withValues(alpha: 0.12)
                      : Colors.grey.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isUnlocked ? Icons.extension_rounded : Icons.lock_rounded,
                  color: isUnlocked ? Colors.green : Colors.grey.shade400,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),

              // Teks
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kuis: ${mod['judul_modul']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isUnlocked ? Colors.black87 : Colors.grey.shade500,
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
                          color: isUnlocked ? Colors.green : Colors.red.shade300,
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

              // Arrow
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

  void _showLockedDialog(Map<String, dynamic> mod) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Kuis Terkunci',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'Kamu belum membaca "${mod['judul_modul']}".\n\nBaca materinya terlebih dahulu untuk membuka kuis ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nanti saja',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => MateriDetailScreen(module: mod)),
              ).then((_) => setState(() {}));
            },
            child: const Text('Baca Materi',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
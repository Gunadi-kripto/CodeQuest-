import 'dart:convert'; // Wajib ditambah
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
  String? currentUserId; // Menyimpan ID User yang sedang aktif

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    prefs = await SharedPreferences.getInstance();
    
    // Ambil ID User yang sedang login
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

  // Mengecek apakah materi kuis ini sudah dibaca OLEH USER INI
  bool _isUnlocked(String moduleId) {
    if (prefs == null || currentUserId == null) return false;
    // Cek gembok menggunakan kombinasi ID User dan ID Materi
    return prefs!.getBool('read_${currentUserId}_$moduleId') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Daftar Kuis', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false, 
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : modules.isEmpty
              ? const Center(child: Text('Kuis belum tersedia.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: modules.length,
                  itemBuilder: (context, index) {
                    final mod = modules[index];
                    final String moduleId = mod['_id'];
                    final bool isUnlocked = _isUnlocked(moduleId);

                    return Card(
                      elevation: isUnlocked ? 2 : 0, 
                      color: isUnlocked ? Colors.white : Colors.grey[300], 
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: isUnlocked ? Colors.green.withOpacity(0.2) : Colors.grey[400],
                          child: Icon(
                            isUnlocked ? Icons.extension : Icons.lock, 
                            color: isUnlocked ? Colors.green : Colors.white
                          ),
                        ),
                        title: Text(
                          'Kuis ${mod['judul_modul']}', 
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 16, 
                            color: isUnlocked ? Colors.black : Colors.grey[600]
                          )
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            isUnlocked ? 'Terbuka! Siap dikerjakan.' : 'Terkunci. Baca materinya terlebih dahulu.',
                            style: TextStyle(color: isUnlocked ? Colors.green : Colors.red[400]),
                          ),
                        ),
                        trailing: Icon(
                          isUnlocked ? Icons.play_arrow : Icons.menu_book, 
                          color: isUnlocked ? Colors.green : Colors.grey[500]
                        ),
                        onTap: () {
                          if (isUnlocked) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => QuizScreen(moduleId: moduleId)),
                            );
                          } else {
                            _showLockedDialog(mod);
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }

  void _showLockedDialog(Map<String, dynamic> mod) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kuis Terkunci 🔒', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text('Kamu belum membaca "${mod['judul_modul']}".\n\nBaca materinya terlebih dahulu untuk membuka kuis ini.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nanti saja', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(context); 
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MateriDetailScreen(module: mod)),
              ).then((_) {
                setState(() {});
              });
            },
            child: const Text('Baca Materi Sekarang', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}
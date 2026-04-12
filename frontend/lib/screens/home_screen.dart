import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key}); // Tambahan const constructor

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? userData;
  List<dynamic> modules = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Fungsi untuk memuat Profil User dan Daftar Materi
  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userStr = prefs.getString('user_data');
    
    if (userStr != null) {
      userData = jsonDecode(userStr);
    }

    // Tembak API Node.js untuk ambil materi
    final fetchedModules = await ApiService.getModules();
    
    setState(() {
      modules = fetchedModules;
      isLoading = false;
    });
  }

  // Fungsi Logout
  void _logout() async {
    await ApiService.logoutUser();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('CodeQuest', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _logout),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === HEADER PROFIL ===
                Container(
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30, top: 10),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(radius: 35, backgroundColor: Colors.white, child: Icon(Icons.person, size: 40, color: Colors.green)),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Halo, ${userData?['nama_lengkap'] ?? 'Coder'}!', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Level ${userData?['level'] ?? 1} • ${userData?['total_xp'] ?? 0} XP', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                        ],
                      )
                    ],
                  ),
                ),
                
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('Peta Petualangan (Materi)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),

                // === LIST MATERI DARI MONGODB ===
                Expanded(
                  child: modules.isEmpty
                      ? const Center(child: Text('Materi belum tersedia dari Admin.', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: modules.length,
                          itemBuilder: (context, index) {
                            final mod = modules[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green.withOpacity(0.2),
                                  child: Text('${mod['urutan']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                ),
                                title: Text(mod['judul_modul']?.toString() ?? 'Tanpa Judul', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(mod['deskripsi']?.toString() ?? 'Tidak ada deskripsi.'),
                                ),
                                trailing: const Icon(Icons.play_circle_fill, color: Colors.green, size: 36),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Membuka ${mod['judul_modul']}...'))
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
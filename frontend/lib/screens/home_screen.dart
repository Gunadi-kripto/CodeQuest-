import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? userData;
  List<dynamic> leaderboard = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 1. Load Data Profil Diri Sendiri
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userStr = prefs.getString('user_data');
    if (userStr != null) {
      userData = jsonDecode(userStr);
    }

    // 2. Load Data Leaderboard dari Backend
    final fetchedLeaderboard = await ApiService.getLeaderboard();

    if (mounted) {
      setState(() {
        leaderboard = fetchedLeaderboard;
        isLoading = false;
      });
    }
  }

  void _logout() async {
    await ApiService.logoutUser();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (context) => const LoginScreen()), 
        (route) => false
      );
    }
  }

  // Menentukan warna piala/medali berdasarkan peringkat
  Color _getRankColor(int index) {
    if (index == 0) return Colors.amber; // Juara 1: Emas
    if (index == 1) return Colors.grey[400]!; // Juara 2: Perak
    if (index == 2) return const Color(0xFFCD7F32); // Juara 3: Perunggu
    return Colors.green[200]!; // Sisanya: Hijau Muda
  }

  @override
  Widget build(BuildContext context) {
    int currentXp = userData?['total_xp'] ?? 0;
    double progress = (currentXp % 100) / 100.0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.notifications, color: Colors.white), onPressed: () {}),
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _logout),
        ],
      ),
      body: userData == null 
        ? const Center(child: CircularProgressIndicator(color: Colors.green))
        : RefreshIndicator(
            onRefresh: _loadData, // Tarik layar ke bawah untuk refresh Leaderboard!
            color: Colors.green,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === HEADER DASHBOARD & LEVEL BAR ===
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 35, 
                              backgroundColor: Colors.white, 
                              backgroundImage: userData!['avatar_url'] != null && userData!['avatar_url'] != "" ? NetworkImage(userData!['avatar_url']) : null,
                              child: userData!['avatar_url'] == null || userData!['avatar_url'] == "" ? const Icon(Icons.person, size: 40, color: Colors.green) : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Halo, ${userData?['nama_lengkap'] ?? 'Coder'}!', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('Level ${userData?['level'] ?? 1}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Bar Progress Level
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${currentXp} XP', style: const TextStyle(color: Colors.white)),
                            Text('100 XP ke Level ${((userData?['level'] ?? 1) + 1)}', style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress == 0 ? 0.05 : progress, 
                            minHeight: 12,
                            backgroundColor: Colors.green[800],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text('Leaderboard Top Coder 🏆', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),

                  // === LEADERBOARD ASLI DARI MONGODB ===
                  isLoading 
                    ? const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: Colors.green)))
                    : leaderboard.isEmpty
                        ? const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('Belum ada data', style: TextStyle(color: Colors.grey))))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: leaderboard.length,
                            itemBuilder: (context, index) {
                              final user = leaderboard[index];
                              
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _getRankColor(index),
                                    child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                  title: Text(user['nama_lengkap'] ?? 'Anonim', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Level ${user['level'] ?? 1} • ${user['total_xp'] ?? 0} XP', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                                  trailing: user['avatar_url'] != null && user['avatar_url'] != "" 
                                      ? CircleAvatar(backgroundImage: NetworkImage(user['avatar_url']), radius: 16)
                                      : const Icon(Icons.person, color: Colors.grey),
                                ),
                              );
                            },
                          )
                ],
              ),
            ),
          ),
    );
  }
}
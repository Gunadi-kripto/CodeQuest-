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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Hanya memuat Profil User, tidak memuat materi lagi
  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userStr = prefs.getString('user_data');
    if (userStr != null) {
      if (mounted) {
        setState(() {
          userData = jsonDecode(userStr);
        });
      }
    }
  }

  void _logout() async {
    await ApiService.logoutUser();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Simulasi perhitungan level bar (misal: butuh 100 XP untuk naik level)
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
        : SingleChildScrollView(
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
                          const CircleAvatar(radius: 35, backgroundColor: Colors.white, child: Icon(Icons.person, size: 40, color: Colors.green)),
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
                          value: progress == 0 ? 0.05 : progress, // minimal ada isinya dikit
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

                // === LEADERBOARD (Tampilan Sementara) ===
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3, // Nanti diganti data asli dari backend
                  itemBuilder: (context, index) {
                    List<String> dummyNames = ["Darrell", "Gunadi Setiawan", "Elvan"];
                    List<int> dummyLevels = [5, 1, 3];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: index == 0 ? Colors.amber : (index == 1 ? Colors.grey[400] : Colors.brown[300]),
                        child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(dummyNames[index], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Level ${dummyLevels[index]}'),
                      trailing: const Icon(Icons.emoji_events, color: Colors.orange),
                    );
                  },
                )
              ],
            ),
          ),
    );
  }
}
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'leaderboard_screen.dart';
import 'materi_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? userData;
  List<dynamic> leaderboard = [];
  bool isLoading = true;

  // Data Quest untuk Slider
  final List<Map<String, String>> _allQuests = [
    {'title': 'Misi Harian:\nPython Loop', 'image': 'assets/python.png'},
    {'title': 'Misi Harian:\nJava Variable', 'image': 'assets/java.png'},
    {'title': 'Misi Harian:\nC++ Basics', 'image': 'assets/cpp.png'},
    {'title': 'Misi Harian:\nHTML Tags', 'image': 'assets/html.png'},
  ];

  int _questIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startQuestTimer();
  }

  // Logika Timer 5 Detik
  void _startQuestTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _questIndex = (_questIndex + 1) % _allQuests.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Mencegah memory leak
    super.dispose();
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userStr = prefs.getString('user_data');

    if (userStr != null) {
      userData = jsonDecode(userStr);
    }

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
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int currentXp = userData?['total_xp'] ?? 0;
    double progress = (currentXp % 100) / 100.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: userData == null || isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: Colors.green,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(currentXp, progress),
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
    );
  }

  // ================= HEADER =================
  Widget _buildHeader(int currentXp, double progress) {
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
                backgroundImage: (userData!['avatar_url'] != null && userData!['avatar_url'] != "")
                    ? NetworkImage(userData!['avatar_url'])
                    : null,
                child: (userData!['avatar_url'] == null || userData!['avatar_url'] == "")
                    ? const Icon(Icons.person, size: 40, color: Colors.green)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, ${userData?['nama_lengkap'] ?? 'Coder'}!',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Level ${userData?['level'] ?? 1}',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 18),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$currentXp XP', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(
                '100 XP ke Level ${((userData?['level'] ?? 1) + 1)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress == 0 ? 0.05 : progress,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
            ),
          ),
        ],
      ),
    );
  }

  // ================= LANJUT BELAJAR =================
  Widget _buildContinueLearning() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2C3E50),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.play_circle_fill, color: Colors.orangeAccent, size: 50),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Lanjut Belajar', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const Text(
                    'Pemahaman Loop Lanjutan',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(value: 0.45, backgroundColor: Colors.white12, color: Colors.green),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MateriScreen())),
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
            )
          ],
        ),
      ),
    );
  }

  // ================= CURRENT QUESTS (DENGAN EFEK GESER) =================
  Widget _buildCurrentQuests() {
    final firstQuest = _allQuests[_questIndex];
    final secondQuest = _allQuests[(_questIndex + 1) % _allQuests.length];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('Current Quests', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 800),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return SlideTransition(
                      position: Tween<Offset>(begin: const Offset(1.2, 0.0), end: Offset.zero).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: _buildQuestCard(firstQuest['title']!, firstQuest['image']!, key: ValueKey('q1_$_questIndex')),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 800),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return SlideTransition(
                      position: Tween<Offset>(begin: const Offset(1.2, 0.0), end: Offset.zero).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: _buildQuestCard(secondQuest['title']!, secondQuest['image']!, key: ValueKey('q2_$_questIndex')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= HELPER KARTU QUEST =================
  Widget _buildQuestCard(String title, String imagePath, {Key? key}) {
    return GestureDetector(
      key: key,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MateriScreen())),
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: Image.asset(imagePath, fit: BoxFit.contain)),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ================= PERINGKAT MINGGUAN =================
  Widget _buildWeeklyLeaderboard() {
    List<dynamic> topThree = leaderboard.take(3).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Peringkat Mingguan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LeaderboardScreen(leaderboard: leaderboard))),
                  child: const Text('Lihat Semua'),
                )
              ],
            ),
            const Divider(),
            ...topThree.asMap().entries.map((entry) {
              int index = entry.key;
              var data = entry.value;
              Color rankColor = index == 0 ? Colors.orangeAccent : (index == 1 ? Colors.blueGrey.shade300 : Colors.brown.shade400);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 24, child: Text('#${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: rankColor))),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.green.shade100,
                        backgroundImage: (data['avatar_url'] != null && data['avatar_url'] != "") ? NetworkImage(data['avatar_url']) : null,
                        child: (data['avatar_url'] == null || data['avatar_url'] == "") ? const Icon(Icons.person, color: Colors.green, size: 20) : null,
                      ),
                    ],
                  ),
                  title: Text(data['nama_lengkap'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Text('Level ${data['level'] ?? 1}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Text('${data['total_xp']} XP', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
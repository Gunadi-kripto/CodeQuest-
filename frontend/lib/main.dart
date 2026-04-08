import 'package:flutter/material.dart';

void main() {
  runApp(const CodeQuestApp());
}

class CodeQuestApp extends StatelessWidget {
  const CodeQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CodeQuest',
      debugShowCheckedModeBanner: false, // Menghilangkan tulisan "DEBUG" di kanan atas
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E88E5)),
        primaryColor: Colors.green, // Warna tema utama CodeQuest
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

// ==========================================
// WIDGET UTAMA (BOTTOM NAVIGATION BAR)
// ==========================================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Daftar halaman yang akan ditampilkan saat tab ditekan
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    MateriScreen(),
    QuizScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: 'Materi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.extension_rounded),
            label: 'Quiz',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green, // Warna ikon saat dipilih
        unselectedItemColor: Colors.grey, // Warna ikon saat tidak dipilih
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed, // Agar semua menu tampil sejajar
        onTap: _onItemTapped,
      ),
    );
  }
}

// ==========================================
// 1. HOME SCREEN (DASHBOARD UTAMA)
// ==========================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER (Bagian Hijau Atas) ---
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  // Avatar Profil
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Colors.green),
                  ),
                  const SizedBox(width: 15),
                  // Info Level & XP
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Level 8',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: const LinearProgressIndicator(
                            value: 0.8, // 80% progress
                            backgroundColor: Colors.white38,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'XP 2400/3000',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  // Ikon Pengaturan / Notifikasi
                  const Icon(Icons.settings, color: Colors.white),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- CURRENT QUESTS SECTION ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Current Quests',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'See All',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),

            // --- LIST QUESTS ---
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  _buildQuestCard(
                    title: 'Misi Harian: Python Loop',
                    icon: Icons.bolt,
                    iconColor: Colors.orange,
                    progressText: '3/3',
                    progressValue: 1.0,
                  ),
                  const SizedBox(height: 10),
                  _buildQuestCard(
                    title: 'Misi Harian: Pascal Logic',
                    icon: Icons.monetization_on,
                    iconColor: Colors.blue,
                    progressText: '1/4',
                    progressValue: 0.25,
                  ),
                  const SizedBox(height: 10),
                  _buildQuestCard(
                    title: 'Selesaikan 2 Kuis',
                    icon: Icons.star,
                    iconColor: Colors.yellow,
                    progressText: '0/2',
                    progressValue: 0.0,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk membuat Card Quest agar kode lebih rapi
  Widget _buildQuestCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String progressText,
    required double progressValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Text(
            progressText,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 2. MATERI SCREEN (PLACEHOLDER)
// ==========================================
class MateriScreen extends StatelessWidget {
  const MateriScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Halaman Materi\n(Bab Pembelajaran akan ada di sini)', textAlign: TextAlign.center,),
      ),
    );
  }
}

// ==========================================
// 3. QUIZ SCREEN (PLACEHOLDER)
// ==========================================
class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Halaman Quiz\n(Peta Quiz Terkunci akan ada di sini)', textAlign: TextAlign.center,),
      ),
    );
  }
}

// ==========================================
// 4. PROFILE SCREEN (PLACEHOLDER)
// ==========================================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Halaman Profile\n(Avatar dan Statistik akan ada di sini)', textAlign: TextAlign.center,),
      ),
    );
  }
}
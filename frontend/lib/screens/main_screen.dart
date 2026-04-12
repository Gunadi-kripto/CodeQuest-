import 'package:flutter/material.dart';
import 'home_screen.dart';
// Asumsi kamu sudah punya 3 file ini (walau isinya masih kosong/dasar)
import 'materi_screen.dart'; 
import 'quiz_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Daftar halaman yang akan diganti-ganti
  final List<Widget> _screens = [
    HomeScreen(),
    MateriScreen(), // Pastikan class-nya bernama MateriScreen
    QuizScreen(),   // Pastikan class-nya bernama QuizScreen
    ProfileScreen() // Pastikan class-nya bernama ProfileScreen
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body akan menampilkan layar sesuai index yang dipilih
      body: _screens[_selectedIndex],
      
      // Ini dia Bar Bawahnya!
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Materi'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Quiz'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
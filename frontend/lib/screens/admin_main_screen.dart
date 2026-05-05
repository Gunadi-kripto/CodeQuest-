import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'admin_manage_users.dart';
import 'admin_manage_materi.dart';
import 'admin_manage_kuis.dart';
import 'admin_manage_achievements.dart'; // IMPORT LAYAR BARU

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;

  // DAFTAR LAYAR DITAMBAH SATU
  static final List<Widget> _widgetOptions = <Widget>[
    const AdminManageUsers(),
    const AdminManageMateri(),
    const AdminManageKuis(),
    const AdminManageAchievements(), 
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portal Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white), 
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        // === MENU DI BAWAH DITAMBAH ===
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Materi'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Kuis'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Piala'), // TAB BARU
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green, 
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, 
        onTap: _onItemTapped,
      ),
    );
  }
}
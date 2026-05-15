import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import file layar user
import 'screens/user/home_screen.dart';
import 'screens/user/materi_screen.dart';
import 'screens/user/profile_screen.dart';
import 'screens/user/quiz_list_screen.dart';

// Import auth
import 'screens/auth/login_screen.dart';

// Import admin
import 'screens/admin/admin_main_screen.dart';

void main() {
  runApp(const CodeQuestApp());
}

class CodeQuestApp extends StatelessWidget {
  const CodeQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CodeQuest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
        ),
        primaryColor: Colors.green,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// =====================================================
// SPLASH SCREEN / AUTO LOGIN CHECK
// =====================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String? token = prefs.getString('jwt_token');
    final String? userDataString = prefs.getString('user_data');

    if (!mounted) return;

    if (token == null || userDataString == null || userDataString.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
      return;
    }

    try {
      final Map<String, dynamic> userData = jsonDecode(userDataString);

      final String role = userData['role']?.toString().toLowerCase() ?? 'user';

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminMainScreen(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MainScreen(),
          ),
        );
      }
    } catch (e) {
      await prefs.remove('jwt_token');
      await prefs.remove('user_data');

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.code_rounded, size: 100, color: Colors.white),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// MAIN SCREEN USER
// =====================================================

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const MateriScreen(),
    const QuizListScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
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
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userStr = prefs.getString('user_data');
    if (userStr != null) {
      setState(() {
        userData = jsonDecode(userStr);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profil Saya', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfileScreen(userData: userData!)),
              ).then((_) => _loadUserData()); // Refresh data saat kembali dari edit
            },
          )
        ],
      ),
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 30),
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.green[100],
                  backgroundImage: userData!['avatar_url'] != "" 
                    ? NetworkImage(userData!['avatar_url']) 
                    : null,
                  child: userData!['avatar_url'] == "" 
                    ? const Icon(Icons.person, size: 60, color: Colors.green) 
                    : null,
                ),
                const SizedBox(height: 16),
                Text(userData!['nama_lengkap'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text('Level ${userData!['level']} • ${userData!['total_xp']} XP', style: const TextStyle(color: Colors.grey, fontSize: 16)),
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Divider(),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.green),
                  title: const Text('Bio'),
                  subtitle: Text(userData!['bio'] ?? 'Belum ada bio.'),
                ),
                ListTile(
                  leading: const Icon(Icons.email_outlined, color: Colors.green),
                  title: const Text('Email'),
                  subtitle: Text(userData!['email'] ?? ''),
                ),
              ],
            ),
    );
  }
}
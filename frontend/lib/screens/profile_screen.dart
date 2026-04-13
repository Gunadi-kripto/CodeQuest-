import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_profile_screen.dart';
import 'social_screen.dart'; // Import layar teman yang akan kita buat

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
    // Logika Cerdas untuk Bio Kosong
    String displayBio = 'Belum ada bio.';
    if (userData != null && userData!['bio'] != null && userData!['bio'].toString().trim().isNotEmpty) {
      displayBio = userData!['bio'];
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profil Saya', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfileScreen(userData: userData!)),
              ).then((_) => _loadUserData());
            },
          )
        ],
      ),
      body: userData == null
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : Column(
              children: [
                const SizedBox(height: 30),
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.green[100],
                  backgroundImage: userData!['avatar_url'] != null && userData!['avatar_url'] != "" 
                    ? NetworkImage(userData!['avatar_url']) 
                    : null,
                  child: userData!['avatar_url'] == null || userData!['avatar_url'] == "" 
                    ? const Icon(Icons.person, size: 60, color: Colors.green) 
                    : null,
                ),
                const SizedBox(height: 16),
                Text(userData!['nama_lengkap'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text('Level ${userData!['level'] ?? 1} • ${userData!['total_xp'] ?? 0} XP', style: const TextStyle(color: Colors.grey, fontSize: 16)),
                
                const SizedBox(height: 20),
                
                // TOMBOL ADD FRIEND / TEMAN
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SocialScreen(currentUserId: userData!['id'] ?? userData!['_id'])),
                      );
                    },
                    icon: const Icon(Icons.people, color: Colors.white),
                    label: const Text('Teman Saya', style: TextStyle(color: Colors.white, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                    ),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Divider(),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.green),
                  title: const Text('Bio', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(displayBio), // Menggunakan logika pintar di atas
                ),
                ListTile(
                  leading: const Icon(Icons.email_outlined, color: Colors.green),
                  title: const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(userData!['email'] ?? ''),
                ),
              ],
            ),
    );
  }
}
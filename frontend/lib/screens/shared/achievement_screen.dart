// lib/shared/achievement_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});

  @override
  _AchievementScreenState createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
  List<dynamic> allAchievements = [];
  List<dynamic> unlockedIds = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    final achievementsData = await ApiService.getAchievements();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userStr = prefs.getString('user_data');
    
    if (userStr != null) {
      Map<String, dynamic> localUserData = jsonDecode(userStr);
      String userId = localUserData['id'] ?? localUserData['_id'];
      
      final latestUserProfile = await ApiService.getUserProfile(userId);
      if (latestUserProfile != null) {
        unlockedIds = latestUserProfile['unlocked_achievements'] ?? [];
      }
    }

    if (mounted) {
      setState(() {
        allAchievements = achievementsData;
        isLoading = false;
      });
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'star': return Icons.star;
      case 'menu_book': return Icons.menu_book;
      case 'military_tech': return Icons.military_tech;
      case 'bolt': return Icons.bolt;
      case 'group_add': return Icons.group_add;
      default: return Icons.emoji_events;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, 
      appBar: AppBar(
        title: const Text('Achievements', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
        backgroundColor: Colors.orange, 
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/Achievement.jpeg',
              fit: BoxFit.cover, 
            ),
          ),
          
          Positioned.fill(
            child: isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.orange))
              : allAchievements.isEmpty
                ? const Center(child: Text('Admin belum membuat Pencapaian apapun.', style: TextStyle(fontWeight: FontWeight.bold)))
                : GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15,
                    ),
                    itemCount: allAchievements.length,
                    itemBuilder: (context, index) {
                      final item = allAchievements[index];
                      bool isUnlocked = unlockedIds.contains(item['_id']);

                      return GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: Row(
                                children: [
                                  Icon(_getIconData(item['icon']), color: isUnlocked ? Colors.orange : Colors.grey, size: 30),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(item['judul'], style: const TextStyle(fontWeight: FontWeight.bold))),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['deskripsi'], style: const TextStyle(fontSize: 16)),
                                  const SizedBox(height: 15),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                                    child: Text('Syarat: ${item['syarat_tipe']} mencapai ${item['syarat_nilai']}'),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    isUnlocked ? '✅ Status: Terbuka' : '🔒 Status: Terkunci', 
                                    style: TextStyle(fontWeight: FontWeight.bold, color: isUnlocked ? Colors.green : Colors.red)
                                  )
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context), 
                                  child: const Text('Tutup', style: TextStyle(color: Colors.grey))
                                )
                              ],
                            ),
                          );
                        },
                        child: Opacity(
                          opacity: isUnlocked ? 1.0 : 0.4, 
                          child: Card(
                            elevation: isUnlocked ? 6 : 2,
                            color: Colors.white.withOpacity(0.9), 
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: BorderSide(color: isUnlocked ? Colors.orange : Colors.transparent, width: 2)
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_getIconData(item['icon']), size: 50, color: isUnlocked ? Colors.orange : Colors.grey),
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(item['judul'], textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                                if (!isUnlocked) 
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Text('Terkunci', style: TextStyle(fontSize: 12, color: Colors.red)),
                                  ),
                              ],
                            ),
                          ),
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
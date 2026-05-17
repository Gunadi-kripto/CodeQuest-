// lib/screens/user/profile_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'edit_profile_screen.dart';
import 'social_screen.dart';
import '../shared/achievement_screen.dart';
import '../auth/login_screen.dart';
import '../../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  List<dynamic> allAchievements = [];
  List<dynamic> unlockedIds = [];
  bool isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userStr = prefs.getString('user_data');

    if (userStr == null) {
      if (mounted) {
        setState(() => isLoadingData = false);
      }
      return;
    }

    if (mounted) {
      setState(() {
        userData = jsonDecode(userStr);
        isLoadingData = true;
      });
    }

    final String userId =
        (userData?['id'] ?? userData?['_id'] ?? '').toString();

    if (userId.isEmpty) {
      if (mounted) {
        setState(() => isLoadingData = false);
      }
      return;
    }

    try {
      final results = await Future.wait([
        ApiService.getUserProfile(userId),
        ApiService.getAchievements(),
      ]);

      if (!mounted) return;

      setState(() {
        if (results[0] != null) {
          final freshProfile = results[0] as Map<String, dynamic>;

          userData!['total_xp'] = freshProfile['total_xp'] ?? 0;
          userData!['level'] = freshProfile['level'] ?? 1;
          userData!['avatar_url'] = freshProfile['avatar_url'];
          userData!['nama_lengkap'] =
              freshProfile['nama_lengkap'] ?? userData!['nama_lengkap'];
          userData!['bio'] = freshProfile['bio'];
          userData!['email'] = freshProfile['email'] ?? userData!['email'];

          unlockedIds = _normalizeUnlockedAchievements(
            freshProfile['unlocked_achievements'] ??
                freshProfile['achievements'] ??
                [],
          );
        }

        allAchievements = results[1] as List<dynamic>? ?? [];
        isLoadingData = false;
      });
    } catch (e) {
      debugPrint('Load profile error: $e');

      if (mounted) {
        setState(() => isLoadingData = false);
      }
    }
  }

  List<dynamic> _normalizeUnlockedAchievements(dynamic raw) {
    if (raw == null) return [];

    if (raw is! List) return [];

    return raw.map((item) {
      if (item is String) return item;

      if (item is Map) {
        return item['achievement_id']?['_id'] ??
            item['achievement_id'] ??
            item['_id'] ??
            item['id'] ??
            '';
      }

      return item.toString();
    }).where((id) {
      return id.toString().isNotEmpty;
    }).toList();
  }

  bool _isAchievementUnlocked(dynamic achievement) {
    final String achievementId =
        (achievement['_id'] ?? achievement['id'] ?? '').toString();

    return unlockedIds.any((id) => id.toString() == achievementId);
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (confirmContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Konfirmasi Logout',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text('Yakin ingin logout dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmContext),
            child: const Text(
              'Tidak',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(confirmContext);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) => const Center(
                  child: CircularProgressIndicator(color: Colors.green),
                ),
              );

              try {
                await ApiService.logoutUser().timeout(
                  const Duration(seconds: 3),
                );
              } catch (e) {
                debugPrint("Logout server gagal atau timeout: $e");
              } finally {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                if (!mounted) return;

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Ya',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'star':
        return Icons.star;
      case 'menu_book':
        return Icons.menu_book;
      case 'military_tech':
        return Icons.military_tech;
      case 'bolt':
        return Icons.bolt;
      case 'group_add':
        return Icons.group_add;
      default:
        return Icons.emoji_events;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );
    }

    String displayBio = 'Belum ada bio.';
    if (userData!['bio'] != null &&
        userData!['bio'].toString().trim().isNotEmpty) {
      displayBio = userData!['bio'].toString();
    }

    final int currentXp = int.tryParse(
          (userData!['total_xp'] ?? 0).toString(),
        ) ??
        0;

    final int level = int.tryParse(
          (userData!['level'] ?? 1).toString(),
        ) ??
        1;

    final double progress = (currentXp % 100) / 100.0;

    final String avatarUrl = (userData!['avatar_url'] ?? '').toString();
    final String namaLengkap =
        (userData!['nama_lengkap'] ?? 'User').toString();
    final String email = (userData!['email'] ?? '').toString();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox.expand(
        child: Stack(
          children: [
            SizedBox.expand(
              child: Image.asset(
                'assets/coding_bg.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadUserData,
                color: Colors.green,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Profil Saya',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.settings,
                                    color: Colors.black87,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EditProfileScreen(
                                          userData: userData!,
                                        ),
                                      ),
                                    ).then((_) => _loadUserData());
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.logout,
                                    color: Colors.black87,
                                  ),
                                  onPressed: _confirmLogout,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.green[100],
                        backgroundImage:
                            avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.green,
                              )
                            : null,
                      ),

                      const SizedBox(height: 16),

                      Text(
                        namaLengkap,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        'Level $level • $currentXp XP',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Card(
                          elevation: 2,
                          color: Colors.white.withOpacity(0.92),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CodeQuest Progress',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Level $level',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    Text(
                                      '$currentXp XP',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: progress == 0 ? 0.05 : progress,
                                    minHeight: 12,
                                    backgroundColor: Colors.grey[200],
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      Colors.green,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${100 - (currentXp % 100)} XP lagi untuk naik level!',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Card(
                          elevation: 2,
                          color: Colors.white.withOpacity(0.92),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Achievement Badges',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (allAchievements.isNotEmpty)
                                      GestureDetector(
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const AchievementScreen(),
                                          ),
                                        ),
                                        child: const Text(
                                          'Lihat Semua',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                isLoadingData
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.green,
                                        ),
                                      )
                                    : allAchievements.isEmpty
                                        ? const Center(
                                            child: Text(
                                              'Belum ada lencana',
                                              style: TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: allAchievements
                                                .take(4)
                                                .map((item) {
                                              final String iconUrl =
                                                  (item['icon_url'] ??
                                                          item['icon'] ??
                                                          '')
                                                      .toString();

                                              final String title =
                                                  (item['judul'] ??
                                                          'Achievement')
                                                      .toString();

                                              final bool isUnlocked =
                                                  _isAchievementUnlocked(item);

                                              return _buildDynamicBadge(
                                                iconUrl: iconUrl,
                                                fallbackIcon: _getIconData(
                                                  (item['icon'] ??
                                                          'emoji_events')
                                                      .toString(),
                                                ),
                                                label: title,
                                                isUnlocked: isUnlocked,
                                              );
                                            }).toList(),
                                          ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SocialScreen(
                                  currentUserId:
                                      (userData!['id'] ?? userData!['_id'])
                                          .toString(),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.people,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Teman Saya',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AchievementScreen(),
                              ),
                            ).then((_) => _loadUserData());
                          },
                          icon: const Icon(
                            Icons.emoji_events,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Semua Pencapaian',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(
                                  Icons.info_outline,
                                  color: Colors.green,
                                ),
                                title: const Text(
                                  'Bio',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(displayBio),
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(
                                  Icons.email_outlined,
                                  color: Colors.green,
                                ),
                                title: const Text(
                                  'Email',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(email),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicBadge({
    required String iconUrl,
    required IconData fallbackIcon,
    required String label,
    required bool isUnlocked,
  }) {
    final bool hasImage =
        iconUrl.startsWith('http://') || iconUrl.startsWith('https://');

    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: isUnlocked
                ? Colors.orange.withOpacity(0.15)
                : Colors.grey.withOpacity(0.1),
            child: hasImage
                ? ClipOval(
                    child: Image.network(
                      iconUrl,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      color: isUnlocked ? null : Colors.grey.withOpacity(0.6),
                      colorBlendMode:
                          isUnlocked ? null : BlendMode.saturation,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          fallbackIcon,
                          color:
                              isUnlocked ? Colors.orange : Colors.grey[400],
                        );
                      },
                    ),
                  )
                : Icon(
                    fallbackIcon,
                    color: isUnlocked ? Colors.orange : Colors.grey[400],
                  ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isUnlocked ? Colors.black87 : Colors.grey,
              fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
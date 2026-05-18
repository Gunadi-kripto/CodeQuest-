// lib/screens/shared/achievement_screen.dart

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
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final achievementsData = await ApiService.getAchievements();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userStr = prefs.getString('user_data');

      if (userStr != null) {
        Map<String, dynamic> localUserData = jsonDecode(userStr);
        String userId =
            (localUserData['id'] ?? localUserData['_id'] ?? '').toString();

        if (userId.isNotEmpty) {
          final latestUserProfile = await ApiService.getUserProfile(userId);

          if (latestUserProfile != null) {
            unlockedIds = _normalizeUnlockedAchievements(
              latestUserProfile['unlocked_achievements'] ??
                  latestUserProfile['achievements'] ??
                  [],
            );
          }
        }
      }

      if (!mounted) return;

      setState(() {
        allAchievements = achievementsData;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Load achievements error: $e');

      if (!mounted) return;

      setState(() {
        allAchievements = [];
        isLoading = false;
      });
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

  String _getCategoryLabel(String value) {
    switch (value) {
      case 'progress_belajar':
        return 'Progress Belajar';
      case 'quiz_master':
        return 'Quiz Master';
      case 'xp_reward':
        return 'XP Reward';
      case 'baca_materi':
        return 'Baca Materi';
      case 'selesai_kuis':
        return 'Selesai Kuis';
      case 'capai_xp':
        return 'Capai XP';
      default:
        return value.isEmpty ? 'Achievement' : value;
    }
  }

  Color _rarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'rare':
        return Colors.green;
      case 'epic':
        return Colors.purple;
      case 'legendary':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Achievements',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  )
                : allAchievements.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Admin belum membuat Pencapaian apapun.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: Colors.orange,
                        onRefresh: _loadData,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: allAchievements.length,
                          itemBuilder: (context, index) {
                            final item = allAchievements[index];
                            final bool isUnlocked =
                                _isAchievementUnlocked(item);

                            return _buildAchievementCard(item, isUnlocked);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(dynamic item, bool isUnlocked) {
    final String title =
        (item['judul'] ?? item['title'] ?? 'Achievement').toString();

    final String description =
        (item['deskripsi'] ?? item['description'] ?? '').toString();

    final String iconUrl =
        (item['icon_url'] ?? item['icon'] ?? '').toString();

    final String iconName = (item['icon'] ?? 'emoji_events').toString();

    final String syaratTipe =
        (item['syarat_tipe'] ?? item['kategori'] ?? '').toString();

    final String syaratNilai =
        (item['syarat_nilai'] ?? '0').toString();

    final String rarity =
        (item['rarity'] ?? 'Common').toString();

    final int xpReward = int.tryParse(
          (item['xp_reward'] ?? item['xp'] ?? 0).toString(),
        ) ??
        0;

    return GestureDetector(
      onTap: () {
        _showAchievementDetail(
          title: title,
          description: description,
          iconUrl: iconUrl,
          iconName: iconName,
          syaratTipe: syaratTipe,
          syaratNilai: syaratNilai,
          rarity: rarity,
          xpReward: xpReward,
          isUnlocked: isUnlocked,
        );
      },
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.45,
        child: Card(
          elevation: isUnlocked ? 6 : 2,
          color: Colors.white.withOpacity(0.92),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: isUnlocked ? Colors.orange : Colors.transparent,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAchievementImage(
                  iconUrl: iconUrl,
                  iconName: iconName,
                  isUnlocked: isUnlocked,
                  size: 62,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isUnlocked ? Colors.black87 : Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '+$xpReward XP',
                  style: TextStyle(
                    color: isUnlocked ? Colors.orange : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                if (!isUnlocked)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Terkunci',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAchievementDetail({
    required String title,
    required String description,
    required String iconUrl,
    required String iconName,
    required String syaratTipe,
    required String syaratNilai,
    required String rarity,
    required int xpReward,
    required bool isUnlocked,
  }) {
    final Color rarityColor = _rarityColor(rarity);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            _buildAchievementImage(
              iconUrl: iconUrl,
              iconName: iconName,
              isUnlocked: isUnlocked,
              size: 42,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description.isNotEmpty)
              Text(
                description,
                style: const TextStyle(fontSize: 16),
              )
            else
              const Text(
                'Tidak ada deskripsi.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Syarat: ${_getCategoryLabel(syaratTipe)} mencapai $syaratNilai',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: rarityColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    rarity,
                    style: TextStyle(
                      color: rarityColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '+$xpReward XP',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              isUnlocked ? '✅ Status: Terbuka' : '🔒 Status: Terkunci',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isUnlocked ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Tutup',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementImage({
    required String iconUrl,
    required String iconName,
    required bool isUnlocked,
    required double size,
  }) {
    final bool isNetworkImage =
        iconUrl.startsWith('http://') || iconUrl.startsWith('https://');

    if (isNetworkImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 4),
        child: Image.network(
          iconUrl,
          width: size,
          height: size,
          fit: BoxFit.contain,
          color: isUnlocked ? null : Colors.grey.withOpacity(0.65),
          colorBlendMode: isUnlocked ? null : BlendMode.saturation,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              _getIconData(iconName),
              size: size,
              color: isUnlocked ? Colors.orange : Colors.grey,
            );
          },
        ),
      );
    }

    return Icon(
      _getIconData(iconName),
      size: size,
      color: isUnlocked ? Colors.orange : Colors.grey,
    );
  }
}
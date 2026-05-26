// lib/screens/shared/achievement_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';

class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
  List<dynamic> allAchievements = [];
  List<dynamic> unlockedIds = [];

  bool isLoading = true;
  String selectedFilter = 'Semua';

  final List<String> filters = ['Semua', 'Terbuka', 'Terkunci'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // =====================================================
  // LOAD DATA
  // =====================================================

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final achievementsData = await ApiService.getAchievements();

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userStr = prefs.getString('user_data');

      if (userStr != null) {
        final Map<String, dynamic> localUserData = jsonDecode(userStr);
        final String userId =
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

    return raw
        .map((item) {
          if (item is String) return item;

          if (item is Map) {
            return item['achievement_id']?['_id'] ??
                item['achievement_id'] ??
                item['_id'] ??
                item['id'] ??
                '';
          }

          return item.toString();
        })
        .where((id) {
          return id.toString().isNotEmpty;
        })
        .toList();
  }

  bool _isAchievementUnlocked(dynamic achievement) {
    final String achievementId = (achievement['_id'] ?? achievement['id'] ?? '')
        .toString();

    return unlockedIds.any((id) => id.toString() == achievementId);
  }

  List<dynamic> get filteredAchievements {
    if (selectedFilter == 'Terbuka') {
      return allAchievements.where((item) {
        return _isAchievementUnlocked(item);
      }).toList();
    }

    if (selectedFilter == 'Terkunci') {
      return allAchievements.where((item) {
        return !_isAchievementUnlocked(item);
      }).toList();
    }

    return allAchievements;
  }

  int get unlockedCount {
    return allAchievements.where((item) {
      return _isAchievementUnlocked(item);
    }).length;
  }

  int get lockedCount {
    return allAchievements.length - unlockedCount;
  }

  // =====================================================
  // NORMALIZE TEXT
  // =====================================================

  String _getAchievementTitle(dynamic item) {
    final String rawTitle = (item['judul'] ?? item['title'] ?? 'Achievement')
        .toString();

    if (rawTitle.trim() == '111') {
      return 'New Hero';
    }

    return rawTitle;
  }

  String _getAchievementDescription(dynamic item) {
    final String rawTitle = (item['judul'] ?? item['title'] ?? '')
        .toString()
        .trim();

    final String rawDescription =
        (item['deskripsi'] ?? item['description'] ?? '').toString();

    if (rawTitle == '111') {
      return 'Memulai perjalanan baru di CodeQuest';
    }

    if (rawDescription.trim() == '111') {
      return 'Memulai perjalanan baru di CodeQuest';
    }

    return rawDescription;
  }

  String _getRequirementText({
    required String syaratTipe,
    required String syaratNilai,
    required String title,
  }) {
    if (title == 'New Hero') {
      return 'Memulai perjalanan baru';
    }

    switch (syaratTipe) {
      case 'progress_belajar':
        return 'Selesaikan $syaratNilai materi';
      case 'quiz_master':
        return 'Selesaikan $syaratNilai quiz';
      case 'xp_reward':
        return 'Capai $syaratNilai XP';
      case 'baca_materi':
        return 'Baca $syaratNilai materi';
      case 'selesai_kuis':
        return 'Selesaikan $syaratNilai kuis';
      case 'capai_xp':
        return 'Capai $syaratNilai XP';
      default:
        return syaratTipe.isEmpty
            ? 'Selesaikan misi achievement'
            : '${_getCategoryLabel(syaratTipe)} mencapai $syaratNilai';
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

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'star':
        return Icons.star_rounded;
      case 'menu_book':
        return Icons.menu_book_rounded;
      case 'military_tech':
        return Icons.military_tech_rounded;
      case 'bolt':
        return Icons.bolt_rounded;
      case 'group_add':
        return Icons.group_add_rounded;
      default:
        return Icons.emoji_events_rounded;
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
      case 'common':
        return Colors.blueGrey;
      default:
        return Colors.blueGrey;
    }
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final double progress = allAchievements.isEmpty
        ? 0
        : unlockedCount / allAchievements.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6EF),
      appBar: AppBar(
        title: const Text(
          'Achievements',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/Achievement.jpeg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.70)),
          ),
          isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                )
              : allAchievements.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: Colors.orange,
                  onRefresh: _loadData,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProgressCard(progress),
                              const SizedBox(height: 16),
                              _buildFilterChips(),
                              const SizedBox(height: 18),
                              _buildSectionHeader(),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                      if (filteredAchievements.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: _buildFilterEmptyState(),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                  childAspectRatio: 0.64,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final item = filteredAchievements[index];
                              final bool isUnlocked = _isAchievementUnlocked(
                                item,
                              );

                              return _buildAchievementCard(item, isUnlocked);
                            }, childCount: filteredAchievements.length),
                          ),
                        ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(double progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.orange,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Progress Achievement',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$unlockedCount dari ${allAchievements.length} achievement terbuka',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 9,
                    backgroundColor: Colors.orange.withOpacity(0.13),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final String filter = filters[index];
          final bool selected = selectedFilter == filter;

          int count = allAchievements.length;
          if (filter == 'Terbuka') count = unlockedCount;
          if (filter == 'Terkunci') count = lockedCount;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedFilter = filter;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.orange
                    : Colors.white.withOpacity(0.94),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: selected ? Colors.orange : Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(selected ? 0.08 : 0.035),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '$filter ($count)',
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader() {
    String title = 'Semua Achievement';

    if (selectedFilter == 'Terbuka') {
      title = 'Achievement Terbuka';
    } else if (selectedFilter == 'Terkunci') {
      title = 'Achievement Terkunci';
    }

    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 19,
            color: Colors.black87,
          ),
        ),
        const Spacer(),
        Text(
          '${filteredAchievements.length} item',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.94),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 70,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 14),
            const Text(
              'Belum Ada Achievement',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Admin belum membuat pencapaian apa pun.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(
            selectedFilter == 'Terbuka'
                ? Icons.emoji_events_outlined
                : Icons.lock_outline_rounded,
            size: 56,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            selectedFilter == 'Terbuka'
                ? 'Belum ada achievement terbuka.'
                : 'Tidak ada achievement terkunci.',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // CARD
  // =====================================================

  Widget _buildAchievementCard(dynamic item, bool isUnlocked) {
    final String title = _getAchievementTitle(item);
    final String description = _getAchievementDescription(item);

    final String iconUrl = (item['icon_url'] ?? item['icon'] ?? '').toString();
    final String iconName = (item['icon'] ?? 'emoji_events').toString();

    final String syaratTipe = (item['syarat_tipe'] ?? item['kategori'] ?? '')
        .toString();

    final String syaratNilai = (item['syarat_nilai'] ?? '0').toString();

    final String rarity = (item['rarity'] ?? 'Common').toString();

    final int xpReward = _toInt(item['xp_reward'] ?? item['xp'] ?? 0);

    final Color rarityColor = _rarityColor(rarity);
    final Color mainColor = isUnlocked ? rarityColor : Colors.blueGrey;

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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnlocked
              ? Colors.white.withOpacity(0.96)
              : Colors.white.withOpacity(0.90),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isUnlocked
                ? rarityColor.withOpacity(0.55)
                : Colors.blueGrey.withOpacity(0.18),
            width: isUnlocked ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isUnlocked ? 0.075 : 0.035),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (!isUnlocked)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    color: Colors.blueGrey.shade300,
                    size: 17,
                  ),
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: _buildAchievementImage(
                    iconUrl: iconUrl,
                    iconName: iconName,
                    isUnlocked: isUnlocked,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: isUnlocked ? Colors.black87 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  description.isEmpty ? 'Achievement CodeQuest' : description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.25,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: mainColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    isUnlocked ? 'Terbuka • +$xpReward XP' : 'Terkunci',
                    style: TextStyle(
                      color: isUnlocked ? mainColor : Colors.blueGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // DETAIL DIALOG
  // =====================================================

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
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFF8F6EF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: _buildAchievementImage(
                iconUrl: iconUrl,
                iconName: iconName,
                isUnlocked: isUnlocked,
                size: 78,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 21),
            ),
            const SizedBox(height: 8),
            Text(
              description.isEmpty ? 'Tidak ada deskripsi.' : description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.86),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.flag_rounded, color: rarityColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Syarat: ${_getRequirementText(syaratTipe: syaratTipe, syaratNilai: syaratNilai, title: title)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDialogBadge(
                    label: rarity,
                    color: rarityColor,
                    icon: Icons.auto_awesome_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDialogBadge(
                    label: '+$xpReward XP',
                    color: Colors.orange,
                    icon: Icons.bolt_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? Colors.green.withOpacity(0.10)
                    : Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                isUnlocked ? '✅ Status: Terbuka' : '🔒 Status: Terkunci',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: isUnlocked ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Tutup',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogBadge({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // CENTERED ACHIEVEMENT IMAGE
  // =====================================================

  Widget _buildAchievementImage({
    required String iconUrl,
    required String iconName,
    required bool isUnlocked,
    required double size,
  }) {
    final bool isNetworkImage =
        iconUrl.startsWith('http://') || iconUrl.startsWith('https://');

    final Color fallbackColor = isUnlocked ? Colors.orange : Colors.blueGrey;

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.16),
      decoration: BoxDecoration(
        color: fallbackColor.withOpacity(isUnlocked ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(size / 3.8),
      ),
      alignment: Alignment.center,
      child: SizedBox.square(
        dimension: size * 0.68,
        child: Center(
          child: isNetworkImage
              ? Image.network(
                  iconUrl,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  color: isUnlocked ? null : Colors.blueGrey.withOpacity(0.75),
                  colorBlendMode: isUnlocked ? null : BlendMode.saturation,
                  errorBuilder: (context, error, stackTrace) {
                    return FittedBox(
                      fit: BoxFit.contain,
                      child: Icon(_getIconData(iconName), color: fallbackColor),
                    );
                  },
                )
              : FittedBox(
                  fit: BoxFit.contain,
                  child: Icon(_getIconData(iconName), color: fallbackColor),
                ),
        ),
      ),
    );
  }
}

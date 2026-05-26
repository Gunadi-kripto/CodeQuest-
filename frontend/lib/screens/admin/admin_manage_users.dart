import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class AdminManageUsers extends StatefulWidget {
  const AdminManageUsers({super.key});

  @override
  State<AdminManageUsers> createState() => _AdminManageUsersState();
}

class _AdminManageUsersState extends State<AdminManageUsers> {
  List<dynamic> users = [];
  List<dynamic> filteredUsers = [];

  bool isLoading = true;
  bool isStatsLoading = true;

  final TextEditingController _searchController = TextEditingController();

  int totalUsers = 0;
  int totalXP = 0;
  int totalQuiz = 0;
  int totalMateri = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterUsers);
    _loadAllData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterUsers);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadUsers(),
      _loadAdminStats(),
    ]);
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final fetchedUsers = await ApiService.getAllUsers();

      if (!mounted) return;

      setState(() {
        users = fetchedUsers;
        filteredUsers = fetchedUsers;
        isLoading = false;
      });

      _filterUsers();
    } catch (e) {
      debugPrint('ERROR LOAD USERS: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showSnackBar('Gagal mengambil data user.', Colors.red);
    }
  }

  Future<void> _loadAdminStats() async {
    if (!mounted) return;

    setState(() {
      isStatsLoading = true;
    });

    try {
      final stats = await ApiService.getAdminUserStats();

      if (!mounted) return;

      setState(() {
        totalUsers = _toInt(stats['total_users']);
        totalXP = _toInt(stats['total_xp']);
        totalQuiz = _toInt(stats['total_quiz']);
        totalMateri = _toInt(stats['total_materi']);
        isStatsLoading = false;
      });
    } catch (e) {
      debugPrint('ERROR LOAD ADMIN STATS: $e');

      if (!mounted) return;

      setState(() {
        isStatsLoading = false;
      });
    }
  }

  void _filterUsers() {
    final keyword = _searchController.text.toLowerCase().trim();

    if (!mounted) return;

    setState(() {
      if (keyword.isEmpty) {
        filteredUsers = users;
      } else {
        filteredUsers = users.where((user) {
          final name = (user['nama_lengkap'] ?? '').toString().toLowerCase();
          final email = (user['email'] ?? '').toString().toLowerCase();
          final role = (user['role'] ?? '').toString().toLowerCase();

          return name.contains(keyword) ||
              email.contains(keyword) ||
              role.contains(keyword);
        }).toList();
      }
    });
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  String _getUserId(Map<String, dynamic> user) {
    return (user['_id'] ?? user['id'] ?? '').toString();
  }

  String formatNumber(dynamic number) {
    return NumberFormat.decimalPattern('id').format(_toInt(number));
  }

  void _confirmDeleteUser(String userId, String userName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          'Hapus Paksa?',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Apakah kamu yakin ingin menghapus akun "$userName" selamanya?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Batal',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);

              if (!mounted) return;

              setState(() {
                isLoading = true;
              });

              final success = await ApiService.adminDeleteUser(userId);

              if (!mounted) return;

              if (success) {
                _showSnackBar(
                  'Akun $userName berhasil dihapus.',
                  Colors.green,
                );

                await _loadAllData();
              } else {
                setState(() {
                  isLoading = false;
                });

                _showSnackBar(
                  'Gagal menghapus akun.',
                  Colors.red,
                );
              }
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _showUserMaterials(Map<String, dynamic> user) async {
    final userId = _getUserId(user);
    final userName = (user['nama_lengkap'] ?? 'User').toString();

    await _showProgressBottomSheet(
      title: 'Materi Selesai',
      subtitle: userName,
      icon: Icons.menu_book_rounded,
      color: Colors.blue,
      future: ApiService.getAdminUserMaterials(userId),
      emptyText: 'User ini belum menyelesaikan materi.',
      itemBuilder: (item) {
        final module = item['module_id'];

        String title = 'Materi tidak ditemukan';
        String description = '';
        String language = '';

        if (module is Map) {
          title = (module['judul_modul'] ?? 'Tanpa Judul').toString();
          description = (module['deskripsi'] ?? '').toString();

          final lang = module['id_bahasa'];
          if (lang is Map) {
            language = (lang['nama_bahasa'] ?? '').toString();
          }
        }

        return _buildDetailTile(
          icon: Icons.menu_book_rounded,
          color: Colors.blue,
          title: title,
          subtitle: language.isEmpty ? description : '$language • $description',
          trailing: _formatDate(item['tanggal_selesai']),
        );
      },
    );
  }

  Future<void> _showUserQuizzes(Map<String, dynamic> user) async {
    final userId = _getUserId(user);
    final userName = (user['nama_lengkap'] ?? 'User').toString();

    await _showProgressBottomSheet(
      title: 'Kuis Dikerjakan',
      subtitle: userName,
      icon: Icons.quiz_rounded,
      color: Colors.orange,
      future: ApiService.getAdminUserQuizzes(userId),
      emptyText: 'User ini belum mengerjakan kuis.',
      itemBuilder: (item) {
        final module = item['module_id'];
        final quiz = item['quiz_id'];

        String moduleTitle = 'Kuis';
        String quizInfo = 'Skor: ${_toInt(item['skor'])}';

        if (module is Map) {
          moduleTitle = (module['judul_modul'] ?? 'Materi').toString();
        } else if (quiz is Map && quiz['module_id'] is Map) {
          moduleTitle =
              (quiz['module_id']['judul_modul'] ?? 'Materi').toString();
        }

        return _buildDetailTile(
          icon: Icons.quiz_rounded,
          color: Colors.orange,
          title: moduleTitle,
          subtitle: quizInfo,
          trailing: _formatDate(item['tanggal_selesai']),
        );
      },
    );
  }

  Future<void> _showUserAchievements(Map<String, dynamic> user) async {
    final userId = _getUserId(user);
    final userName = (user['nama_lengkap'] ?? 'User').toString();

    await _showProgressBottomSheet(
      title: 'Achievement',
      subtitle: userName,
      icon: Icons.emoji_events_rounded,
      color: Colors.amber,
      future: ApiService.getAdminUserAchievements(userId),
      emptyText: 'User ini belum punya achievement.',
      itemBuilder: (item) {
        final title = (item['judul'] ?? 'Achievement').toString();
        final description = (item['deskripsi'] ?? '').toString();
        final xpReward = _toInt(item['xp_reward']);
        final rarity = (item['rarity'] ?? '').toString();

        return _buildDetailTile(
          icon: Icons.emoji_events_rounded,
          color: Colors.amber,
          title: title,
          subtitle: description,
          trailing: rarity.isEmpty ? '+$xpReward XP' : '$rarity • +$xpReward XP',
        );
      },
    );
  }

  Future<void> _showProgressBottomSheet({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Future<List<dynamic>> future,
    required String emptyText,
    required Widget Function(dynamic item) itemBuilder,
  }) async {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: FutureBuilder<List<dynamic>>(
                future: future,
                builder: (context, snapshot) {
                  final loading =
                      snapshot.connectionState == ConnectionState.waiting;
                  final data = snapshot.data ?? [];

                  return Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(icon, color: color),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  Text(
                                    subtitle,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  Navigator.pop(bottomSheetContext),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: loading
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: color,
                                ),
                              )
                            : data.isEmpty
                                ? ListView(
                                    controller: scrollController,
                                    padding: const EdgeInsets.all(24),
                                    children: [
                                      const SizedBox(height: 80),
                                      Icon(
                                        icon,
                                        color: Colors.grey.shade300,
                                        size: 70,
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        emptyText,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView.builder(
                                    controller: scrollController,
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      5,
                                      20,
                                      24,
                                    ),
                                    itemCount: data.length,
                                    itemBuilder: (context, index) {
                                      return itemBuilder(data[index]);
                                    },
                                  ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            trailing,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';

    try {
      final date = DateTime.parse(value.toString()).toLocal();
      return DateFormat('dd MMM yyyy', 'id').format(date);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Fix agar background terekspos
      body: Stack(
        children: [
          // Background Universal
          SizedBox.expand(
            child: Image.asset(
              'assets/coding_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.green),
                )
              : SafeArea(
                  child: RefreshIndicator(
                    onRefresh: _loadAllData,
                    color: Colors.green,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Users',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const Text(
                            'Kelola semua pengguna aplikasi',
                            style: TextStyle(color: Colors.black54, fontSize: 14),
                          ),
                          const SizedBox(height: 25),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.4,
                            children: [
                              _buildSummaryCard(
                                'Total Users',
                                isStatsLoading ? '...' : formatNumber(totalUsers),
                                Icons.people_outline,
                                Colors.green,
                              ),
                              _buildSummaryCard(
                                'Total XP',
                                isStatsLoading ? '...' : formatNumber(totalXP),
                                Icons.stars_outlined,
                                Colors.purple,
                              ),
                              _buildSummaryCard(
                                'Kuis Dikerjakan',
                                isStatsLoading ? '...' : formatNumber(totalQuiz),
                                Icons.quiz_outlined,
                                Colors.orange,
                              ),
                              _buildSummaryCard(
                                'Materi Selesai',
                                isStatsLoading ? '...' : formatNumber(totalMateri),
                                Icons.menu_book_outlined,
                                Colors.blue,
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),
                          _buildSearchBar(),
                          const SizedBox(height: 20),
                          if (filteredUsers.isEmpty)
                            _buildEmptySearch()
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredUsers.length,
                              itemBuilder: (context, index) {
                                return _buildUserCard(
                                  Map<String, dynamic>.from(filteredUsers[index]),
                                );
                              },
                            ),
                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92), // Glassmorphism Transparan
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Cari pengguna berdasarkan nama',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildEmptySearch() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92), // Glassmorphism Transparan
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off_rounded, color: Colors.grey, size: 48),
          SizedBox(height: 12),
          Text(
            'Pengguna tidak ditemukan',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92), // Glassmorphism Transparan
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final bool isAdmin = user['role'] == 'admin';
    final List<dynamic> badges = user['unlocked_achievements'] is List
        ? user['unlocked_achievements']
        : [];

    final int totalXp = _toInt(user['total_xp']);
    final int level = _toInt(user['level']) == 0 ? 1 : _toInt(user['level']);
    final int userTotalMateri = _toInt(user['total_materi_dibaca']);
    final int userTotalQuiz = _toInt(user['total_kuis_selesai']);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92), // Glassmorphism Transparan
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.green.shade50,
                backgroundImage:
                    user['avatar_url'] != null && user['avatar_url'] != ''
                        ? NetworkImage(user['avatar_url'])
                        : null,
                child: user['avatar_url'] == null || user['avatar_url'] == ''
                    ? Text(
                        (user['nama_lengkap'] ?? 'U')
                            .toString()
                            .trim()
                            .characters
                            .first
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['nama_lengkap'] ?? 'No Name',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      user['email'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Level $level',
                      style: const TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'ADMIN',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ]
                ],
              ),
              const SizedBox(width: 8),
              if (!isAdmin)
                IconButton(
                  onPressed: () => _confirmDeleteUser(
                    _getUserId(user),
                    user['nama_lengkap'] ?? 'User',
                  ),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 22,
                  ),
                ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1F1F1)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildClickableSmallStat(
                icon: Icons.stars,
                label: '${formatNumber(totalXp)} XP',
                color: Colors.green,
                onTap: null,
              ),
              _buildClickableSmallStat(
                icon: Icons.menu_book,
                label: '$userTotalMateri Materi',
                color: Colors.blue,
                onTap: () => _showUserMaterials(user),
              ),
              _buildClickableSmallStat(
                icon: Icons.quiz_rounded,
                label: '$userTotalQuiz Kuis',
                color: Colors.orange,
                onTap: () => _showUserQuizzes(user),
              ),
              InkWell(
                onTap: () => _showUserAchievements(user),
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    if (badges.isEmpty)
                      const Icon(
                        Icons.emoji_events_outlined,
                        color: Colors.grey,
                        size: 16,
                      )
                    else
                      ...badges.take(3).map(
                            (_) => const Padding(
                              padding: EdgeInsets.only(left: 3),
                              child: Icon(
                                Icons.verified,
                                color: Colors.amber,
                                size: 16,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildClickableSmallStat({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final child = Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
      ],
    );

    if (onTap == null) return child;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
        child: child,
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }
}
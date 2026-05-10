import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Pastikan sudah tambah 'intl' di pubspec.yaml
import '../../services/api_service.dart';

class AdminManageUsers extends StatefulWidget {
  const AdminManageUsers({super.key});

  @override
  _AdminManageUsersState createState() => _AdminManageUsersState();
}

class _AdminManageUsersState extends State<AdminManageUsers> {
  List<dynamic> users = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // Variabel Statistik Summary
  int totalUsers = 0;
  int totalXP = 0;
  int totalQuiz = 0;
  int totalMateri = 0;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    
    try {
      final fetchedUsers = await ApiService.getAllUsers();
      if (mounted) {
        setState(() {
          users = fetchedUsers;
          
          // HITUNG STATISTIK REAL-TIME
          totalUsers = users.length;
          totalXP = users.fold(0, (sum, item) => sum + (item['total_xp'] as int? ?? 0));
          totalQuiz = users.fold(0, (sum, item) => sum + (item['quizzes_done'] as int? ?? 0));
          // Menghitung materi yang selesai (berdasarkan panjang array completed_materials)
          totalMateri = users.fold(0, (sum, item) {
            final completed = item['completed_materials'] as List?;
            return sum + (completed?.length ?? 0);
          });
          
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      debugPrint("Error load users: $e");
    }
  }

  String formatNumber(int number) {
    return NumberFormat.decimalPattern('id').format(number);
  }

  void _confirmDeleteUser(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Hapus Paksa?', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text('Apakah kamu yakin ingin menghapus akun "$userName" selamanya?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => isLoading = true);
              bool success = await ApiService.adminDeleteUser(userId);
              if (success) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Akun $userName berhasil dihapus.'), backgroundColor: Colors.green)
                  );
                }
                _loadUsers();
              } else {
                if (mounted) {
                  setState(() => isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal menghapus akun.'), backgroundColor: Colors.red)
                  );
                }
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold di sini tidak menggunakan AppBar lagi agar tidak bertumpuk
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : RefreshIndicator(
              onRefresh: _loadUsers,
              color: Colors.green,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // JUDUL HALAMAN (Sesuai Gambar 2)
                    const Text('Users', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const Text('Kelola semua pengguna aplikasi', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 25),

                    // --- SECTION 1: SUMMARY STATS GRID ---
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        _buildSummaryCard('Total Users', formatNumber(totalUsers), Icons.people_outline, Colors.green),
                        _buildSummaryCard('Total XP', formatNumber(totalXP), Icons.stars_outlined, Colors.purple),
                        _buildSummaryCard('Kuis Dikerjakan', formatNumber(totalQuiz), Icons.emoji_events_outlined, Colors.orange),
                        _buildSummaryCard('Materi Selesai', formatNumber(totalMateri), Icons.menu_book_outlined, Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // --- SECTION 2: SEARCH BAR ---
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Cari pengguna...',
                                prefixIcon: Icon(Icons.search, color: Colors.grey),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 15),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: DropdownButton<String>(
                            value: 'Semua Level',
                            underline: const SizedBox(),
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.green),
                            items: ['Semua Level'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value, 
                                child: Text(value, style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold))
                              );
                            }).toList(),
                            onChanged: (_) {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // --- SECTION 3: USER LIST ---
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        return _buildUserCard(users[index]);
                      },
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(18), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final bool isAdmin = user['role'] == 'admin';
    final List<dynamic> badges = user['unlocked_achievements'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.green.shade50,
                backgroundImage: user['avatar_url'] != null && user['avatar_url'] != "" ? NetworkImage(user['avatar_url']) : null,
                child: user['avatar_url'] == null || user['avatar_url'] == "" ? const Icon(Icons.person, color: Colors.green) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['nama_lengkap'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(user['email'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.deepPurple.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Text('Level ${user['level'] ?? 1}', style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                      child: const Text('ADMIN', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 9)),
                    ),
                  ]
                ],
              ),
              const SizedBox(width: 8),
              if (!isAdmin) 
                IconButton(
                  onPressed: () => _confirmDeleteUser(user['_id'], user['nama_lengkap']),
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFF1F1F1))),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSmallStat(Icons.stars, '${formatNumber(user['total_xp'] ?? 0)} XP', Colors.green),
              _buildSmallStat(Icons.menu_book, '${(user['completed_materials'] as List?)?.length ?? 0} Materi', Colors.blue),
              _buildSmallStat(Icons.emoji_events, '${user['quizzes_done'] ?? 0} Kuis', Colors.orange),
              Row(
                children: badges.take(3).map((b) => const Padding(
                  padding: EdgeInsets.only(left: 3),
                  child: Icon(Icons.verified, color: Colors.amber, size: 16),
                )).toList(),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSmallStat(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
      ],
    );
  }
}
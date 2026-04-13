import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminManageUsers extends StatefulWidget {
  const AdminManageUsers({super.key});

  @override
  _AdminManageUsersState createState() => _AdminManageUsersState();
}

class _AdminManageUsersState extends State<AdminManageUsers> {
  List<dynamic> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => isLoading = true);
    final fetchedUsers = await ApiService.getAllUsers();
    if (mounted) {
      setState(() {
        users = fetchedUsers;
        isLoading = false;
      });
    }
  }

  void _confirmDeleteUser(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Paksa?', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text('Apakah kamu yakin ingin menghapus akun "$userName" beserta seluruh datanya?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog
              setState(() => isLoading = true); // Tampilkan loading
              
              bool success = await ApiService.deleteAccount(userId);
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Akun $userName berhasil dihapus.'), backgroundColor: Colors.green));
                _loadUsers(); // Refresh daftar user
              } else {
                setState(() => isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menghapus akun.'), backgroundColor: Colors.red));
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      // Tidak perlu AppBar karena akan masuk ke dalam tab AdminMainScreen
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : RefreshIndicator(
              onRefresh: _loadUsers,
              color: Colors.green,
              child: users.isEmpty
                  ? const Center(child: Text('Belum ada pengguna.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final bool isAdmin = user['role'] == 'admin';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isAdmin ? Colors.blueGrey : Colors.green[100],
                              backgroundImage: user['avatar_url'] != null && user['avatar_url'] != "" ? NetworkImage(user['avatar_url']) : null,
                              child: user['avatar_url'] == null || user['avatar_url'] == "" ? Icon(isAdmin ? Icons.admin_panel_settings : Icons.person, color: isAdmin ? Colors.white : Colors.green) : null,
                            ),
                            title: Text(user['nama_lengkap'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${user['email']}\nLevel ${user['level'] ?? 1} • ${user['total_xp'] ?? 0} XP'),
                            isThreeLine: true,
                            trailing: isAdmin
                                ? const Chip(label: Text('ADMIN', style: TextStyle(color: Colors.white, fontSize: 10)), backgroundColor: Colors.blueGrey)
                                : IconButton(
                                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                                    onPressed: () => _confirmDeleteUser(user['_id'], user['nama_lengkap']),
                                  ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
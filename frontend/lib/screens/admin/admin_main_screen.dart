import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import 'admin_manage_users.dart';
import 'admin_language_screen.dart'; // Ini tetap ada jika kamu butuh halaman tambah bahasa
import 'admin_manage_kuis.dart';
import 'admin_manage_achievements.dart';
import 'admin_manage_materi.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 1; // Default ke tab Materi (Grid Bahasa)
  List<dynamic> languages = [];
  bool isLoadingLang = true;

  @override
  void initState() {
    super.initState();
    _loadLanguages();
  }

  Future<void> _loadLanguages() async {
    setState(() => isLoadingLang = true);
    try {
      final data = await ApiService.getLanguages();
      setState(() {
        languages = data;
        isLoadingLang = false;
      });
    } catch (e) {
      setState(() => isLoadingLang = false);
    }
  }

  void _confirmDeleteLanguage(String id, String nama) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Bahasa?", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text("Yakin ingin menghapus bahasa '$nama'? Ini akan membersihkan ikon yang nyangkut di dashboard."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              bool success = await ApiService.deleteLanguage(id);
              if (success) {
                Navigator.pop(context);
                _loadLanguages();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Bahasa berhasil dihapus!"), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) _loadLanguages(); // Refresh data bahasa saat masuk tab materi
  }

  void _logout() async {
    await ApiService.logoutUser();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (context) => const LoginScreen()), 
        (route) => false
      );
    }
  }

  // Widget khusus untuk menampilkan Grid Bahasa di Tab Materi
  Widget _buildLanguageGrid() {
    if (isLoadingLang) return const Center(child: CircularProgressIndicator(color: Colors.green));
    if (languages.isEmpty) return const Center(child: Text("Belum ada bahasa."));

    return RefreshIndicator(
      onRefresh: _loadLanguages,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.9,
        ),
        itemCount: languages.length,
        itemBuilder: (context, index) {
          final lang = languages[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminManageMateri(
                    languageId: lang['_id'],
                    languageName: lang['nama_bahasa'],
                  ),
                ),
              ).then((_) => _loadLanguages());
            },
            onLongPress: () => _confirmDeleteLanguage(lang['_id'], lang['nama_bahasa']),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (lang['icon_url'] != null)
                    Image.network(lang['icon_url'], height: 50, width: 50, errorBuilder: (c, e, s) => const Icon(Icons.code, size: 40))
                  else
                    const Icon(Icons.language, size: 40, color: Colors.green),
                  const SizedBox(height: 10),
                  Text(lang['nama_bahasa'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Text("Tahan untuk hapus", style: TextStyle(fontSize: 9, color: Colors.grey)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // List layar berdasarkan index
    final List<Widget> widgetOptions = [
      const AdminManageUsers(),
      _buildLanguageGrid(), // Ganti halaman AdminLanguageScreen lama dengan Grid ini
      const AdminManageKuis(),
      const AdminManageAchievements(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portal Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        actions: [
          if (_selectedIndex == 1) // Tombol tambah bahasa hanya muncul di tab materi
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.white),
              onPressed: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const AdminLanguageScreen())
              ).then((_) => _loadLanguages()),
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white), 
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Materi'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Kuis'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Piala'), 
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green, 
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
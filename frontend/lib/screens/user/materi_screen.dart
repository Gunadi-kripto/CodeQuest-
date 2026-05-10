import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';
import 'materi_detail_screen.dart';

class MateriScreen extends StatefulWidget {
  const MateriScreen({super.key});

  @override
  State<MateriScreen> createState() => _MateriScreenState();
}

class _MateriScreenState extends State<MateriScreen> {
  List<dynamic> languages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLanguages();
  }

  Future<void> _loadLanguages() async {
    final fetchedLanguages = await ApiService.getLanguages();
    if (mounted) {
      setState(() {
        languages = fetchedLanguages;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── BACKGROUND DARI GUNADI ──
          SizedBox.expand(
            child: Image.asset(
              'assets/coding_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // ── KONTEN UI KEREN KAMU ──
          SafeArea(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : RefreshIndicator(
                    onRefresh: _loadLanguages,
                    color: Colors.green,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          // Header Gambar (Punya Kamu)
                          Image.asset(
                            'assets/Software Engineer.jpg',
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Pilih Bahasa\nPemrograman',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Grid Bahasa Dinamis
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: languages.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 15,
                              mainAxisSpacing: 15,
                              childAspectRatio: 0.9,
                            ),
                            itemBuilder: (context, index) {
                              final lang = languages[index];
                              return _buildLanguageCard(lang);
                            },
                          ),

                          const SizedBox(height: 25),

                          // Streak Box (Punya Kamu)
                          _buildStreakBox(),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard(dynamic lang) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentModuleListScreen(
              languageId: lang['_id'],
              languageName: lang['nama_bahasa'],
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 65,
              height: 65,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: CachedNetworkImage(
                imageUrl: lang['icon_url'] ?? '',
                fit: BoxFit.contain,
                placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
                errorWidget: (context, url, error) => const Icon(Icons.code, size: 30, color: Colors.green),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              lang['nama_bahasa'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakBox() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8EA).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: Colors.green, size: 35),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bangun Streak Belajarmu!',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Dapatkan lebih banyak XP setiap hari!',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── DAFTAR MODUL (Style Container Keren) ──

class StudentModuleListScreen extends StatefulWidget {
  final String languageId;
  final String languageName;
  const StudentModuleListScreen({super.key, required this.languageId, required this.languageName});

  @override
  State<StudentModuleListScreen> createState() => _StudentModuleListScreenState();
}

class _StudentModuleListScreenState extends State<StudentModuleListScreen> {
  List<dynamic> modules = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  Future<void> _loadModules() async {
    final data = await ApiService.getModulesByLanguage(widget.languageId);
    if (mounted) {
      setState(() {
        modules = data;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Text('Materi ${widget.languageName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: modules.length,
              itemBuilder: (context, index) {
                final mod = modules[index];
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MateriDetailScreen(module: mod))),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.green.withValues(alpha: 0.1),
                          child: Text('${index + 1}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(mod['judul_modul'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(mod['deskripsi'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.green),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
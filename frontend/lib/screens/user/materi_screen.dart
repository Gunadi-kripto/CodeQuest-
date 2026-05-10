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

          // ── UI PILIH BAHASA (GAYA DELVIN) ──
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
                          const SizedBox(height: 25),

                          // Grid Bahasa Dinamis
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: languages.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 18,
                              mainAxisSpacing: 18,
                              childAspectRatio: 0.9,
                            ),
                            itemBuilder: (context, index) {
                              final lang = languages[index];
                              return _buildLanguageCard(lang);
                            },
                          ),
                          const SizedBox(height: 30),
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
              iconUrl: lang['icon_url'] ?? '',
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CachedNetworkImage(
              imageUrl: lang['icon_url'] ?? '',
              height: 70,
              placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
              errorWidget: (context, url, error) => const Icon(Icons.code, size: 40),
            ),
            const SizedBox(height: 12),
            Text(
              lang['nama_bahasa'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
        color: const Color(0xFFEAF8EA).withOpacity(0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: Colors.green, size: 35),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bangun Streak Belajarmu!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Dapatkan XP lebih banyak hari ini!', style: TextStyle(color: Colors.black54, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── STUDENT MODULE LIST SCREEN (MIRIP GAMBAR 3) ──

class StudentModuleListScreen extends StatefulWidget {
  final String languageId;
  final String languageName;
  final String iconUrl;
  const StudentModuleListScreen({super.key, required this.languageId, required this.languageName, required this.iconUrl});

  @override
  State<StudentModuleListScreen> createState() => _StudentModuleListScreenState();
}

class _StudentModuleListScreenState extends State<StudentModuleListScreen> {
  List<dynamic> modules = [];
  bool isLoading = true;
  int completedCount = 0;

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
        // Simulasi: Tandai 2 materi awal sebagai selesai agar mirip Gambar 3
        completedCount = modules.length > 2 ? 2 : modules.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.languageName, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  CachedNetworkImage(
                    imageUrl: widget.iconUrl,
                    height: 80,
                    errorWidget: (context, url, error) => const Icon(Icons.code, size: 80, color: Colors.blue),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Belajar ${widget.languageName} dari dasar hingga\nbisa membuat program sendiri!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 25),
                  
                  // STATS CARDS
                  Row(
                    children: [
                      _buildStatCard('Progress Kamu', '$completedCount/${modules.length} Materi', true, 
                          modules.isNotEmpty ? completedCount / modules.length : 0),
                      const SizedBox(width: 15),
                      _buildStatCard('XP Didapat', '1200 XP', false, 0),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Materi Dasar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
                  const SizedBox(height: 15),

                  // MODULE LIST (Design ala Gambar 3)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: modules.length,
                    itemBuilder: (context, index) {
                      final mod = modules[index];
                      bool isDone = index < completedCount;
                      bool isLocked = index > completedCount;

                      return _buildModuleItem(index + 1, mod, isDone, isLocked);
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, bool showProgress, double progress) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                if (!showProgress) const Icon(Icons.stars, color: Colors.orange, size: 18),
              ],
            ),
            if (showProgress) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  minHeight: 6,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildModuleItem(int number, dynamic mod, bool isDone, bool isLocked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFF1F9F1) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDone ? Colors.green.withOpacity(0.3) : Colors.transparent),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDone ? Colors.green : (isLocked ? Colors.grey[300] : Colors.black87),
          radius: 14,
          child: Text('$number', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        title: Text(mod['judul_modul'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(mod['deskripsi'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
        trailing: Icon(
          isDone ? Icons.check_circle : (isLocked ? Icons.lock : Icons.arrow_forward_ios),
          color: isDone ? Colors.green : Colors.grey[400],
          size: 20,
        ),
        onTap: isLocked ? null : () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => MateriDetailScreen(module: mod)));
        },
      ),
    );
  }
}
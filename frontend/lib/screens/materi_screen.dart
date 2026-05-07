import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'materi_detail_screen.dart';

class MateriScreen extends StatefulWidget {
  const MateriScreen({super.key});

  @override
  State<MateriScreen> createState() => _MateriScreenState();
}

class _MateriScreenState extends State<MateriScreen> {
  List<dynamic> modules = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  Future<void> _loadModules() async {
    final fetchedModules = await ApiService.getModules();

    if (mounted) {
      setState(() {
        modules = fetchedModules;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,

        title: const Text(
          'Pilih Bahasa',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),

              child: Column(
                children: [
                  // ================= IMAGE HEADER =================
                  Image.asset(
                    'assets/Software Engineer.jpg',
                    height: 210,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Pilih Bahasa\nPemrograman',
                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Setiap bahasa memiliki jalur belajar\nyang berbeda',
                    textAlign: TextAlign.center,

                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),

                  const SizedBox(height: 30),

                  // ================= GRID =================
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),

                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 18,
                          mainAxisSpacing: 18,
                          childAspectRatio: 0.88,
                        ),

                    children: [
                      _buildLanguageCard(
                        context,
                        'Python',
                        'assets/python.png',
                        Colors.green,
                      ),

                      _buildLanguageCard(
                        context,
                        'Java',
                        'assets/java.png',
                        Colors.grey.shade300,
                      ),

                      _buildLanguageCard(
                        context,
                        'C++',
                        'assets/cpp.png',
                        Colors.grey.shade300,
                      ),

                      _buildLanguageCard(
                        context,
                        'HTML',
                        'assets/html.png',
                        Colors.grey.shade300,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ================= STREAK BOX =================
                  Container(
                    padding: const EdgeInsets.all(18),

                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF8EA),

                      borderRadius: BorderRadius.circular(22),
                    ),

                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,

                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),

                          child: const Icon(
                            Icons.local_fire_department,
                            color: Colors.green,
                            size: 30,
                          ),
                        ),

                        const SizedBox(width: 16),

                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Text(
                                'Bangun Streak Belajarmu!',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),

                              SizedBox(height: 4),

                              Text(
                                'Belajar setiap hari untuk\nmendapatkan XP lebih banyak!',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  // ================= CARD =================

  Widget _buildLanguageCard(
    BuildContext context,
    String language,
    String imagePath,
    Color borderColor,
  ) {
    final filteredModules = modules.where((m) {
      return (m['bahasa'] ?? '').toString().toLowerCase() ==
          language.toLowerCase();
    }).toList();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LanguageDetailScreen(
              language: language,
              modules: filteredModules,
            ),
          ),
        );
      },

      child: Container(
        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(24),

          border: Border.all(color: borderColor, width: 2),

          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Image.asset(imagePath, height: 70),

            const SizedBox(height: 16),

            Text(
              language,

              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),

            const SizedBox(height: 6),

            Text(
              '${filteredModules.length} Materi',

              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= DETAIL SCREEN =================

class LanguageDetailScreen extends StatelessWidget {
  final String language;
  final List<dynamic> modules;

  const LanguageDetailScreen({
    super.key,
    required this.language,
    required this.modules,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        iconTheme: const IconThemeData(color: Colors.black),

        title: Text(
          language,

          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: modules.isEmpty
          ? const Center(child: Text('Belum ada materi.'))
          : ListView.builder(
              padding: const EdgeInsets.all(20),

              itemCount: modules.length,

              itemBuilder: (context, index) {
                final mod = modules[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MateriDetailScreen(module: mod),
                      ),
                    );
                  },

                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(18),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.circular(22),

                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 5),
                      ],
                    ),

                    child: Row(
                      children: [
                        Container(
                          width: 55,
                          height: 55,

                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),

                            borderRadius: BorderRadius.circular(16),
                          ),

                          child: const Icon(
                            Icons.menu_book,
                            color: Colors.green,
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Text(
                                mod['judul_modul']?.toString() ?? 'Tanpa Judul',

                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                mod['deskripsi']?.toString() ?? '',

                                maxLines: 2,

                                overflow: TextOverflow.ellipsis,

                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),

                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

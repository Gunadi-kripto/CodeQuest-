import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
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
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.9,
              ),
              itemCount: languages.length,
              itemBuilder: (context, index) {
                final lang = languages[index];
                return InkWell(
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CachedNetworkImage(
                          imageUrl: lang['icon_url'] ?? '',
                          height: 60,
                          placeholder: (context, url) => const CircularProgressIndicator(),
                          errorWidget: (context, url, error) => const Icon(Icons.code, size: 40),
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
              },
            ),
    );
  }
}

// Widget baru untuk menampilkan daftar bab setelah pilih bahasa
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
      appBar: AppBar(title: Text('Materi ${widget.languageName}')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: modules.length,
              itemBuilder: (context, index) {
                final mod = modules[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(mod['judul_modul']),
                    subtitle: Text(mod['deskripsi'], maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MateriDetailScreen(module: mod)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
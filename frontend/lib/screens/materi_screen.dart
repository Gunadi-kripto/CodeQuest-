import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'materi_detail_screen.dart'; // Import file pembaca materi

class MateriScreen extends StatefulWidget {
  const MateriScreen({super.key});

  @override
  _MateriScreenState createState() => _MateriScreenState();
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Daftar Materi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false, // Menghilangkan tombol back karena ini adalah Tab Utama
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : modules.isEmpty
              ? const Center(child: Text('Materi belum tersedia.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: modules.length,
                  itemBuilder: (context, index) {
                    final mod = modules[index];
                    // Simulasi status dibaca (Gelap/Terang) - Nanti disambung ke backend UserProgress
                    bool isRead = false; 

                    return Card(
                      elevation: isRead ? 0 : 2, // Kalau sudah dibaca, bayangannya hilang
                      color: isRead ? Colors.grey[300] : Colors.white, // Kalau sudah dibaca jadi agak gelap
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: isRead ? Colors.grey[400] : Colors.green.withOpacity(0.2),
                          child: Icon(isRead ? Icons.check : Icons.menu_book, 
                            color: isRead ? Colors.white : Colors.green),
                        ),
                        title: Text(
                          mod['judul_modul']?.toString() ?? 'Tanpa Judul', 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isRead ? Colors.grey[600] : Colors.black)
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            mod['deskripsi']?.toString() ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: isRead ? Colors.grey[600] : Colors.grey[800]),
                          ),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, color: isRead ? Colors.grey : Colors.green),
                        onTap: () {
                          // Pindah ke layar baca detail
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MateriDetailScreen(module: mod)),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
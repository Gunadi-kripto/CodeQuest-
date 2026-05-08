import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';

class AdminManageMateri extends StatefulWidget {
  final String languageId;
  final String languageName;

  const AdminManageMateri({
    super.key, 
    required this.languageId, 
    required this.languageName
  });

  @override
  State<AdminManageMateri> createState() => _AdminManageMateriState();
}

class _AdminManageMateriState extends State<AdminManageMateri> {
  List<dynamic> modules = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchModules();
  }

  // Mengambil daftar modul/materi berdasarkan ID Bahasa
  Future<void> _fetchModules() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.getModulesByLanguage(widget.languageId);
      if (mounted) {
        setState(() {
          modules = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      print("Error fetching modules: $e");
    }
  }

  // Dialog Form Tambah Materi
  void _showAddModuleForm() {
    final TextEditingController judulController = TextEditingController();
    final TextEditingController deskripsiController = TextEditingController();
    final TextEditingController textContentController = TextEditingController();
    
    String selectedType = 'text'; // Default tipe adalah teks
    File? selectedImage;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25))
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24, right: 24, top: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tambah Bab: ${widget.languageName}', 
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: judulController, 
                    decoration: const InputDecoration(
                      labelText: 'Judul Modul (Contoh: Variabel)', 
                      border: OutlineInputBorder()
                    )
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: deskripsiController, 
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi Singkat', 
                      border: OutlineInputBorder()
                    )
                  ),
                  const SizedBox(height: 20),
                  
                  const Text('Jenis Konten Pertama:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Radio(
                        value: 'text', 
                        groupValue: selectedType, 
                        onChanged: (val) => setSheetState(() => selectedType = val.toString())
                      ),
                      const Text('Teks'),
                      const SizedBox(width: 20),
                      Radio(
                        value: 'image', 
                        groupValue: selectedType, 
                        onChanged: (val) => setSheetState(() => selectedType = val.toString())
                      ),
                      const Text('Gambar'),
                    ],
                  ),

                  if (selectedType == 'text')
                    TextField(
                      controller: textContentController, 
                      maxLines: 4, 
                      decoration: const InputDecoration(
                        labelText: 'Isi Materi', 
                        border: OutlineInputBorder(),
                        hintText: 'Tulis penjelasan materi di sini...'
                      )
                    )
                  else
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final img = await picker.pickImage(source: ImageSource.gallery);
                        if (img != null) setSheetState(() => selectedImage = File(img.path));
                      },
                      child: Container(
                        height: 150, 
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200], 
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[400]!)
                        ),
                        child: selectedImage != null 
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(selectedImage!, fit: BoxFit.cover)
                              ) 
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                                  Text('Pilih Gambar Materi', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                      ),
                    ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, 
                        padding: const EdgeInsets.all(15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      onPressed: isSaving ? null : () async {
                        if (judulController.text.isEmpty || deskripsiController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Judul dan deskripsi wajib diisi!'))
                          );
                          return;
                        }
                        
                        setSheetState(() => isSaving = true);
                        
                        // Memanggil API Service untuk push ke MongoDB
                        final res = await ApiService.addModuleWithLanguage(
                          widget.languageId,
                          judulController.text,
                          deskripsiController.text,
                          selectedType,
                          textContentController.text,
                          selectedImage
                        );

                        if (res['success']) {
                          Navigator.pop(context);
                          _fetchModules(); // Refresh list materi
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Materi berhasil disimpan!'))
                          );
                        } else {
                          setSheetState(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res['message'] ?? 'Gagal simpan'))
                          );
                        }
                      },
                      child: isSaving 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text('Simpan Materi', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 30),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Materi ${widget.languageName}', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddModuleForm,
        backgroundColor: Colors.green,
        label: const Text('Tambah Bab', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.green)) 
        : modules.isEmpty
          ? const Center(
              child: Text('Belum ada materi untuk bahasa ini.\nKlik tombol + untuk menambah.', 
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))
            )
          : RefreshIndicator(
              onRefresh: _fetchModules,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: modules.length,
                itemBuilder: (context, index) {
                  final mod = modules[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      title: Text(
                        mod['judul_modul'] ?? 'No Title', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                      ),
                      subtitle: Text(mod['deskripsi'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmDelete(mod['_id']),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  void _confirmDelete(String moduleId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Materi?'),
        content: const Text('Data yang dihapus tidak bisa dikembalikan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ApiService.deleteModule(moduleId);
              if (success) _fetchModules();
            }, 
            child: const Text('Hapus', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}
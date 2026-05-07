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
  _AdminManageMateriState createState() => _AdminManageMateriState();
}

class _AdminManageMateriState extends State<AdminManageMateri> {
  List<dynamic> modules = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMateri();
  }

  Future<void> _loadMateri() async {
    setState(() => isLoading = true);
    // Memanggil API khusus untuk bahasa yang dipilih
    final fetchedModules = await ApiService.getModulesByLanguage(widget.languageId);
    if (mounted) {
      setState(() {
        modules = fetchedModules;
        isLoading = false;
      });
    }
  }

  // FORM TAMBAH MATERI (MENDUKUNG TEKS & GAMBAR)
  void _showMateriForm() {
    final TextEditingController judulController = TextEditingController();
    final TextEditingController deskripsiController = TextEditingController();
    final TextEditingController isiController = TextEditingController();
    
    String selectedType = 'text';
    File? selectedImage;
    final ImagePicker picker = ImagePicker();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
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
                  Text('Tambah Bab untuk ${widget.languageName}', 
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)
                  ),
                  const SizedBox(height: 20),
                  
                  TextField(
                    controller: judulController, 
                    decoration: const InputDecoration(labelText: 'Judul Bab (Cth: Bab 1)', border: OutlineInputBorder())
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: deskripsiController, maxLines: 2, 
                    decoration: const InputDecoration(labelText: 'Deskripsi Singkat', border: OutlineInputBorder())
                  ),
                  const SizedBox(height: 16),

                  // PILIH TIPE MATERI
                  const Text('Pilih Tipe Isi Materi:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Teks Paragraf'),
                        selected: selectedType == 'text',
                        onSelected: (val) => setSheetState(() => selectedType = 'text'),
                        selectedColor: Colors.green[100],
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('Gambar Informatif'),
                        selected: selectedType == 'image',
                        onSelected: (val) => setSheetState(() => selectedType = 'image'),
                        selectedColor: Colors.green[100],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // INPUT BERDASARKAN TIPE
                  if (selectedType == 'text')
                    TextField(
                      controller: isiController, maxLines: 5, 
                      decoration: const InputDecoration(labelText: 'Ketik isi materi di sini...', border: OutlineInputBorder(), alignLabelWithHint: true)
                    )
                  else
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                          if (image != null) setSheetState(() => selectedImage = File(image.path));
                        },
                        child: Container(
                          height: 150, width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200], 
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey)
                          ),
                          child: selectedImage != null 
                              ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(selectedImage!, fit: BoxFit.cover))
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                                    Text('Klik untuk Upload Gambar', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),
                  
                  // TOMBOL SIMPAN
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: isSaving ? null : () async {
                        // Validasi Form
                        if (judulController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Judul tidak boleh kosong!')));
                          return;
                        }
                        if (selectedType == 'text' && isiController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi teks tidak boleh kosong!')));
                          return;
                        }
                        if (selectedType == 'image' && selectedImage == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gambar belum dipilih!')));
                          return;
                        }

                        setSheetState(() => isSaving = true);
                        
                        final result = await ApiService.addModuleWithLanguage(
                          widget.languageId, 
                          judulController.text, 
                          deskripsiController.text, 
                          selectedType, 
                          isiController.text, 
                          selectedImage
                        );
                        
                        setSheetState(() => isSaving = false);

                        if (result['success']) {
                          Navigator.pop(context); 
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bab Baru Ditambahkan!'), backgroundColor: Colors.green));
                          _loadMateri(); // Refresh data
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: Colors.red));
                        }
                      },
                      child: isSaving 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Simpan Bab', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  void _confirmDeleteMateri(String moduleId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Bab?', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus "$title"? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context); 
              setState(() => isLoading = true);
              
              bool success = await ApiService.deleteModule(moduleId);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bab dihapus.'), backgroundColor: Colors.green));
                _loadMateri();
              } else {
                setState(() => isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menghapus bab.'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Ya, Hapus', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Materi: ${widget.languageName}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showMateriForm,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Bab', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : modules.isEmpty
              ? Center(child: Text('Belum ada materi untuk ${widget.languageName}.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: modules.length,
                  itemBuilder: (context, index) {
                    final mod = modules[index];
                    
                    // Mendapatkan info isi pertama dari array materi_isi
                    String previewTipe = 'text';
                    String previewContent = '';
                    if (mod['materi_isi'] != null && mod['materi_isi'].isNotEmpty) {
                      previewTipe = mod['materi_isi'][0]['tipe'];
                      previewContent = mod['materi_isi'][0]['content'];
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: Colors.green[50], 
                          child: Icon(previewTipe == 'image' ? Icons.image : Icons.text_snippet, color: Colors.green)
                        ),
                        title: Text(mod['judul_modul'] ?? 'Tanpa Judul', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text(mod['deskripsi'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min, 
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDeleteMateri(mod['_id'], mod['judul_modul']),
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
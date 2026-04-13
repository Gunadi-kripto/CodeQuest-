import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminManageMateri extends StatefulWidget {
  const AdminManageMateri({super.key});

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
    final fetchedModules = await ApiService.getModules();
    if (mounted) {
      setState(() {
        modules = fetchedModules;
        isLoading = false;
      });
    }
  }

  // FUNGSI FORM PINTAR (BISA TAMBAH / EDIT)
  void _showMateriForm({Map<String, dynamic>? module}) {
    // Jika module tidak null, berarti kita sedang mode EDIT
    final bool isEdit = module != null;
    
    final TextEditingController judulController = TextEditingController(text: isEdit ? module['judul_modul'] : '');
    final TextEditingController deskripsiController = TextEditingController(text: isEdit ? module['deskripsi'] : '');
    final TextEditingController isiController = TextEditingController(text: isEdit ? module['materi_isi'] : '');
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
                  Text(isEdit ? 'Edit Materi' : 'Tambah Materi Baru', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 20),
                  
                  TextField(controller: judulController, decoration: const InputDecoration(labelText: 'Judul Bab', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  
                  TextField(controller: deskripsiController, maxLines: 2, decoration: const InputDecoration(labelText: 'Deskripsi Singkat', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  
                  TextField(controller: isiController, maxLines: 6, decoration: const InputDecoration(labelText: 'Isi Materi Lengkap', border: OutlineInputBorder(), alignLabelWithHint: true)),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: isSaving ? null : () async {
                        if (judulController.text.isEmpty || isiController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Judul dan Isi tidak boleh kosong!')));
                          return;
                        }

                        setSheetState(() => isSaving = true);
                        
                        bool success;
                        if (isEdit) {
                          // Eksekusi API Update
                          success = await ApiService.updateModule(module['_id'], judulController.text, deskripsiController.text, isiController.text);
                        } else {
                          // Eksekusi API Tambah Baru
                          success = await ApiService.addModule(judulController.text, deskripsiController.text, isiController.text);
                        }
                        
                        setSheetState(() => isSaving = false);

                        if (success) {
                          Navigator.pop(context); 
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'Materi Diperbarui!' : 'Materi Ditambahkan!'), backgroundColor: Colors.green));
                          _loadMateri(); 
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terjadi kesalahan pada server'), backgroundColor: Colors.red));
                        }
                      },
                      child: isSaving 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(isEdit ? 'Simpan Perubahan' : 'Simpan Materi', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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

  // FUNGSI KONFIRMASI HAPUS
  void _confirmDeleteMateri(String moduleId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Materi?', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus "$title"? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog
              setState(() => isLoading = true);
              
              bool success = await ApiService.deleteModule(moduleId);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Materi dihapus.'), backgroundColor: Colors.green));
                _loadMateri();
              } else {
                setState(() => isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menghapus materi.'), backgroundColor: Colors.red));
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMateriForm(), // Panggil tanpa parameter = Tambah Baru
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Materi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : modules.isEmpty
              ? const Center(child: Text('Belum ada materi.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: modules.length,
                  itemBuilder: (context, index) {
                    final mod = modules[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(backgroundColor: Colors.green[100], child: const Icon(Icons.menu_book, color: Colors.green)),
                        title: Text(mod['judul_modul'] ?? 'Tanpa Judul', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text(mod['deskripsi'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min, // Agar ikon rapi di kanan
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _showMateriForm(module: mod), // Panggil dengan parameter = Edit
                            ),
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
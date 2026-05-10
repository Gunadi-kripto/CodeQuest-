import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';

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

  Future<void> _fetchModules() async {
    if (!mounted) return;
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
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengambil data materi')),
        );
      }
    }
  }

  // === FITUR HAPUS MATERI UNTUK BERSIHKAN DATA NYANGKUT ===
  void _confirmDeleteModule(String id, String judul) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Materi?", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text("Yakin ingin menghapus materi '$judul'? Data ini tidak bisa dikembalikan."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              bool success = await ApiService.deleteModule(id);
              if (success) {
                if (mounted) Navigator.pop(context);
                _fetchModules();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Materi berhasil dihapus!"), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text("Ya, Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showForm({Map<String, dynamic>? module}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => MultiContentForm(
        languageId: widget.languageId,
        existingModule: module,
        onSave: _fetchModules,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Materi ${widget.languageName}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Bab', style: TextStyle(color: Colors.white)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : modules.isEmpty
              ? const Center(child: Text('Belum ada materi.'))
              : RefreshIndicator(
                  onRefresh: _fetchModules,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: modules.length,
                    itemBuilder: (context, index) {
                      final mod = modules[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          title: Text(mod['judul_modul'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(mod['deskripsi'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showForm(module: mod),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDeleteModule(mod['_id'], mod['judul_modul'] ?? 'Tanpa Judul'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class MultiContentForm extends StatefulWidget {
  final String languageId;
  final Map<String, dynamic>? existingModule;
  final VoidCallback onSave;

  const MultiContentForm({super.key, required this.languageId, this.existingModule, required this.onSave});

  @override
  State<MultiContentForm> createState() => _MultiContentFormState();
}

class _MultiContentFormState extends State<MultiContentForm> {
  final _judulController = TextEditingController();
  final _descController = TextEditingController();
  List<Map<String, dynamic>> contentItems = []; 
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingModule != null) {
      _judulController.text = widget.existingModule!['judul_modul'] ?? '';
      _descController.text = widget.existingModule!['deskripsi'] ?? '';
      
      var materiIsi = widget.existingModule!['materi_isi'];
      if (materiIsi != null && materiIsi is List) {
        for (var item in materiIsi) {
          contentItems.add({
            'tipe': item['tipe'] ?? 'text',
            'content': item['content'] ?? '',
            'isExisting': true,
            'controller': item['tipe'] == 'text' ? TextEditingController(text: item['content']?.toString() ?? '') : null,
          });
        }
      }
    }
  }

  void _addText() => setState(() => contentItems.add({'tipe': 'text', 'controller': TextEditingController(), 'isExisting': false}));

  void _addImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => contentItems.add({'tipe': 'image', 'file': File(picked.path), 'isExisting': false}));
    }
  }

  Future<void> _submit() async {
    if (_judulController.text.isEmpty || contentItems.isEmpty) return;
    setState(() => isSaving = true);
    
    final res = await ApiService.addModuleV2(
      idBahasa: widget.languageId,
      judul: _judulController.text,
      deskripsi: _descController.text,
      contents: contentItems,
    );

    if (mounted) {
      setState(() => isSaving = false);
      if (res['success']) {
        widget.onSave();
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Column(
        children: [
          const Text('Input Materi Multi-Konten', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(controller: _judulController, decoration: const InputDecoration(labelText: 'Judul Bab', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder())),
                  const SizedBox(height: 20),
                  ...contentItems.asMap().entries.map((entry) {
                    int i = entry.key; var itm = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Konten #${i + 1} (${itm['tipe'].toUpperCase()})"),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => contentItems.removeAt(i))),
                            ],
                          ),
                          if (itm['tipe'] == 'text')
                            TextField(controller: itm['controller'], maxLines: 3, decoration: const InputDecoration(hintText: 'Tulis teks materi...'))
                          else
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: itm['isExisting'] == true
                                ? CachedNetworkImage(imageUrl: itm['content'], height: 150, width: double.infinity, fit: BoxFit.cover)
                                : Image.file(itm['file'], height: 150, width: double.infinity, fit: BoxFit.cover),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(onPressed: _addText, icon: const Icon(Icons.text_fields), label: const Text('Teks')),
                      ElevatedButton.icon(onPressed: _addImage, icon: const Icon(Icons.image), label: const Text('Gambar')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: isSaving ? null : _submit, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text('Simpan Materi', style: TextStyle(color: Colors.white)))),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
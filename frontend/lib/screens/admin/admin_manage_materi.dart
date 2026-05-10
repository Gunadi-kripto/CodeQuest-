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

  void _showForm({Map<String, dynamic>? module}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
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
        title: Text('Manage ${widget.languageName}'),
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
              ? const Center(child: Text('Belum ada materi untuk bahasa ini.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: modules.length,
                  itemBuilder: (context, index) {
                    final mod = modules[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        title: Text(
                          mod['judul_modul'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
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
                              onPressed: () async {
                                bool confirm = await showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Hapus Materi?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
                                    ],
                                  ),
                                );
                                if (confirm) {
                                  await ApiService.deleteModule(mod['_id']);
                                  _fetchModules();
                                }
                              },
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

class MultiContentForm extends StatefulWidget {
  final String languageId;
  final Map<String, dynamic>? existingModule;
  final VoidCallback onSave;

  const MultiContentForm({
    super.key, 
    required this.languageId, 
    this.existingModule, 
    required this.onSave
  });

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
            'controller': item['tipe'] == 'text' 
                ? TextEditingController(text: item['content']?.toString() ?? '') 
                : null,
          });
        }
      }
    }
  }

  void _addTextField() {
    setState(() {
      contentItems.add({
        'tipe': 'text',
        'controller': TextEditingController(),
        'isExisting': false,
      });
    });
  }

  void _addImageField() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        contentItems.add({
          'tipe': 'image',
          'file': File(pickedFile.path),
          'isExisting': false,
        });
      });
    }
  }

  Future<void> _submit() async {
    if (_judulController.text.isEmpty || contentItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan minimal 1 konten harus diisi!')),
      );
      return;
    }

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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'])),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Form Materi Multi-Konten', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 15),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: _judulController,
                    decoration: const InputDecoration(labelText: 'Judul Bab', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(labelText: 'Deskripsi Singkat', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Isi Materi:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  
                  ...contentItems.asMap().entries.map((entry) {
                    int index = entry.key;
                    var item = entry.value;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Konten #${index + 1} (${item['tipe'].toString().toUpperCase()})'),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () => setState(() => contentItems.removeAt(index)),
                              ),
                            ],
                          ),
                          if (item['tipe'] == 'text')
                            TextField(
                              controller: item['controller'],
                              maxLines: 4,
                              decoration: const InputDecoration(hintText: 'Tulis materi di sini...', border: InputBorder.none),
                            )
                          else
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: item['isExisting'] == true
                                  ? CachedNetworkImage(
                                      imageUrl: item['content'],
                                      height: 150, width: double.infinity, fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                      errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                                    )
                                  : Image.file(item['file'], height: 150, width: double.infinity, fit: BoxFit.cover),
                            ),
                        ],
                      ),
                    );
                  }).toList(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _addTextField, 
                        icon: const Icon(Icons.text_fields), 
                        label: const Text('Tambah Teks'),
                        style: ElevatedButton.styleFrom(foregroundColor: Colors.blue),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addImageField, 
                        icon: const Icon(Icons.image), 
                        label: const Text('Tambah Gambar'),
                        style: ElevatedButton.styleFrom(foregroundColor: Colors.orange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSaving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, 
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: isSaving 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Text('Simpan Materi', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
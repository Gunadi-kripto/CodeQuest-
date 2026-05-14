import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';
import 'admin_manage_materi.dart'; 

class AdminLanguageScreen extends StatefulWidget {
  const AdminLanguageScreen({super.key});

  @override
  State<AdminLanguageScreen> createState() => _AdminLanguageScreenState();
}

class _AdminLanguageScreenState extends State<AdminLanguageScreen> {
  List<dynamic> languages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLanguages();
  }

  Future<void> _loadLanguages() async {
    setState(() => isLoading = true);
    final fetchedLanguages = await ApiService.getLanguages();
    if (mounted) {
      setState(() {
        languages = fetchedLanguages;
        isLoading = false;
      });
    }
  }

  Color _hexToColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return Colors.green;
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.green;
    }
  }

  void _showAddLanguageForm() {
    final TextEditingController nameController = TextEditingController();
    File? selectedIcon;
    final ImagePicker picker = ImagePicker();
    bool isSaving = false;
    final List<String> colorOptions = ['#4CAF50', '#2196F3', '#FF9800', '#E91E63', '#9C27B0', '#607D8B'];
    String selectedColor = colorOptions[0];

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
                children: [
                  const Text('Tambah Bahasa Baru', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController, 
                    decoration: const InputDecoration(labelText: 'Nama Bahasa', border: OutlineInputBorder())
                  ),
                  const SizedBox(height: 16),
                  const Align(alignment: Alignment.centerLeft, child: Text('Pilih Warna Tema:')),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: colorOptions.map((hex) => GestureDetector(
                      onTap: () => setSheetState(() => selectedColor = hex),
                      child: CircleAvatar(
                        backgroundColor: _hexToColor(hex),
                        radius: 15,
                        child: selectedColor == hex ? const Icon(Icons.check, color: Colors.white, size: 15) : null,
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () async {
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) setSheetState(() => selectedIcon = File(image.path));
                    },
                    child: Container(
                      height: 80, width: 80,
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(15)),
                      child: selectedIcon != null 
                        ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(selectedIcon!, fit: BoxFit.cover)) 
                        : const Icon(Icons.add_a_photo, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: isSaving ? null : () async {
                        debugPrint("🛠️ LOG: Tombol Simpan ditekan");

                        if (nameController.text.isEmpty || selectedIcon == null) {
                          _showAlertDialog('Peringatan', 'Nama bahasa dan icon wajib diisi!');
                          return;
                        }

                        setSheetState(() => isSaving = true);
                        debugPrint("🛠️ LOG: Mengirim ke API: ${nameController.text}");
                        
                        final res = await ApiService.addLanguage(nameController.text, selectedColor, selectedIcon!);
                        
                        debugPrint("🛠️ LOG: Respon API diterima: $res");
                        setSheetState(() => isSaving = false);

                        if (res['success'] == true) {
                          Navigator.pop(context); // Tutup BottomSheet
                          _showAlertDialog('Sukses', 'Bahasa berhasil ditambahkan!', isError: false);
                          _loadLanguages(); 
                        } else {
                          _showAlertDialog('Gagal', res['message'] ?? 'Terjadi kesalahan');
                        }
                      },
                      child: isSaving 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                        : const Text('Simpan', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAlertDialog(String title, String message, {bool isError = true}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: TextStyle(color: isError ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('System add Quiz', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.85,
              ),
              itemCount: languages.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) return _buildAddCard();
                final lang = languages[index - 1];
                return _buildLanguageCard(lang);
              },
            ),
    );
  }

  Widget _buildAddCard() {
    return InkWell(
      onTap: _showAddLanguageForm,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(20), 
          border: Border.all(color: Colors.grey[300]!, width: 2)
        ),
        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add_circle_outline, size: 40, color: Colors.grey),
          SizedBox(height: 10),
          Text('Tambah Bahasa', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        ]),
      ),
    );
  }

  Widget _buildLanguageCard(Map<String, dynamic> lang) {
    final themeColor = _hexToColor(lang['warna_tema']);
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminManageMateri(
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
          border: Border(bottom: BorderSide(color: themeColor, width: 4)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CachedNetworkImage(
              imageUrl: lang['icon_url'], 
              height: 50, 
              placeholder: (context, url) => const CircularProgressIndicator(color: Colors.green),
              errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 40, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(lang['nama_bahasa'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
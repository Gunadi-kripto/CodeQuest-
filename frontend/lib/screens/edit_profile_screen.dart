import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'login_screen.dart'; // Import layar login untuk lemparan setelah hapus akun

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['nama_lengkap']);
    _bioController = TextEditingController(text: widget.userData['bio'] ?? '');
  }

  // Fungsi untuk membuka galeri HP
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50); // Kompres agar ringan
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Fungsi menyimpan data ke server
  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    String userId = widget.userData['id'] ?? widget.userData['_id'];
    
    final result = await ApiService.updateProfile(
      userId, 
      _nameController.text, 
      _bioController.text, 
      _selectedImage
    );

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success'] ? Colors.green : Colors.red,
      )
    );

    if (result['success']) {
      Navigator.pop(context); // Kembali ke layar profil jika sukses
    }
  }

  // Fungsi konfirmasi dan eksekusi Hapus Akun
  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Akun?', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text('Semua data, XP, dan progres kamu akan hilang selamanya. Apakah kamu yakin?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Batal', style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              // Tampilkan loading (opsional, untuk UX yang lebih baik)
              showDialog(
                context: context, 
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.red))
              );

              String userId = widget.userData['id'] ?? widget.userData['_id'];
              bool success = await ApiService.deleteAccount(userId);
              
              if (success) {
                // Jika sukses dihapus, lempar paksa ke layar Login dan hapus semua riwayat layar
                Navigator.pushAndRemoveUntil(
                  context, 
                  MaterialPageRoute(builder: (context) => const LoginScreen()), 
                  (route) => false
                );
              } else {
                Navigator.pop(context); // Tutup loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gagal menghapus akun'), backgroundColor: Colors.red)
                );
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profil', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // === FOTO PROFIL ===
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.green[100],
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!) as ImageProvider
                      : (widget.userData['avatar_url'] != null && widget.userData['avatar_url'] != ""
                          ? NetworkImage(widget.userData['avatar_url'])
                          : null),
                  child: _selectedImage == null && (widget.userData['avatar_url'] == null || widget.userData['avatar_url'] == "")
                      ? const Icon(Icons.person, size: 60, color: Colors.green)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      onPressed: _pickImage,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 32),
            
            // === INPUT NAMA ===
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nama Lengkap',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 20),
            
            // === INPUT BIO ===
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Bio Singkat',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 30),
                  child: Icon(Icons.info),
                ),
              ),
            ),
            const SizedBox(height: 40),
            
            // === TOMBOL SIMPAN ===
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Simpan Perubahan', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // === TOMBOL HAPUS AKUN (BAHAYA) ===
            TextButton(
              onPressed: _confirmDeleteAccount,
              child: const Text('Hapus Akun Permanen', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}
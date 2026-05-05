import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['nama_lengkap']);
    _bioController = TextEditingController(text: widget.userData['bio'] ?? '');
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _saveProfile() async {
    setState(() => _isLoading = true);
    
    String userId = widget.userData['id'] ?? widget.userData['_id'];
    final response = await ApiService.updateProfile(userId, _nameController.text, _bioController.text, _imageFile);
    
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']),
          backgroundColor: response['success'] ? Colors.green : Colors.red,
        )
      );
      if (response['success']) {
        Navigator.pop(context, true); 
      }
    }
  }

  // === FUNGSI KONFIRMASI HAPUS AKUN (BYPASS GOOGLE) ===
  void _confirmDelete() {
    final TextEditingController passwordController = TextEditingController();
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text('Hapus Akun Permanen?', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Masukkan password kamu untuk mengonfirmasi penghapusan.\n\n(Khusus pengguna Google, ketik kata: HAPUS)', 
                  style: TextStyle(fontSize: 14)
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: false, // Biarkan false supaya teks "HAPUS" kelihatan
                  decoration: const InputDecoration(
                    labelText: 'Password / Ketik HAPUS', 
                    border: OutlineInputBorder(), 
                    prefixIcon: Icon(Icons.lock)
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text('Batal', style: TextStyle(color: Colors.grey))
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: isDeleting ? null : () async {
                  if (passwordController.text.isEmpty) return;
                  
                  setDialogState(() => isDeleting = true);
                  
                  String userId = widget.userData['id'] ?? widget.userData['_id'];
                  final res = await ApiService.deleteAccount(userId, passwordController.text);
                  
                  setDialogState(() => isDeleting = false);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(res['message']), 
                        backgroundColor: res['success'] ? Colors.green : Colors.red
                      )
                    );
                    
                    if (res['success']) {
                      Navigator.pushAndRemoveUntil(
                        context, 
                        MaterialPageRoute(builder: (context) => const LoginScreen()), 
                        (route) => false
                      );
                    }
                  }
                },
                child: isDeleting 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Text('Ya, Hapus', style: TextStyle(color: Colors.white)),
              )
            ],
          );
        }
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.green[100],
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : (widget.userData['avatar_url'] != null && widget.userData['avatar_url'] != ""
                            ? NetworkImage(widget.userData['avatar_url'])
                            : null) as ImageProvider?,
                    child: _imageFile == null && (widget.userData['avatar_url'] == null || widget.userData['avatar_url'] == "")
                        ? const Icon(Icons.person, size: 60, color: Colors.green)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.green,
                      radius: 20,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Bio Singkat', border: OutlineInputBorder(), prefixIcon: Icon(Icons.info)),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Simpan Perubahan', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _confirmDelete,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Hapus Akun Permanen', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
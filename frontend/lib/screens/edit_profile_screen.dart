// lib/screens/edit_profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart'; 
import '../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _bioController;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  final Color greenTheme = const Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['nama_lengkap'] ?? widget.userData['username']);
    _bioController = TextEditingController(text: widget.userData['bio'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path); 
      });
    }
  }

  // --- MENGGUNAKAN API_SERVICE BAWAAN ANDA ---
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = widget.userData['id'] ?? widget.userData['_id'];

      // Memanggil fungsi updateProfile dari api_service.dart Anda
      final response = await ApiService.updateProfile(
        userId,
        _nameController.text,
        _bioController.text,
        _imageFile,
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Profil berhasil diperbarui!', style: TextStyle(color: Colors.white)), backgroundColor: greenTheme),
          );
          Navigator.pop(context, true); 
        }
      } else {
        throw Exception(response['message'] ?? 'Gagal memperbarui profil');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''), style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- MENGGUNAKAN API_SERVICE BAWAAN ANDA ---
  Future<void> _deleteAccount(String password) async {
    setState(() => _isLoading = true);
    try {
      final userId = widget.userData['id'] ?? widget.userData['_id'];

      // Memanggil fungsi deleteAccount dari api_service.dart Anda (Wajib kirim password)
      final response = await ApiService.deleteAccount(userId, password);

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Akun berhasil dihapus selamanya.'), backgroundColor: Colors.green),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Gagal menghapus akun. Password salah?');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''), style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- DIALOG KONFIRMASI HAPUS (DITAMBAH INPUT PASSWORD) ---
  void _showDeleteConfirmation() {
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('Hapus Akun?', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tindakan ini tidak dapat dibatalkan. Semua data Anda akan terhapus.'),
            const SizedBox(height: 15),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Masukkan Password Anda',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (passwordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password harus diisi!'), backgroundColor: Colors.red)
                );
                return;
              }
              Navigator.pop(context); 
              _deleteAccount(passwordController.text); 
            },
            child: const Text('Ya, Hapus Akun', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? currentProfilePic = widget.userData['avatar_url'] ?? widget.userData['profilePicture'];

    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        title: const Text('Edit Profil', style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: greenTheme,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: greenTheme))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.green.withOpacity(0.2),
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!) as ImageProvider
                                : (currentProfilePic != null && currentProfilePic.isNotEmpty
                                    ? NetworkImage(currentProfilePic) as ImageProvider
                                    : null),
                            child: (_imageFile == null && (currentProfilePic == null || currentProfilePic.isEmpty))
                                ? Icon(Icons.person, size: 50, color: greenTheme)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                height: 32,
                                width: 32,
                                decoration: BoxDecoration(
                                  color: greenTheme,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Lengkap',
                        prefixIcon: const Icon(Icons.person), 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10), 
                          borderSide: BorderSide(color: greenTheme, width: 2)
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Nama tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _bioController,
                      maxLines: 3, 
                      decoration: InputDecoration(
                        labelText: 'Bio singkat',
                        alignLabelWithHint: true, 
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 45), 
                          child: Icon(Icons.info),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10), 
                          borderSide: BorderSide(color: greenTheme, width: 2)
                        ),
                      ),
                    ),
                    const SizedBox(height: 35),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: greenTheme, 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                          'Simpan Perubahan',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextButton(
                      onPressed: _isLoading ? null : _showDeleteConfirmation,
                      child: const Text(
                        'Hapus Akun Permanen', 
                        style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
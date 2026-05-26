// lib/screens/user/edit_profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 
import '../auth/login_screen.dart';
import '../../services/api_service.dart';

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
  final Color greenTheme = Colors.green;

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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = widget.userData['id'] ?? widget.userData['_id'];

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

  Future<void> _deleteAccount(String password) async {
    setState(() => _isLoading = true);
    try {
      final userId = widget.userData['id'] ?? widget.userData['_id'];

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

  void _showDeleteConfirmation() {
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
            ),
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
      backgroundColor: Colors.transparent, 
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profil', 
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)
        ),
      ),
      body: SizedBox.expand(
        child: Stack(
          children: [
            // Background Image SAMA PERSIS dengan profile_screen.dart
            SizedBox.expand(
              child: Image.asset(
                'assets/coding_bg.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            
            // Konten Utama di dalam SafeArea agar tidak menabrak header
            SafeArea(
              child: _isLoading
                ? Center(child: CircularProgressIndicator(color: greenTheme))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Center(
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
                                  ),
                                  child: CircleAvatar(
                                    radius: 55,
                                    backgroundColor: Colors.green[100], 
                                    backgroundImage: _imageFile != null
                                        ? FileImage(_imageFile!) as ImageProvider
                                        : (currentProfilePic != null && currentProfilePic.isNotEmpty
                                            ? NetworkImage(currentProfilePic) as ImageProvider
                                            : null),
                                    child: (_imageFile == null && (currentProfilePic == null || currentProfilePic.isEmpty))
                                        ? Icon(Icons.person, size: 55, color: greenTheme)
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: _pickImage,
                                    child: Container(
                                      height: 36,
                                      width: 36,
                                      decoration: BoxDecoration(
                                        color: greenTheme,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 3),
                                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5)],
                                      ),
                                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Input Nama Modern
                          _buildModernTextField(
                            controller: _nameController,
                            hint: 'Nama Lengkap',
                            icon: Icons.person_outline,
                            validator: (value) => value == null || value.isEmpty ? 'Nama tidak boleh kosong' : null,
                          ),
                          
                          const SizedBox(height: 20),

                          // Input Bio Modern
                          _buildModernTextField(
                            controller: _bioController,
                            hint: 'Bio singkat (hobi, status, dll)',
                            icon: Icons.info_outline,
                            maxLines: 3,
                          ),
                          
                          const SizedBox(height: 40),

                          // Tombol Simpan Modern
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: greenTheme, 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), 
                                elevation: 3,
                                shadowColor: Colors.green.withOpacity(0.5),
                              ),
                              child: const Text(
                                'Simpan Perubahan',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          // Tombol Hapus Akun (Background disesuaikan agar terbaca di atas gambar)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: TextButton.icon(
                              onPressed: _isLoading ? null : _showDeleteConfirmation,
                              icon: const Icon(Icons.delete_forever, color: Colors.red, size: 20),
                              label: const Text(
                                'Hapus Akun Permanen', 
                                style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold)
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget bantuan untuk membuat TextField bergaya modern
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95), // Dibuat sedikit opacity agar elegan
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Padding(
            padding: EdgeInsets.only(bottom: maxLines > 1 ? 45 : 0),
            child: Icon(icon, color: Colors.grey[600]),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
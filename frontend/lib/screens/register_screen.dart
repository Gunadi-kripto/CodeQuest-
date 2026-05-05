import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _showOTPDialog(String email) {
    final TextEditingController otpController = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text('Verifikasi Email', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Kami telah mengirimkan 6 digit kode OTP ke email $email. Masukkan kode tersebut di bawah ini (Berlaku 2 Menit).', style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 16),
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 10, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(border: OutlineInputBorder(), counterText: ""),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  setDialogState(() => isVerifying = true);
                  final res = await ApiService.resendOTP(email);
                  setDialogState(() => isVerifying = false);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
                }, 
                child: const Text('Kirim Ulang OTP', style: TextStyle(color: Colors.orange))
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: isVerifying ? null : () async {
                  if (otpController.text.length < 6) return;

                  setDialogState(() => isVerifying = true);
                  final res = await ApiService.verifyRegisterOTP(email, otpController.text);
                  
                  final nav = Navigator.of(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res['message']), backgroundColor: res['statusCode'] == 200 ? Colors.green : Colors.red)
                    );
                    if (res['statusCode'] == 200) {
                      nav.pop(); // Tutup Dialog OTP
                      nav.pop(); // Kembali ke Layar Login
                    }
                  }
                  setDialogState(() => isVerifying = false);
                },
                child: isVerifying 
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Text('Verifikasi', style: TextStyle(color: Colors.white)),
              )
            ],
          );
        }
      ),
    );
  }

  void _register() async {
    // === PENJAGA GERBANG: Validasi Kolom Kosong ===
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua kolom wajib diisi!'), backgroundColor: Colors.red),
      );
      return; // Stop proses di sini, jangan hubungi backend
    }
    // ===============================================

    setState(() => _isLoading = true);
    
    final response = await ApiService.registerUser(
      _nameController.text, _emailController.text, _passwordController.text,
    );

    setState(() => _isLoading = false);

    // Backend mungkin mengembalikan 200 atau 201 untuk sukses
    if (response['statusCode'] == 200 || response['statusCode'] == 201) {
      _showOTPDialog(_emailController.text); // Munculkan dialog OTP
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Terjadi kesalahan'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Text('Mulai Petualanganmu!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 8),
              const Text('Buat akun CodeQuest sekarang.', style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 40),
              
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
              const SizedBox(height: 16),
              TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email))),
              const SizedBox(height: 16),
              TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('Daftar', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Sudah punya akun? Masuk di sini', style: TextStyle(color: Colors.green)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
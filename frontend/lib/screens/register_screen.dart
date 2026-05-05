import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  
  // === STATE UNTUK PASSWORD ===
  bool _isPasswordValid = false;
  String? _passwordErrorText; 
  bool _obscurePassword = true; // State untuk fitur Mata (Show/Hide)

  // Fungsi mengecek kekuatan password secara Real-Time
  void _validatePassword(String value) {
    // Regex Baru: Semua simbol (termasuk +, -, =) sekarang diizinkan!
    RegExp regex = RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[^a-zA-Z0-9]).{8,}$');
    
    setState(() {
      if (value.isEmpty) {
        _passwordErrorText = 'Password tidak boleh kosong';
        _isPasswordValid = false;
      } else if (!regex.hasMatch(value)) {
        _passwordErrorText = 'Min 8 karakter, kombinasi huruf besar, kecil, angka, & simbol';
        _isPasswordValid = false;
      } else {
        _passwordErrorText = null; // Password Kuat!
        _isPasswordValid = true;
      }
    });
  }

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
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua kolom wajib diisi!'), backgroundColor: Colors.red));
      return; 
    }
    
    if (!_isPasswordValid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password belum memenuhi standar keamanan!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    
    final response = await ApiService.registerUser(
      _nameController.text, _emailController.text, _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (response['statusCode'] == 200 || response['statusCode'] == 201) {
      _showOTPDialog(_emailController.text); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Terjadi kesalahan'), backgroundColor: Colors.red));
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
              
              TextField(
                controller: _nameController, 
                decoration: const InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _emailController, 
                keyboardType: TextInputType.emailAddress, 
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email))
              ),
              const SizedBox(height: 16),
              
              // === TEXTFIELD PASSWORD DENGAN FITUR MATA ===
              TextField(
                controller: _passwordController, 
                obscureText: _obscurePassword, // Dikontrol oleh variabel
                onChanged: _validatePassword, 
                decoration: InputDecoration(
                  labelText: 'Password Kuat', 
                  border: const OutlineInputBorder(), 
                  prefixIcon: const Icon(Icons.lock),
                  errorText: _passwordErrorText, 
                  errorMaxLines: 2,
                  suffixIcon: IconButton( // Tombol Mata
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword; // Toggle on/off
                      });
                    },
                  ),
                )
              ),
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _isLoading || !_isPasswordValid ? null : _register,
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
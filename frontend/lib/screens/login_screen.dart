import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart'; // IMPORT GOOGLE SIGN IN
import '../services/api_service.dart';
import '../main.dart'; // Import main.dart untuk memanggil MainScreen
import 'register_screen.dart'; 
import 'admin_main_screen.dart'; // Import layar portal admin

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // ==========================================
  // 1. LOGIKA LOGIN MANUAL (EMAIL & PASSWORD)
  // ==========================================
  void _login() async {
    setState(() => _isLoading = true);
    
    final response = await ApiService.loginUser(
      _emailController.text,
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (response['statusCode'] == 200 || response['token'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selamat datang, ${response['user']['nama_lengkap']}!'), backgroundColor: Colors.green),
      );
      
      // === LOGIKA BERCABANG: PENJAGA PINTU ===
      if (response['user']['role'] == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminMainScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
      
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Login Gagal'), backgroundColor: Colors.red),
      );
    }
  }

  // ==========================================
  // 2. LOGIKA LOGIN GOOGLE (OAUTH)
  // ==========================================
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      // INISIALISASI GOOGLE SIGN IN
      // WAJIB GANTI: Masukkan Client ID Web Application kamu di bawah ini!
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: '946414111075-tb595grrhu28td3ss6a7o3p925jcpvt7.apps.googleusercontent.com',
      );

      // Munculkan popup Google
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      // Jika user membatalkan / klik di luar popup
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; 
      }

      // Ambil idToken
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken != null) {
        // Tembak idToken ke Backend Node.js
        final response = await ApiService.loginWithGoogle(idToken);

        setState(() => _isLoading = false);

        // Jika berhasil dapat token JWT dari backend kita
        if (response['token'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Selamat datang, ${response['user']['nama_lengkap']}!'), backgroundColor: Colors.green),
          );
          
          // Arahkan ke Dashboard berdasarkan role
          if (response['user']['role'] == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminMainScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          }
        } else {
          // Jika gagal dari backend
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Gagal otentikasi di server'), backgroundColor: Colors.red),
          );
        }
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mendapatkan token Google'), backgroundColor: Colors.red),
        );
      }
    } catch (error) {
      setState(() => _isLoading = false);
      print('Error Google Sign-In: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $error'), backgroundColor: Colors.red),
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
              const SizedBox(height: 60),
              const Icon(Icons.code, size: 80, color: Colors.green), 
              const SizedBox(height: 16),
              const Text('CodeQuest', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 40),
              
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
              ),
              const SizedBox(height: 32),
              
              // === TOMBOL LOGIN MANUAL ===
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('Masuk', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              
              const SizedBox(height: 24),
              
              // === GARIS PEMISAH "ATAU" ===
              Row(
                children: const [
                  Expanded(child: Divider(color: Colors.grey)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('ATAU', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(child: Divider(color: Colors.grey)),
                ],
              ),
              
              const SizedBox(height: 24),

              // === TOMBOL LOGIN GOOGLE ===
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                icon: const Icon(Icons.g_mobiledata, size: 36, color: Colors.red), // Ikon Google Bawaan Flutter
                label: const Text('Masuk dengan Google', style: TextStyle(fontSize: 16, color: Colors.black87)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.grey),
                  backgroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 16),
              
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen()));
                },
                child: const Text('Belum punya akun? Daftar sekarang', style: TextStyle(color: Colors.green)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
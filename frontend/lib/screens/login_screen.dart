import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/api_service.dart';
import '../main.dart'; 
import 'register_screen.dart'; 
import 'admin_main_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // === FUNGSI POPUP RESET PASSWORD (DUA TAHAP) ===
  void _showResetPasswordDialog() {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController otpController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    
    bool isProcessing = false;
    bool isOtpSent = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text(isOtpSent ? 'Verifikasi OTP' : 'Lupa Password', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isOtpSent 
                  ? 'Kami telah mengirimkan OTP ke ${emailController.text}. Masukkan kode dan password barumu di bawah ini.' 
                  : 'Masukkan email akun CodeQuest kamu. Kami akan mengirimkan OTP.', 
                  style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 16),
                
                if (!isOtpSent) ...[
                  TextField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email))),
                ] else ...[
                  TextField(controller: otpController, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(labelText: 'Kode OTP 6 Digit', border: OutlineInputBorder(), prefixIcon: Icon(Icons.numbers), counterText: "")),
                  const SizedBox(height: 12),
                  TextField(controller: newPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password Baru', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_reset))),
                ]
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text('Batal', style: TextStyle(color: Colors.grey))
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: isProcessing ? null : () async {
                  setDialogState(() => isProcessing = true);
                  
                  if (!isOtpSent) {
                    // TAHAP 1: Minta OTP
                    if (emailController.text.isEmpty) { setDialogState(() => isProcessing = false); return; }
                    final res = await ApiService.requestForgotPasswordOTP(emailController.text);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']), backgroundColor: res['statusCode'] == 200 ? Colors.green : Colors.red));
                    if (res['statusCode'] == 200) setDialogState(() => isOtpSent = true);
                  } else {
                    // TAHAP 2: Reset Password
                    if (otpController.text.length < 6 || newPasswordController.text.isEmpty) { setDialogState(() => isProcessing = false); return; }
                    final res = await ApiService.resetPasswordWithOTP(emailController.text, otpController.text, newPasswordController.text);
                    final nav = Navigator.of(context);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']), backgroundColor: res['statusCode'] == 200 ? Colors.green : Colors.red));
                      if (res['statusCode'] == 200) nav.pop(); 
                    }
                  }
                  
                  setDialogState(() => isProcessing = false);
                },
                child: isProcessing 
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : Text(isOtpSent ? 'Simpan Password' : 'Kirim OTP', style: const TextStyle(color: Colors.white)),
              )
            ],
          );
        }
      ),
    );
  }

  void _login() async {
    setState(() => _isLoading = true);
    final response = await ApiService.loginUser(_emailController.text, _passwordController.text);
    setState(() => _isLoading = false);

    if (response['statusCode'] == 200 || response['token'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selamat datang, ${response['user']['nama_lengkap']}!'), backgroundColor: Colors.green));
      if (response['user']['role'] == 'admin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminMainScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
      }
    } else {
      // Jika errornya karena unverified, suruh OTP
      if (response['unverified'] == true) {
        _emailController.clear();
        _passwordController.clear();
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Login Gagal'), backgroundColor: Colors.red));
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(serverClientId: '946414111075-tb595grrhu28td3ss6a7o3p925jcpvt7.apps.googleusercontent.com');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) { setState(() => _isLoading = false); return; }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken != null) {
        final response = await ApiService.loginWithGoogle(idToken);
        setState(() => _isLoading = false);
        if (response['token'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selamat datang, ${response['user']['nama_lengkap']}!'), backgroundColor: Colors.green));
          if (response['user']['role'] == 'admin') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminMainScreen()));
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Gagal otentikasi di server'), backgroundColor: Colors.red));
        }
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mendapatkan token Google'), backgroundColor: Colors.red));
      }
    } catch (error) {
      setState(() => _isLoading = false);
      print('Error Google Sign-In: $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $error'), backgroundColor: Colors.red));
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
              
              TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email))),
              const SizedBox(height: 16),
              TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
              
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showResetPasswordDialog,
                  child: const Text('Lupa Password?', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 16),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Masuk', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              
              const SizedBox(height: 24),
              Row(
                children: const [
                  Expanded(child: Divider(color: Colors.grey)),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('ATAU', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                  Expanded(child: Divider(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 24),

              OutlinedButton.icon(
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                icon: const Icon(Icons.g_mobiledata, size: 36, color: Colors.red),
                label: const Text('Masuk dengan Google', style: TextStyle(fontSize: 16, color: Colors.black87)),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: Colors.grey), backgroundColor: Colors.white),
              ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen())); },
                child: const Text('Belum punya akun? Daftar sekarang', style: TextStyle(color: Colors.green)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
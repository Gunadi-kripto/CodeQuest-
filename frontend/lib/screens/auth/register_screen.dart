import 'package:flutter/material.dart';
import '../../services/api_service.dart';

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
  bool _isPasswordValid = false;
  String? _passwordErrorText; 
  bool _obscurePassword = true;

  // Warna utama desain soft (sama dengan login)
  final Color primaryGreen = const Color(0xFF1F9E58);
  final Color lightGray = const Color(0xFFF0F2F5);

  // === LOGIKA VALIDASI PASSWORD (TETAP SAMA) ===
  void _validatePassword(String value) {
    RegExp regex = RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[^a-zA-Z0-9]).{8,}$');
    
    setState(() {
      if (value.isEmpty) {
        _passwordErrorText = 'Password tidak boleh kosong';
        _isPasswordValid = false;
      } else if (!regex.hasMatch(value)) {
        _passwordErrorText = 'Min 8 karakter, huruf besar, kecil, angka, & simbol';
        _isPasswordValid = false;
      } else {
        _passwordErrorText = null; 
        _isPasswordValid = true;
      }
    });
  }

  // === DIALOG OTP DENGAN DESAIN SOFT ===
  void _showOTPDialog(String email) {
    final TextEditingController otpController = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Verifikasi Email', style: TextStyle(fontWeight: FontWeight.bold, color: primaryGreen)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Kami telah mengirimkan kode OTP ke email $email.', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                const SizedBox(height: 20),
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: lightGray,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    counterText: "",
                  ),
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
                child: const Text('Kirim Ulang', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                onPressed: isVerifying ? null : () async {
                  if (otpController.text.length < 6) return;
                  setDialogState(() => isVerifying = true);
                  final res = await ApiService.verifyRegisterOTP(email, otpController.text);
                  final nav = Navigator.of(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res['message']), backgroundColor: res['statusCode'] == 200 ? primaryGreen : Colors.red)
                    );
                    if (res['statusCode'] == 200) {
                      nav.pop(); // Tutup Dialog
                      nav.pop(); // Kembali ke Login
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
        },
      ),
    );
  }

  // === LOGIKA REGISTER (TETAP SAMA) ===
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
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          // Ornamen Lingkaran (Konsisten dengan Login)
          Positioned(
            top: -40,
            right: -60,
            child: CircleAvatar(radius: 120, backgroundColor: primaryGreen.withOpacity(0.08)),
          ),
          Positioned(
            top: 250,
            left: -50,
            child: CircleAvatar(radius: 80, backgroundColor: primaryGreen.withOpacity(0.06)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Logo
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        color: primaryGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: primaryGreen.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
                        ],
                      ),
                      child: const Center(
                        child: Text('</>', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Text('Create Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 8),
                    const Text('Mulai petualangan kodingmu sekarang!', style: TextStyle(fontSize: 14, color: Colors.black45)),
                    const SizedBox(height: 40),

                    // Input Fields
                    _buildPillTextField(
                      controller: _nameController,
                      hint: 'Full Name',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    _buildPillTextField(
                      controller: _emailController,
                      hint: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildPillTextField(
                      controller: _passwordController,
                      hint: 'Strong Password',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      onChanged: _validatePassword,
                      errorText: _passwordErrorText,
                    ),
                    const SizedBox(height: 32),

                    // Tombol Daftar
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading || !_isPasswordValid ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 3,
                          shadowColor: primaryGreen.withOpacity(0.5),
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),

                    const SizedBox(height: 20),
                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account? ', style: TextStyle(color: Colors.black54, fontSize: 13)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text('Log In', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget Helper: TextField Bentuk Pil
  Widget _buildPillTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
    String? errorText,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      onChanged: onChanged,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        filled: true,
        fillColor: lightGray,
        hintText: hint,
        errorText: errorText,
        errorMaxLines: 2,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 15, right: 10),
          child: Icon(icon, color: Colors.black38, size: 22),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.black38, size: 20),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }
}
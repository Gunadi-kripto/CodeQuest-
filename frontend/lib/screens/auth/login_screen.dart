import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../services/api_service.dart';
import '../../main.dart';
import 'register_screen.dart';
import '../admin/admin_main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  // Warna utama yang diambil dari desain gambar
  final Color primaryGreen = const Color(0xFF1F9E58);
  final Color lightGray = const Color(0xFFF0F2F5);

  // Inisialisasi GoogleSignIn yang dikonfigurasi untuk Web dan Android
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '946414111075-tb595grrhu28td3ss6a7o3p925jcpvt7.apps.googleusercontent.com',
    serverClientId: '946414111075-tb595grrhu28td3ss6a7o3p925jcpvt7.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  // === FUNGSI POPUP RESET PASSWORD (LOGIKA TETAP, DESAIN LIGHT MODE) ===
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
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              isOtpSent ? 'Verifikasi OTP' : 'Lupa Password',
              style: TextStyle(fontWeight: FontWeight.bold, color: primaryGreen),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isOtpSent
                      ? 'Kami telah mengirimkan OTP ke ${emailController.text}. Masukkan kode dan password barumu di bawah ini.'
                      : 'Masukkan email akun CodeQuest kamu. Kami akan mengirimkan OTP.',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                if (!isOtpSent) ...[
                  _buildDialogTextField(controller: emailController, hint: 'Email', icon: Icons.email),
                ] else ...[
                  _buildDialogTextField(controller: otpController, hint: 'Kode OTP 6 Digit', icon: Icons.numbers, isNumber: true, maxLength: 6),
                  const SizedBox(height: 12),
                  _buildDialogTextField(controller: newPasswordController, hint: 'Password Baru', icon: Icons.lock_reset, isPassword: true),
                ]
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                onPressed: isProcessing
                    ? null
                    : () async {
                        setDialogState(() => isProcessing = true);

                        if (!isOtpSent) {
                          if (emailController.text.isEmpty) {
                            setDialogState(() => isProcessing = false);
                            return;
                          }
                          final res = await ApiService.requestForgotPasswordOTP(emailController.text);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(res['message']),
                                backgroundColor: res['statusCode'] == 200 ? primaryGreen : Colors.red));
                          }
                          if (res['statusCode'] == 200) setDialogState(() => isOtpSent = true);
                        } else {
                          if (otpController.text.length < 6 || newPasswordController.text.isEmpty) {
                            setDialogState(() => isProcessing = false);
                            return;
                          }
                          final res = await ApiService.resetPasswordWithOTP(
                              emailController.text, otpController.text, newPasswordController.text);
                          final nav = Navigator.of(context);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(res['message']),
                                backgroundColor: res['statusCode'] == 200 ? primaryGreen : Colors.red));
                            if (res['statusCode'] == 200) nav.pop();
                          }
                        }

                        setDialogState(() => isProcessing = false);
                      },
                child: isProcessing
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(isOtpSent ? 'Simpan' : 'Kirim OTP', style: const TextStyle(color: Colors.white)),
              )
            ],
          );
        },
      ),
    );
  }

  // === LOGIKA LOGIN (TETAP SAMA) ===
  void _login() async {
    setState(() => _isLoading = true);
    final response = await ApiService.loginUser(_emailController.text, _passwordController.text);
    setState(() => _isLoading = false);

    if (response['statusCode'] == 200 || response['token'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Selamat datang, ${response['user']['nama_lengkap']}!'), backgroundColor: primaryGreen));
      if (response['user']['role'] == 'admin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminMainScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
      }
    } else {
      if (response['unverified'] == true) {
        _emailController.clear();
        _passwordController.clear();
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Login Gagal'), backgroundColor: Colors.red));
    }
  }

  // === LOGIKA GOOGLE SIGN IN (TEMBAK SAMA DENGAN INSTANCE KELAS) ===
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken != null) {
        final response = await ApiService.loginWithGoogle(idToken);
        setState(() => _isLoading = false);
        if (response['token'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Selamat datang, ${response['user']['nama_lengkap']}!'), backgroundColor: primaryGreen));
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
      backgroundColor: const Color(0xFFFAFAFA), // Warna dasar putih agak keabu-abuan
      body: Stack(
        children: [
          // Latar Belakang Lingkaran Hijau Transparan (Persis seperti gambar)
          Positioned(
            top: -40,
            right: -60,
            child: CircleAvatar(radius: 120, backgroundColor: primaryGreen.withOpacity(0.08)),
          ),
          Positioned(
            top: 200,
            left: -50,
            child: CircleAvatar(radius: 80, backgroundColor: primaryGreen.withOpacity(0.06)),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    
                    // ================= LOGO =================
                    Container(
                      height: 90,
                      width: 90,
                      decoration: BoxDecoration(
                        color: primaryGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: primaryGreen.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '</>',
                          style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // ================= NAMA APLIKASI =================
                    Text.rich(
                      TextSpan(
                        text: 'Code',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                        children: [
                          TextSpan(
                            text: 'Quest',
                            style: TextStyle(color: primaryGreen),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // ================= JUDUL =================
                    const Text(
                      'Welcome Back',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 35),

                    // ================= INPUT EMAIL =================
                    _buildPillTextField(
                      controller: _emailController,
                      hint: 'Email',
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 16),

                    // ================= INPUT PASSWORD =================
                    _buildPillTextField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock_outline,
                      isPassword: true,
                    ),
                    const SizedBox(height: 30),

                    // ================= TOMBOL MASUK =================
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 3,
                          shadowColor: primaryGreen.withOpacity(0.5),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ================= LUPA PASSWORD =================
                    TextButton(
                      onPressed: _showResetPasswordDialog,
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ================= TOMBOL GOOGLE =================
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                        icon: const Icon(Icons.g_mobiledata, size: 32, color: Colors.red),
                        label: const Text(
                          'Login with Google',
                          style: TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.grey.shade200,
                          elevation: 2,
                          shadowColor: Colors.black12,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ================= DAFTAR SEKARANG =================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Don\'t have an account? ',
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen()));
                          },
                          child: Text(
                            'Sign Up',
                            style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
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

  // WIDGET HELPER: TEXT FIELD BENTUK PIL (Sesuai Desain)
  Widget _buildPillTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscureText : false,
      style: const TextStyle(color: Colors.black87, fontSize: 15),
      decoration: InputDecoration(
        filled: true,
        fillColor: lightGray,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 15, right: 10),
          child: Icon(icon, color: Colors.black38, size: 22),
        ),
        suffixIcon: isPassword
            ? Padding(
                padding: const EdgeInsets.only(right: 10),
                child: IconButton(
                  icon: Icon(_obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.black38, size: 20),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                ),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }

  // WIDGET HELPER: DIALOG TEXT FIELD
  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isNumber = false,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isNumber ? TextInputType.number : TextInputType.emailAddress,
      maxLength: maxLength,
      decoration: InputDecoration(
        filled: true,
        fillColor: lightGray,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Colors.black45),
        prefixIcon: Icon(icon, color: primaryGreen, size: 20),
        counterText: "",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5000/api'; 

  // ==========================================
  // FUNGSI REGISTER & LOGIN MANUAL
  // ==========================================
  static Future<Map<String, dynamic>> registerUser(String nama, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nama_lengkap': nama, 'email': email, 'password': password}),
      );
      return jsonDecode(response.body);
    } catch (e) { return {'message': 'Gagal menghubungi server'}; }
  }

  static Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['token'] != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['token']);
        await prefs.setString('user_data', jsonEncode(data['user']));
      }

      data['statusCode'] = response.statusCode;
      return data;
    } catch (e) { return {'message': 'Gagal menghubungi server', 'statusCode': 500}; }
  }

  static Future<void> logoutUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_data');

    try {
    await GoogleSignIn().signOut();
    } catch (e) {
    print('Gagal logout Google: $e');
    }
  }

  // ==========================================
  // FUNGSI LOGIN GOOGLE (OAUTH)
  // ==========================================
  static Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    try {
      // Sekarang sudah memakai baseUrl utama ($baseUrl/auth/google)
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );
      
      final data = jsonDecode(response.body);

      // Jika berhasil, simpan token ke memori HP seperti login manual
      if ((response.statusCode == 200 || response.statusCode == 201) && data['token'] != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['token']);
        await prefs.setString('user_data', jsonEncode(data['user']));
      }

      data['statusCode'] = response.statusCode;
      return data;
    } catch (e) {
      print('Error kirim token ke backend: $e');
      return {'message': 'Terjadi kesalahan koneksi saat login Google', 'statusCode': 500};
    }
  }

  // ==========================================
  // FUNGSI MATERI & KUIS (GET)
  // ==========================================
  static Future<List<dynamic>> getModules() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/modules'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) { return []; }
  }

  static Future<List<dynamic>> getQuizzes(String moduleId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/quizzes/$moduleId'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) { return []; }
  }

  // ==========================================
  // FUNGSI PROFIL & XP
  // ==========================================
  static Future<bool> addXp(String userId, int xpToAdd) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/add-xp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'xpToAdd': xpToAdd}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? userStr = prefs.getString('user_data');
        if (userStr != null) {
          Map<String, dynamic> userData = jsonDecode(userStr);
          userData['total_xp'] = data['total_xp'];
          userData['level'] = data['level'];
          await prefs.setString('user_data', jsonEncode(userData));
        }
        return true;
      }
      return false;
    } catch (e) { return false; }
  }

  static Future<Map<String, dynamic>> updateProfile(String userId, String nama, String bio, File? imageFile) async {
    try {
      var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/users/update-profile/$userId'));
      request.fields['nama_lengkap'] = nama;
      request.fields['bio'] = bio;

      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('avatar', imageFile.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(data['user']));
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Gagal update profil'};
      }
    } catch (e) { return {'success': false, 'message': 'Gagal menghubungi server'}; }
  }

  static Future<Map<String, dynamic>> deleteAccount(String userId, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/delete-account/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'password': password}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await logoutUser();
      }
      return {'success': response.statusCode == 200, 'message': data['message']};
    } catch (e) {
      return {'success': false, 'message': 'Gagal menghubungi server'};
    }
  }

  // ==========================================
  // FUNGSI SOSIAL & LEADERBOARD
  // ==========================================
  static Future<List<dynamic>> searchUsers(String query, String currentUserId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/search?query=$query&currentUserId=$currentUserId'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) { return []; }
  }

  static Future<Map<String, dynamic>> sendFriendRequest(String senderId, String targetId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/request-friend'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'senderId': senderId, 'targetId': targetId}),
      );
      return jsonDecode(response.body);
    } catch (e) { return {'message': 'Gagal menghubungi server'}; }
  }

  static Future<Map<String, dynamic>> acceptFriendRequest(String userId, String senderId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/accept-friend'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'senderId': senderId}),
      );
      return jsonDecode(response.body);
    } catch (e) { return {'message': 'Gagal menghubungi server'}; }
  }

  static Future<Map<String, dynamic>?> getSocialData(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/$userId/social'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) { return null; }
  }

  static Future<List<dynamic>> getLeaderboard() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/leaderboard'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) { return []; }
  }

  static Future<List<dynamic>> getAllUsers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/all-users'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) { return []; }
  }

  // ==========================================
  // FUNGSI ADMIN: KELOLA MATERI, KUIS & USER
  // ==========================================
  static Future<bool> addModule(String judul, String deskripsi, String isi) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/modules'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'judul_modul': judul, 'deskripsi': deskripsi, 'materi_isi': isi}),
      );
      return response.statusCode == 201;
    } catch (e) { return false; }
  }

  static Future<bool> updateModule(String id, String judul, String deskripsi, String isi) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/modules/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'judul_modul': judul, 'deskripsi': deskripsi, 'materi_isi': isi}),
      );
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  static Future<bool> deleteModule(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/modules/$id'));
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  static Future<bool> addQuiz(String moduleId, String pertanyaan, String kunci, String hint, int xp) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/quizzes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'module_id': moduleId, 'pertanyaan': pertanyaan, 'kunci_jawaban': kunci, 'hint': hint, 'xp_reward': xp}),
      );
      return res.statusCode == 201;
    } catch (e) { return false; }
  }

  static Future<bool> updateQuiz(String quizId, String pertanyaan, String kunci, String hint, int xp) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/quizzes/$quizId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pertanyaan': pertanyaan, 'kunci_jawaban': kunci, 'hint': hint, 'xp_reward': xp}),
      );
      return res.statusCode == 200;
    } catch (e) { return false; }
  }

  static Future<bool> deleteQuiz(String quizId) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/quizzes/$quizId'));
      return res.statusCode == 200;
    } catch (e) { return false; }
  }

  static Future<bool> adminDeleteUser(String userId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/users/admin/force-delete/$userId'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
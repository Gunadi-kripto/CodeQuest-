import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5000/api'; 

  // FUNGSI OTENTIKASI & OTP
  static Future<Map<String, dynamic>> registerUser(String nama, String email, String password) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/auth/register'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'nama_lengkap': nama, 'email': email, 'password': password}));
      return {'statusCode': response.statusCode, ...jsonDecode(response.body)};
    } catch (e) { return {'statusCode': 500, 'message': 'Gagal server'}; }
  }

  static Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/auth/login'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email, 'password': password}));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['token'] != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['token']);
        await prefs.setString('user_data', jsonEncode(data['user']));
      }
      data['statusCode'] = response.statusCode;
      return data;
    } catch (e) { return {'message': 'Gagal server', 'statusCode': 500}; }
  }

  static Future<void> logoutUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_data');
    try { await GoogleSignIn().signOut(); } catch (e) {}
  }

  static Future<Map<String, dynamic>> verifyRegisterOTP(String email, String otp) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/auth/verify-register'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email, 'otp': otp}));
      return {'statusCode': response.statusCode, ...jsonDecode(response.body)};
    } catch (e) { return {'statusCode': 500, 'message': 'Gagal server'}; }
  }

  static Future<Map<String, dynamic>> resendOTP(String email) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/auth/resend-otp'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email}));
      return {'statusCode': response.statusCode, ...jsonDecode(response.body)};
    } catch (e) { return {'statusCode': 500, 'message': 'Gagal server'}; }
  }

  static Future<Map<String, dynamic>> requestForgotPasswordOTP(String email) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/auth/forgot-password'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email}));
      return {'statusCode': response.statusCode, ...jsonDecode(response.body)};
    } catch (e) { return {'statusCode': 500, 'message': 'Gagal server'}; }
  }

  static Future<Map<String, dynamic>> resetPasswordWithOTP(String email, String otp, String newPassword) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/auth/reset-password'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email, 'otp': otp, 'newPassword': newPassword}));
      return {'statusCode': response.statusCode, ...jsonDecode(response.body)};
    } catch (e) { return {'statusCode': 500, 'message': 'Gagal server'}; }
  }

  static Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/auth/google'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'idToken': idToken}));
      final data = jsonDecode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) && data['token'] != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['token']);
        await prefs.setString('user_data', jsonEncode(data['user']));
      }
      data['statusCode'] = response.statusCode;
      return data;
    } catch (e) { return {'message': 'Kesalahan koneksi', 'statusCode': 500}; }
  }

  // FUNGSI PROFIL & SOSIAL
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/profile/$userId'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) { return null; }
  }

  static Future<Map<String, dynamic>> updateProfile(String userId, String nama, String bio, File? imageFile) async {
    try {
      var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/users/update-profile/$userId'));
      request.fields['nama_lengkap'] = nama;
      request.fields['bio'] = bio;
      if (imageFile != null) request.files.add(await http.MultipartFile.fromPath('avatar', imageFile.path));
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(data['user']));
        return {'success': true, 'message': data['message']};
      } else { return {'success': false, 'message': data['message'] ?? 'Gagal update'}; }
    } catch (e) { return {'success': false, 'message': 'Gagal server'}; }
  }

  static Future<Map<String, dynamic>> deleteAccount(String userId, String password) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/users/delete-account/$userId'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'password': password}));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) await logoutUser();
      return {'success': response.statusCode == 200, 'message': data['message']};
    } catch (e) { return {'success': false, 'message': 'Gagal server'}; }
  }

  static Future<List<dynamic>> searchUsers(String query, String currentUserId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/search?query=$query&currentUserId=$currentUserId'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) { return []; }
  }

  static Future<Map<String, dynamic>> sendFriendRequest(String senderId, String targetId) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/users/request-friend'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'senderId': senderId, 'targetId': targetId}));
      return jsonDecode(response.body);
    } catch (e) { return {'message': 'Gagal server'}; }
  }

  static Future<Map<String, dynamic>> acceptFriendRequest(String userId, String senderId) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/users/accept-friend'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'userId': userId, 'senderId': senderId}));
      return jsonDecode(response.body);
    } catch (e) { return {'message': 'Gagal server'}; }
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

  // FUNGSI MATERI, KUIS, & XP
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

  static Future<Map<String, dynamic>> addXp(String userId, int xpToAdd) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/users/add-xp'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'userId': userId, 'xpToAdd': xpToAdd}));
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
        return {'success': true, 'new_achievements': data['new_achievements']};
      }
      return {'success': false};
    } catch (e) { return {'success': false}; }
  }

  // FUNGSI ADMIN: CRUD MATERI & KUIS & USER
  static Future<bool> addModule(String judul, String deskripsi, String isi) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/modules'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'judul_modul': judul, 'deskripsi': deskripsi, 'materi_isi': isi}));
      return response.statusCode == 201;
    } catch (e) { return false; }
  }

  static Future<bool> updateModule(String id, String judul, String deskripsi, String isi) async {
    try {
      final response = await http.put(Uri.parse('$baseUrl/modules/$id'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'judul_modul': judul, 'deskripsi': deskripsi, 'materi_isi': isi}));
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  static Future<bool> deleteModule(String id) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/modules/$id'));
      return res.statusCode == 200;
    } catch (e) { return false; }
  }

  static Future<bool> addQuiz(String moduleId, String pertanyaan, String kunci, String hint, int xp) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/quizzes'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'module_id': moduleId, 'pertanyaan': pertanyaan, 'kunci_jawaban': kunci, 'hint': hint, 'xp_reward': xp}));
      return res.statusCode == 201;
    } catch (e) { return false; }
  }

  static Future<bool> updateQuiz(String quizId, String pertanyaan, String kunci, String hint, int xp) async {
    try {
      final res = await http.put(Uri.parse('$baseUrl/quizzes/$quizId'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'pertanyaan': pertanyaan, 'kunci_jawaban': kunci, 'hint': hint, 'xp_reward': xp}));
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
      final res = await http.delete(Uri.parse('$baseUrl/users/admin/force-delete/$userId'));
      return res.statusCode == 200;
    } catch (e) { return false; }
  }

  // FUNGSI ADMIN: KELOLA PENCAPAIAN
  static Future<List<dynamic>> getAchievements() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/achievements'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) { return []; }
  }

  static Future<bool> addAchievement(String judul, String deskripsi, String syaratTipe, int syaratNilai, String icon) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/achievements'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'judul': judul, 'deskripsi': deskripsi, 'syarat_tipe': syaratTipe, 'syarat_nilai': syaratNilai, 'icon': icon}));
      return res.statusCode == 201;
    } catch (e) { return false; }
  }

  static Future<bool> updateAchievement(String id, String judul, String deskripsi, String syaratTipe, int syaratNilai, String icon) async {
    try {
      final res = await http.put(Uri.parse('$baseUrl/achievements/$id'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'judul': judul, 'deskripsi': deskripsi, 'syarat_tipe': syaratTipe, 'syarat_nilai': syaratNilai, 'icon': icon}));
      return res.statusCode == 200;
    } catch (e) { return false; }
  }

  static Future<bool> deleteAchievement(String id) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/achievements/$id'));
      return res.statusCode == 200;
    } catch (e) { return false; }
  }

  static Future<Map<String, dynamic>> rejectFriendRequest(String userId, String senderId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/reject-friend'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'senderId': senderId})
      );
      return jsonDecode(response.body);
    } catch (e) { return {'message': 'Gagal server'}; }
  }

  static Future<Map<String, dynamic>> removeFriend(String userId, String friendId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/remove-friend'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'friendId': friendId})
      );
      return jsonDecode(response.body);
    } catch (e) { return {'message': 'Gagal server'}; }
  }

  // FUNGSI CHAT
  static Future<Map<String, dynamic>> getChats(String userId, String friendId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/chats/$userId/$friendId'));
      if (res.statusCode == 200) return jsonDecode(res.body);
      return {'messages': [], 'canChat': true, 'dailyCount': 0};
    } catch (e) { return {'messages': [], 'canChat': true, 'dailyCount': 0}; }
  }

  static Future<bool> sendMessage(String senderId, String receiverId, String text) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/chats/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'senderId': senderId, 'receiverId': receiverId, 'text': text})
      );
      return res.statusCode == 200;
    } catch (e) { return false; }
  }
}
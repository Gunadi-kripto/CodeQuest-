// services/api_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // PENTING: Gunakan 10.0.2.2 khusus untuk Android Emulator agar bisa mengakses localhost komputer
  static const String baseUrl = 'http://10.0.2.2:5000/api'; 

  // ==========================================
  // FUNGSI REGISTER
  // ==========================================
  static Future<Map<String, dynamic>> registerUser(String nama, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nama_lengkap': nama,
          'email': email,
          'password': password,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Gagal menghubungi server'};
    }
  }

  // ==========================================
  // FUNGSI LOGIN
  // ==========================================
  static Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      // Jika login berhasil dan dapat token, simpan ke memori HP
      if (response.statusCode == 200 && data['token'] != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['token']);
        await prefs.setString('user_data', jsonEncode(data['user']));
      }

      data['statusCode'] = response.statusCode; // Menyisipkan status untuk validasi UI
      return data;
    } catch (e) {
      return {'message': 'Gagal menghubungi server', 'statusCode': 500};
    }
  }

  // Fungsi untuk Logout (Menghapus token)
  static Future<void> logoutUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_data');
  }

  
  // Mengambil daftar semua materi
  static Future<List<dynamic>> getModules() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/modules'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Mengembalikan List data materi
      }
      return [];
    } catch (e) {
      print('Error getModules: $e');
      return [];
    }
  }

  // Mengambil daftar kuis berdasarkan ID materi
  static Future<List<dynamic>> getQuizzes(String moduleId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/quizzes/module/$moduleId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('Error getQuizzes: $e');
      return [];
    }
  }

  static Future<bool> addXp(String userId, int xpToAdd) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/add-xp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'xpToAdd': xpToAdd,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Update data di memori HP agar bar level di Home langsung berubah!
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
    } catch (e) {
      print('Error addXp: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> updateProfile(String userId, String nama, String bio, File? imageFile) async {
    try {
      var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/users/update-profile/$userId'));
      
      // Masukkan data teks
      request.fields['nama_lengkap'] = nama;
      request.fields['bio'] = bio;

      // Masukkan file gambar jika ada
      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('avatar', imageFile.path));
      }

      // Kirim ke server
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Jika sukses, perbarui data di memori HP agar foto langsung berubah
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(data['user']));
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Gagal update profil'};
      }
    } catch (e) {
      print('Error updateProfile: $e');
      return {'success': false, 'message': 'Gagal menghubungi server'};
    }
  }
  // FUNGSI HAPUS AKUN
  static Future<bool> deleteAccount(String userId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/users/delete-account/$userId'));
      if (response.statusCode == 200) {
        await logoutUser(); // Hapus token dari HP
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }



}
import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://code-quest-eta-wine.vercel.app/api';

  // ==========================================
  // 1. FUNGSI BAHASA (LANGUAGE)
  // ==========================================

  static Future<List<dynamic>> getLanguages() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/language'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      print('Error fetch languages: $e');
      return [];
    }
  }

  static Future<bool> deleteLanguage(String id) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/language/$id'));
      return res.statusCode == 200;
    } catch (e) {
      print('Error delete language: $e');
      return false;
    }
  }

  static Future<bool> updateLanguage(String id, String namaBahasa) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/language/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nama_bahasa': namaBahasa,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Gagal update bahasa: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error update language: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> addLanguage(
    String namaBahasa,
    String warnaTema,
    File iconFile,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/language'),
      );

      request.fields['nama_bahasa'] = namaBahasa;
      request.fields['warna_tema'] = warnaTema;

      request.files.add(
        await http.MultipartFile.fromPath(
          'icon_file',
          iconFile.path,
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Bahasa berhasil ditambahkan!',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menambah bahasa',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal koneksi: $e',
      };
    }
  }

  // ==========================================
  // 2. FUNGSI MATERI (MODULE) - MULTI-KONTEN V2
  // ==========================================

  static Future<Map<String, dynamic>> addModuleV2({
    required String idBahasa,
    required String judul,
    required String deskripsi,
    required List<Map<String, dynamic>> contents,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/modules'),
      );

      request.fields['id_bahasa'] = idBahasa;
      request.fields['judul_modul'] = judul;
      request.fields['deskripsi'] = deskripsi;
      request.fields['urutan'] = "1";

      for (int i = 0; i < contents.length; i++) {
        var item = contents[i];

        request.fields['type_$i'] = item['tipe'] ?? 'text';

        if (item['tipe'] == 'text') {
          String textVal = "";

          if (item['controller'] != null) {
            textVal = item['controller'].text;
          } else {
            textVal = item['content']?.toString() ?? "";
          }

          request.fields['content_$i'] = textVal;
        } else if (item['tipe'] == 'image') {
          if (item['isExisting'] == true) {
            request.fields['content_$i'] = item['content'] ?? "";
          } else if (item['file'] != null) {
            final File imageFile = item['file'];

            if (!await imageFile.exists()) {
              return {
                'success': false,
                'message':
                    'Gambar konten ${i + 1} tidak ditemukan. Silakan pilih ulang gambar.',
              };
            }

            request.files.add(
              await http.MultipartFile.fromPath(
                'file_$i',
                imageFile.path,
              ),
            );
          }
        }
      }

      request.fields['total_items'] = contents.length.toString();

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.body.contains('<!DOCTYPE html>')) {
        return {
          'success': false,
          'message': 'Server Error (404/500). Cek Endpoint /api/modules',
        };
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true};
      } else {
        final data = jsonDecode(response.body);

        return {
          'success': false,
          'message': data['message'] ?? 'Gagal simpan materi',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Koneksi error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> updateModuleV2({
    required String idModule,
    required String idBahasa,
    required String judul,
    required String deskripsi,
    required List<Map<String, dynamic>> contents,
  }) async {
    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/modules/$idModule'),
      );

      request.fields['id_bahasa'] = idBahasa;
      request.fields['judul_modul'] = judul;
      request.fields['deskripsi'] = deskripsi;
      request.fields['urutan'] = "1";

      for (int i = 0; i < contents.length; i++) {
        var item = contents[i];

        request.fields['type_$i'] = item['tipe'] ?? 'text';

        if (item['tipe'] == 'text') {
          String textVal = "";

          if (item['controller'] != null) {
            textVal = item['controller'].text;
          } else {
            textVal = item['content']?.toString() ?? "";
          }

          request.fields['content_$i'] = textVal;
        } else if (item['tipe'] == 'image') {
          if (item['isExisting'] == true) {
            request.fields['content_$i'] = item['content'] ?? "";
          } else if (item['file'] != null) {
            final File imageFile = item['file'];

            if (!await imageFile.exists()) {
              return {
                'success': false,
                'message':
                    'Gambar konten ${i + 1} tidak ditemukan. Silakan pilih ulang gambar.',
              };
            }

            request.files.add(
              await http.MultipartFile.fromPath(
                'file_$i',
                imageFile.path,
              ),
            );
          }
        }
      }

      request.fields['total_items'] = contents.length.toString();

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.body.contains('<!DOCTYPE html>')) {
        return {
          'success': false,
          'message':
              'Server Error (404/500). Cek Endpoint /api/modules/$idModule',
        };
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true};
      } else {
        final data = jsonDecode(response.body);

        return {
          'success': false,
          'message': data['message'] ?? 'Gagal update materi',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Koneksi error: $e',
      };
    }
  }

  static Future<List<dynamic>> getModulesByLanguage(String idBahasa) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/modules/bahasa/$idBahasa'),
      );

      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getModules() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/modules'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> deleteModule(String id) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/modules/$id'));
      return res.statusCode == 200;
    } catch (e) {
      print("Error delete module: $e");
      return false;
    }
  }

  // ==========================================
  // 3. FUNGSI OTENTIKASI & OTP
  // ==========================================

  static Future<Map<String, dynamic>> registerUser(
    String nama,
    String email,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nama_lengkap': nama,
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      return {
        'statusCode': response.statusCode,
        ...jsonDecode(response.body),
      };
    } on TimeoutException {
      return {
        'statusCode': 408,
        'message': 'Server timeout, coba lagi',
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'message': 'Gagal server: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> loginUser(
    String email,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['token'] != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();

        await prefs.setString('jwt_token', data['token']);
        await prefs.setString('user_data', jsonEncode(data['user']));
      }

      data['statusCode'] = response.statusCode;
      return data;
    } on TimeoutException {
      return {
        'message': 'Server timeout, coba lagi',
        'statusCode': 408,
      };
    } catch (e) {
      return {
        'message': 'Gagal server: $e',
        'statusCode': 500,
      };
    }
  }

  static Future<void> logoutUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_data');

    try {
      await GoogleSignIn().signOut();
    } catch (e) {}
  }

  static Future<Map<String, dynamic>> verifyRegisterOTP(
    String email,
    String otp,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );

      return {
        'statusCode': response.statusCode,
        ...jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'message': 'Gagal server',
      };
    }
  }

  static Future<bool> adminDeleteUser(String userId) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/users/admin/force-delete/$userId'),
      );

      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> resendOTP(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/resend-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 15));

      return {
        'statusCode': response.statusCode,
        ...jsonDecode(response.body),
      };
    } on TimeoutException {
      return {'statusCode': 408, 'message': 'Server timeout, coba lagi'};
    } catch (e) {
      return {'statusCode': 500, 'message': 'Gagal server: $e'};
    }
  }

  static Future<Map<String, dynamic>> requestForgotPasswordOTP(
    String email,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/forgot-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 15));

      return {
        'statusCode': response.statusCode,
        ...jsonDecode(response.body),
      };
    } on TimeoutException {
      return {'statusCode': 408, 'message': 'Server timeout, coba lagi'};
    } catch (e) {
      return {'statusCode': 500, 'message': 'Gagal server: $e'};
    }
  }

  static Future<Map<String, dynamic>> resetPasswordWithOTP(
    String email,
    String otp,
    String newPassword,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/reset-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'otp': otp,
              'newPassword': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 15));

      return {
        'statusCode': response.statusCode,
        ...jsonDecode(response.body),
      };
    } on TimeoutException {
      return {'statusCode': 408, 'message': 'Server timeout, coba lagi'};
    } catch (e) {
      return {'statusCode': 500, 'message': 'Gagal server: $e'};
    }
  }

  static Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/google'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'idToken': idToken}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['token'] != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['token']);
        await prefs.setString('user_data', jsonEncode(data['user']));
      }

      data['statusCode'] = response.statusCode;
      return data;
    } on TimeoutException {
      return {'message': 'Server timeout, coba lagi', 'statusCode': 408};
    } catch (e) {
      return {'message': 'Kesalahan koneksi: $e', 'statusCode': 500};
    }
  }

  // ==========================================
  // 4. FUNGSI PROFIL & SOSIAL
  // ==========================================

  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/profile/$userId'),
      );

      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> updateProfile(
    String userId,
    String nama,
    String bio,
    File? imageFile,
  ) async {
    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/users/update-profile/$userId'),
      );

      request.fields['nama_lengkap'] = nama;
      request.fields['bio'] = bio;

      if (imageFile != null) {
        if (!await imageFile.exists()) {
          return {
            'success': false,
            'message': 'Foto profil tidak ditemukan. Silakan pilih ulang foto.',
          };
        }

        request.files.add(
          await http.MultipartFile.fromPath(
            'avatar',
            imageFile.path,
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(data['user']));

        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal update',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal server',
      };
    }
  }

  static Future<Map<String, dynamic>> deleteAccount(
    String userId,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/delete-account/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) await logoutUser();

      return {
        'success': response.statusCode == 200,
        'message': data['message'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal server',
      };
    }
  }

  static Future<List<dynamic>> searchUsers(
    String query,
    String currentUserId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/users/search?query=$query&currentUserId=$currentUserId',
        ),
      );

      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> sendFriendRequest(
    String senderId,
    String targetId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/request-friend'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderId': senderId,
          'targetId': targetId,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'message': 'Gagal server',
      };
    }
  }

  static Future<Map<String, dynamic>> acceptFriendRequest(
    String userId,
    String senderId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/accept-friend'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'senderId': senderId,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'message': 'Gagal server',
      };
    }
  }

  static Future<Map<String, dynamic>> rejectFriendRequest(
    String userId,
    String senderId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/reject-friend'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'senderId': senderId,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'message': 'Gagal server',
      };
    }
  }

  static Future<Map<String, dynamic>> removeFriend(
    String userId,
    String friendId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/remove-friend'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'friendId': friendId,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'message': 'Gagal server',
      };
    }
  }

  static Future<Map<String, dynamic>?> getSocialData(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/social'),
      );

      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<dynamic>> getLeaderboard() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/leaderboard'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getAllUsers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/all-users'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  // ==========================================
  // 5. FUNGSI KUIS (QUIZ) - MULTIPLE SOAL V3
  // ==========================================

  static Future<List<dynamic>> getQuizzes(String moduleId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/quizzes/$moduleId'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  static int _answerLetterToIndex(dynamic answer) {
    final value = answer.toString().toUpperCase().trim();

    switch (value) {
      case 'A':
        return 0;
      case 'B':
        return 1;
      case 'C':
        return 2;
      case 'D':
        return 3;
      default:
        return 0;
    }
  }

  static Future<bool> addQuiz(
    String moduleId,
    List<Map<String, dynamic>> daftarSoal,
    int xp,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/quizzes'),
      );

      final List<Map<String, dynamic>> cleanSoal = [];

      for (int i = 0; i < daftarSoal.length; i++) {
        final soal = Map<String, dynamic>.from(daftarSoal[i]);
        final imageFile = soal['image_file'];

        if (imageFile != null && imageFile is File) {
          if (!await imageFile.exists()) {
            print('Gambar soal ${i + 1} tidak ditemukan.');
            return false;
          }

          request.files.add(
            await http.MultipartFile.fromPath(
              'gambar_soal_$i',
              imageFile.path,
            ),
          );
        }

        final opsiRaw = soal['opsi'];

        List<String> opsiList = [];

        if (opsiRaw is Map) {
          opsiList = [
            opsiRaw['A']?.toString() ?? '',
            opsiRaw['B']?.toString() ?? '',
            opsiRaw['C']?.toString() ?? '',
            opsiRaw['D']?.toString() ?? '',
          ];
        } else if (opsiRaw is List) {
          opsiList = opsiRaw.map((e) => e.toString()).toList();
        }

        cleanSoal.add({
          'pertanyaan': soal['pertanyaan']?.toString() ?? '',
          'gambar_url': soal['gambar_url']?.toString() ?? '',
          'opsi': opsiList,
          'jawaban_benar': _answerLetterToIndex(soal['jawaban_benar']),
        });
      }

      request.fields['module_id'] = moduleId;
      request.fields['xp_reward'] = xp.toString();
      request.fields['daftar_soal'] = jsonEncode(cleanSoal);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('ADD QUIZ STATUS: ${response.statusCode}');
      print('ADD QUIZ BODY: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error add quiz: $e');
      return false;
    }
  }

  static Future<bool> updateQuiz(
    String quizId,
    List<Map<String, dynamic>> daftarSoal,
    int xp,
  ) async {
    try {
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/quizzes/$quizId'),
      );

      final List<Map<String, dynamic>> cleanSoal = [];

      for (int i = 0; i < daftarSoal.length; i++) {
        final soal = Map<String, dynamic>.from(daftarSoal[i]);
        final imageFile = soal['image_file'];

        if (imageFile != null && imageFile is File) {
          if (!await imageFile.exists()) {
            print('Gambar soal ${i + 1} tidak ditemukan.');
            return false;
          }

          request.files.add(
            await http.MultipartFile.fromPath(
              'gambar_soal_$i',
              imageFile.path,
            ),
          );
        }

        final opsiRaw = soal['opsi'];

        List<String> opsiList = [];

        if (opsiRaw is Map) {
          opsiList = [
            opsiRaw['A']?.toString() ?? '',
            opsiRaw['B']?.toString() ?? '',
            opsiRaw['C']?.toString() ?? '',
            opsiRaw['D']?.toString() ?? '',
          ];
        } else if (opsiRaw is List) {
          opsiList = opsiRaw.map((e) => e.toString()).toList();
        }

        cleanSoal.add({
          'pertanyaan': soal['pertanyaan']?.toString() ?? '',
          'gambar_url': soal['gambar_url']?.toString() ?? '',
          'opsi': opsiList,
          'jawaban_benar': _answerLetterToIndex(soal['jawaban_benar']),
        });
      }

      request.fields['xp_reward'] = xp.toString();
      request.fields['daftar_soal'] = jsonEncode(cleanSoal);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('UPDATE QUIZ STATUS: ${response.statusCode}');
      print('UPDATE QUIZ BODY: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error update quiz: $e');
      return false;
    }
  }

  static Future<bool> deleteQuiz(String quizId) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/quizzes/$quizId'));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> submitQuiz({
    required String userId,
    required String quizId,
    required int skor,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/quizzes/submit'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'quiz_id': quizId,
          'skor': skor,
        }),
      );

      print('SUBMIT QUIZ STATUS: ${response.statusCode}');
      print('SUBMIT QUIZ BODY: ${response.body}');

      dynamic data;

      try {
        data = jsonDecode(response.body);
      } catch (_) {
        return {
          'success': false,
          'message':
              'Server tidak mengirim JSON. Status: ${response.statusCode}. Body: ${response.body}',
          'new_achievements': [],
        };
      }

      if (response.statusCode == 200) {
        if (data['user'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', jsonEncode(data['user']));
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Quiz berhasil disubmit',
          'already_completed': data['already_completed'] ?? false,
          'xp_added': data['xp_added'] ?? 0,
          'total_kuis_selesai': data['total_kuis_selesai'] ?? 0,
          'progress': data['progress'],
          'new_achievements': data['new_achievements'] ?? [],
          'user': data['user'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Gagal submit quiz',
        'new_achievements': [],
      };
    } catch (e) {
      print('SUBMIT QUIZ ERROR: $e');

      return {
        'success': false,
        'message': 'Koneksi error: $e',
        'new_achievements': [],
      };
    }
  }

  // ==========================================
  // 6. FUNGSI XP & PROGRESS
  // ==========================================

  static Future<Map<String, dynamic>> addXp(
    String userId,
    int xpToAdd,
  ) async {
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

        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? userStr = prefs.getString('user_data');

        if (userStr != null) {
          Map<String, dynamic> userData = jsonDecode(userStr);
          userData['total_xp'] = data['total_xp'];
          userData['level'] = data['level'];

          if (data['unlocked_achievements'] != null) {
            userData['unlocked_achievements'] = data['unlocked_achievements'];
          }

          await prefs.setString('user_data', jsonEncode(userData));
        }

        return {
          'success': true,
          'new_achievements': data['new_achievements'] ?? [],
          'total_xp': data['total_xp'],
          'level': data['level'],
        };
      }

      return {
        'success': false,
        'new_achievements': [],
      };
    } catch (e) {
      return {
        'success': false,
        'new_achievements': [],
      };
    }
  }

  static Future<Map<String, dynamic>> completeModule({
    required String userId,
    required String moduleId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/progress/complete-module'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'module_id': moduleId,
        }),
      );

      print('COMPLETE MODULE STATUS: ${response.statusCode}');
      print('COMPLETE MODULE BODY: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['user'] != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', jsonEncode(data['user']));
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Materi berhasil diselesaikan',
          'progress': data['progress'],
          'new_achievements': data['new_achievements'] ?? [],
          'user': data['user'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Gagal menyelesaikan materi',
        'new_achievements': [],
      };
    } catch (e) {
      print('COMPLETE MODULE ERROR: $e');

      return {
        'success': false,
        'message': 'Koneksi error: $e',
        'new_achievements': [],
      };
    }
  }

  // ==========================================
  // 7. FUNGSI ACHIEVEMENTS (PIALA)
  // ==========================================

  static Future<List<dynamic>> getAchievements() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/achievements'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> addAchievement(
    String judul,
    String deskripsi,
    String syaratTipe,
    int syaratNilai,
    String icon,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/achievements'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'judul': judul,
          'deskripsi': deskripsi,
          'syarat_tipe': syaratTipe,
          'syarat_nilai': syaratNilai,
          'icon': icon,
        }),
      );

      return res.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateAchievement(
    String id,
    String judul,
    String deskripsi,
    String syaratTipe,
    int syaratNilai,
    String icon,
  ) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/achievements/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'judul': judul,
          'deskripsi': deskripsi,
          'syarat_tipe': syaratTipe,
          'syarat_nilai': syaratNilai,
          'icon': icon,
        }),
      );

      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteAchievement(String id) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/achievements/$id'));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> addAchievementV2({
    required String languageId,
    required String judul,
    required String deskripsi,
    required String syaratTipe,
    required int syaratNilai,
    required int xpReward,
    required String rarity,
    required File iconFile,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/achievements'),
      );

      request.fields['language_id'] = languageId;
      request.fields['judul'] = judul;
      request.fields['deskripsi'] = deskripsi;
      request.fields['syarat_tipe'] = syaratTipe;
      request.fields['syarat_nilai'] = syaratNilai.toString();
      request.fields['xp_reward'] = xpReward.toString();
      request.fields['rarity'] = rarity;

      if (!await iconFile.exists()) {
        return {
          'success': false,
          'message': 'File badge tidak ditemukan. Silakan pilih ulang badge.',
        };
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'icon_file',
          iconFile.path,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.body.contains('<!DOCTYPE html>')) {
        return {
          'success': false,
          'message': 'Server Error. Cek endpoint POST /api/achievements',
        };
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': response.body.isNotEmpty ? jsonDecode(response.body) : null,
        };
      }

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body);
      } catch (_) {}

      return {
        'success': false,
        'message': data['message'] ?? 'Gagal menambah achievement',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Koneksi error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> updateAchievementV2({
    required String id,
    required String languageId,
    required String judul,
    required String deskripsi,
    required String syaratTipe,
    required int syaratNilai,
    required int xpReward,
    required String rarity,
    File? iconFile,
    String? existingIconUrl,
  }) async {
    try {
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/achievements/$id'),
      );

      request.fields['language_id'] = languageId;
      request.fields['judul'] = judul;
      request.fields['deskripsi'] = deskripsi;
      request.fields['syarat_tipe'] = syaratTipe;
      request.fields['syarat_nilai'] = syaratNilai.toString();
      request.fields['xp_reward'] = xpReward.toString();
      request.fields['rarity'] = rarity;

      if (existingIconUrl != null && existingIconUrl.isNotEmpty) {
        request.fields['existing_icon'] = existingIconUrl;
      }

      if (iconFile != null) {
        if (!await iconFile.exists()) {
          return {
            'success': false,
            'message': 'File badge tidak ditemukan. Silakan pilih ulang badge.',
          };
        }

        request.files.add(
          await http.MultipartFile.fromPath(
            'icon_file',
            iconFile.path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.body.contains('<!DOCTYPE html>')) {
        return {
          'success': false,
          'message': 'Server Error. Cek endpoint PUT /api/achievements/$id',
        };
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': response.body.isNotEmpty ? jsonDecode(response.body) : null,
        };
      }

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body);
      } catch (_) {}

      return {
        'success': false,
        'message': data['message'] ?? 'Gagal update achievement',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Koneksi error: $e',
      };
    }
  }

  // ==========================================
  // 8. FUNGSI CHAT
  // ==========================================

  static Future<Map<String, dynamic>> getChats(
    String userId,
    String friendId,
  ) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/chats/$userId/$friendId'));

      if (res.statusCode == 200) return jsonDecode(res.body);

      return {
        'messages': [],
        'canChat': true,
        'dailyCount': 0,
      };
    } catch (e) {
      return {
        'messages': [],
        'canChat': true,
        'dailyCount': 0,
      };
    }
  }

  static Future<bool> sendMessage(
    String senderId,
    String receiverId,
    String text,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/chats/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderId': senderId,
          'receiverId': receiverId,
          'text': text,
        }),
      );

      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<dynamic>> getUserProgress(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/progress/user/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }

      return [];
    } catch (e) {
      print('GET USER PROGRESS ERROR: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getAdminUserStats() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/users/admin/stats'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? {};
    }

    return {};
  } catch (e) {
    print('GET ADMIN USER STATS ERROR: $e');
    return {};
  }
}

static Future<List<dynamic>> getAdminUserMaterials(String userId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/users/admin/$userId/materials'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    }

    return [];
  } catch (e) {
    print('GET ADMIN USER MATERIALS ERROR: $e');
    return [];
  }
}

static Future<List<dynamic>> getAdminUserQuizzes(String userId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/users/admin/$userId/quizzes'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    }

    return [];
  } catch (e) {
    print('GET ADMIN USER QUIZZES ERROR: $e');
    return [];
  }
}

static Future<List<dynamic>> getAdminUserAchievements(String userId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/users/admin/$userId/achievements'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    }

    return [];
  } catch (e) {
    print('GET ADMIN USER ACHIEVEMENTS ERROR: $e');
    return [];
  }
}

}
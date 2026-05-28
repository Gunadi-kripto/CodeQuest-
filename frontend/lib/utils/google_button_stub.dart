// lib/utils/google_button_stub.dart
// Dipakai di MOBILE (Android/iOS) — tidak ada import google_sign_in_web

import 'package:flutter/material.dart';

Widget buildGoogleWebButton({required Function(String idToken) onSuccess}) {
  // Tidak pernah dirender di mobile karena _buildGoogleButton()
  // sudah return tombol ElevatedButton duluan via kIsWeb check
  return const SizedBox.shrink();
}
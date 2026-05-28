// lib/utils/google_button_web.dart
// Dipakai di WEB saja — google_sign_in ^6.x

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as web_only;
import 'package:google_sign_in_web/google_sign_in_web.dart';

// Instance khusus web — dibuat sekali
final _webGoogleSignIn = GoogleSignIn(
  clientId: '946414111075-tb595grrhu28td3ss6a7o3p925jcpvt7.apps.googleusercontent.com',
  scopes: ['email', 'profile'],
);

bool _isListening = false;

Widget buildGoogleWebButton({required Function(String idToken) onSuccess}) {
  // Daftarkan listener SEKALI saja
  if (!_isListening) {
    _isListening = true;
    _webGoogleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) async {
      if (account != null) {
        try {
          final GoogleSignInAuthentication auth = await account.authentication;
          final String? idToken = auth.idToken;
          if (idToken != null && idToken.isNotEmpty) {
            onSuccess(idToken);
          }
        } catch (e) {
          debugPrint('Error getting idToken: $e');
        }
      }
    });
  }

  // Render tombol resmi Google
  return web_only.renderButton(
    configuration: GSIButtonConfiguration(
      type: GSIButtonType.standard,
      theme: GSIButtonTheme.outline,
      size: GSIButtonSize.large,
      text: GSIButtonText.signinWith,
      shape: GSIButtonShape.rectangular,
    ),
  );
}
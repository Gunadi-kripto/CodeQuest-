// lib/utils/google_button_helper.dart
// File ini sebagai ROUTER conditional import
// - Di web  → pakai google_button_web.dart
// - Di mobile → pakai google_button_stub.dart

export 'google_button_stub.dart'
    if (dart.library.html) 'google_button_web.dart';
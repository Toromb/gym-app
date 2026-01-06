import 'dart:io';
import 'package:flutter/foundation.dart';

// Use 10.0.2.2 for Android emulator, localhost for web/iOS/Windows
String get baseUrl {
  if (kReleaseMode) {
    return 'https://tugymflow.com/api';
  }

  if (kIsWeb) {
    if (kDebugMode) {
      return 'http://127.0.0.1:3000';
    }
    // Use the current window origin to ensure absolute URL
    // This avoids issues with relative URIs in some HTTP clients
    final String origin = Uri.base.origin;
    return '$origin/api';
  }
  // Allow injection via --dart-define=API_URL=...
  const apiUrl = String.fromEnvironment('API_URL');
  if (apiUrl.isNotEmpty) {
    return apiUrl;
  }

  if (Platform.isAndroid) {
      return 'http://10.0.2.2:3001';
  }
  return 'http://localhost:3001';
}

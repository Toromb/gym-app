import 'dart:io';
import 'package:flutter/foundation.dart';

// Use 10.0.2.2 for Android emulator, localhost for web/iOS/Windows
String get baseUrl {
  if (kIsWeb) {
    if (kDebugMode) {
      return 'http://localhost:3000';
    }
    // In production (Web), use relative path to let Nginx proxy handle it.
    // This assumes the app is served from the same domain/port as the API (via Nginx reverse proxy).
    // Returning empty string means requests to '/users' become 'CurrentDomain/users'.
    // If we want 'CurrentDomain/api/users', and Nginx rewrites /api/, we should check that.
    // Nginx config: rewrite ^/api/(.*) /$1 break;
    // So if I send request to '/api/users', Nginx sends '/users' to backend.
    return '/api';
  }
  if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
  }
  return 'http://localhost:3000';
}

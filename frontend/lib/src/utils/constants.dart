import 'dart:io';
import 'package:flutter/foundation.dart';

// Use 10.0.2.2 for Android emulator, localhost for web/iOS/Windows
String get baseUrl {
  if (kIsWeb) {
    if (kDebugMode) {
      return 'http://localhost:3000';
    }
    // Use the current window origin to ensure absolute URL
    // This avoids issues with relative URIs in some HTTP clients
    final String origin = Uri.base.origin;
    return '$origin/api';
  }
  if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
  }
  return 'http://localhost:3000';
}

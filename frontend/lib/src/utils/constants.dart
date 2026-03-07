
import 'package:flutter/foundation.dart';

// Use 10.0.2.2 for Android emulator, localhost for web/iOS/Windows
String get baseUrl {
  // return 'https://tugymflow.com/api'; // FORCED FOR PRODUCTION DEBUGGING
  if (kReleaseMode) {
    return 'https://tugymflow.com/api';
  }

  if (kIsWeb) {
    if (kDebugMode) {
      return 'http://localhost:3001';
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

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3001'; // Changed default to 3001 to match backend
  }
  return 'http://localhost:3001';
}

String resolveImageUrl(String? relativeUrl) {
  if (relativeUrl == null || relativeUrl.isEmpty) return '';
  if (relativeUrl.startsWith('http')) return relativeUrl;
  
  String base = baseUrl;
  // If baseUrl ends with /api, remove it to get the root domain where images are served
  if (base.endsWith('/api')) {
      base = base.substring(0, base.length - 4);
  }
  
  // Clean up slashes
  if (base.endsWith('/')) base = base.substring(0, base.length - 1);
  if (relativeUrl.startsWith('/')) relativeUrl = relativeUrl.substring(1);

  return '$base/$relativeUrl';
}

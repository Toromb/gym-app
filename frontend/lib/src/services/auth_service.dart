import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  String get baseUrl {
    if (kIsWeb) {
      if (kReleaseMode) return '/api';
      return 'http://localhost:3000';
    }
    // Mobile/Simulator
    return 'http://10.0.2.2:3000';
  }

  Future<dynamic> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        await _storage.write(key: 'jwt', value: data['access_token']);
        return data; // Success Map
      }
      
      // Return error message if available
      return data['message'] ?? 'Login failed'; 
    } catch (e) {
      debugPrint('Login error: $e');
      return 'Connection error';
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt');
  }
}

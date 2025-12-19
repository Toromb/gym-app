import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  Future<void> _saveToken(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt', token);
    } else {
      await _storage.write(key: 'jwt', value: token);
    }
  }

  Future<String?> _readToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('jwt');
    } else {
      return await _storage.read(key: 'jwt');
    }
  }

  Future<void> _deleteToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt');
    } else {
      await _storage.delete(key: 'jwt');
    }
  }

  Future<dynamic> login(String email, String password) async {
    final url = '$baseUrl/auth/login';
    debugPrint('AuthService: Requesting $url');
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      debugPrint('AuthService: Response Code ${response.statusCode}');

      if (response.body.isEmpty) {
         return 'Empty response from server';
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (data['access_token'] == null) {
           return 'No access token in response';
        }
        await _saveToken(data['access_token']);
        return data; // Success Map
      }
      
      if (response.statusCode == 401) {
        return 'invalidCredentials';
      }
      
      return data['message'] ?? 'Login failed'; 
    } catch (e, stack) {
      debugPrint('Login error: $e');
      debugPrint('$stack');
      return 'Connection error';
    }
  }

  Future<void> logout() async {
    await _deleteToken();
  }

  Future<String?> getToken() async {
    return await _readToken();
  }
}

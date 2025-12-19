import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

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
        await _storage.write(key: 'jwt', value: data['access_token']);
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
    await _storage.delete(key: 'jwt');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt');
  }
}

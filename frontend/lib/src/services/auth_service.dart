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
  Future<String?> activateAccount(String token, String password) async {
    final url = '$baseUrl/auth/activate-account';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token, 'password': password}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) return null;
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Activation failed';
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String?> resetPassword(String token, String password) async {
    final url = '$baseUrl/auth/reset-password';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token, 'password': password}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) return null;
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Reset failed';
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String?> generateActivationLink(String userId) async {
     final token = await _readToken();
     if (token == null) return null;

     final url = '$baseUrl/auth/generate-activation-link';
     try {
       final response = await http.post(
         Uri.parse(url),
         headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
         },
         body: jsonEncode({'userId': userId}),
       );
       if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          return data['token'];
       }
       return null;
     } catch (e) {
       debugPrint('Error generating link: $e');
       return null;
     }
  }

  Future<String?> generateResetLink(String userId) async {
     final token = await _readToken();
     if (token == null) return null;

     final url = '$baseUrl/auth/generate-reset-link';
     try {
       final response = await http.post(
         Uri.parse(url),
         headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
         },
         body: jsonEncode({'userId': userId}),
       );
       if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          return data['token'];
       }
       return null;
     } catch (e) {
       debugPrint('Error generating reset link: $e');
       return null;
     }
  }
}

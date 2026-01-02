import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'api_exceptions.dart';

class AuthService {
  final ApiClient _api = ApiClient();
  final _storage = const FlutterSecureStorage();

  Future<void> _saveToken(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt', token);
    } else {
      await _storage.write(key: 'jwt', value: token);
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
    try {
      final response = await _api.post('/auth/login', {
          'email': email, 
          'password': password
      });

      // Response is parsed JSON (Map)
      if (response == null || response is! Map) {
         return 'Empty or invalid response from server';
      }

      final token = response['access_token'];
      if (token == null) {
          return 'No access token in response';
      }
      
      await _saveToken(token);
      return response;

    } on UnauthorizedException {
      return 'invalidCredentials';
    } on ApiException catch (e) {
       return e.message;
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<void> logout() async {
    await _deleteToken();
  }

  Future<String?> getToken() async {
    if (kIsWeb) {
       final prefs = await SharedPreferences.getInstance();
       return prefs.getString('jwt');
    }
    return await _storage.read(key: 'jwt');
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

  Future<String?> generateActivationToken(String userId) async {
     final token = await getToken();
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

  Future<String?> generateResetToken(String userId) async {
     final token = await getToken();
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

  String getActivationUrl(String token) {
    String origin = Uri.base.origin;
    // Fallback for non-web or weird environments, though typically Uri.base.origin is safe in Flutter Web
    if (origin.isEmpty || origin == 'null') origin = 'http://localhost:3000';
    return '$origin/#/activate-account?token=$token';
  }

  String getResetUrl(String token) {
    String origin = Uri.base.origin;
    if (origin.isEmpty || origin == 'null') origin = 'http://localhost:3000';
    return '$origin/#/reset-password?token=$token';
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final token = await getToken();
    if (token == null) throw ApiException('No authenticated session');

    final response = await http.post(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw ApiException(body['message'] ?? 'Error changing password');
    }
  }
}

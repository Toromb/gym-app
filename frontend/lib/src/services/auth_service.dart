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
}

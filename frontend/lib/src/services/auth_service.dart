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

  Future<void> _saveTokens(String accessToken, String? refreshToken) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt', accessToken);
      if (refreshToken != null) await prefs.setString('refresh_token', refreshToken);
    } else {
      await _storage.write(key: 'jwt', value: accessToken);
      if (refreshToken != null) await _storage.write(key: 'refresh_token', value: refreshToken);
    }
  }

  Future<void> _deleteTokens() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt');
      await prefs.remove('refresh_token');
    } else {
      await _storage.delete(key: 'jwt');
      await _storage.delete(key: 'refresh_token');
    }
  }

  Future<dynamic> login(String email, String password) async {
    try {
      final response = await _api.post('/auth/login', {
          'email': email, 
          'password': password,
          'platform': kIsWeb ? 'web' : 'mobile'
      });

      // Response is parsed JSON (Map)
      if (response == null || response is! Map) {
         return 'Empty or invalid response from server';
      }

      final token = response['access_token'];
      final refreshToken = response['refresh_token'];
      if (token == null) {
          return 'No access token in response';
      }
      
      await _saveTokens(token, refreshToken);
      return response;

    } on UnauthorizedException {
      return 'invalidCredentials';
    } on ApiException catch (e) {
       return e.message;
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<dynamic> loginWithGoogle(String idToken, [String? inviteToken]) async {
    try {
      final response = await _api.post('/auth/google', {
          'idToken': idToken, 
          if (inviteToken != null) 'inviteToken': inviteToken,
          'platform': kIsWeb ? 'web' : 'mobile'
      });

      if (response == null || response is! Map) {
         return 'Invalid response from server';
      }

      final token = response['access_token'];
      final refreshToken = response['refresh_token'];
      if (token == null) {
          return 'No access token in response';
      }
      
      await _saveTokens(token, refreshToken);
      return response;
    } on BadRequestException catch (e) { 
        return e.message; // e.g. "El usuario no pertenece a ningún gimnasio..."
    } on UnauthorizedException {
      return 'Session expired or invalid token';
    } on ApiException catch (e) {
       return e.message;
    } catch (e) {
      return 'Error: $e';
    }

  }

  Future<dynamic> loginWithApple({
    required String identityToken,
    String? inviteToken,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final response = await _api.post('/auth/apple', {
        'identityToken': identityToken,
        if (inviteToken != null) 'inviteToken': inviteToken,
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        'platform': kIsWeb ? 'web' : 'mobile'
      });

      if (response == null || response is! Map) {
        return 'Invalid response from server';
      }

      final token = response['access_token'];
      final refreshToken = response['refresh_token'];
      if (token == null) {
        return 'No access token in response';
      }

      await _saveTokens(token, refreshToken);
      return response;
    } on BadRequestException catch (e) {
      return e.message;
    } on UnauthorizedException {
      return 'Session expired or invalid token';
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<void> logout() async {
    final rToken = await getRefreshToken();
    try {
      if (rToken != null) {
        // Optimistically tell the server to revoke it. Ignore errors.
        await _api.post('/auth/logout', {'refreshToken': rToken});
      } else {
        await _api.post('/auth/logout', {});
      }
    } catch (_) {}
    
    await _deleteTokens();
  }

  Future<String?> getToken() async {
    if (kIsWeb) {
       final prefs = await SharedPreferences.getInstance();
       return prefs.getString('jwt');
    }
    return await _storage.read(key: 'jwt');
  }

  Future<String?> getRefreshToken() async {
    if (kIsWeb) {
       final prefs = await SharedPreferences.getInstance();
       return prefs.getString('refresh_token');
    }
    return await _storage.read(key: 'refresh_token');
  }

  Future<bool> refreshToken() async {
    final rToken = await getRefreshToken();
    if (rToken == null) return false;

    try {
      final response = await _api.post('/auth/refresh', {'refreshToken': rToken});
      if (response != null && response['access_token'] != null) {
        await _saveTokens(response['access_token'], response['refresh_token']);
        return true;
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
    }
    // If refresh failed, ensure we clear state
    await _deleteTokens();
    return false;
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
     try {
       final response = await _api.post('/auth/generate-activation-link', {'userId': userId});
       if (response != null && response['token'] != null) {
          return response['token'];
       }
       return null;
     } catch (e) {
       debugPrint('Error generating link: $e');
       return null;
     }
  }

  Future<String?> generateResetToken(String userId) async {
     try {
       final response = await _api.post('/auth/generate-reset-link', {'userId': userId});
       if (response != null && response['token'] != null) {
          return response['token'];
       }
       return null;
     } catch (e) {
       debugPrint('Error generating reset link: $e');
       return null;
     }
  }

  String getActivationUrl(String token) {
    String origin;
    if (kIsWeb) {
       origin = Uri.base.origin;
    } else {
       // For Android/iOS app, we want to point to the Web App for activation
       origin = 'https://tugymflow.com';
    }
    
    // Fallback/Localhost handling
    if (origin.isEmpty || origin == 'null') {
        origin = kReleaseMode ? 'https://tugymflow.com' : 'http://localhost:3000';
    }
    
    return '$origin/activate-account?token=$token';
  }

  String getResetUrl(String token) {
    String origin;
    if (kIsWeb) {
       origin = Uri.base.origin;
    } else {
       origin = 'https://tugymflow.com';
    }

    if (origin.isEmpty || origin == 'null') {
         origin = kReleaseMode ? 'https://tugymflow.com' : 'http://localhost:3000';
    }
    return '$origin/reset-password?token=$token';
  }

  String getInviteUrl(String token) {
    String origin;
    if (kIsWeb) {
       origin = Uri.base.origin;
    } else {
       origin = 'https://tugymflow.com';
    }
    
    if (origin.isEmpty || origin == 'null') {
         origin = kReleaseMode ? 'https://tugymflow.com' : 'http://localhost:3000';
    }
    return '$origin/invite?token=$token';
  }

  Future<String?> generateInviteLink(String gymId, {String role = 'ALUMNO'}) async {
     try {
       final response = await _api.post('/auth/generate-invite-link', {
           'gymId': gymId, 
           'role': role
       });
       if (response != null && response['token'] != null) {
          return response['token'];
       }
       throw ApiException('Server error: Token no devuelto');
     } catch (e) {
       debugPrint('Exception in generateInviteLink: $e');
       if (e is ApiException) rethrow;
       throw ApiException(e.toString());
     }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
        await _api.post('/auth/change-password', {
            'currentPassword': currentPassword,
            'newPassword': newPassword,
        });
    } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException('Error changing password: $e');
    }
  }
}

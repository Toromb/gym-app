import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _token;
  User? _user;
  final AuthService _authService = AuthService();

  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  User? get user => _user;
  String? get role => _user?.role;

  Future<String?> login(String email, String password) async {
    final result = await _authService.login(email, password);
    
    if (result is Map<String, dynamic>) {
      _token = result['access_token'];
      if (result['user'] != null) {
        _user = User.fromJson(result['user']);
      }
      _isAuthenticated = true;
      notifyListeners();
      return null; // Success (no error)
    } else {
       return result.toString(); // Error message
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    _token = null;
    _user = null;
    notifyListeners();
  }
}

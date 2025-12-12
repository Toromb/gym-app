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

  Future<bool> login(String email, String password) async {
    final data = await _authService.login(email, password);
    if (data != null) {
      _token = data['access_token'];
      if (data['user'] != null) {
        _user = User.fromJson(data['user']);
      }
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    _token = null;
    _user = null;
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/gym_model.dart';
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

  // Gym Customization
  String? get currentGymLogo => _user?.gym?.logoUrl;
  String? get currentGymPrimaryColor => _user?.gym?.primaryColor;
  String? get currentGymSecondaryColor => _user?.gym?.secondaryColor;
  String? get currentGymWelcomeMessage => _user?.gym?.welcomeMessage;
  String? get currentGymName => _user?.gym?.businessName ?? _user?.gymName;

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
  void updateGym(Gym updatedGym) {
     if (_user != null) {
        _user = _user!.copyWith(gym: updatedGym);
        notifyListeners();
     }
  }
}

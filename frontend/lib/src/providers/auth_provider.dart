import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/gym_model.dart';
import '../services/auth_service.dart';
import '../services/onboarding_service.dart';
import '../services/user_service.dart';
import '../services/api_client.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _token;
  User? _user;
  final AuthService _authService = AuthService();
  // We use ApiClient singleton here
  final OnboardingService _onboardingService = OnboardingService(ApiClient());
  final UserService _userService = UserService();

  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  User? get user => _user;
  String? get role => _user?.role;
  
  bool _isOnboarded = true; // Default to true to assume done until checked
  bool get isOnboarded => _isOnboarded;

  // Gym Customization
  String? get currentGymLogo => _user?.gym?.logoUrl;
  String? get currentGymPrimaryColor => _user?.gym?.primaryColor;
  String? get currentGymSecondaryColor => _user?.gym?.secondaryColor;
  String? get currentGymWelcomeMessage => _user?.gym?.welcomeMessage;
  String? get currentGymName => _user?.gym?.businessName ?? _user?.gymName;

  Future<String?> login(String email, String password) async {
    final result = await _authService.login(email, password);
    
    if (result is Map<String, dynamic>) {
      print('AuthProvider login result: $result'); // Debug log
      _token = result['access_token'];
      if (result['user'] != null) {
        _user = User.fromJson(result['user']);
      } else {
        print('AuthProvider Error: User object is NULL in login response');
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
  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _authService.changePassword(currentPassword, newPassword);
  }

  void updateGym(Gym updatedGym) {
     if (_user != null) {
        _user = _user!.copyWith(gym: updatedGym);
        notifyListeners();
     }
  }

  Future<void> checkOnboardingStatus() async {
      if (_user == null) return;
      // Only students need onboarding check? Or everyone?
      // Requirement: "Student begins session for first time".
      if (_user!.role == 'alumno') {
          _isOnboarded = await _onboardingService.getMyStatus();
          print('AuthProvider: Onboarding status for ${_user!.email}: $_isOnboarded');
          notifyListeners();
      } else {
          _isOnboarded = true; // Teachers/Admins don't need onboarding
      }
  }

  // Force local update (e.g. after submitting form)
  void setOnboarded(bool value) {
      _isOnboarded = value;
      notifyListeners();
  }

  Future<void> refreshUser() async {
      final updatedUser = await _userService.getProfile();
      if (updatedUser != null) {
          _user = updatedUser;
          notifyListeners();
      }
  }
}

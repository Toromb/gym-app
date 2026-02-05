import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/gym_model.dart';
import '../services/auth_service.dart';
import '../services/onboarding_service.dart';
import '../services/user_service.dart';
import '../services/api_client.dart';
import '../services/google_auth_service.dart';

enum AuthStatus { unknown, unauthenticated, authenticated, loading }

class AuthProvider with ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  AuthStatus get status => _status;

  bool _isAuthenticated = false;
  String? _token;
  User? _user;
  final AuthService _authService = AuthService();
  final GoogleAuthService _googleAuthService = GoogleAuthService();
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
    return _handleAuthResult(result);
  }

  Future<String?> loginWithGoogle() async {
    try {
      // 1. Native Google Sign-In
      final googleUser = await _googleAuthService.signIn();
      if (googleUser == null) return 'Inicio de sesión cancelado';

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
          return 'Error: No se pudo obtener el ID Token de Google';
      }

      // 2. Backend Validation & Login
      final result = await _authService.loginWithGoogle(idToken);
      
      // 3. Handle Result (Success or Error Message)
      return _handleAuthResult(result);

    } catch (e) {
      return 'Error iniciando sesión con Google: $e';
    }
  }

  Future<String?> _handleAuthResult(dynamic result) async {
    if (result is Map<String, dynamic>) {
      _token = result['access_token'];
      if (result['user'] != null) {
        _user = User.fromJson(result['user']);
      } else {
        debugPrint('AuthProvider Error: User object is NULL in login response');
      }
      _isAuthenticated = true;
      await checkOnboardingStatus(); // Ensure status is checked on explicit login
      notifyListeners();
      return null; // Success (no error)
    } else {
       return result.toString(); // Error message
    }
  }

  Future<void> tryAutoLogin() async {
    _status = AuthStatus.loading;
    notifyListeners();

    final token = await _authService.getToken();
    if (token == null) {
      _status = AuthStatus.unauthenticated;
      _isAuthenticated = false;
      notifyListeners();
      return;
    }

    try {
      // Validate token by fetching profile
      final user = await _userService.getProfile();
      if (user != null) {
        _token = token;
        _user = user;
        _isAuthenticated = true;
        _status = AuthStatus.authenticated;
        
        // Check onboarding if needed
        await checkOnboardingStatus(); 
      } else {
        // Token invalid or user not found
        _status = AuthStatus.unauthenticated;
        _isAuthenticated = false;
        await _authService.logout(); // Clear invalid token
      }
    } catch (e) {
      debugPrint('AutoLogin Error: $e');
      _status = AuthStatus.unauthenticated;
      _isAuthenticated = false;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    await _googleAuthService.signOut(); // Ensure Google session is also cleared
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
      if (_user!.role == 'alumno') {
          _isOnboarded = await _onboardingService.getMyStatus();
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

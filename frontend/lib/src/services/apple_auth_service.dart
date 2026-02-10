import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';

class AppleAuthService {
  Future<AuthorizationCredentialAppleID?> signIn() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      
      return credential;
    } catch (e) {
      debugPrint('Apple Sign In Error: $e');
      return null;
    }
  }
  
  // Apple handles session state differently, usually we just sign in again or use the backend token validity.
  // There is no explicit "signOut" for Apple Sign In on the device like Google.
}

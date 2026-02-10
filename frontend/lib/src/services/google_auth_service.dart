import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Optional: clientId for Web
    clientId: '27743341865-7b8mslthc15e40gfqrai2dks9u0vgmut.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  Future<GoogleSignInAccount?> signIn() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<GoogleSignInAuthentication?> getAuthentication() async {
    if (_googleSignIn.currentUser == null) return null;
    return await _googleSignIn.currentUser!.authentication;
  }
}

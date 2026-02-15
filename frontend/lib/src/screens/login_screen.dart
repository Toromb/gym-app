import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../localization/app_localizations.dart';

import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  final Map<String, String>? queryParams; // Receive parameters from deep links/web

  const LoginScreen({super.key, this.queryParams});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  String? _inviteToken;

  @override
  void initState() {
    super.initState();
    // Parse invite token from query parameters if available
    if (widget.queryParams != null && widget.queryParams!.containsKey('token')) {
       _inviteToken = widget.queryParams!['token'];
       debugPrint('LoginScreen: Invite Token detected: $_inviteToken');
    }
  }

  Future<void> _performLogin() async {
      setState(() => _isLoading = true);
      final errorMsg = await context.read<AuthProvider>().login(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
      
      if (!mounted) return;
      
      if (errorMsg == null) {
        // Success
        await _onLoginSuccess();
      } else {
          setState(() {
            _isLoading = false;
             // Basic error mapping
            if (errorMsg.contains('invalidCredentials')) {
               _errorMessage = 'Email o contraseña incorrectos';
            } else {
               _errorMessage = errorMsg.replaceAll('Exception:', '').trim();
            }
          });
      }
  }

  Future<void> _performGoogleLogin() async {
      setState(() => _isLoading = true);
      
      // Trigger Google Login with Invite Token
      final errorMsg = await context.read<AuthProvider>().loginWithGoogle(inviteToken: _inviteToken);
      
      if (!mounted) return;

      if (errorMsg == null) {
        await _onLoginSuccess();
      } else {
          if (errorMsg == 'Google Sign-In canceled') {
             setState(() => _isLoading = false);
             return;
          }
          setState(() {
            _isLoading = false;
            _errorMessage = errorMsg;
          });
      }
  }

  Future<void> _performAppleLogin() async {
    setState(() => _isLoading = true);

    final errorMsg = await context.read<AuthProvider>().loginWithApple(inviteToken: _inviteToken);

    if (!mounted) return;

    if (errorMsg == null) {
      await _onLoginSuccess();
    } else {
      if (errorMsg == 'Inicio de sesión cancelado') {
         setState(() => _isLoading = false);
         return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = errorMsg;
      });
    }
  }

  Future<void> _onLoginSuccess() async {
      // Clear user provider state to ensure fresh data if needed, though AuthProvider usually handles this.
      // context.read<UserProvider>().clear(); 
      // Navigate to Home
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false
      );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // If invite token is present, show a banner
    final bool hasInvite = _inviteToken != null;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Hero(
                  tag: 'logo',
                  child: Image.asset(
                    'assets/images/logo_gym_app.png',
                    height: 120,
                  ),
                ),
                const SizedBox(height: 40),
                if (hasInvite)
                   Container(
                     padding: const EdgeInsets.all(12),
                     margin: const EdgeInsets.only(bottom: 24),
                     decoration: BoxDecoration(
                       color: Colors.blue.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(8),
                       border: Border.all(color: Colors.blue),
                     ),
                     child: const Row(
                       children: [
                         Icon(Icons.mark_email_read, color: Colors.blue),
                         SizedBox(width: 12),
                         Expanded(child: Text("Has recibido una invitación. Inicia sesión para aceptarla.", style: TextStyle(color: Colors.blue))),
                       ],
                     ),
                   ),

                const Text(
                  'Bienvenido',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Inicia sesión para continuar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 48),
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                       const url = 'https://tugymflow.com/#/reset-password-request'; 
                       launchUrl(Uri.parse(url));
                    },
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Login Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _performLogin,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Iniciar Sesión', style: TextStyle(fontSize: 16)),
                  ),
                ),

                const SizedBox(height: 24),
                
                // OR Divider
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('O continuar con'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),

                // Social Login Buttons
                if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) ...[
                   Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _performGoogleLogin,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset('assets/images/google_logo.png', height: 24),
                              const SizedBox(width: 8),
                              const Text('Google'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SignInWithAppleButton(
                          onPressed: _performAppleLogin,
                          text: "Apple", 
                          style: SignInWithAppleButtonStyle.white,
                          height: 48, // Match standard button height
                          borderRadius: const BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                    ],
                   ),
                ] else ...[
                  // Google Login Button (Full Width for Android/Web)
                  OutlinedButton(
                    onPressed: _isLoading ? null : _performGoogleLogin,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/google_logo.png', height: 24),
                        const SizedBox(width: 12),
                        const Text('Continuar con Google', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Text(
                      "¿No tienes una cuenta? ",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: () {
                         showDialog(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('Registro'),
                              content: const Text('El registro de nuevos usuarios debe ser realizado por un administrador.'),
                              actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
                            )
                         );
                      },
                      child: const Text('Regístrate', style: TextStyle(fontWeight: FontWeight.bold)),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

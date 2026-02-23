import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart' as apple;
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

  Widget _buildSocialButtons() {
    // Check if we should show Apple Sign In (iOS only generally, or if configured for web but here we follow previous logic)
    final bool showApple = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

    if (!showApple) {
      return OutlinedButton(
        onPressed: _isLoading ? null : _performGoogleLogin,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: Colors.grey.withOpacity(0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/google_logo.png', height: 24),
            const SizedBox(width: 12),
             Text(
                'Continuar con Google',
                style: TextStyle(
                    fontSize: 16,
                    // Use contrasting color based on theme context (which is inside the bottom sheet)
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87
                )
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : _performGoogleLogin,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: Colors.grey.withOpacity(0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/google_logo.png', height: 24),
                const SizedBox(width: 8),
                 Text(
                    'Google',
                    style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87
                    )
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : _performAppleLogin,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: Colors.grey.withOpacity(0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.apple,
                  size: 28, // Match the visual weight of the google logo (24px image)
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                ),
                const SizedBox(width: 8),
                 Text(
                    'Apple',
                    style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87
                    )
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // If invite token is present, show a banner
    final bool hasInvite = _inviteToken != null;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Overlay to improve text readability (Gradient or solid)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          // Content
          Column(
            children: [
              // Logo and Welcome Text Area (Top)
              Expanded(
                flex: 4, // Takes up ~40% of space
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Hero(
                        tag: 'logo',
                        child: Image.asset(
                          'assets/images/tugymflow_logo.png',
                          height: 80, 
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Bienvenido',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tu Gym Flow',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Login Form Area (Bottom Sheet)
              Expanded(
                flex: 6, // Takes up ~60% of space
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),
                          Text(
                            'Iniciar Sesión',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Por favor ingresa tus credenciales para continuar',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.withOpacity(0.5)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          if (_inviteToken != null)
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

                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: 'Correo electrónico',
                              prefixIcon: const Icon(Icons.email_outlined),
                              filled: true,
                              fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: 'Contraseña',
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
                              filled: true,
                              fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          
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
                            height: 54, // Slightly taller
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _performLogin,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 2,
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              child: _isLoading
                                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('Ingresar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward, size: 20),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // OR Divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey[400])),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('O continuar con', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              ),
                              Expanded(child: Divider(color: Colors.grey[400])),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Social Login Buttons
                           _buildSocialButtons(),

                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '¿No tienes una cuenta? ',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              Text(
                                "Habla con tu gimnasio",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                          // Extra padding for bottom safe area if needed
                          SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 0 : 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
          
          // Theme Toggle (Absolute Positioned)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: IconButton(
              onPressed: () => themeProvider.toggleTheme(!isDark),
              icon: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                color: Colors.white, // Always white on the background image
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class RegisterWithInviteScreen extends StatefulWidget {
  final String inviteToken;

  const RegisterWithInviteScreen({super.key, required this.inviteToken});

  @override
  _RegisterWithInviteScreenState createState() => _RegisterWithInviteScreenState();
}

class _RegisterWithInviteScreenState extends State<RegisterWithInviteScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  String? _gymName;
  bool _isValidatingToken = true;

  @override
  void initState() {
    super.initState();
    _validateToken();
  }

  Future<void> _validateToken() async {
    // Ideally, we could have an endpoint to just validate and return Gym Name: GET /auth/validate-invite?token=...
    // For MVP, we decode the JWT locally or just let the registration fail.
    // However, since we want to show the Gym Name in the UI, we should decode the payload.
    // JWT has 3 parts separated by dots.
    try {
      final parts = widget.inviteToken.split('.');
      if (parts.length != 3) throw Exception('Invalid token format');
      
      // We need just the payload to see what's inside (often not encrypted, just base64 encoded)
      // Since it's signed by backend, we trust it until submission.
      
      setState(() {
         // Fallback if we cannot parse it easily in flutter without another package
         _gymName = "Tu Gimnasio"; 
         _isValidatingToken = false;
      });
      
    } catch (e) {
      setState(() {
        _errorMessage = 'El enlace de invitación es inválido o está corrupto.';
        _isValidatingToken = false;
      });
    }
  }

  Future<void> _performRegistration() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty || _firstNameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Por favor completa todos los campos requeridos.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ApiClient();
      final response = await api.post('/auth/register-with-invite', {
        'inviteToken': widget.inviteToken,
        'user': {
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'provider': 'LOCAL',
        }
      });

      // Login succeeds returning tokens
      if (response != null && response['access_token'] != null) {
         // We might trigger logic in AuthProvider or just navigate to Login to force a fresh state
         // Better UX: Show success dialog and pop back to LoginScreen which will handle the token if mapped
         
         if (!mounted) return;
         
         // Using the auth provider to handle the manually returned token could be complex if we bypass login,
         // so let's just alert and pop to login so the user logs in with their new credentials.
         await showDialog(
           context: context,
           builder: (ctx) => AlertDialog(
             title: const Text('¡Registro Exitoso!'),
             content: const Text('Tu cuenta ha sido creada y vinculada al gimnasio. Por favor inicia sesión.'),
             actions: [
               TextButton(
                 onPressed: () {
                   Navigator.of(ctx).pop(); // close dialog
                   Navigator.of(context).pop(); // close register
                 }, 
                 child: const Text('Ir al Login')
               )
             ],
           )
         );
      }
    } catch (e) {
       setState(() {
         _errorMessage = e.toString().contains('Exception:') 
             ? e.toString().replaceAll('Exception:', '').trim() 
             : 'Ocurrió un error en el registro.';
       });
    } finally {
       if (mounted) {
         setState(() => _isLoading = false);
       }
    }
  }

  Future<void> _performGoogleLogin() async {
      setState(() => _isLoading = true);
      
      final errorMsg = await context.read<AuthProvider>().loginWithGoogle(inviteToken: widget.inviteToken);
      
      if (!mounted) return;

      if (errorMsg == null) {
        Navigator.of(context).pop(); // Should redirect home from AuthProvider state change
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

    final errorMsg = await context.read<AuthProvider>().loginWithApple(inviteToken: widget.inviteToken);

    if (!mounted) return;

    if (errorMsg == null) {
      Navigator.of(context).pop();
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

  Widget _buildSocialButtons() {
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
                 Text('Google', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
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
                Icon(Icons.apple, size: 28, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                const SizedBox(width: 8),
                 Text('Apple', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Completar Registro"),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isValidatingToken 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.stars_rounded, size: 48, color: Theme.of(context).primaryColor),
                      const SizedBox(height: 12),
                      const Text(
                        "¡Has sido invitado!",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Estás a un paso de unirte a $_gymName.",
                         style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                         textAlign: TextAlign.center,
                      )
                    ],
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

                TextField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    hintText: 'Nombre',
                    prefixIcon: const Icon(Icons.person_outline),
                    filled: true,
                    fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    hintText: 'Apellido',
                    prefixIcon: const Icon(Icons.person_outline),
                    filled: true,
                    fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                     hintText: 'Correo electrónico',
                     prefixIcon: const Icon(Icons.email_outlined),
                     filled: true,
                     fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Contraseña (mínimo 6 caracteres)',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                
                const SizedBox(height: 32),

                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _performRegistration,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('Completar Registro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[400])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('O continua con', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ),
                    Expanded(child: Divider(color: Colors.grey[400])),
                  ],
                ),
                const SizedBox(height: 24),
                
                _buildSocialButtons(),
                
                const SizedBox(height: 40),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Ya tengo cuenta, quiero iniciar sesión"),
                )
              ],
            ),
        ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../localization/app_localizations.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Consumer<ThemeProvider>(
            builder: (_, theme, __) => IconButton(
              icon: Icon(theme.isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => theme.toggleTheme(!theme.isDarkMode),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface, // Use theme surface instead of fixed grey
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.fitness_center, size: 72, color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.welcome,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900, // Extra Bold
                          color: Theme.of(context).colorScheme.onSurface, // Theme aware
                          fontSize: 32, // Larger
                        ),
                  ),
                  Text(AppLocalizations.of(context)!.loginTitle, style: const TextStyle(color: Colors.grey)), // 'Sign in to continue' -> 'Iniciar Sesión' text below welcome
                  const SizedBox(height: 32),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.emailLabel,
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.passwordLabel,
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        showDialog(
                          context: context, 
                          builder: (c) => AlertDialog(
                            title: const Text('Recuperar Contraseña'),
                            content: const Text('Si olvidaste tu contraseña, por favor contacta al administrador del gimnasio para que genere un enlace de recuperación.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cerrar')),
                            ],
                          )
                        );
                      },
                      child: const Text('¿Olvidaste tu contraseña?'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                          onPressed: () async {
                              setState(() => _isLoading = true);
                              final errorMsg = await context.read<AuthProvider>().login(
                                    _emailController.text,
                                    _passwordController.text,
                                  );
                              setState(() => _isLoading = false);
                              if (errorMsg == null && mounted) {
                                // Clear stale data
                                context.read<UserProvider>().clear();
                                
                                // Explicitly navigate to HomeScreen
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                                  (route) => false
                                );
                              } else if (mounted) {
                                  final isInvalidCreds = errorMsg == 'invalidCredentials';
                                  final displayMsg = isInvalidCreds 
                                      ? AppLocalizations.of(context)!.invalidCredentials
                                      : (errorMsg ?? '${AppLocalizations.of(context)!.error}: ${AppLocalizations.of(context)!.invalidEmail}');

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(displayMsg),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: Text(AppLocalizations.of(context)!.loginButton, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

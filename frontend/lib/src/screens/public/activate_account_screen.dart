import 'package:flutter/material.dart';
import 'package:gym_app/src/services/auth_service.dart';
// import 'package:gym_app/src/widgets/responsive_layout.dart'; // Removed missing file
// import 'package:go_router/go_router.dart'; // Removed

class ActivateAccountScreen extends StatefulWidget {
  final String? token;
  // Route can be /activate-account?token=XYZ or /reset-password?token=XYZ
  // We can reuse same screen or detecting mode.
  // Ideally checking path or query param 'mode' if strict separation needed. 
  // But logic is identical: verify token (implied by just submitting) -> set password.
  // Actually, backend has different endpoints: /activate-account and /reset-password.
  // So we need to know which one to call. 
  // Let's assume we pass a 'mode' parameter or similar, OR we have 2 routes pointing effectively here.
  final String mode; // 'activate' or 'reset'

  const ActivateAccountScreen({
    super.key, 
    required this.token,
    this.mode = 'activate', 
  });

  @override
  State<ActivateAccountScreen> createState() => _ActivateAccountScreenState();
}

class _ActivateAccountScreenState extends State<ActivateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  Future<void> _submit() async {
    // ... (rest of _submit)
    if (!_formKey.currentState!.validate()) return;
    if (widget.token == null || widget.token!.isEmpty) {
      setState(() => _errorMessage = 'Token inválido o faltante');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? error;
      if (widget.mode == 'activate') {
         // Call activate endpoint
         final res = await _authService.activateAccount(widget.token!, _passwordController.text);
         if (res != null) error = res; // Assuming authService returns null on success or error string
      } else {
         // Call reset endpoint
         final res = await _authService.resetPassword(widget.token!, _passwordController.text);
         if (res != null) error = res;
      }

      if (error == null) {
        setState(() => _successMessage = 'Contraseña establecida exitosamente. Redirigiendo...');
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
           Navigator.of(context).pushReplacementNamed('/login');
        }
      } else {
        setState(() => _errorMessage = error);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error inesperado: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.mode == 'activate' ? 'Activar Cuenta' : 'Restablecer Contraseña';
    
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 24),
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.red.withOpacity(0.1),
                        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      ),
                    if (_successMessage != null)
                       Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.green.withOpacity(0.1),
                        child: Text(_successMessage!, style: const TextStyle(color: Colors.green)),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Nueva Contraseña',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) {
                         if (value == null || value.length < 6) return 'Mínimo 6 caracteres';
                         return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmController,
                      decoration: InputDecoration(
                        labelText: 'Confirmar Contraseña',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirm = !_obscureConfirm;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureConfirm,
                      validator: (value) {
                         if (value != _passwordController.text) return 'Las contraseñas no coinciden';
                         return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading 
                          ? const CircularProgressIndicator() 
                          : const Text('Guardar Contraseña'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

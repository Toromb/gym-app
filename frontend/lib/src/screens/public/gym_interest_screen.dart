import 'package:flutter/material.dart';
import '../../widgets/constrained_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import '../../services/api_client.dart';
import '../../providers/theme_provider.dart';

class GymInterestScreen extends StatefulWidget {
  const GymInterestScreen({super.key});

  @override
  _GymInterestScreenState createState() => _GymInterestScreenState();
}

class _GymInterestScreenState extends State<GymInterestScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _gymNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _studentsCountController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _gymNameController.dispose();
    _cityController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _studentsCountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = {
        'fullName': _fullNameController.text.trim(),
        'gymName': _gymNameController.text.trim(),
        'city': _cityController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'studentsCount': int.tryParse(_studentsCountController.text.trim()),
        'message': _messageController.text.trim(),
        'source': kIsWeb ? 'web_app' : 'mobile_app',
      };

      await ApiClient().createGymLead(data);

      setState(() {
        _isSuccess = true;
        _isLoading = false;
        _fullNameController.clear();
        _gymNameController.clear();
        _cityController.clear();
        _emailController.clear();
        _phoneController.clear();
        _studentsCountController.clear();
        _messageController.clear();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Ocurrió un error al enviar la solicitud. Por favor intenta más tarde.';
      });
    }
  }

  Widget _buildSuccessView(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
          const SizedBox(height: 24),
          const Text(
            '¡Gracias por tu interés!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Te vamos a contactar pronto para contarte cómo implementar TuGymFlow en tu centro.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[300] : Colors.grey[700]),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Volver al inicio',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final content = _isSuccess
        ? _buildSuccessView(isDark)
        : Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Contacto Comercial',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Completá tus datos y un representante se comunicará con vos para armar un plan a medida.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 20),
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
                _buildTextField(
                  controller: _fullNameController,
                  label: 'Nombre y Apellido *',
                  icon: Icons.person_outline,
                  isDark: isDark,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _gymNameController,
                  label: 'Nombre del Gimnasio *',
                  icon: Icons.fitness_center,
                  isDark: isDark,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _cityController,
                  label: 'Ciudad / Provincia *',
                  icon: Icons.location_on_outlined,
                  isDark: isDark,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email Institucional o Personal *',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  isDark: isDark,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Requerido';
                    if (!value.contains('@')) return 'Email inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: 'WhatsApp / Teléfono *',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  isDark: isDark,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _studentsCountController,
                  label: 'Cantidad aprox. de alumnos (Opcional)',
                  icon: Icons.groups_outlined,
                  keyboardType: TextInputType.number,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _messageController,
                  label: 'Mensaje adicional (Opcional)',
                  icon: Icons.message_outlined,
                  maxLines: 4,
                  isDark: isDark,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                        : const Text('Enviar Solicitud',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );

    return Scaffold(
      appBar: ConstrainedAppBar(
        title:
            const Text('Implementar TuGymFlow', style: TextStyle(fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    required bool isDark,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        hintText: label,
        prefixIcon: Padding(
          padding:
              EdgeInsets.only(bottom: maxLines > 1 ? (maxLines - 1) * 20.0 : 0),
          child: Icon(icon),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
    );
  }
}

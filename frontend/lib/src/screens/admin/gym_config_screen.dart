import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gyms_provider.dart';
import '../../models/gym_model.dart';
import '../../utils/constants.dart';

class GymConfigScreen extends StatefulWidget {
  const GymConfigScreen({super.key});

  @override
  _GymConfigScreenState createState() => _GymConfigScreenState();
}

class _GymConfigScreenState extends State<GymConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _businessNameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _openingHoursController;
  late TextEditingController _welcomeMessageController;
  late TextEditingController _primaryColorController;
  late TextEditingController _secondaryColorController;

   Gym? _currentGym;
   bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _loadGym();
      _isInit = false;
    }
  }

  Future<void> _loadGym() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user?.gym?.id != null) {
        // Find gym in provider to ensure freshness, or fetch
        // For simple Admin flow, user.gym might be enough for ID, but we want fresh data.
        // Assuming fetchGyms is called or we call it.
        final gymsProvider = Provider.of<GymsProvider>(context, listen: false);
        // If list is empty, fetch.
        if (gymsProvider.gyms.isEmpty) {
            await gymsProvider.fetchGyms();
        }
        
        try {
            final gym = gymsProvider.gyms.firstWhere((g) => g.id == user!.gym!.id);
             _populateParams(gym);
        } catch (e) {
            // Gym not found in list?
        }
    }
  }
  
  void _populateParams(Gym gym) {
      setState(() {
          _currentGym = gym;
          _businessNameController = TextEditingController(text: gym.businessName);
          _addressController = TextEditingController(text: gym.address);
          _phoneController = TextEditingController(text: gym.phone);
          _emailController = TextEditingController(text: gym.email);
          _openingHoursController = TextEditingController(text: gym.openingHours);
          _welcomeMessageController = TextEditingController(text: gym.welcomeMessage);
          _primaryColorController = TextEditingController(text: gym.primaryColor);
          _secondaryColorController = TextEditingController(text: gym.secondaryColor);
      });
  }

  @override
  void initState() {
    super.initState();
    // Controllers initialized in populate or with empty strings if needed, 
    // but better to initialize with empty to avoid late init error if build called before load.
    _businessNameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _openingHoursController = TextEditingController();
    _welcomeMessageController = TextEditingController();
    _primaryColorController = TextEditingController();
    _secondaryColorController = TextEditingController();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _openingHoursController.dispose();
    _welcomeMessageController.dispose();
    _primaryColorController.dispose();
    _secondaryColorController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadLogo() async {
      if (_currentGym == null) return;
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
          try {
              final newUrl = await Provider.of<GymsProvider>(context, listen: false)
                  .uploadLogo(_currentGym!.id, image);
              
              if (newUrl != null) {
                  setState(() {
                      // Update local gym state to show new logo immediately
                      // Actually provider refresh updates the list, so we should re-fetch or rely on parent rebuild?
                      // But we manually populated controllers. We should update _currentGym.
                       // Re-load gym from provider to get new URL
                       _loadGym();
                  });
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logo actualizado correctamente')));
              }
          } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al subir logo: $e')));
          }
      }
  }

  Future<void> _saveForm() async {
      if (_formKey.currentState!.validate() && _currentGym != null) {
          final updatedGym = Gym(
              id: _currentGym!.id,
              businessName: _businessNameController.text,
              address: _addressController.text,
              phone: _phoneController.text,
              email: _emailController.text,
              status: _currentGym!.status,
              maxProfiles: _currentGym!.maxProfiles,
              // New fields
              logoUrl: _currentGym!.logoUrl, // Url not changed here, only via upload
              primaryColor: _primaryColorController.text,
              secondaryColor: _secondaryColorController.text,
              welcomeMessage: _welcomeMessageController.text,
              openingHours: _openingHoursController.text,
          );

          try {
               await Provider.of<GymsProvider>(context, listen: false).updateGym(_currentGym!.id, updatedGym);
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuración guardada')));
          } catch (e) {
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
          }
      }
  }
  
  String _resolveLogoUrl(String relativeUrl) {
      if (relativeUrl.startsWith('http')) return relativeUrl;
      
      if (kIsWeb) {
          if (kReleaseMode) return relativeUrl; 
          return 'http://localhost:3000$relativeUrl'; 
      }
      return 'http://10.0.2.2:3000$relativeUrl'; 
  }

  @override
  Widget build(BuildContext context) {
    if (_currentGym == null) {
        return Scaffold(
            appBar: AppBar(title: const Text('Configuración del Gym')),
            body: const Center(child: CircularProgressIndicator()),
        );
    }
    
    // Resolve URL for display
    String? logoDisplayUrl;
    if (_currentGym!.logoUrl != null) {
        logoDisplayUrl = _resolveLogoUrl(_currentGym!.logoUrl!);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración del Gym')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               const Text('Identidad Visual', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
               const SizedBox(height: 10),
               
               // Logo Section
               Center(
                   child: Column(
                       children: [
                           if (logoDisplayUrl != null) 
                                Image.network(logoDisplayUrl, height: 100, errorBuilder: (c,e,s) => const Icon(Icons.broken_image, size:50)),
                           const SizedBox(height: 8),
                           ElevatedButton.icon(
                               onPressed: _pickAndUploadLogo,
                               icon: const Icon(Icons.upload),
                               label: const Text('Subir Logo del Gym'),
                           ),
                       ],
                   ),
               ),
               const SizedBox(height: 20),
               
               // Colors
               TextFormField(
                controller: _primaryColorController,
                decoration: const InputDecoration(labelText: 'Color Principal (Hex, ej: #FF0000)', hintText: '#RRGGBB'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _secondaryColorController,
                decoration: const InputDecoration(labelText: 'Color Secundario (Hex)', hintText: '#RRGGBB'),
              ),
              
              const SizedBox(height: 20),
              const Text('Información Institucional', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(labelText: 'Nombre del Gimnasio'),
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Dirección'),
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Teléfono / WhatsApp'),
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email de Contacto'),
              ),
              TextFormField(
                controller: _openingHoursController,
                decoration: const InputDecoration(labelText: 'Horarios de Atención'),
                maxLines: 2,
              ),
              
              const SizedBox(height: 20),
              const Text('Mensajes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
               TextFormField(
                controller: _welcomeMessageController,
                decoration: const InputDecoration(labelText: 'Mensaje de Bienvenida (Dashboard Alumnos)'),
                maxLines: 2,
              ),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveForm,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                ),
                child: const Text('Guardar Cambios', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

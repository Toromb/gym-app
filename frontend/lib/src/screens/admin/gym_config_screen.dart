import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/auth_provider.dart';
import '../../providers/gyms_provider.dart';
import '../../models/gym_model.dart';

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
  late TextEditingController _welcomeMessageController;
  // Payment Info Controllers
  late TextEditingController _paymentAliasController;
  late TextEditingController _paymentCbuController;
  late TextEditingController _paymentAccountNameController;
  late TextEditingController _paymentBankNameController;
  late TextEditingController _paymentNotesController;
  


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
        final gymsProvider = Provider.of<GymsProvider>(context, listen: false);
        try {
            final gym = await gymsProvider.fetchGym(user!.gym!.id);
            if (gym != null) {
                 _populateParams(gym);
            } else if (user!.gym != null) {
                 _populateParams(user.gym!);
            }
        } catch (e) {
             if (user!.gym != null) _populateParams(user.gym!);
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
          _welcomeMessageController = TextEditingController(text: gym.welcomeMessage);
          
          _paymentAliasController = TextEditingController(text: gym.paymentAlias);
          _paymentCbuController = TextEditingController(text: gym.paymentCbu);
          _paymentAccountNameController = TextEditingController(text: gym.paymentAccountName);
          _paymentBankNameController = TextEditingController(text: gym.paymentBankName);
          _paymentNotesController = TextEditingController(text: gym.paymentNotes);
          
      });
  }

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _welcomeMessageController = TextEditingController();
    _paymentAliasController = TextEditingController();
    _paymentCbuController = TextEditingController();
    _paymentAccountNameController = TextEditingController();
    _paymentBankNameController = TextEditingController();
    _paymentNotesController = TextEditingController();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _welcomeMessageController.dispose();
    _paymentAliasController.dispose();
    _paymentCbuController.dispose();
    _paymentAccountNameController.dispose();
    _paymentBankNameController.dispose();
    _paymentNotesController.dispose();
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
                  // Manually update local state to ensure save uses new URL
                  setState(() {
                      if (_currentGym != null) {
                          _currentGym = _currentGym!.copyWith(logoUrl: newUrl);
                      }
                  });
                  // Also reload from backend to be safe
                  _loadGym();
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
              logoUrl: _currentGym!.logoUrl, 
              primaryColor: _currentGym!.primaryColor,
              secondaryColor: _currentGym!.secondaryColor,
              welcomeMessage: _welcomeMessageController.text,
              openingHours: _currentGym!.openingHours, // Preserve existing or empty
              paymentAlias: _paymentAliasController.text,
              paymentCbu: _paymentCbuController.text,
              paymentAccountName: _paymentAccountNameController.text,
              paymentBankName: _paymentBankNameController.text,
              paymentNotes: _paymentNotesController.text,
          );

          try {
               final updated = await Provider.of<GymsProvider>(context, listen: false).updateGym(_currentGym!.id, updatedGym);
               if (updated != null) {
                  Provider.of<AuthProvider>(context, listen: false).updateGym(updated);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuración guardada y aplicada')));
               }
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
                           const SizedBox(height: 4),
                           const Text('Formatos: JPG, PNG. Máx: 5MB', style: TextStyle(fontSize: 12, color: Colors.grey)),
                       ],
                   ),
               ),
               const SizedBox(height: 20),
               
              
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
              // Opening Hours Removed as requested
              
              const SizedBox(height: 20),
              const Text('Mensajes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
               TextFormField(
                controller: _welcomeMessageController,
                decoration: const InputDecoration(labelText: 'Mensaje informativo (Pagina principal de Alumnos)'),
                maxLines: 2,
              ),

              const SizedBox(height: 20),
              const Text('Datos de Pago', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _paymentAliasController,
                decoration: const InputDecoration(labelText: 'Alias (Opcional)'),
              ),
              TextFormField(
                controller: _paymentCbuController,
                decoration: const InputDecoration(labelText: 'CBU / CVU (Opcional)'),
              ),
               TextFormField(
                controller: _paymentBankNameController,
                decoration: const InputDecoration(labelText: 'Nombre del Banco (Opcional)'),
              ),
              TextFormField(
                controller: _paymentAccountNameController,
                decoration: const InputDecoration(labelText: 'Titular de la Cuenta (Opcional)'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _paymentNotesController,
                decoration: const InputDecoration(
                    labelText: 'Notas / Avisos (Ej: Enviar comprobante al WhatsApp...)',
                    border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 30),
              Center(
                  child: ElevatedButton(
                    onPressed: _saveForm,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                        backgroundColor: Theme.of(context).primaryColor, 
                        foregroundColor: Theme.of(context).primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                    ),
                    child: const Text('Guardar cambios', style: TextStyle(fontSize: 16)),
                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

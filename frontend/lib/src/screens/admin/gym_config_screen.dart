import 'package:flutter/material.dart';
import '../../widgets/constrained_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gyms_provider.dart';
import '../../models/gym_model.dart';
import '../../utils/constants.dart';
import '../../widgets/background_page_wrapper.dart';

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
  // Social Media Controllers
  late TextEditingController _whatsappController;
  late TextEditingController _instagramController;
  late TextEditingController _facebookController;

  Gym? _currentGym;
  bool _isInit = true;
  Color _selectedPrimaryColor =
      const Color(0xFF6750A4); // default Material purple
  bool _isSaving = false;

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
        } else if (user.gym != null) {
          _populateParams(user.gym!);
        }
      } catch (e) {
        if (user!.gym != null) _populateParams(user.gym!);
      }
    }
  }

  void _populateParams(Gym gym) {
    Color parsedColor = const Color(0xFF6750A4);
    if (gym.primaryColor != null && gym.primaryColor!.isNotEmpty) {
      try {
        final hex = gym.primaryColor!.replaceAll('#', '');
        final fullHex = hex.length == 6 ? 'FF$hex' : hex;
        parsedColor = Color(int.parse(fullHex, radix: 16));
      } catch (_) {}
    }
    setState(() {
      _currentGym = gym;
      _selectedPrimaryColor = parsedColor;
      _businessNameController = TextEditingController(text: gym.businessName);
      _addressController = TextEditingController(text: gym.address);
      _phoneController = TextEditingController(text: gym.phone);
      _emailController = TextEditingController(text: gym.email);
      _welcomeMessageController =
          TextEditingController(text: gym.welcomeMessage);

      _paymentAliasController = TextEditingController(text: gym.paymentAlias);
      _paymentCbuController = TextEditingController(text: gym.paymentCbu);
      _paymentAccountNameController =
          TextEditingController(text: gym.paymentAccountName);
      _paymentBankNameController =
          TextEditingController(text: gym.paymentBankName);
      _paymentNotesController = TextEditingController(text: gym.paymentNotes);
      _whatsappController = TextEditingController(text: gym.whatsapp);
      _instagramController = TextEditingController(text: gym.instagram);
      _facebookController = TextEditingController(text: gym.facebook);
    });
  }

  String _colorToHex(Color color) {
    return '#${color.red.toRadixString(16).padLeft(2, '0')}${color.green.toRadixString(16).padLeft(2, '0')}${color.blue.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  Future<void> _openColorPicker() async {
    Color tempColor = _selectedPrimaryColor;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Color primario del Gym'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: tempColor,
            onColorChanged: (color) => tempColor = color,
            enableAlpha: false,
            labelTypes: const [ColorLabelType.hex, ColorLabelType.rgb],
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _selectedPrimaryColor = tempColor);
              Navigator.of(ctx).pop();
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
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
    _whatsappController = TextEditingController();
    _instagramController = TextEditingController();
    _facebookController = TextEditingController();
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
    _whatsappController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
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
            if (_currentGym != null) {
              _currentGym = _currentGym!.copyWith(logoUrl: newUrl);
            }
          });
          _loadGym();
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Logo actualizado correctamente')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al subir logo: $e')));
      }
    }
  }

  Future<void> _pickAndUploadBackground() async {
    if (_currentGym == null) return;
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      try {
        final newUrl = await Provider.of<GymsProvider>(context, listen: false)
            .uploadBackgroundImage(_currentGym!.id, image);

        if (newUrl != null) {
          setState(() {
            if (_currentGym != null) {
              _currentGym = _currentGym!.copyWith(backgroundImageUrl: newUrl);
            }
          });
          _loadGym();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Imagen de fondo actualizada correctamente')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al subir imagen de fondo: $e')));
      }
    }
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate() && _currentGym != null) {
      setState(() => _isSaving = true);
      final updatedGym = Gym(
        id: _currentGym!.id,
        businessName: _businessNameController.text,
        address: _addressController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        status: _currentGym!.status,
        maxProfiles: _currentGym!.maxProfiles,
        logoUrl: _currentGym!.logoUrl,
        primaryColor: _colorToHex(_selectedPrimaryColor),
        secondaryColor: _currentGym!.secondaryColor,
        welcomeMessage: _welcomeMessageController.text,
        openingHours: _currentGym!.openingHours,
        paymentAlias: _paymentAliasController.text,
        paymentCbu: _paymentCbuController.text,
        paymentAccountName: _paymentAccountNameController.text,
        paymentBankName: _paymentBankNameController.text,
        paymentNotes: _paymentNotesController.text,
        whatsapp: _whatsappController.text.trim(),
        instagram: _instagramController.text.trim(),
        facebook: _facebookController.text.trim(),
      );

      try {
        final updated = await Provider.of<GymsProvider>(context, listen: false)
            .updateGym(_currentGym!.id, updatedGym);
        if (updated != null) {
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          authProvider.updateGym(updated);
          await authProvider.refreshUser();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Configuración guardada y aplicada ✓')));
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentGym == null) {
      return Scaffold(
        appBar: ConstrainedAppBar(title: const Text('Configuración del Gym')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    String? logoDisplayUrl;
    if (_currentGym!.logoUrl != null) {
      logoDisplayUrl = resolveImageUrl(_currentGym!.logoUrl!);
    }

    final bgUrl =
        context.watch<AuthProvider>().currentGymBackgroundImage != null
            ? resolveImageUrl(
                context.watch<AuthProvider>().currentGymBackgroundImage!)
            : null;

    final primary = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return BackgroundPageWrapper(
      overlayOpacity: 0.88,
      backgroundNetworkUrl: bgUrl,
      child: Scaffold(
        appBar: ConstrainedAppBar(title: const Text('Configuración del Gym')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _isSaving ? null : _saveForm,
          backgroundColor: primary,
          foregroundColor: onPrimary,
          icon: _isSaving
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: onPrimary,
                  ),
                )
              : const Icon(Icons.save_rounded),
          label: Text(
            _isSaving ? 'Guardando...' : 'Guardar cambios',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Identidad Visual',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    // ── Logo + Imagen de Fondo (lado a lado) ──────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo
                        Expanded(
                          child: Column(
                            children: [
                              if (logoDisplayUrl != null)
                                Image.network(logoDisplayUrl,
                                    height: 80,
                                    errorBuilder: (c, e, s) => const Icon(
                                        Icons.broken_image,
                                        size: 40)),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _pickAndUploadLogo,
                                icon: const Icon(Icons.upload, size: 18),
                                label: const Text('Logo del Gym'),
                              ),
                              const SizedBox(height: 4),
                              const Text('JPG, PNG · Máx 5MB',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey),
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Imagen de Fondo
                        Expanded(
                          child: Column(
                            children: [
                              if (_currentGym?.backgroundImageUrl != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    resolveImageUrl(
                                        _currentGym!.backgroundImageUrl!),
                                    height: 80,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Icon(
                                        Icons.broken_image,
                                        size: 40),
                                  ),
                                )
                              else
                                Container(
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                      child: Icon(Icons.wallpaper,
                                          size: 36, color: Colors.grey)),
                                ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _pickAndUploadBackground,
                                icon:
                                    const Icon(Icons.image_outlined, size: 18),
                                label: const Text('Imagen de Fondo'),
                              ),
                              const SizedBox(height: 4),
                              const Text('JPG, PNG · Máx 10MB',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey),
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Color Primario ─────────────────────────────────────
                    const Text('Color Primario',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _openColorPicker,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _selectedPrimaryColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.grey.shade300, width: 2),
                              boxShadow: [
                                BoxShadow(
                                    color: _selectedPrimaryColor.withValues(
                                        alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3))
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _colorToHex(_selectedPrimaryColor),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Toca el color para cambiar',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _openColorPicker,
                          icon: const Icon(Icons.palette_outlined, size: 18),
                          label: const Text('Cambiar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('Información Institucional',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _businessNameController,
                      decoration: const InputDecoration(
                          labelText: 'Nombre del Gimnasio'),
                      validator: (value) => value!.isEmpty ? 'Requerido' : null,
                    ),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Dirección'),
                      validator: (value) => value!.isEmpty ? 'Requerido' : null,
                    ),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                          labelText: 'Teléfono / WhatsApp'),
                    ),
                    TextFormField(
                      controller: _emailController,
                      decoration:
                          const InputDecoration(labelText: 'Email de Contacto'),
                    ),
                    // Opening Hours Removed as requested

                    const SizedBox(height: 20),
                    const Text('Mensajes',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _welcomeMessageController,
                      decoration: const InputDecoration(
                          labelText:
                              'Mensaje informativo (Pagina principal de Alumnos)'),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 20),
                    const Text('Datos de Pago',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _paymentAliasController,
                      decoration:
                          const InputDecoration(labelText: 'Alias (Opcional)'),
                    ),
                    TextFormField(
                      controller: _paymentCbuController,
                      decoration: const InputDecoration(
                          labelText: 'CBU / CVU (Opcional)'),
                    ),
                    TextFormField(
                      controller: _paymentBankNameController,
                      decoration: const InputDecoration(
                          labelText: 'Nombre del Banco (Opcional)'),
                    ),
                    TextFormField(
                      controller: _paymentAccountNameController,
                      decoration: const InputDecoration(
                          labelText: 'Titular de la Cuenta (Opcional)'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _paymentNotesController,
                      decoration: const InputDecoration(
                        labelText:
                            'Notas / Avisos (Ej: Enviar comprobante al WhatsApp...)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 20),
                    const Text('Redes Sociales y Contacto',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      'Si completás estos campos, aparecerán como accesos rápidos en el dashboard.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _whatsappController,
                      decoration: InputDecoration(
                        labelText: 'WhatsApp (número con código de país)',
                        hintText: 'Ej: 5491112345678',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(Icons.chat_bubble_outline,
                              color: Colors.green[600], size: 22),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _instagramController,
                      decoration: InputDecoration(
                        labelText: 'Instagram (usuario, sin @)',
                        hintText: 'Ej: migimnasio',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(Icons.camera_alt_outlined,
                              color: Colors.purple[400], size: 22),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _facebookController,
                      decoration: InputDecoration(
                        labelText: 'Facebook (usuario o URL de la página)',
                        hintText: 'Ej: migimnasio o https://facebook.com/...',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(Icons.facebook,
                              color: Colors.blue[700], size: 22),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
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

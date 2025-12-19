import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  User? _user;
  bool _isLoading = true;
  bool _isEditing = false; // For basic fields

  // Controllers for editable fields
  late TextEditingController _phoneController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  
  // Student controllers
  late TextEditingController _currentWeightController;
  late TextEditingController _personalCommentController;

  // Professor controllers
  late TextEditingController _specialtyController;
  late TextEditingController _internalNotesController;
  
  // Admin controllers
  late TextEditingController _adminNotesController;
  
  String? _selectedGender;


  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final user = await _userService.getProfile();
    setState(() {
      _user = user;
      _isLoading = false;
      if (user != null) {
        _initControllers(user);
      }
    });
  }

  void _initControllers(User user) {
    _phoneController = TextEditingController(text: user.phone ?? '');
    _ageController = TextEditingController(text: user.age?.toString() ?? '');
    _heightController = TextEditingController(text: user.height?.toString() ?? '');
    
    _currentWeightController = TextEditingController(text: user.currentWeight?.toString() ?? '');
    _personalCommentController = TextEditingController(text: user.personalComment ?? '');
    
    _specialtyController = TextEditingController(text: user.specialty ?? '');
    _internalNotesController = TextEditingController(text: user.internalNotes ?? '');
    
    
    _adminNotesController = TextEditingController(text: user.adminNotes ?? '');
    _selectedGender = user.gender; 
  }
  
  @override
  void dispose() {
    _phoneController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _currentWeightController.dispose();
    _personalCommentController.dispose();
    _specialtyController.dispose();
    _internalNotesController.dispose();
    _adminNotesController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_user == null) return;

    final data = <String, dynamic>{
      'phone': _phoneController.text,
      'age': int.tryParse(_ageController.text),
      'height': double.tryParse(_heightController.text),
      'gender': _selectedGender, 
    };
    
    // Add role specific fields
    if (_user!.role == AppRoles.alumno) {
      data['currentWeight'] = double.tryParse(_currentWeightController.text);
      data['personalComment'] = _personalCommentController.text;
    } else if (_user!.role == 'profe') {
      data['specialty'] = _specialtyController.text;
      data['internalNotes'] = _internalNotesController.text;
    } else if (_user!.role == 'admin') {
      data['adminNotes'] = _adminNotesController.text;
    }

    final success = await _userService.updateProfile(data);
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
      setState(() => _isEditing = false);
      _loadProfile(); // Reload to get fresh data/formatted dates
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al actualizar perfil')));
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_user == null) return const Scaffold(body: Center(child: Text('Error al cargar perfil')));

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            tooltip: _isEditing ? 'Guardar Cambios' : 'Editar Perfil',
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(colorScheme),
            const SizedBox(height: 24),
            _buildSectionCard(
               title: 'Información Personal',
               icon: Icons.person_outline,
               child: _buildCommonSection(),
            ),
            const SizedBox(height: 16),
            if (_user!.role == AppRoles.alumno) _buildSectionCard(
               title: 'Información del Alumno',
               icon: Icons.school_outlined,
               child: _buildStudentSection()
            ),
            if (_user!.role == AppRoles.profe) _buildSectionCard(
               title: 'Información Profesional',
               icon: Icons.work_outline,
               child: _buildProfessorSection()
            ),
            if (_user!.role == AppRoles.admin) _buildSectionCard(
               title: 'Información Administrativa',
               icon: Icons.admin_panel_settings_outlined,
               child: _buildAdminSection()
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: colorScheme.primary,
              child: Text(
                _user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : '?',
                style: TextStyle(fontSize: 40, color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
              ),
            ),
            if (_isEditing)
               Container(
                 padding: const EdgeInsets.all(4),
                 decoration: BoxDecoration(color: colorScheme.secondary, shape: BoxShape.circle),
                 child: Icon(Icons.edit, size: 16, color: colorScheme.onSecondary),
               ),
          ],
        ),
        const SizedBox(height: 16),
        Text(_user!.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _user!.role.toUpperCase(), 
            style: TextStyle(color: colorScheme.onTertiaryContainer, fontWeight: FontWeight.bold, fontSize: 12)
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
     return Card(
       elevation: 0,
       shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(16),
         side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
       ),
       child: Padding(
         padding: const EdgeInsets.all(20),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
              Row(
                children: [
                   Icon(icon, color: Theme.of(context).colorScheme.primary),
                   const SizedBox(width: 12),
                   Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              child,
           ],
         ),
       ),
     );
  }

  Widget _buildCommonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextFieldWithLabel(
           label: 'Email',
           controller: TextEditingController(text: _user!.email),
           readOnly: true,
           icon: Icons.email_outlined,
        ),
         const SizedBox(height: 16),
        _buildTextFieldWithLabel(
           label: 'Teléfono',
           controller: _phoneController,
           readOnly: !_isEditing,
           icon: Icons.phone_outlined,
           keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextFieldWithLabel(
                 label: 'Edad',
                 controller: _ageController,
                 readOnly: !_isEditing,
                 keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _isEditing 
                ? DropdownButtonFormField<String>(
                    value: ['M', 'F', 'O'].contains(_selectedGender) ? _selectedGender : 'M',
                    decoration: InputDecoration(
                       labelText: 'Género',
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                       filled: true,
                       fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    ),
                    items: const [
                        DropdownMenuItem(value: 'M', child: Text('Masculino')),
                        DropdownMenuItem(value: 'F', child: Text('Femenino')),
                        DropdownMenuItem(value: 'O', child: Text('Otro')),
                    ],
                    onChanged: (val) {
                         setState(() {
                           _selectedGender = val;
                         });
                    },
                  )
                : _buildTextFieldWithLabel(
                    label: 'Género',
                    controller: TextEditingController(text: _user!.gender == 'M' ? 'Masculino' : _user!.gender == 'F' ? 'Femenino' : 'Otro'), 
                    readOnly: true,
                ),
            ),
          ],
        ),
         const SizedBox(height: 16),
         if (_user!.role != 'admin')
            _buildTextFieldWithLabel(
                label: 'Altura (cm)',
                controller: _heightController,
                readOnly: !_isEditing,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                icon: Icons.height,
            ),
      ],
    );
  }

  Widget _buildStudentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextFieldWithLabel(
          label: 'Objetivo (Definido por Profesor)',
          controller: TextEditingController(text: _user!.trainingGoal),
          readOnly: true,
          icon: Icons.flag_outlined,
        ),
        const SizedBox(height: 16),
         _buildTextFieldWithLabel(
          label: 'Observaciones del Profesor',
          controller: TextEditingController(text: _user!.professorObservations),
          readOnly: true,
          maxLines: 2,
          icon: Icons.comment_outlined,
        ),
        const SizedBox(height: 24),
        Text('Progreso Físico', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 12),
         Row(
          children: [
            Expanded(
              child: _buildTextFieldWithLabel(
                label: 'Peso Inicial (kg)',
                controller: TextEditingController(text: _user!.initialWeight?.toString()),
                readOnly: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextFieldWithLabel(
                label: 'Peso Actual (kg)',
                controller: _currentWeightController,
                readOnly: !_isEditing,
                 keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
         if (_user!.weightUpdateDate != null)
           Padding(
             padding: const EdgeInsets.only(top: 8),
             child: Text('Última actualización: ${_user!.weightUpdateDate}', style: Theme.of(context).textTheme.bodySmall),
           ),
        
        const SizedBox(height: 16),
        _buildTextFieldWithLabel(
          label: 'Comentario Personal',
          controller: _personalCommentController,
          readOnly: !_isEditing,
          maxLines: 2,
          icon: Icons.note_alt_outlined,
        ),
        
         const SizedBox(height: 24),
        Text('Membresía', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _user!.isActive == true ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _user!.isActive == true ? Colors.green : Colors.red),
          ),
          child: Row(
            children: [
               Icon(_user!.isActive == true ? Icons.check_circle : Icons.cancel, color: _user!.isActive == true ? Colors.green : Colors.red),
               const SizedBox(width: 12),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      Text('Estado: ${_user!.isActive == true ? 'Activo' : 'Inactivo'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (_user!.membershipExpirationDate != null)
                         Text('Vence el: ${_user!.membershipExpirationDate!}', style: const TextStyle(fontSize: 12)),
                   ],
                 ),
               )
            ],
          ),
        )

      ],
    );
  }

  Widget _buildProfessorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextFieldWithLabel(
          label: 'Especialidad',
          controller: _specialtyController,
          readOnly: !_isEditing,
          icon: Icons.star_outline,
        ),
        const SizedBox(height: 16),
        _buildTextFieldWithLabel(
          label: 'Notas Internas',
          controller: _internalNotesController,
          readOnly: !_isEditing,
          maxLines: 2,
          icon: Icons.lock_outline,
        ),
        const SizedBox(height: 24),
        Text('Permisos (Informativo)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 8),
        _buildPermissionItem('Puede crear planes'),
        _buildPermissionItem('Puede asignar planes a alumnos'),
        _buildPermissionItem('Puede crear usuarios alumno'),
      ],
    );
  }

  Widget _buildPermissionItem(String text) {
     return Padding(
       padding: const EdgeInsets.symmetric(vertical: 4),
       child: Row(
         children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 16),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(fontSize: 13)),
         ],
       ),
     );
  }

  Widget _buildAdminSection() {
     return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         _buildTextFieldWithLabel(
          label: 'Notas Administrativas',
          controller: _adminNotesController,
          readOnly: !_isEditing,
          maxLines: 3,
          icon: Icons.security,
        ),
        const SizedBox(height: 24),
        Text('Permisos de Sistema', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 8),
         ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.security, color: Colors.blue),
          ),
          title: const Text('Acceso Total al Sistema', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: const Text('Gestionar usuarios, planes, gimnasio', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildTextFieldWithLabel({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: readOnly ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3) : Theme.of(context).colorScheme.surface,
      ),
    );
  }

}

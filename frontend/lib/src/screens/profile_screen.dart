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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(),
            _buildCommonSection(),
            const Divider(),
            if (_user!.role == AppRoles.alumno) _buildStudentSection(),
            if (_user!.role == AppRoles.profe) _buildProfessorSection(),
            if (_user!.role == AppRoles.admin) _buildAdminSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            child: Icon(Icons.person, size: 50),
          ),
          const SizedBox(height: 10),
          Text(_user!.name, style: Theme.of(context).textTheme.headlineSmall),
          Chip(label: Text(_user!.role.toUpperCase())),
        ],
      ),
    );
  }

  Widget _buildCommonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Información Personal', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        TextField(
          controller: TextEditingController(text: _user!.email),
          decoration: const InputDecoration(labelText: 'Email'),
          readOnly: true,
          enabled: false,
        ),
         const SizedBox(height: 10),
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(labelText: 'Teléfono'),
          readOnly: !_isEditing,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Edad'),
                readOnly: !_isEditing,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _isEditing 
                ? DropdownButtonFormField<String>(
                    value: ['M', 'F', 'O'].contains(_selectedGender) ? _selectedGender : 'M',
                    decoration: const InputDecoration(labelText: 'Género'),
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
                : TextField(
                    controller: TextEditingController(text: _user!.gender == 'M' ? 'Masculino' : _user!.gender == 'F' ? 'Femenino' : 'Otro'), // Display readable
                    decoration: const InputDecoration(labelText: 'Género'),
                    readOnly: true,
                ),
            ),
          ],
        ),
         const SizedBox(height: 10),
         if (_user!.role != 'admin')
            TextField(
                controller: _heightController,
                decoration: const InputDecoration(labelText: 'Altura (cm)'),
                readOnly: !_isEditing,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
      ],
    );
  }

  Widget _buildStudentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Información del Alumno', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        TextField(
          controller: TextEditingController(text: _user!.trainingGoal),
          decoration: const InputDecoration(labelText: 'Objetivo (Definido por Profesor)'),
          readOnly: true,
          enabled: false,
        ),
        const SizedBox(height: 10),
         TextField(
          controller: TextEditingController(text: _user!.professorObservations),
          decoration: const InputDecoration(labelText: 'Observaciones del Profesor'),
          readOnly: true,
          enabled: false,
          maxLines: 2,
        ),
        const SizedBox(height: 20),
        Text('Progreso Físico', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
         Row(
          children: [
            Expanded(
              child: TextField(
                controller: TextEditingController(text: _user!.initialWeight?.toString()),
                decoration: const InputDecoration(labelText: 'Peso Inicial (kg)'),
                readOnly: true,
                enabled: false,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _currentWeightController,
                decoration: const InputDecoration(labelText: 'Peso Actual (kg)'),
                readOnly: !_isEditing,
                 keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
         if (_user!.weightUpdateDate != null)
           Padding(
             padding: const EdgeInsets.only(top: 5),
             child: Text('Última actualización: ${_user!.weightUpdateDate}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
           ),
        
        const SizedBox(height: 10),
        TextField(
          controller: _personalCommentController,
          decoration: const InputDecoration(labelText: 'Comentario Personal'),
          readOnly: !_isEditing,
          maxLines: 2,
        ),
        
         const SizedBox(height: 20),
        Text('Membresía', style: Theme.of(context).textTheme.titleMedium),
         ListTile(
           title: const Text('Estado'),
           trailing: Chip(
             label: Text(_user!.isActive == true ? 'Activo' : 'Inactivo'),
             backgroundColor: _user!.isActive == true ? Colors.green[100] : Colors.red[100],
           ),
         ),
         if (_user!.membershipExpirationDate != null)
           ListTile(
             title: const Text('Vencimiento'),
             subtitle: Text(_user!.membershipExpirationDate!),
             leading: const Icon(Icons.calendar_today),
           ),

      ],
    );
  }

  Widget _buildProfessorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Información Profesional', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        TextField(
          controller: _specialtyController,
          decoration: const InputDecoration(labelText: 'Especialidad'),
          readOnly: !_isEditing,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _internalNotesController,
          decoration: const InputDecoration(labelText: 'Notas Internas'),
          readOnly: !_isEditing,
          maxLines: 2,
        ),
        const SizedBox(height: 20),
        Text('Permisos (Informativo)', style: Theme.of(context).textTheme.titleMedium),
        const ListTile(
          leading: Icon(Icons.check_circle, color: Colors.green),
          title: Text('Puede crear planes'),
        ),
        const ListTile(
           leading: Icon(Icons.check_circle, color: Colors.green),
           title: Text('Puede asignar planes a alumnos'),
        ),
        const ListTile(
           leading: Icon(Icons.check_circle, color: Colors.green),
           title: Text('Puede crear usuarios alumno'),
        ),
      ],
    );
  }

  Widget _buildAdminSection() {
     return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Información Administrativa', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
         TextField(
          controller: _adminNotesController,
          decoration: const InputDecoration(labelText: 'Notas Administrativas'),
          readOnly: !_isEditing,
          maxLines: 3,
        ),
        const SizedBox(height: 20),
        Text('Permisos de Sistema', style: Theme.of(context).textTheme.titleMedium),
         const ListTile(
          leading: Icon(Icons.security, color: Colors.blue),
          title: Text('Acceso Total al Sistema'),
          subtitle: Text('Gestionar usuarios, planes, gimnasio'),
        ),
      ],
    );
  }

}

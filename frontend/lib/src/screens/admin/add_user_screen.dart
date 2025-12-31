import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _notesController = TextEditingController();
  final _membershipDateController = TextEditingController();
  final _weightController = TextEditingController();
  
  String _selectedRole = AppRoles.alumno;
  String _selectedGender = 'M';

  // For Professor Assignment
  String? _selectedProfessorId;
  List<User> _professors = [];
  bool _isLoadingProfessors = false;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (_selectedRole == AppRoles.alumno) {
      _fetchProfessors();
    }
  }

    Future<void> _fetchProfessors() async {
      setState(() => _isLoadingProfessors = true);
      try {
          // Use UserService directly
          final professors = await UserService().getUsers(role: UserRoles.profe);
          if (mounted) {
              setState(() {
                  _professors = professors;
                  _isLoadingProfessors = false;
              });
          }
      } catch (e) {
          if (mounted) setState(() => _isLoadingProfessors = false);
          print("Error fetching professors: $e");
      }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _membershipDateController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Usuario')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (context.read<AuthProvider>().role != AppRoles.profe)
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(labelText: 'Rol'),
                    items: const [
                      DropdownMenuItem(value: AppRoles.admin, child: Text('Admin')),
                      DropdownMenuItem(value: AppRoles.profe, child: Text('Profesor')),
                      DropdownMenuItem(value: AppRoles.alumno, child: Text('Alumno')),
                    ],
                    onChanged: (value) {
                         setState(() {
                             _selectedRole = value!;
                             if (_selectedRole == AppRoles.alumno) {
                                  _fetchProfessors();
                             } else {
                                  _selectedProfessorId = null;
                             }
                         });
                    },
                  )
                else
                   Padding(
                     padding: const EdgeInsets.symmetric(vertical: 16.0),
                     child: TextFormField(
                       initialValue: 'Alumno', 
                       readOnly: true,
                       decoration: const InputDecoration(labelText: 'Rol'),
                     ),
                   ),

                 // Assign Professor Dropdown (Visible only if Student)
                 if (_selectedRole == AppRoles.alumno) ...[
                     const SizedBox(height: 16),
                     if (_isLoadingProfessors)
                         const LinearProgressIndicator()
                     else
                         DropdownButtonFormField<String>(
                             value: _selectedProfessorId,
                             decoration: const InputDecoration(
                                 labelText: 'Profesor Asignado',
                                 helperText: 'Selecciona un profesor para supervisar a este alumno',
                             ),
                             items: [
                                 const DropdownMenuItem<String>(
                                     value: null,
                                     child: Text('Sin Profesor'),
                                 ),
                                 ..._professors.map((p) => DropdownMenuItem(
                                     value: p.id,
                                     child: Text(p.name),
                                 )),
                             ],
                             onChanged: (val) => setState(() => _selectedProfessorId = val),
                         ),
                         const SizedBox(height: 16),
                         TextFormField(
                           controller: _membershipDateController,
                           decoration: const InputDecoration(
                             labelText: 'Fecha Inicio Membresía (YYYY-MM-DD)',
                             hintText: 'Selecciona la fecha',
                             suffixIcon: Icon(Icons.calendar_today),
                           ),
                           readOnly: true,
                           onTap: () => _selectDate(context),
                         ),
                     const SizedBox(height: 16),
                 ],

                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) => value!.isEmpty ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Apellido'),
                  validator: (value) => value!.isEmpty ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) => value!.isEmpty ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                ),
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(labelText: 'Edad'),
                  keyboardType: TextInputType.number,
                ),
                if (_selectedRole == AppRoles.alumno)
                  TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(labelText: 'Peso Inicial (kg)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(labelText: 'Sexo'),
                  items: const [
                    DropdownMenuItem(value: 'M', child: Text('Masculino')),
                    DropdownMenuItem(value: 'F', child: Text('Femenino')),
                    DropdownMenuItem(value: 'O', child: Text('Otro')),
                  ],
                  onChanged: (value) => setState(() => _selectedGender = value!),
                ),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notas'),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => _isLoading = true);
                            final success = await context.read<UserProvider>().addUser(
                                  email: _emailController.text,
                                  // Password not sent, handled by backend generator + email
                                  firstName: _firstNameController.text,
                                  lastName: _lastNameController.text,
                                  phone: _phoneController.text,
                                  age: int.tryParse(_ageController.text),
                                  gender: _selectedGender,
                                  notes: _notesController.text,
                                  role: _selectedRole,
                                  professorId: _selectedProfessorId,
                                  initialWeight: double.tryParse(_weightController.text),
                                  membershipStartDate: _membershipDateController.text.isNotEmpty ? _membershipDateController.text : null,
                                );
                            setState(() => _isLoading = false);
                            if (success && mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Usuario agregado exitosamente')),
                              );
                            }
                          }
                        },
                  child: _isLoading ? const CircularProgressIndicator() : const Text('Crear Usuario'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

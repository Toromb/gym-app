import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gyms_provider.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';


class AddUserScreen extends StatefulWidget {
  final User? userToEdit;
  final String? lockedRole;
  const AddUserScreen({super.key, this.userToEdit, this.lockedRole});

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
  bool _paysMembership = true;

  // For Professor Assignment
  String? _selectedProfessorId;
  List<User> _professors = [];
  bool _isLoadingProfessors = false;

  // For Gym Assignment (Super Admin)
  String? _selectedGymId;
  bool _isLoadingGyms = false;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();

    if (widget.userToEdit != null) {
      final u = widget.userToEdit!;
      _emailController.text = u.email;
      _firstNameController.text = u.firstName;
      _lastNameController.text = u.lastName;
      _phoneController.text = u.phone ?? '';
      _ageController.text = u.age?.toString() ?? '';
      _notesController.text = u.notes ?? '';
      _selectedRole = u.role;
      _selectedGender = u.gender ?? 'M';
      _selectedProfessorId = u.professorId;
      _selectedGymId = u.gym?.id;
      
      // Handle membership date if available? 
      // User model might not have membershipStartDate mapped perfectly or it's named differently.
      // DTO has membershipStartDate, User model has membershipExpirationDate.
      // We often don't store start date in return IDK.
      // Let's assume edit doesn't change start date easily or we skip prefill if unknown.
      
      // If we want to allow editing password, we leave it empty.
    }

    if (widget.lockedRole != null) {
        _selectedRole = widget.lockedRole!;
    }
    
    if (_selectedRole == AppRoles.alumno) {
      _fetchProfessors();
    }
    if (authProvider.role == AppRoles.superAdmin) {
      _fetchGyms();
    }
  }

  Future<void> _fetchGyms() async {
    setState(() => _isLoadingGyms = true);
    // Fetch via GymsProvider
    await context.read<GymsProvider>().fetchGyms();
    if (mounted) {
      setState(() => _isLoadingGyms = false);
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
    final authProvider = context.watch<AuthProvider>();
    final gymsProvider = context.watch<GymsProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(widget.userToEdit != null ? 'Editar Usuario' : 'Agregar Usuario')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // SUPER ADMIN: Select Gym
                if (authProvider.role == AppRoles.superAdmin) ...[
                    if (_isLoadingGyms || gymsProvider.isLoading)
                        const LinearProgressIndicator()
                    else
                        DropdownButtonFormField<String>(
                            value: _selectedGymId,
                            decoration: const InputDecoration(
                                labelText: 'Gimnasio',
                                helperText: 'Selecciona el gimnasio al que pertenece este usuario',
                            ),
                            items: gymsProvider.gyms.map((g) => DropdownMenuItem(
                                value: g.id,
                                child: Text(g.businessName),
                            )).toList(),
                            onChanged: (val) => setState(() => _selectedGymId = val),
                            validator: (val) => val == null ? 'Requerido' : null,
                        ),
                    const SizedBox(height: 16),
                ],

                if (widget.lockedRole != null)
                   Padding(
                     padding: const EdgeInsets.symmetric(vertical: 16.0),
                     child: TextFormField(
                       initialValue: widget.lockedRole == AppRoles.admin ? 'Administrador' : widget.lockedRole, 
                       readOnly: true,
                       decoration: const InputDecoration(labelText: 'Rol', helperText: 'El rol está predefinido para esta acción'),
                     ),
                   )
                else if (authProvider.role != AppRoles.profe)
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRole,
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
                             value: _selectedProfessorId, // Use value instead of initialValue to react to changes
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
                     const SizedBox(height: 16),
                 ],

                 // Membership options for Professor
                 if (_selectedRole == AppRoles.profe) ...[
                      SwitchListTile(
                        title: const Text('¿Paga Membresía?'),
                        subtitle: const Text('Define si este profesor abona membresía del sistema'),
                        value: _paysMembership,
                        onChanged: (val) => setState(() => _paysMembership = val),
                      ),
                 ],

                  // Membership Date Picker (Visible for Student OR Professor who pays)
                  if (_selectedRole == AppRoles.alumno || (_selectedRole == AppRoles.profe && _paysMembership)) ...[
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
                           validator: (value) {
                             if (_selectedRole == AppRoles.alumno) {
                                return value == null || value.isEmpty ? 'Requerido para alumnos' : null;
                             }
                             if (_selectedRole == AppRoles.profe && _paysMembership) {
                                return value == null || value.isEmpty ? 'Requerido si paga membresía' : null;
                             }
                             return null;
                           },
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
                  initialValue: _selectedGender,
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
                            
                            bool success;
                            if (widget.userToEdit != null) {
                                // EDIT MODE
                                final data = {
                                    'firstName': _firstNameController.text,
                                    'lastName': _lastNameController.text,
                                    'email': _emailController.text, // Should we allow email edit? Maybe not backend supported yet but ok.
                                    'phone': _phoneController.text,
                                    'age': int.tryParse(_ageController.text),
                                    'gender': _selectedGender,
                                    'notes': _notesController.text,
                                    // Role usually not editable freely but let's send it
                                    'role': _selectedRole,
                                    'gymId': _selectedGymId, 
                                    'professorId': _selectedProfessorId,
                                    'initialWeight': double.tryParse(_weightController.text),
                                    'membershipStartDate': _membershipDateController.text.isNotEmpty ? _membershipDateController.text : null,
                                    'paysMembership': _paysMembership,
                                };


                                success = await context.read<UserProvider>().updateUser(widget.userToEdit!.id, data);
                            } else {
                                // CREATE MODE
                                success = await context.read<UserProvider>().addUser(
                                  email: _emailController.text,
                                  // Password not sent, handled by backend generator + email
                                  firstName: _firstNameController.text,
                                  lastName: _lastNameController.text,
                                  phone: _phoneController.text,
                                  age: int.tryParse(_ageController.text),
                                  gender: _selectedGender,
                                  notes: _notesController.text,
                                  role: _selectedRole,
                                  gymId: _selectedGymId, // Pass selected Gym ID
                                  professorId: _selectedProfessorId,
                                  initialWeight: double.tryParse(_weightController.text),
                                  membershipStartDate: _membershipDateController.text.isNotEmpty ? _membershipDateController.text : null,
                                  paysMembership: _paysMembership,
                                );
                            }
                            
                            if (!mounted) return;
                            setState(() => _isLoading = false);

                            if (success) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(widget.userToEdit != null ? 'Usuario actualizado exitosamente' : 'Usuario agregado exitosamente')),
                              );
                            } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Error al guardar usuario')),
                              );
                            }
                          }
                        },
                  child: _isLoading ? const CircularProgressIndicator() : Text(widget.userToEdit != null ? 'Guardar Cambios' : 'Crear Usuario'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

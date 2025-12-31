import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';

class EditUserScreen extends StatefulWidget {
  final User user;

  const EditUserScreen({super.key, required this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _ageController;
  late TextEditingController _notesController;
  late TextEditingController _lastPaymentDateController;
  
  late String _selectedRole;
  late String _selectedGender;
  late String _paymentStatus;
  
  String? _selectedProfessorId;
  List<User> _professors = [];
  bool _isLoadingProfessors = false;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.user.email);
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _ageController = TextEditingController(text: widget.user.age?.toString() ?? '');
    _notesController = TextEditingController(text: widget.user.notes ?? '');
    _lastPaymentDateController = TextEditingController(text: widget.user.lastPaymentDate ?? '');
    
    _selectedRole = widget.user.role;
    _selectedProfessorId = widget.user.professorId;
    
    print("DEBUG: EditUserScreen role='$_selectedRole'");
    
    // Validate Gender
    const validGenders = ['M', 'F', 'O'];
    _selectedGender = widget.user.gender ?? 'M';
    if (!validGenders.contains(_selectedGender)) {
        _selectedGender = 'M';
    }

    // Validate Payment Status
    const validPaymentStatuses = ['pending', 'paid', 'overdue'];
    _paymentStatus = widget.user.paymentStatus ?? 'pending';
    if (!validPaymentStatuses.contains(_paymentStatus)) {
        _paymentStatus = 'pending';
    }

    // Case-insensitive check just to be safe
    if (_selectedRole.toLowerCase() == UserRoles.alumno.toLowerCase()) {
        print("DEBUG: Fetching professors for student");
        _fetchProfessors();
    } else {
        print("DEBUG: Role $_selectedRole is not student");
    }
  }

  Future<void> _fetchProfessors() async {
      setState(() => _isLoadingProfessors = true);
      try {
          // Use UserService directly to avoid overwriting UserProvider state
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

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _notesController.dispose();
    _lastPaymentDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Usuario')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Role is usually not editable easily due to permission complexity, but let's allow it for Admin.
                // If Profe, they arguably shouldn't change role of student to Admin.
                // For MVP simplicity, we keep it disabled or read-only if desired, or allow if we trust backend validation.
                // Let's assume for this screen we just show it read-only to avoid complexity.
                 Padding(
                   padding: const EdgeInsets.symmetric(vertical: 16.0),
                   child: TextFormField(
                     initialValue: _selectedRole.toUpperCase(),
                     readOnly: true,
                     decoration: const InputDecoration(labelText: 'Rol'),
                   ),
                 ),
                 
                 // Assign Professor Dropdown (Visible only if Student)
                 if (_selectedRole.toLowerCase() == UserRoles.alumno.toLowerCase()) ...[
                     if (_isLoadingProfessors)
                         const LinearProgressIndicator()
                     else
                         DropdownButtonFormField<String>(
                             value: _professors.any((p) => p.id == _selectedProfessorId) ? _selectedProfessorId : null,
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
                // Password Field - One instance only
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                ),
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(labelText: 'Edad'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  value: ['M', 'F', 'O'].contains(_selectedGender) ? _selectedGender : 'M',
                  decoration: const InputDecoration(labelText: 'Sexo'),
                  items: const [
                    DropdownMenuItem(value: 'M', child: Text('Masculino')),
                    DropdownMenuItem(value: 'F', child: Text('Femenino')),
                    DropdownMenuItem(value: 'O', child: Text('Otro')),
                  ],
                  onChanged: (value) => setState(() => _selectedGender = value!),
                ),
                 DropdownButtonFormField<String>(
                  value: ['pending', 'paid', 'overdue'].contains(_paymentStatus) ? _paymentStatus : 'pending',
                  decoration: const InputDecoration(labelText: 'Estado de Pago'),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pendiente')),
                    DropdownMenuItem(value: 'paid', child: Text('Pagado')),
                    DropdownMenuItem(value: 'overdue', child: Text('Vencido')),
                  ],
                  onChanged: (value) => setState(() => _paymentStatus = value!),
                ),
                TextFormField(
                  controller: _lastPaymentDateController,
                  decoration: const InputDecoration(
                    labelText: 'Última Fecha de Pago (YYYY-MM-DD)',
                    hintText: '2024-01-01',
                  ),
                  onTap: () async {
                    FocusScope.of(context).requestFocus(FocusNode());
                    DateTime initialDate = DateTime.now();
                    if (_lastPaymentDateController.text.isNotEmpty) {
                      try {
                        initialDate = DateTime.parse(_lastPaymentDateController.text);
                      } catch (_) {}
                    }
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initialDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                         _lastPaymentDateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                      });
                    }
                  },
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
                            
                            final updateData = {
                              'email': _emailController.text,
                              'firstName': _firstNameController.text,
                              'lastName': _lastNameController.text,
                              'phone': _phoneController.text,
                              'age': int.tryParse(_ageController.text),
                              'gender': _selectedGender,
                              'notes': _notesController.text,
                              'paymentStatus': _paymentStatus,
                              'lastPaymentDate': _lastPaymentDateController.text.isEmpty ? null : _lastPaymentDateController.text,
                              // Send professorId (null if explicitly unassigned)
                              'professorId': _selectedProfessorId, 
                            };
                            

                            final success = await context.read<UserProvider>().updateUser(
                                  widget.user.id,
                                  updateData
                                );
                            setState(() => _isLoading = false);
                            if (success && mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Usuario actualizado exitosamente')),
                              );
                              // Refresh list
                              context.read<UserProvider>().fetchUsers(forceRefresh: true);
                            } else if (mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Error al actualizar usuario')),
                              );
                            }
                          }
                        },
                  child: _isLoading ? const CircularProgressIndicator() : const Text('Guardar Cambios'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

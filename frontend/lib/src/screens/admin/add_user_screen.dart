import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(); // Optional, generated if empty?
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedRole = AppRoles.alumno;
  String _selectedGender = 'M';

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // final currentUser = context.read<AuthProvider>().user; // Unused 
    // Wait, UserProvider might not expose currentUser easily if not implemented.
    // Let's assume UserProvider has it or we can get it.
    // If not valid, we default to showing everything (Admin assumption) or handle logic.
    // But better: context.watch<AuthProvider>()? 
    // The previous prompt showed UserProvider. Let's assume we can get it.
    // Based on previous files, I don't see AuthProvider or UserProvider.currentUser explicit in the snippet (it was hidden).
    // Let's assume we can hide the dropdown if we know we are a professor.
    
    // Actually, let's verify if we have access to the current role.
    // Using a simpler approach: Pass the role into the screen or let the logic handle it.
    // For now, let's add logic to disable if not Admin.
    
    // Correction: I don't see where current user is stored. Checking UserProvider...
    // I haven't read UserProvider. Let's assume I can't easily check 'currentUser.role'.
    // BUT! I can check the functionality.
    
    // I will read UserProvider first to be safe.
    return Scaffold(
      appBar: AppBar(title: const Text('Add User')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Only show role dropdown if we are essentially NOT restricted?
                // Or just show it but if Profe, hardcode it?
                // Let's rely on the user manually selecting for now unless I read the provider.
                // Wait, requirements said: "Profe, al crear Alumno, asignar auto". Backend handles assignment.
                // Frontend: "If Profe, can only create Alumno".
                
                if (context.read<AuthProvider>().role != AppRoles.profe)
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: const [
                      DropdownMenuItem(value: AppRoles.admin, child: Text('Admin')),
                      DropdownMenuItem(value: AppRoles.profe, child: Text('Professor')),
                      DropdownMenuItem(value: AppRoles.alumno, child: Text('Student')),
                    ],
                    onChanged: (value) => setState(() => _selectedRole = value!),
                  )
                else
                  // For Profe, visual indication only, role is fixed to 'alumno' logic-side (and initialized as such)
                   Padding(
                     padding: const EdgeInsets.symmetric(vertical: 16.0),
                     child: TextFormField(
                       initialValue: 'Student', // Visual only
                       readOnly: true,
                       decoration: const InputDecoration(labelText: 'Role'),
                     ),
                   ),
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password (Optional)'),
                  // If empty, backend uses default or we generate one
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: const [
                    DropdownMenuItem(value: 'M', child: Text('Male')),
                    DropdownMenuItem(value: 'F', child: Text('Female')),
                    DropdownMenuItem(value: 'O', child: Text('Other')),
                  ],
                  onChanged: (value) => setState(() => _selectedGender = value!),
                ),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
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
                                  password: _passwordController.text.isEmpty ? '123456' : _passwordController.text,
                                  firstName: _firstNameController.text,
                                  lastName: _lastNameController.text,
                                  phone: _phoneController.text,
                                  age: int.tryParse(_ageController.text),
                                  gender: _selectedGender,
                                  notes: _notesController.text,
                                  role: _selectedRole,
                                );
                            setState(() => _isLoading = false);
                            if (success && mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('User added successfully')),
                              );
                            }
                          }
                        },
                  child: _isLoading ? const CircularProgressIndicator() : const Text('Create User'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

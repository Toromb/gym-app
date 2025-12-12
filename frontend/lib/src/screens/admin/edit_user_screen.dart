import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';

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
    _selectedGender = widget.user.gender ?? 'M';
    _paymentStatus = widget.user.paymentStatus ?? 'pending';
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
      appBar: AppBar(title: const Text('Edit User')),
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
                 DropdownButtonFormField<String>(
                  value: _paymentStatus,
                  decoration: const InputDecoration(labelText: 'Payment Status'),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'paid', child: Text('Paid')),
                    DropdownMenuItem(value: 'overdue', child: Text('Overdue')),
                  ],
                  onChanged: (value) => setState(() => _paymentStatus = value!),
                ),
                TextFormField(
                  controller: _lastPaymentDateController,
                  decoration: const InputDecoration(
                    labelText: 'Last Payment Date (YYYY-MM-DD)',
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
                            
                            final updateData = {
                              'email': _emailController.text,
                              'firstName': _firstNameController.text,
                              'lastName': _lastNameController.text,
                              'phone': _phoneController.text,
                              'age': int.tryParse(_ageController.text),
                              'gender': _selectedGender,
                              'notes': _notesController.text,
                              'paymentStatus': _paymentStatus,
                              'lastPaymentDate': _lastPaymentDateController.text,
                              // role not sent
                            };

                            final success = await context.read<UserProvider>().updateUser(
                                  widget.user.id,
                                  updateData
                                );
                            setState(() => _isLoading = false);
                            if (success && mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('User updated successfully')),
                              );
                              // Refresh list
                              context.read<UserProvider>().fetchUsers();
                            } else if (mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to update user')),
                              );
                            }
                          }
                        },
                  child: _isLoading ? const CircularProgressIndicator() : const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

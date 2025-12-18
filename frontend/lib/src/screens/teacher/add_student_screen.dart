import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  final _membershipDateController = TextEditingController();
  bool _isLoading = false;

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
      appBar: AppBar(title: const Text('Agregar Alumno')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator: (value) => value!.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(labelText: 'Apellido'),
                        validator: (value) => value!.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) => value!.isEmpty ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                  validator: (value) => value!.isEmpty ? 'Requerido' : null,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Teléfono'),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _ageController,
                        decoration: const InputDecoration(labelText: 'Edad'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                        child: TextFormField(
                        controller: _weightController,
                        decoration: const InputDecoration(labelText: 'Peso Inicial (kg)'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                       child: DropdownButtonFormField<String>(
                        value: _genderController.text.isNotEmpty ? _genderController.text : null,
                        decoration: const InputDecoration(labelText: 'Sexo'),
                        items: const [
                          DropdownMenuItem(value: 'M', child: Text('Masculino')),
                          DropdownMenuItem(value: 'F', child: Text('Femenino')),
                          DropdownMenuItem(value: 'O', child: Text('Otro')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _genderController.text = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: _membershipDateController,
                  decoration: const InputDecoration(
                    labelText: 'Fecha Inicio Membresía',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notas'),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => _isLoading = true);
                            final success = await context.read<UserProvider>().addStudent(
                                  email: _emailController.text,
                                  password: _passwordController.text,
                                  firstName: _firstNameController.text,
                                  lastName: _lastNameController.text,
                                  phone: _phoneController.text,
                                  age: int.tryParse(_ageController.text),
                                  gender: _genderController.text,
                                  notes: _notesController.text,
                                  initialWeight: double.tryParse(_weightController.text), // Add initial weight
                                  membershipStartDate: _membershipDateController.text.isNotEmpty ? _membershipDateController.text : null,
                                );
                            setState(() => _isLoading = false);
                            if (success && mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Alumno agregado exitosamente')),
                              );
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Error al agregar alumno')),
                              );
                            }
                          }
                        },
                        child: const Text('Agregar Alumno'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

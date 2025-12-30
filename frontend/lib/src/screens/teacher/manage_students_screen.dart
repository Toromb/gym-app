import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import 'assign_plan_modal.dart';
import 'student_plans_screen.dart';
import '../shared/user_detail_screen.dart';
import '../student/muscle_flow_screen.dart';
import '../../widgets/student_card_item.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar Alumnos')),
      // FAB removed to restrict student creation for Professors.
      body: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          List<User> students = userProvider.students;
          if (_searchQuery.isNotEmpty) {
            students = students.where((s) => 
              s.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
              s.email.toLowerCase().contains(_searchQuery.toLowerCase())
            ).toList();
          }

          if (userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (students.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.people_outline, size: 60, color: colorScheme.outline),
                   const SizedBox(height: 16),
                   Text('No hay alumnos asignados.', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                ],
              )
            );
          }
          
          return Column(
            children: [
              _buildSearch(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    
                    return StudentCardItem(
                      student: student,
                      onDelete: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Eliminar Alumno'),
                            content: Text('¿Estás seguro de que quieres eliminar a ${student.name}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancelar'),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && context.mounted) {
                          // ignore: use_build_context_synchronously
                          final error = await context.read<UserProvider>().deleteUser(student.id);
                          if (context.mounted) {
                            if (error == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Usuario eliminado')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error), backgroundColor: colorScheme.error),
                              );
                            }
                          }
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearch() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
          decoration: InputDecoration(
            hintText: 'Buscar alumno por nombre...',
            prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
      ),
    );
  }
}

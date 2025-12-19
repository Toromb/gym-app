import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'add_student_screen.dart';
import 'assign_plan_modal.dart';
import 'create_plan_screen.dart';
import '../shared/user_detail_screen.dart';
import 'student_plans_screen.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers();
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar Alumnos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddStudentScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          if (userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (userProvider.students.isEmpty) {
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
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: userProvider.students.length,
            itemBuilder: (context, index) {
              final student = userProvider.students[index];
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                   borderRadius: BorderRadius.circular(12),
                   side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                       Row(
                         children: [
                            CircleAvatar(
                              backgroundColor: colorScheme.primaryContainer,
                              radius: 24,
                              child: Text(
                                student.firstName.isNotEmpty ? student.firstName[0].toUpperCase() : '?',
                                style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                   Text(
                                     student.name,
                                     style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                   ),
                                   Text(
                                     student.email,
                                     style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                   ),
                                ],
                              ),
                            ),
                            // Quick Action: View
                             IconButton(
                              icon: const Icon(Icons.visibility_outlined),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserDetailScreen(user: student),
                                  ),
                                );
                              },
                            ),
                         ],
                       ),
                       const SizedBox(height: 12),
                       const Divider(),
                       const SizedBox(height: 8),
                       
                       // Action Chips / Buttons row
                       Wrap(
                         spacing: 8,
                         runSpacing: 8,
                         alignment: WrapAlignment.end,
                         children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.assignment_ind, size: 18),
                              label: const Text('Asignar Plan'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                textStyle: const TextStyle(fontSize: 13),
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AssignPlanModal(preselectedStudent: student),
                                );
                              },
                            ),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.list_alt, size: 18),
                              label: const Text('Planes'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                textStyle: const TextStyle(fontSize: 13),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => StudentPlansScreen(student: student),
                                  ),
                                );
                              },
                            ),
                             IconButton.filledTonal(
                               icon: Icon(Icons.delete_outline, color: colorScheme.error, size: 20),
                               style: IconButton.styleFrom(backgroundColor: colorScheme.errorContainer),
                               onPressed: () async {
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

                                if (confirm == true && mounted) {
                                  final success = await context.read<UserProvider>().deleteUser(student.id);
                                  if (success && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Alumno eliminado')),
                                    );
                                  }
                                }
                              },
                            ),
                         ],
                       )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

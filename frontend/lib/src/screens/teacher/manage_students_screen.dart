import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import 'add_student_screen.dart';
import 'assign_plan_modal.dart';
import 'student_plans_screen.dart';
import '../shared/user_detail_screen.dart';
import '../student/muscle_flow_screen.dart';

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
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2), // Compact
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(12),
                         side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Compact
                        child: Column(
                          children: [
                             Row(
                               children: [
                                  CircleAvatar(
                                    backgroundColor: colorScheme.primaryContainer,
                                    radius: 20, // Smaller
                                    child: Text(
                                      student.firstName.isNotEmpty ? student.firstName[0].toUpperCase() : '?',
                                      style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                         Text(
                                           student.name,
                                           style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold), // Smaller title
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
                                     visualDensity: VisualDensity.compact,
                                     iconSize: 20,
                                     padding: EdgeInsets.zero,
                                     constraints: const BoxConstraints(),
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
                             const SizedBox(height: 8),
                             const Divider(),
                             const SizedBox(height: 4),
                             
                             // Action Chips / Buttons row
                             Row(
                               mainAxisAlignment: MainAxisAlignment.end,
                               children: [
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.assignment_ind, size: 16),
                                    label: const Text('Asignar Plan'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      textStyle: const TextStyle(fontSize: 12),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AssignPlanModal(preselectedStudent: student),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.list_alt, size: 16),
                                    label: const Text('Planes'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      textStyle: const TextStyle(fontSize: 12),
                                      visualDensity: VisualDensity.compact,
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
                                    // const SizedBox(width: 8),
                                    // OutlinedButton.icon(
                                    //   icon: const Icon(Icons.accessibility_new, size: 16),
                                    //   label: const Text('Estado'),
                                    //   style: OutlinedButton.styleFrom(
                                    //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    //     textStyle: const TextStyle(fontSize: 12),
                                    //     visualDensity: VisualDensity.compact,
                                    //   ),
                                    //   onPressed: () {
                                    //     Navigator.push(
                                    //       context,
                                    //       MaterialPageRoute(
                                    //         builder: (context) => MuscleFlowScreen(studentId: student.id),
                                    //       ),
                                    //     );
                                    //   },
                                    // ),
                                     const SizedBox(width: 8),
                                   IconButton(
                                     visualDensity: VisualDensity.compact,
                                     iconSize: 20,
                                     padding: EdgeInsets.zero,
                                     constraints: const BoxConstraints(),
                                     icon: Icon(Icons.delete_outline, color: colorScheme.error),
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

                                      if (confirm == true && context.mounted) {
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
                                  ),
                               ],
                             )
                          ],
                        ),
                      ),
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

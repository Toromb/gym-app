import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'add_student_screen.dart';
import 'assign_plan_modal.dart';
import 'create_plan_screen.dart';
import 'student_profile_screen.dart';
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
  Widget build(BuildContext context) {
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
            return const Center(child: Text('No hay alumnos encontrados.'));
          }
          return ListView.builder(
            itemCount: userProvider.students.length,
            itemBuilder: (context, index) {
              final student = userProvider.students[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ExpansionTile(
                  leading: CircleAvatar(child: Text(student.firstName[0])),
                  title: Text(student.name),
                  subtitle: Text(student.email),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Wrap(
                        spacing: 10,
                        children: [
                          ActionChip(
                            avatar: const Icon(Icons.person),
                            label: const Text('Perfil'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StudentProfileScreen(student: student),
                                ),
                              );
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.add_chart),
                            label: const Text('Crear Plan'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CreatePlanScreen()),
                              );
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.assignment_ind),
                            label: const Text('Asignar Plan'),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AssignPlanModal(preselectedStudent: student),
                              );
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.list_alt),
                            label: const Text('Gestionar Planes'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StudentPlansScreen(student: student),
                                ),
                              );
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.delete, color: Colors.red),
                            label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
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
                                    TextButton(
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
                                } else if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Error al eliminar alumno')),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

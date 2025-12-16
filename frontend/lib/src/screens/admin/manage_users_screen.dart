import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_constants.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/plan_provider.dart';
import '../../models/plan_model.dart';
import '../../models/user_model.dart'; // Import User model for type checking
import 'add_user_screen.dart';
import 'edit_user_screen.dart';
import '../teacher/student_plans_screen.dart';
import '../../widgets/payment_status_badge.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  String _searchQuery = '';
  String _filterStatus = 'all'; // 'all', 'paid', 'pending', 'overdue'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers(); // Fetches all accessible users
    });
  }

  @override
  Widget build(BuildContext context) {
    final userRole = context.read<AuthProvider>().role;
    final isAdmin = userRole == AppRoles.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Usuarios'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddUserScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          if (userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = userProvider.students; // 'students' contains all users

          // Filter Logic
          final filteredUsers = users.where((u) {
            final matchesSearch = (u.firstName + ' ' + u.lastName).toLowerCase().contains(_searchQuery.toLowerCase()) || 
                                  u.email.toLowerCase().contains(_searchQuery.toLowerCase());
            
            if (!matchesSearch) return false;

            if (_filterStatus == 'all') return true;
            
            final status = u.paymentStatus?.toLowerCase() ?? 'pending';
            return status == _filterStatus;
          }).toList();

          if (isAdmin) {
            final admins = filteredUsers.where((u) => u.role == 'admin').toList();
            final profes = filteredUsers.where((u) => u.role == 'profe').toList();
            final alumnos = filteredUsers.where((u) => u.role == 'alumno').toList();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchAndFilter(),
                  _buildSectionHeader(context, 'Admins', admins.length),
                  ..._buildUserListWidgets(context, admins, isAdmin, false),
                  
                  _buildSectionHeader(context, 'Profesores', profes.length),
                  ..._buildUserListWidgets(context, profes, isAdmin, false),
                  
                  _buildSectionHeader(context, 'Alumnos', alumnos.length),
                  ..._buildUserListWidgets(context, alumnos, isAdmin, false),
                  
                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            );
          } else {
            // Profe View: Show only Alumnos
            // Also apply search for Profe view? Yes.
            final students = filteredUsers.where((u) => u.role == AppRoles.alumno).toList();
            return Column(
              children: [
                 _buildSearchAndFilter(), // Reuse
                _buildSectionHeader(context, 'Alumnos', students.length),
                Expanded(
                  child: ListView(
                    children: _buildUserListWidgets(context, students, false, true),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o email...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _filterStatus,
            decoration: InputDecoration(
              labelText: 'Estado de Cuota',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Todos')),
              DropdownMenuItem(value: 'paid', child: Text('Cuota Paga')),
              DropdownMenuItem(value: 'pending', child: Text('Cuota Por Vencer')),
              DropdownMenuItem(value: 'overdue', child: Text('Cuota Vencida')),
            ],
            onChanged: (val) {
                if (val != null) {
                    setState(() {
                        _filterStatus = val;
                    });
                }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        '$title ($count)',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  List<Widget> _buildUserListWidgets(BuildContext context, List<dynamic> users, bool isAdmin, bool isProfeView) {
    if (users.isEmpty) {
      return [const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Text('No users found in this category.', style: TextStyle(fontStyle: FontStyle.italic)),
      )];
    }
    return users.map((user) {
      return ListTile(
        leading: CircleAvatar(child: Text(user.firstName.isNotEmpty ? user.firstName[0] : '?')),
        title: Text('${user.firstName} ${user.lastName}'),
        subtitle: Text('${user.email} - ${user.role}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Payment Status (Only for Students/Profes and Admin view)
            if (isAdmin && (user.role == 'alumno' || user.role == 'profe')) 
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: PaymentStatusBadge(
                  status: user.paymentStatus,
                  isEditable: true,
                  onMarkAsPaid: () async {
                       final success = await context.read<UserProvider>().markUserAsPaid(user.id);
                       if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Payment updated' : 'Failed to update')));
                       }
                  },
                ),
              ),

            if ((isProfeView || isAdmin) && user.role == 'alumno') ...[
              if (isAdmin) 
               IconButton(
                 icon: const Icon(Icons.assignment_ind),
                 tooltip: 'Asignar Profesor',
                 onPressed: () => _showAssignProfessorDialog(context, user),
               ),
              IconButton(
                icon: const Icon(Icons.assignment),
                tooltip: 'Asignar Plan',
                onPressed: () => _showAssignPlanDialog(context, user.id),
              ),
              IconButton(
                icon: const Icon(Icons.list_alt),
                tooltip: 'Gestionar Planes',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentPlansScreen(student: user),
                    ),
                  );
                },
              ),
            ],
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Editar Usuario',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditUserScreen(user: user),
                  ),
                );
              },
            ),
             IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Eliminar Usuario',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('¿Estás seguro?'),
                    content: const Text('¿Quieres eliminar este usuario?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('No')),
                      TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Sí')),
                    ],
                  ),
                );
                
                if (confirm == true && context.mounted) {
                  context.read<UserProvider>().deleteUser(user.id);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario eliminado')));
                }
              },
            ),
          ],
        ),
      );
    }).toList();
  }

  void _showAssignProfessorDialog(BuildContext context, User student) async {
      // We can use a StatefulBuilder to handle local loading state inside dialog
      // Or fetch before showing. Let's fetch insde dialog for better UX (loading indicator).
      
      showDialog(
          context: context,
          builder: (context) {
              return _AssignProfessorDialog(student: student);
          }
      );
  }

  void _showAssignPlanDialog(BuildContext context, String studentId) {
    // Fetch plans first
    context.read<PlanProvider>().fetchPlans();

    showDialog(
      context: context,
      builder: (context) {
        String? selectedPlanId;
        return AlertDialog(
          title: const Text('Asignar Plan'),
          content: Consumer<PlanProvider>(
            builder: (context, planProvider, child) {
              if (planProvider.isLoading) return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()));
              if (planProvider.plans.isEmpty) return const Text('No hay planes disponibles. Crea uno primero.');

              return DropdownButtonFormField<String>(
                items: planProvider.plans.map((plan) {
                  return DropdownMenuItem(
                    value: plan.id,
                    child: Text(plan.name),
                  );
                }).toList(),
                onChanged: (val) => selectedPlanId = val,
                decoration: const InputDecoration(labelText: 'Seleccionar Plan'),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                if (selectedPlanId != null) {
                   final success = await context.read<PlanProvider>().assignPlan(selectedPlanId!, studentId);
                   if (context.mounted) {
                     Navigator.pop(context);
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text(success ? 'Plan assigned successfully' : 'Failed to assign plan')),
                     );
                   }
                }
              },
              child: const Text('Asignar'),
            ),
          ],
        );
      },
    );
  }
}

class _AssignProfessorDialog extends StatefulWidget {
    final User student;
    const _AssignProfessorDialog({required this.student});

    @override
    State<_AssignProfessorDialog> createState() => _AssignProfessorDialogState();
}

class _AssignProfessorDialogState extends State<_AssignProfessorDialog> {
    List<User> _professors = [];
    bool _isLoading = true;
    String? _selectedProfessorId;
    
    @override
    void initState() {
        super.initState();
        _selectedProfessorId = widget.student.professorId;
        _fetchProfessors();
    }
    
    Future<void> _fetchProfessors() async {
        try {
            // Need to import UserService or use provider? 
            // The file imports UserService? No, it imports UserProvider.
            // Let's use UserProvider if possible, but fetchUsers() gets all.
            // Let's rely on UserService direct call just like EditUserScreen did. 
            // *Wait*, ManageUsersScreen didn't import UserService. I need to add that import.
             
            // Assuming UserService instance is available or I can instantiate it.
            // For now, I'll assume we can use context.read<UserProvider>() if it has a way, 
            // OR I need to add `import '../../services/user_service.dart';` at top of file. 
            // *Self-Correction*: I should add the import in a subsequent step if it's missing.
            // Let's try to assume I will add the import next tool call or assume it's implicitly available (it's not).
            // Actually, I can use UserProvider to update, but fetching specifically teachers might need filter.
            // But UserProvider.students HAS teachers if I am admin.
            // So I can filter `context.read<UserProvider>().students`!
            
            final allUsers = context.read<UserProvider>().students;
            final professors = allUsers.where((u) => u.role == UserRoles.profe).toList();
            if (mounted) {
                setState(() {
                    _professors = professors;
                    _isLoading = false;
                });
            }
        } catch (e) {
             if (mounted) setState(() => _isLoading = false);
        }
    }

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: const Text('Asignar Profesor'),
            content: _isLoading 
                ? const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()))
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        DropdownButtonFormField<String>(
                             value: _professors.any((p) => p.id == _selectedProfessorId) ? _selectedProfessorId : null,
                             decoration: const InputDecoration(
                                 labelText: 'Seleccionar Profesor',
                             ),
                             items: [
                                 const DropdownMenuItem<String>(
                                     value: null,
                                     child: Text('Sin Profesor (Desasignar)'),
                                 ),
                                 ..._professors.map((p) => DropdownMenuItem(
                                     value: p.id,
                                     child: Text(p.name),
                                 )),
                             ],
                             onChanged: (val) => setState(() => _selectedProfessorId = val),
                         ),
                    ],
                ),
                actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                    TextButton(
                        onPressed: () async {
                            final success = await context.read<UserProvider>().updateUser(
                                widget.student.id,
                                { 'professorId': _selectedProfessorId } // If null, backend handles unassign
                            );
                             if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(success ? 'Profesor asignado exitosamente' : 'Error al asignar profesor')),
                                );
                                // Refresh list to show updated data? 
                                // UserProvider.updateUser usually should update local state, 
                                // but if not, we might need fetchUsers.
                                context.read<UserProvider>().fetchUsers(); 
                            }
                        },
                        child: const Text('Guardar'),
                    )
                ]
        );
    }
}

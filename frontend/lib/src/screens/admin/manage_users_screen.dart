import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/plan_provider.dart';
import '../../models/plan_model.dart';
import '../../models/user_model.dart'; // Import User model for type checking
import 'add_user_screen.dart';
import 'edit_user_screen.dart';
import '../teacher/student_plans_screen.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
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
    final isAdmin = userRole == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
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

          if (isAdmin) {
            final admins = users.where((u) => u.role == 'admin').toList();
            final profes = users.where((u) => u.role == 'profe').toList();
            final alumnos = users.where((u) => u.role == 'alumno').toList();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
            final students = users.where((u) => u.role == 'alumno').toList();
            return Column(
              children: [
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
        subtitle: Text('${user.email} - ${user.role.toUpperCase()}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isProfeView && user.role == 'alumno') ...[
              IconButton(
                icon: const Icon(Icons.assignment),
                tooltip: 'Assign Plan',
                onPressed: () => _showAssignPlanDialog(context, user.id),
              ),
              IconButton(
                icon: const Icon(Icons.list_alt),
                tooltip: 'Manage Plans',
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
              tooltip: 'Edit User',
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
              tooltip: 'Delete User',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Are you sure?'),
                    content: const Text('Do you want to delete this user?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('No')),
                      TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Yes')),
                    ],
                  ),
                );
                
                if (confirm == true && context.mounted) {
                  context.read<UserProvider>().deleteUser(user.id);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted')));
                }
              },
            ),
          ],
        ),
      );
    }).toList();
  }

  void _showAssignPlanDialog(BuildContext context, String studentId) {
    // Fetch plans first
    context.read<PlanProvider>().fetchPlans();

    showDialog(
      context: context,
      builder: (context) {
        String? selectedPlanId;
        return AlertDialog(
          title: const Text('Assign Plan'),
          content: Consumer<PlanProvider>(
            builder: (context, planProvider, child) {
              if (planProvider.isLoading) return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()));
              if (planProvider.plans.isEmpty) return const Text('No plans available. Create one first.');

              return DropdownButtonFormField<String>(
                items: planProvider.plans.map((plan) {
                  return DropdownMenuItem(
                    value: plan.id,
                    child: Text(plan.name),
                  );
                }).toList(),
                onChanged: (val) => selectedPlanId = val,
                decoration: const InputDecoration(labelText: 'Select Plan'),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
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
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );
  }
}

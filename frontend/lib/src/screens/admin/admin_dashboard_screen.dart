import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'manage_users_screen.dart';
import '../shared/plans_list_screen.dart';
import '../teacher/create_plan_screen.dart';
import '../shared/gym_schedule_screen.dart';
import '../profile_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenido, ${user?.firstName}!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            _buildDashboardCard(
              context,
              title: 'Gestionar Usuarios',
              icon: Icons.people,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageUsersScreen()),
                );
              },
            ),
            const SizedBox(height: 16),

            _buildDashboardCard(
              context,
              title: 'Crear Plan',
              icon: Icons.add_circle_outline,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreatePlanScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildDashboardCard(
              context,
              title: 'Biblioteca de Planes',
              icon: Icons.library_books,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PlansListScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildDashboardCard(
              context,
              title: 'Horarios del Gimnasio',
              icon: Icons.access_time, // Replaced calendar_today with access_time as it fits better for schedule
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GymScheduleScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
             _buildDashboardCard(
              context,
              title: 'Mi Perfil',
              icon: Icons.person,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
            // Add more admin features here
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context,
      {required String title, required IconData icon, required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Theme.of(context).primaryColor),
              const SizedBox(width: 20),
              Text(title, style: const TextStyle(fontSize: 20)),
            ],
          ),
        ),
      ),
    );
  }
}

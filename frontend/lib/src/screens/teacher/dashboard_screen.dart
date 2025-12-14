import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'manage_students_screen.dart';
import 'create_plan_screen.dart';
import '../shared/plans_list_screen.dart';
import '../shared/gym_schedule_screen.dart';
import '../shared/gym_schedule_screen.dart';
import '../profile_screen.dart';
import '../../widgets/payment_status_badge.dart';

class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
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
              'Welcome, ${user?.firstName ?? "Teacher"}!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            PaymentStatusBadge(status: user?.paymentStatus, isEditable: false),
            const SizedBox(height: 20),
            _buildDashboardCard(
              context,
              title: 'Manage Students',
              icon: Icons.people,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageStudentsScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
             _buildDashboardCard(
              context,
              title: 'My Profile',
              icon: Icons.person,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildDashboardCard(
              context,
              title: 'Create Plan',
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
              title: 'Plans Library',
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
              title: 'Gym Schedule',
              icon: Icons.access_time,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GymScheduleScreen()),
                );
              },
            ),
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

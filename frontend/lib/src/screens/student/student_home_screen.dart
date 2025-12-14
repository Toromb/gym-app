import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../shared/day_detail_screen.dart';
import '../shared/gym_schedule_screen.dart';
import '../profile_screen.dart';
// import 'student_plan_screen.dart'; // No longer direct nav
import 'student_plans_list_screen.dart';
import '../../widgets/payment_status_badge.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
         actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             _buildHeader(user),
            const SizedBox(height: 32),
            _buildDashboardCard(
              context,
              title: 'My Plans', // Changed to plural
              subtitle: 'View active and past plans', // Added subtitle context
              icon: Icons.fitness_center,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StudentPlansListScreen()),
                );
              },
            ),
             const SizedBox(height: 16),
            _buildDashboardCard(
              context,
              title: 'My Profile',
              subtitle: 'Update your goals and weight',
              icon: Icons.person,
              color: Colors.blue,
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
              title: 'Gym Schedule',
              subtitle: 'Check opening hours',
              icon: Icons.access_time,
              color: Colors.orange,
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

  Widget _buildHeader(User? user) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Text(
            (user?.firstName ?? 'S')[0].toUpperCase(),
            style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 24),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back,', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
            Text(user?.firstName ?? "Student", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            PaymentStatusBadge(status: user?.paymentStatus, isEditable: false),
          ],
        ),
      ],
    );
  }

  Widget _buildDashboardCard(BuildContext context,
      {required String title, String? subtitle, required IconData icon, required VoidCallback onTap, Color color = Colors.blue}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (subtitle != null)
                      Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

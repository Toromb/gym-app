import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'gyms_list_screen.dart';
import 'gym_admins_screen.dart';

class SuperAdminDashboardScreen extends StatelessWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDashboardCard(
            context,
            icon: Icons.fitness_center,
            title: 'Manage Gyms',
            onTap: () {
                 Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GymsListScreen()),
                  );
            },
          ),
          _buildDashboardCard(
            context,
            icon: Icons.admin_panel_settings,
            title: 'Manage Admins',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GymAdminsScreen())
              );
            },
          ),
           _buildDashboardCard(
            context,
            icon: Icons.analytics,
            title: 'Platform Stats',
             onTap: () {
              // Stats
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48.0, color: Theme.of(context).primaryColor),
            const SizedBox(height: 16.0),
            Text(title, style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'gyms_list_screen.dart';
import 'gym_admins_screen.dart';
import 'platform_stats_screen.dart';

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              'Panel de Super Admin',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Gestión global de la plataforma',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),

            _buildDashboardCard(
              context,
              icon: Icons.fitness_center,
              title: 'Gestionar Gimnasios',
              subtitle: 'Ver, crear y editar gimnasios registrados',
              onTap: () {
                 if (context.mounted) {
                   Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const GymsListScreen()),
                    );
                 }
              },
            ),
            const SizedBox(height: 16),
            _buildDashboardCard(
              context,
              icon: Icons.admin_panel_settings,
              title: 'Gestionar Admins',
              subtitle: 'Administrar cuentas de administradores',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GymAdminsScreen())
                );
              },
            ),
            const SizedBox(height: 16),
             _buildDashboardCard(
              context,
              icon: Icons.analytics,
              title: 'Estadísticas de Plataforma',
              subtitle: 'Métricas globales y rendimiento',
               onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PlatformStatsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, 
      {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    
    final primaryColor = Theme.of(context).primaryColor;
    
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 30.0, color: primaryColor),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title, 
                      style: TextStyle(
                        fontSize: 18.0, 
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800]
                      )
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle, 
                      style: TextStyle(fontSize: 13.0, color: Colors.grey[600])
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import 'gyms_list_screen.dart';
import 'gym_admins_screen.dart';
import 'platform_stats_screen.dart';

class SuperAdminDashboardScreen extends StatelessWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Dashboard'),
        actions: [
          Consumer<ThemeProvider>(
            builder: (_, themeProvider, __) => IconButton(
              icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => themeProvider.toggleTheme(!themeProvider.isDarkMode),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
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
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary, // Theme aware
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Gestión global de la plataforma',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant, // Theme aware
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
    
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    
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
                  color: primaryColor.withValues(alpha: 0.1),
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
                        color: theme.colorScheme.onSurface, // Theme aware
                      )
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle, 
                      style: TextStyle(fontSize: 13.0, color: theme.colorScheme.onSurfaceVariant) // Theme aware
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

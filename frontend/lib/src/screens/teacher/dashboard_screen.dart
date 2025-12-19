import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'manage_students_screen.dart';
import 'create_plan_screen.dart';
import '../shared/plans_list_screen.dart';
import 'exercises_list_screen.dart';
import '../shared/gym_schedule_screen.dart';
import '../profile_screen.dart';
import '../../widgets/payment_status_badge.dart';

class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.get('dashboardTitleProfe')),
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
             // Header Section
             Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                   // User Info - Flex 3
                   Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                             Text(
                               '${AppLocalizations.of(context)!.welcome},', 
                               style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12, color: Colors.grey)
                             ),
                             Text(
                               '${user?.firstName ?? user?.email ?? "Profesor"}!',
                               style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                             ),
                             const SizedBox(height: 2),
                             PaymentStatusBadge(status: user?.paymentStatus, isEditable: false),
                        ],
                      ),
                   ),

                   // Logo (Center) - Flex 2
                   Expanded(
                     flex: 2,
                     child: Center(
                       child: user?.gym?.logoUrl != null
                           ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                      user!.gym!.logoUrl!.startsWith('http') 
                                          ? user!.gym!.logoUrl! 
                                          : 'http://localhost:3000${user!.gym!.logoUrl}',
                                      height: 80, 
                                      fit: BoxFit.contain,
                                      errorBuilder: (c,e,s) => const SizedBox.shrink(),
                                   ),
                             )
                           : const SizedBox.shrink(),
                     ),
                   ),

                   // Gym Info (Right) - Flex 3
                   Expanded(
                      flex: 3,
                      child: user?.gym != null 
                        ? Container(
                         margin: const EdgeInsets.only(left: 4),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.end,
                           children: [
                               Text(
                                   user!.gym!.businessName, 
                                   style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.primary), 
                                   textAlign: TextAlign.end,
                                   overflow: TextOverflow.ellipsis,
                                   maxLines: 2,
                               ),
                               const SizedBox(height: 2),
                               if (user!.gym!.phone != null && user!.gym!.phone!.isNotEmpty)
                                   Text(user!.gym!.phone!, style: TextStyle(fontSize: 11, color: colorScheme.secondary), textAlign: TextAlign.end), 
                           ],
                         ),
                      )
                      : const SizedBox.shrink()
                   )
                ],
             ),
            const SizedBox(height: 32),
            
            _buildDashboardCard(
              context,
              title: AppLocalizations.of(context)!.get('manageStudents'),
              subtitle: 'Ver progresos y asignar planes',
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
              title: AppLocalizations.of(context)!.get('plansLibrary'),
              subtitle: 'Tus plantillas de entrenamiento',
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
              title: 'Biblioteca de Ejercicios',
              subtitle: 'Catálogo global del gimnasio',
              icon: Icons.fitness_center,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ExercisesListScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildDashboardCard(
              context,
              title: AppLocalizations.of(context)!.get('gymSchedule'),
              subtitle: 'Horarios de atención',
              icon: Icons.access_time,
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
              title: AppLocalizations.of(context)!.get('profileTitle'),
              subtitle: 'Tus datos personales',
              icon: Icons.person,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context,
      {required String title, String? subtitle, required IconData icon, required VoidCallback onTap}) {
    
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                       Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                    ]
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }



  Widget _infoRow(IconData icon, String text) {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
              children: [
                  Icon(icon, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
              ],
          ),
      );
  }
}

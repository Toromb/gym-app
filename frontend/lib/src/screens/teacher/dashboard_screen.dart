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
                               style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12, color: Colors.grey) // Increased
                             ),
                             Text(
                               '${user?.firstName ?? user?.email ?? "Profesor"}!',
                               style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16), // Increased
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
                                      height: 100, // Increased
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
                                   style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor), // Increased
                                   textAlign: TextAlign.end,
                                   overflow: TextOverflow.ellipsis,
                                   maxLines: 2,
                               ),
                               const SizedBox(height: 2),
                               if (user!.gym!.phone != null && user!.gym!.phone!.isNotEmpty)
                                   Text(user!.gym!.phone!, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.secondary), textAlign: TextAlign.end), 
                               if (user!.gym!.email != null && user!.gym!.email!.isNotEmpty)
                                   Text(user!.gym!.email!, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.secondary), textAlign: TextAlign.end), 
                               if (user!.gym!.address != null && user!.gym!.address!.isNotEmpty)
                                   Text(user!.gym!.address!, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.secondary), textAlign: TextAlign.end), 
                           ],
                         ),
                      )
                      : const SizedBox.shrink()
                   )
                ],
             ),
            const SizedBox(height: 20),
            


            _buildDashboardCard(
              context,
              title: AppLocalizations.of(context)!.get('manageStudents'),
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
      {required String title, required IconData icon, required VoidCallback onTap}) {
    
    final iconColor = Theme.of(context).primaryColor;
    final titleColor = Theme.of(context).colorScheme.secondary;

    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: iconColor),
              const SizedBox(width: 20),
              Text(title, style: TextStyle(fontSize: 20, color: titleColor)),
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

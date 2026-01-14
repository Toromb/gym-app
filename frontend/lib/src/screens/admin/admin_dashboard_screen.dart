import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'manage_users_screen.dart';
import '../shared/plans_list_screen.dart';
import '../teacher/exercises_list_screen.dart';
import '../shared/gym_schedule_screen.dart';
import '../profile_screen.dart';
import 'gym_config_screen.dart';
import '../../providers/gym_schedule_provider.dart';
import '../../models/gym_schedule_model.dart';
import 'manage_equipments_screen.dart';
import 'free_training/manage_free_trainings_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GymScheduleProvider>().fetchSchedule();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        actions: [
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
                               'Bienvenido,', 
                               style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12, color: Colors.grey)
                             ),
                             Text(
                               user?.firstName ?? 'Admin',
                               style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                             ),
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
                                          ? user.gym!.logoUrl! 
                                          : 'http://localhost:3001${user.gym!.logoUrl}',
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
                               if (user.gym!.address.isNotEmpty)
                                   Text(user.gym!.address, style: TextStyle(fontSize: 11, color: colorScheme.secondary), textAlign: TextAlign.end), 
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
              title: 'Gestionar Usuarios',
              subtitle: 'Altas, bajas y modificaciones',
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
              title: 'Biblioteca de Planes',
              subtitle: 'Crear y editar planes base',
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
              title: 'Entrenamientos Libres',
              subtitle: 'Gestionar rutinas públicas',
              icon: Icons.repeat,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageFreeTrainingsScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildDashboardCard(
              context,
              title: 'Biblioteca de Ejercicios',
              subtitle: 'Gestionar ejercicios disponibles',
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
              title: 'Gestionar Equipamiento',
              subtitle: 'Equipos, máquinas y accesorios',
              icon: Icons.category, 
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageEquipmentsScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildDashboardCard(
              context,
              title: 'Horarios del Gimnasio',
              subtitle: _getTodayScheduleText(context),
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
              title: 'Configuración del Gym',
              subtitle: 'Logo, nombre y mensajes',
              icon: Icons.settings,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GymConfigScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
             _buildDashboardCard(
              context,
              title: 'Mi Perfil',
              subtitle: 'Tus datos personales',
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

  String _getTodayScheduleText(BuildContext context) {
      final schedules = context.watch<GymScheduleProvider>().schedules;
      if (schedules.isEmpty) return 'Configurar horarios de apertura'; // Fallback

      final now = DateTime.now();
      String dayKey = '';
      switch (now.weekday) {
          case 1: dayKey = 'MONDAY'; break;
          case 2: dayKey = 'TUESDAY'; break;
          case 3: dayKey = 'WEDNESDAY'; break;
          case 4: dayKey = 'THURSDAY'; break;
          case 5: dayKey = 'FRIDAY'; break;
          case 6: dayKey = 'SATURDAY'; break;
          case 7: dayKey = 'SUNDAY'; break;
      }

      // Find schedule or return default closed
      final todaySchedule = schedules.firstWhere(
        (s) => s.dayOfWeek == dayKey, 
        orElse: () => GymSchedule(id: 0, dayOfWeek: dayKey, isClosed: true)
      );
      
      // Get localized day name
      // Note: We might not have access to AppLocalizations in Admin context if not careful, but it should be there.
      // Reuse logic or simple map if needed. Assuming AppLocalizations works.
      String dayName = dayKey; 
      // Reuse Student Home simple logic if no localization context easily available? 
      // Admin dashboard already uses AppLocalizations elsewhere? No, it uses hardcoded strings in this file.
      // So I'll just use a simple map for Admin to be safe, or try AppLocalizations if available.
      // Actually AdminDashboard doesn't import AppLocalizations. I should avoid adding a dependency if not needed.
      // I'll use a simple Spanish map for now since existing text is Spanish.
      switch (dayKey) {
        case 'MONDAY': dayName = 'Lunes'; break;
        case 'TUESDAY': dayName = 'Martes'; break;
        case 'WEDNESDAY': dayName = 'Miércoles'; break;
        case 'THURSDAY': dayName = 'Jueves'; break;
        case 'FRIDAY': dayName = 'Viernes'; break;
        case 'SATURDAY': dayName = 'Sábado'; break;
        case 'SUNDAY': dayName = 'Domingo'; break;
      }

      if (todaySchedule.isClosed || todaySchedule.displayHours == 'Closed') {
          return 'Hoy $dayName: CERRADO';
      }
      
      return 'Hoy $dayName: ${todaySchedule.displayHours}';
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
}

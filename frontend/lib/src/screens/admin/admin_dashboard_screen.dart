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
import '../../widgets/dashboard_header.dart';
import 'collection_dashboard_screen.dart';
import '../../widgets/background_page_wrapper.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

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
    final String? bgUrl = user?.gym?.backgroundImageUrl != null
        ? resolveImageUrl(user!.gym!.backgroundImageUrl!)
        : null;

    return BackgroundPageWrapper(
      overlayOpacity: 0.72,
      backgroundNetworkUrl: bgUrl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    GymDashboardHeader(user: user, showPaymentStatus: false),
                    const SizedBox(height: 32),

                    _buildDashboardCard(
                      context,
                      title: 'Gestionar Usuarios',
                      subtitle: 'Altas, bajas y modificaciones',
                      icon: Icons.people,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ManageUsersScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── COBRANZA (nuevo en Fase 4) ──
                    _buildDashboardCard(
                      context,
                      title: 'Cobranza',
                      subtitle: 'Estado de cuotas y pagos',
                      icon: Icons.receipt_long,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const CollectionDashboardScreen()),
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
                          MaterialPageRoute(
                              builder: (context) => const PlansListScreen()),
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
                          MaterialPageRoute(
                              builder: (context) =>
                                  const ExercisesListScreen()),
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
                          MaterialPageRoute(
                              builder: (context) =>
                                  const ManageEquipmentsScreen()),
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
                          MaterialPageRoute(
                              builder: (context) =>
                                  const ManageFreeTrainingsScreen()),
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
                          MaterialPageRoute(
                              builder: (context) => const GymScheduleScreen()),
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
                          MaterialPageRoute(
                              builder: (context) => const GymConfigScreen()),
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
                          MaterialPageRoute(
                              builder: (context) => const ProfileScreen()),
                        );
                      },
                    ),
                    // Add more admin features here
                  ],
                ),
              ),
            ),
          ),
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
      case 1:
        dayKey = 'MONDAY';
        break;
      case 2:
        dayKey = 'TUESDAY';
        break;
      case 3:
        dayKey = 'WEDNESDAY';
        break;
      case 4:
        dayKey = 'THURSDAY';
        break;
      case 5:
        dayKey = 'FRIDAY';
        break;
      case 6:
        dayKey = 'SATURDAY';
        break;
      case 7:
        dayKey = 'SUNDAY';
        break;
    }

    // Find schedule or return default closed
    final todaySchedule = schedules.firstWhere((s) => s.dayOfWeek == dayKey,
        orElse: () => GymSchedule(id: 0, dayOfWeek: dayKey, isClosed: true));

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
      case 'MONDAY':
        dayName = 'Lunes';
        break;
      case 'TUESDAY':
        dayName = 'Martes';
        break;
      case 'WEDNESDAY':
        dayName = 'Miércoles';
        break;
      case 'THURSDAY':
        dayName = 'Jueves';
        break;
      case 'FRIDAY':
        dayName = 'Viernes';
        break;
      case 'SATURDAY':
        dayName = 'Sábado';
        break;
      case 'SUNDAY':
        dayName = 'Domingo';
        break;
    }

    if (todaySchedule.isClosed || todaySchedule.displayHours == 'Closed') {
      return 'Hoy $dayName: CERRADO';
    }

    return 'Hoy $dayName: ${todaySchedule.displayHours}';
  }

  Widget _buildDashboardCard(BuildContext context,
      {required String title,
      String? subtitle,
      required IconData icon,
      required VoidCallback onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : AppColors.cardSurface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color:
                isDark ? Colors.white12 : Colors.white.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E7FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 28, color: const Color(0xFF4338ca)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : colorScheme.onSurface,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? Colors.white70
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: isDark ? Colors.grey[500] : Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'manage_students_screen.dart';
import '../shared/plans_list_screen.dart';
import 'exercises_list_screen.dart';
import '../shared/gym_schedule_screen.dart';
import '../profile_screen.dart';
import '../../providers/gym_schedule_provider.dart';
import '../../models/gym_schedule_model.dart';
import '../student/free_training/free_training_selector_screen.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/background_page_wrapper.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
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
                    GymDashboardHeader(user: user, showPaymentStatus: true),
                    const SizedBox(height: 32),

                    _buildDashboardCard(
                      context,
                      title: AppLocalizations.of(context)!.get('manageStudents'),
                      subtitle: 'Ver progresos y asignar planes',
                      icon: Icons.people,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ManageStudentsScreen()),
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
                          MaterialPageRoute(
                              builder: (context) => const PlansListScreen()),
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
                          MaterialPageRoute(
                              builder: (context) => const ExercisesListScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDashboardCard(
                      context,
                      title: 'Entrenamiento Libre',
                      subtitle: 'Realizar rutina sin plan',
                      icon: Icons.timer,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const FreeTrainingSelectorScreen(
                                      isAdminMode: false)),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDashboardCard(
                      context,
                      title: AppLocalizations.of(context)!.get('gymSchedule'),
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
                      title: AppLocalizations.of(context)!.get('profileTitle'),
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
    if (schedules.isEmpty) return 'Horarios de atención'; // Default fallback

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
    final loc = AppLocalizations.of(context)!;
    String dayName = '';
    switch (dayKey) {
      case 'MONDAY':
        dayName = loc.get('day_monday');
        break;
      case 'TUESDAY':
        dayName = loc.get('day_tuesday');
        break;
      case 'WEDNESDAY':
        dayName = loc.get('day_wednesday');
        break;
      case 'THURSDAY':
        dayName = loc.get('day_thursday');
        break;
      case 'FRIDAY':
        dayName = loc.get('day_friday');
        break;
      case 'SATURDAY':
        dayName = loc.get('day_saturday');
        break;
      case 'SUNDAY':
        dayName = loc.get('day_sunday');
        break;
      default:
        dayName = dayKey;
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
            ? Colors.white.withOpacity(0.08)
            : AppColors.cardSurface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark ? Colors.white12 : Colors.white.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.15),
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
                  child: Icon(icon,
                      size: 28, color: const Color(0xFF4338ca)),
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

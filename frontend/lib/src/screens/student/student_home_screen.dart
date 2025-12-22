import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/plan_provider.dart';
import '../../models/user_model.dart' as app_models;
import '../../localization/app_localizations.dart';
import '../../models/plan_model.dart';
import '../../models/student_assignment_model.dart';
import '../shared/day_detail_screen.dart';
import '../shared/gym_schedule_screen.dart';
import '../profile_screen.dart';
// import 'student_plan_screen.dart'; // No longer direct nav
import 'student_plans_list_screen.dart';
import 'student_plans_list_screen.dart';
import '../../widgets/payment_status_badge.dart';
import 'calendar_screen.dart';
import 'package:intl/intl.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {

  @override
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PlanProvider>();
      provider.fetchMyHistory();
      provider.computeWeeklyStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app_models.User? user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.get('dashboardTitle')),
         actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: Consumer<PlanProvider>(
        builder: (context, planProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 _buildHeader(user),
                const SizedBox(height: 24),

                // PROGRESS SUMMARY (Simple Text)
                if (planProvider.weeklyWorkoutCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'Has entrenado ${planProvider.weeklyWorkoutCount} ${planProvider.weeklyWorkoutCount == 1 ? "día" : "días"} esta semana. ¡Seguí así!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),

                // --- NEXT WORKOUT SECTION ---
                _buildNextWorkoutCard(context, planProvider),
                const SizedBox(height: 24),
                // ----------------------------

                _buildDashboardCard(
                  context,
                  title: 'Mi rutina', // Renamed from "Planes"
                  subtitle: planProvider.nextWorkout != null && planProvider.nextWorkout!['week'] != null
                      ? 'Plan activo: Semana ${(planProvider.nextWorkout!['week'] as PlanWeek).weekNumber}'
                      : AppLocalizations.of(context)!.get('myPlansSub'),
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
                  title: AppLocalizations.of(context)!.get('workoutHistory'),
                  subtitle: planProvider.weeklyWorkoutCount > 0 
                      ? 'Entrenamientos esta semana: ${planProvider.weeklyWorkoutCount}'
                      : AppLocalizations.of(context)!.get('workoutHistorySub'),
                  icon: Icons.calendar_month,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CalendarScreen()),
                    );
                  },
                ),
                 const SizedBox(height: 16),
                _buildDashboardCard(
                  context,
                  title: AppLocalizations.of(context)!.get('gymSchedule'),
                  subtitle: user?.gym?.openingHours != null && user!.gym!.openingHours!.isNotEmpty
                      ? 'Hoy abierto: ${user.gym!.openingHours}'
                      : AppLocalizations.of(context)!.get('gymScheduleSub'),
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
                  subtitle: AppLocalizations.of(context)!.get('profileSub'),
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
          );
        },
      ),
    );
  }

  Widget _buildNextWorkoutCard(BuildContext context, PlanProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (provider.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Logic to determine state
    final next = provider.nextWorkout;
    // Map: { 'week': PlanWeek, 'day': PlanDay, 'assignment': StudentAssignment } OR { 'finished': true } OR null

    if (next == null) {
      // No assignments
      if (provider.assignments.isEmpty) {
        return _buildGenericInfoCard(
          context, 
          'Sin plan asignado', 
          'Consultá con tu profesor para comenzar.',
          Icons.info_outline,
          colorScheme.secondary
        );
      }
      // Assignments exist but activeAssignment logic failed (e.g. none active?)
      // Or user explicitly reset. Suggest picking one.
      return _buildGenericInfoCard(
          context,
          'Seleccioná un plan',
          'Tenés planes disponibles. Tocá acá para elegir cuál iniciar.',
          Icons.touch_app,
          colorScheme.tertiary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const StudentPlansListScreen()),
            ).then((_) => context.read<PlanProvider>().fetchMyHistory());
          }
      );
    }

    if (next['finished'] == true) {
       final assignment = next['assignment'] as StudentAssignment?;
       
       return Card(
        color: colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                   Icon(Icons.emoji_events, color: colorScheme.primary, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text('¡Plan Completado!', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Felicitaciones. Has completado todos los entrenamientos de este plan.', style: textTheme.bodyMedium),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reiniciar Plan'),
                  onPressed: () {
                     if (assignment == null) return;
                     showDialog(
                       context: context,
                       builder: (context) => AlertDialog(
                         title: const Text('¿Reiniciar Plan?'),
                         content: const Text('Esto archivará tu progreso actual y comenzará un nuevo ciclo desde el día 1.'),
                         actions: [
                           TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                           FilledButton(
                             onPressed: () async {
                               Navigator.pop(context); // Close dialog
                               final success = await context.read<PlanProvider>().restartPlan(assignment.id);
                               if (success && mounted) {
                                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan reiniciado exitosamente')));
                               }
                             }, 
                             child: const Text('Reiniciar')
                           ),
                         ],
                       ),
                     );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    // We have a next workout
    final week = next['week'] as PlanWeek;
    final day = next['day'] as PlanDay; 
    final assignment = next['assignment'] as StudentAssignment; 
    final planId = assignment.plan.id!; // Force unwrap as plan must have ID

    return Card(
      color: colorScheme.primary, // Hero color
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () async {
          // Navigate to DayDetail
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DayDetailScreen(
                day: day, 
                planId: planId, 
                weekNumber: week.weekNumber
              )
            ),
          );

          // If result is true, it means completed. Refresh history to update this card.
          if (result == true && mounted) {
           if (result == true && mounted) {
             context.read<PlanProvider>().fetchMyHistory();
             context.read<PlanProvider>().computeWeeklyStats();
          }
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('PRÓXIMO ENTRENAMIENTO', style: textTheme.labelSmall?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                (day.title ?? 'Día ${day.dayOfWeek}').replaceAll('Day', 'Día'),
                style: textTheme.displaySmall?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.w800, fontSize: 28),
              ),
              const SizedBox(height: 8),
              Text(
                '${assignment.plan.name} • Semana ${week.weekNumber}',
                style: textTheme.bodyLarge?.copyWith(color: colorScheme.onPrimary.withOpacity(0.9)),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                   Text(
                     'Comenzar entrenamiento', 
                     style: textTheme.titleMedium?.copyWith(
                       color: colorScheme.onPrimary, 
                       fontWeight: FontWeight.bold
                     )
                   ),
                   const SizedBox(width: 8),
                   Icon(Icons.arrow_forward, color: colorScheme.onPrimary),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenericInfoCard(BuildContext context, String title, String subtitle, IconData icon, Color color, {VoidCallback? onTap}) {
     // Use surface container low for "empty state" cards
     final colorScheme = Theme.of(context).colorScheme;
     
     return Card(
      color: colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              if (onTap != null) Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(app_models.User? user) {
    final welcomeMessage = user?.gym?.welcomeMessage;
    final colorScheme = Theme.of(context).colorScheme;

    // Format expiration date if available
    String? expirationFormatted;
    if (user?.membershipExpirationDate != null) {
        try {
            final date = DateTime.parse(user!.membershipExpirationDate!);
            expirationFormatted = DateFormat('dd/MM', 'es').format(date);
        } catch (_) {}
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, 
      children: [
        // 1. Header Row: Name/Stats & Gym Info
        Row(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
             // Left: User Name & Status
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    Text(
                      '${user?.firstName} ${user?.lastName ?? ""} (Alumno)'.trim(),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    PaymentStatusBadge(
                      status: user?.paymentStatus, 
                      isEditable: false,
                      expirationDate: expirationFormatted, // Logic for date
                    ),
                 ],
               ),
             ),
             
             // Right: Gym Logo/Info (Less Visual Weight)
             if (user?.gym != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                    if (user!.gym!.logoUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                            user!.gym!.logoUrl!.startsWith('http') 
                                ? user!.gym!.logoUrl! 
                                : 'http://localhost:3000${user!.gym!.logoUrl}',
                            height: 40, // Smaller logo
                            width: 40,
                            fit: BoxFit.contain,
                            errorBuilder: (c,e,s) => const Icon(Icons.fitness_center, color: Colors.grey),
                         ),
                      ),
                     const SizedBox(height: 8),
                     Text(
                       user!.gym!.businessName,
                       style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                       textAlign: TextAlign.end,
                     ),
                ],
              )
          ],
        ),
        
        // 2. Admin Message (Reduced Weight)
        if (welcomeMessage != null && welcomeMessage.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow, // Neutral background
                    borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                          welcomeMessage,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[800]),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ),
        ],
      ],
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
                    if (subtitle != null)
                      Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
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

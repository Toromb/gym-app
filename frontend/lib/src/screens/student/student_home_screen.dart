import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/plan_provider.dart';
import '../../providers/gym_schedule_provider.dart';
import '../../models/user_model.dart' as app_models;
import '../../localization/app_localizations.dart';
import '../../models/gym_schedule_model.dart';
import '../../models/plan_model.dart';
import '../../models/student_assignment_model.dart';
import '../shared/day_detail_screen.dart';
import '../shared/gym_schedule_screen.dart';
import '../profile_screen.dart';
// import 'student_plan_screen.dart'; // No longer direct nav
import 'student_plans_list_screen.dart';
import '../../widgets/payment_status_badge.dart';
import 'calendar_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {

  @override
  void initState() {
    super.initState();
    // Fetch history to determine next workout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlanProvider>().fetchMyHistory();
      context.read<GymScheduleProvider>().fetchSchedule();
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
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
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
                const SizedBox(height: 20),

                const SizedBox(height: 20),
                
                // --- NEXT WORKOUT SECTION ---
                _buildNextWorkoutCard(context, planProvider),
                const SizedBox(height: 24),
                // ----------------------------

                _buildDashboardCard(
                  context,
                  title: AppLocalizations.of(context)!.get('navPlans'), 
                  subtitle: AppLocalizations.of(context)!.get('myPlansSub'),
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
                  subtitle: AppLocalizations.of(context)!.get('workoutHistorySub'),
                  icon: Icons.calendar_month,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CalendarScreen()),
                    );
                  },
                ),
                 const SizedBox(height: 16),
                 // Dynamic Gym Schedule Card
                Consumer<GymScheduleProvider>(
                  builder: (context, scheduleProvider, _) {
                    String subtitle = AppLocalizations.of(context)!.get('gymScheduleSub');
                    
                    if (!scheduleProvider.isLoading && scheduleProvider.schedules.isNotEmpty) {
                       final now = DateTime.now();
                       final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
                       final todayName = days[now.weekday - 1];
                       
                       try {
                         // Find today schedule
                         final actualToday = scheduleProvider.schedules.cast<GymSchedule?>().firstWhere(
                            (s) => s!.dayOfWeek.toLowerCase() == todayName.toLowerCase(),
                            orElse: () => null
                         );

                         if (actualToday != null) {
                            subtitle = actualToday.isClosed 
                                ? 'Hoy: Cerrado' 
                                : 'Hoy: ${actualToday.displayHours}';
                         }
                       } catch (e) {
                         // Fallback
                       }
                    }

                    return _buildDashboardCard(
                      context,
                      title: AppLocalizations.of(context)!.get('gymSchedule'),
                      subtitle: subtitle,
                      icon: Icons.access_time,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const GymScheduleScreen()),
                        );
                      },
                    );
                  }
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
             context.read<PlanProvider>().fetchMyHistory();
          }
        },
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
                  const Spacer(),
                  Icon(Icons.arrow_forward, color: colorScheme.onPrimary),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                day.title ?? 'Día ${day.dayOfWeek}',
                style: textTheme.displaySmall?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Semana ${week.weekNumber} - ${assignment.plan.name}',
                style: textTheme.bodyLarge?.copyWith(color: colorScheme.onPrimary.withOpacity(0.8)),
              ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, 
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center, 
          children: [
            // User Info (Left) - Flex 4 (Increased space since we removed avatar)
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.get('welcomeBack'), style: Theme.of(context).textTheme.bodySmall), 
                  Text(
                    user?.name ?? "Student", 
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), 
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2, // Allow wrapping if barely fitting
                  ), 
                  const SizedBox(height: 4),
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
               )
             ),

            // Gym Info (Right) - Flex 3
             Expanded(
                flex: 3,
                child: user?.gym != null 
                 ? Column(
                   crossAxisAlignment: CrossAxisAlignment.end,
                   children: [
                       Text(
                           user!.gym!.businessName, 
                           style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
                           textAlign: TextAlign.end,
                           overflow: TextOverflow.ellipsis,
                           maxLines: 2,
                       ),
                       const SizedBox(height: 2),
                       if (user!.gym!.phone != null && user!.gym!.phone!.isNotEmpty)
                           Text(user!.gym!.phone!, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.end), 
                       if (user!.gym!.address != null && user!.gym!.address!.isNotEmpty)
                           Text(user!.gym!.address!, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.end), 
                   ],
                 )
                 : const SizedBox.shrink(),
              )
          ],
        ),
        if (welcomeMessage != null && welcomeMessage.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                    welcomeMessage,
                    style: TextStyle(
                        fontStyle: FontStyle.italic, 
                        color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
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

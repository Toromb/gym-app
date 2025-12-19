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
                  color: Theme.of(context).colorScheme.primary, // Dynamic Primary
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
                  color: Theme.of(context).colorScheme.secondary, // Dynamic Secondary
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
                  subtitle: AppLocalizations.of(context)!.get('gymScheduleSub'),
                  icon: Icons.access_time,
                  color: Theme.of(context).colorScheme.tertiary ?? Colors.orange, // Dynamic Tertiary
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
                  color: Theme.of(context).colorScheme.primary, 
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
          Colors.grey
        );
      }
      // Assignments exist but activeAssignment logic failed (e.g. none active?)
      // Or user explicitly reset. Suggest picking one.
      return _buildGenericInfoCard(
          context,
          'Seleccioná un plan',
          'Tenés planes disponibles. Tocá acá para elegir cuál iniciar.',
          Icons.touch_app,
          Colors.orange,
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
        elevation: 4,
        color: Colors.amber.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.orange, size: 40),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text('¡Plan Completado!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Felicitaciones. Has completado todos los entrenamientos de este plan.', style: TextStyle(color: Colors.brown)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reiniciar Plan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                     if (assignment == null) return;
                     showDialog(
                       context: context,
                       builder: (context) => AlertDialog(
                         title: const Text('¿Reiniciar Plan?'),
                         content: const Text('Esto archivará tu progreso actual y comenzará un nuevo ciclo desde el día 1. Tu historial de entrenamientos se mantendrá visible en el calendario.'),
                         actions: [
                           TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                           ElevatedButton(
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
      elevation: 4,
      color: Theme.of(context).primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('PRÓXIMO ENTRENAMIENTO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward, color: Colors.white),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                day.title ?? 'Día ${day.dayOfWeek}',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Semana ${week.weekNumber} - ${assignment.plan.name}',
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenericInfoCard(BuildContext context, String title, String subtitle, IconData icon, Color color, {VoidCallback? onTap}) {
     return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
                    Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: color.withOpacity(0.8), fontSize: 14)),
                  ],
                ),
              ),
              if (onTap != null) Icon(Icons.arrow_forward_ios, size: 16, color: color.withOpacity(0.6)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(app_models.User? user) {
    final welcomeMessage = user?.gym?.welcomeMessage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, // Ensure fill
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center, // Center vertically
          children: [
            // User Info (Left) - Flex 3
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28, // Increased
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      (user?.name ?? 'S')[0].toUpperCase(),
                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: 22), // Increased
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.get('welcomeBack'), style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)), // Increased
                        Text(user?.name ?? "Student", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis), // Increased
                        const SizedBox(height: 2),
                        PaymentStatusBadge(status: user?.paymentStatus, isEditable: false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Logo (Center) - Flex 2 - Large
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
               )
             ),

            // Gym Info (Right) - Flex 2
             Expanded(
                flex: 3,
                child: user?.gym != null 
                 ? Column(
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
                 )
                 : const SizedBox.shrink(),
              )
          ],
        ),
        if (welcomeMessage != null && welcomeMessage.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                ),
                child: Text(
                    welcomeMessage,
                    style: TextStyle(
                        fontStyle: FontStyle.italic, 
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                ),
            ),
        ],
      ],
    );
  }

  Widget _buildDashboardCard(BuildContext context,
      {required String title, String? subtitle, required IconData icon, required VoidCallback onTap, Color? color}) {
    
    // User Requirement: Icons = Primary, Intaractive Words (Title) = Secondary
    final iconColor = Theme.of(context).primaryColor;
    final titleColor = Theme.of(context).colorScheme.secondary;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: iconColor),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor)),
                    if (subtitle != null)
                      Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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

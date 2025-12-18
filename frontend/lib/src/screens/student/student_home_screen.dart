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
                const SizedBox(height: 32),
                
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
                  color: Colors.purple,
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
                  color: Colors.orange,
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
                  color: Colors.blue,
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
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Text(
            (user?.name ?? 'S')[0].toUpperCase(),
            style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 24),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.get('welcomeBack'), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
            Text(user?.name ?? "Student", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            PaymentStatusBadge(status: user?.paymentStatus, isEditable: false),
          ],
        ),
      ],
    );
  }

  Widget _buildDashboardCard(BuildContext context,
      {required String title, String? subtitle, required IconData icon, required VoidCallback onTap, Color color = Colors.blue}) {
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
}

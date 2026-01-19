import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/plan_provider.dart';
import '../../providers/stats_provider.dart'; // Import StatsProvider
import '../../models/user_model.dart' as app_models;
import '../../models/stats_model.dart'; // Import StatsModel
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
import '../../providers/gym_schedule_provider.dart';
import '../../models/gym_schedule_model.dart';
import 'package:intl/intl.dart';

import 'free_training/free_training_selector_screen.dart';
import 'profile/profile_progress_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 2. Load Dashboard Data (Only if onboarded)
      // Since we are here, we are onboarded (guaranteed by HomeScreen)
      final provider = context.read<PlanProvider>();
      provider.fetchMyHistory();
      provider.computeWeeklyStats();
      provider.computeMonthlyStats();
      
      context.read<GymScheduleProvider>().fetchSchedule();
      
      // Fetch Progress for Level Summary
      print('DEBUG: StudentHomeScreen - Calling fetchProgress');
      context.read<StatsProvider>().fetchProgress().then((_) {
         print('DEBUG: StudentHomeScreen - fetchProgress COMPLETED. Data: ${context.read<StatsProvider>().progress?.level?.current}');
      }).catchError((e) {
         print('DEBUG: StudentHomeScreen - fetchProgress FAILED: $e');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: StudentHomeScreen build called - V1.1');
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Consumer<PlanProvider>(
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
                      subtitle: planProvider.nextWorkout != null && planProvider.nextWorkout!['assignment'] != null
                          ? 'Plan activo: ${(planProvider.nextWorkout!['assignment'] as StudentAssignment).plan.name}'
                          : AppLocalizations.of(context)!.get('myPlansSub'),
                      icon: Icons.fitness_center,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const StudentPlansListScreen()),
                        ).then((_) async {
                           // 1. Flush Queue & Get Result
                           print('DEBUG: StudentHomeScreen - Waiting for updates...');
                           final newStatsMap = await context.read<PlanProvider>().waitForPendingUpdates();
                           print('DEBUG: StudentHomeScreen - Got stats map: $newStatsMap');
                           
                           if (context.mounted) {
                               if (newStatsMap != null) {
                                   print('DEBUG: Direct Update Route');
                                   // DIRECT UPDATE: We got the stats from the backend transaction!
                                   // Map structure from backend: { totalExperience: ..., currentLevel: ... }
                                   // Frontend UserProgress structure needs adaptation if backend format differs.
                                   // Backend 'stats.service.ts' returns simple object in updateStats/save.
                                   // Frontend 'StatsModel' (UserProgress) expects: level: { current, exp }, etc.
                                   // Wait, backend 'updateStats' returns the RAW entity (UserStats).
                                   // Frontend expects the composite 'getProgress' structure.
                                   // Ah. I returned RAW entity from backend.
                                   
                                   // FIX: I should have returned getProgress() from backend or handle simple mapping here.
                                   // Let's rely on simple mapping here to avoid re-fetching everything.
                                   final rawStats = newStatsMap;
                                   final currentLevel = rawStats['currentLevel'] as int? ?? 1;
                                   final currentExp = rawStats['totalExperience'] as int? ?? 0;
                                   
                                   print('DEBUG: Updating to Level $currentLevel, Exp $currentExp');

                                   // Create partial or synthetic progress object
                                   // Since we don't have the full volumetrics, maybe we should just set the level info?
                                   // Or, we can trigger a fetch if we strictly want full data, BUT
                                   // The user cares about the "Mi Progreso" card visually updating.
                                   // That card reads `stats.progress?.level`.
                                   
                                   // Let's reconstruct or patch current progress.
                                   // If we have previous progress, copy it.
                                   final oldProgress = context.read<StatsProvider>().progress;
                                   if (oldProgress != null) {
                                       final newProgress = oldProgress.copyWith(
                                           level: LevelStats(current: currentLevel, exp: currentExp)
                                       );
                                       context.read<StatsProvider>().setDirectProgress(newProgress);
                                   } else {
                                        // Fetch if we had nothing (safe fallback)
                                        context.read<StatsProvider>().fetchProgress();
                                   }
                                   
                               } else {
                                   print('DEBUG: Fallback Route (Fetch)');
                                   // Fallback if no stats returned (e.g. offline or other endpoint)
                                   context.read<StatsProvider>().fetchProgress();
                               }

                               // Always refresh dashboard charts
                               context.read<PlanProvider>().computeWeeklyStats();
                           }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // --- MI PROGRESO (Level Summary) ---
                    Consumer<StatsProvider>(
                      builder: (context, stats, child) {
                        Widget? subtitleWidget;
                        String? subtitleText = 'Evolución de peso, volumen y carga.';

                        final progress = stats.progress;
                        if (progress != null) {
                            final level = progress.level;
                            final currentExp = level.exp;
                            // Manual Thresholds (Same as ProfileProgressScreen to avoid heavy logic import)
                            int getNext(int exp) {
                              if (exp < 100) return 100;
                              if (exp < 300) return 300;
                              if (exp < 1300) return 1300;
                              if (exp < 3000) return 3000;
                              if (exp < 6000) return 6000;
                              if (exp < 10000) return 10000;
                              if (exp < 16000) return 16000;
                              if (exp < 30000) return 30000;
                              if (exp < 50000) return 50000;
                              return 1000000;
                            }
                            int getPrev(int exp) {
                              if (exp < 100) return 0;
                              if (exp < 300) return 100;
                              if (exp < 1300) return 300;
                              if (exp < 3000) return 1300;
                              if (exp < 6000) return 3000;
                              if (exp < 10000) return 6000;
                              if (exp < 16000) return 10000;
                              if (exp < 30000) return 16000;
                              if (exp < 50000) return 30000;
                              return 50000;
                            }
                            
                            final nextExp = getNext(currentExp);
                            final prevExp = getPrev(currentExp);
                            final range = nextExp - prevExp;
                            final p = range > 0 ? ((currentExp - prevExp) / range).clamp(0.0, 1.0) : 1.0;
                            
                            // Difficulty (Optional text)
                            String diff = "Principiante";
                            if (level.current >= 10) diff = "Medio";
                            if (level.current >= 30) diff = "Difícil";
                            if (level.current >= 50) diff = "Muy Difícil";

                            subtitleText = null;
                            subtitleWidget = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                 Text('Nivel ${level.current} • $diff', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).colorScheme.primary)),
                                 const SizedBox(height: 6),
                                 ClipRRect(
                                   borderRadius: BorderRadius.circular(4),
                                   child: LinearProgressIndicator(
                                     value: p,
                                     minHeight: 6,
                                     backgroundColor: Colors.grey[300],
                                     valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
                                   ),
                                 ),
                                 const SizedBox(height: 4),
                                 Text('${currentExp} / $nextExp XP', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                              ],
                            );
                        }

                        return _buildDashboardCard(
                          context,
                          title: 'Mi Progreso',
                          subtitle: subtitleText,
                          subtitleWidget: subtitleWidget,
                          icon: Icons.show_chart,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ProfileProgressScreen()),
                            ).then((_) {
                               // Refresh functionality on return if needed
                               context.read<StatsProvider>().fetchProgress();
                            });
                          },
                        );
                      }
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
                          MaterialPageRoute(builder: (context) => const GymScheduleScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDashboardCard(
                      context,
                      title: 'Entrenamiento Libre',
                      subtitle: 'Iniciá una sesión sin plan asignado.',
                      icon: Icons.add_circle_outline_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FreeTrainingSelectorScreen()
                          ),
                        ).then((result) async {
                           // 1. Flush Queue & Get Result
                           final newStatsMap = await context.read<PlanProvider>().waitForPendingUpdates();
                           
                           if (context.mounted) {
                               if (newStatsMap != null) {
                                   final rawStats = newStatsMap;
                                   final currentLevel = rawStats['currentLevel'] as int? ?? 1;
                                   final currentExp = rawStats['totalExperience'] as int? ?? 0;
                                   
                                   final oldProgress = context.read<StatsProvider>().progress;
                                   if (oldProgress != null) {
                                       final newProgress = oldProgress.copyWith(
                                           level: LevelStats(current: currentLevel, exp: currentExp)
                                       );
                                       context.read<StatsProvider>().setDirectProgress(newProgress);
                                   } else {
                                        context.read<StatsProvider>().fetchProgress();
                                   }
                               } else {
                                   context.read<StatsProvider>().fetchProgress();
                               }
                               
                               context.read<PlanProvider>().fetchMyHistory();
                               context.read<PlanProvider>().computeWeeklyStats();
                               context.read<PlanProvider>().computeMonthlyStats();
                           }
                        });
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
                    const SizedBox(height: 100), // Added bottom spacing for "breathing room"
                  ],
                ),
              );
            },
          ),
          ),
        ),
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
                       builder: (dialogCtx) => AlertDialog(
                         title: const Text('¿Reiniciar Plan?'),
                         content: const Text('Esto archivará tu progreso actual y comenzará un nuevo ciclo desde el día 1.'),
                         actions: [
                           TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancelar')),
                           FilledButton(
                             onPressed: () async {
                               Navigator.pop(dialogCtx); // Close dialog
                               final success = await context.read<PlanProvider>().restartPlan(assignment.id);
                               
                               if (!mounted) return;
                               if (success) {
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

          if (!mounted) return;
          if (result == true) {
              // 1. Flush Queue & Get Result
              final newStatsMap = await context.read<PlanProvider>().waitForPendingUpdates();
              
              if (context.mounted) {
                  if (newStatsMap != null) {
                      final rawStats = newStatsMap;
                      final currentLevel = rawStats['currentLevel'] as int? ?? 1;
                      final currentExp = rawStats['totalExperience'] as int? ?? 0;
                      
                      final oldProgress = context.read<StatsProvider>().progress;
                      if (oldProgress != null) {
                          final newProgress = oldProgress.copyWith(
                              level: LevelStats(current: currentLevel, exp: currentExp)
                          );
                          context.read<StatsProvider>().setDirectProgress(newProgress);
                      } else {
                          context.read<StatsProvider>().fetchProgress();
                      }
                  } else {
                      await context.read<StatsProvider>().fetchProgress();
                  }

                  context.read<PlanProvider>().computeWeeklyStats();
                  context.read<PlanProvider>().computeMonthlyStats();
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
                      color: colorScheme.onPrimary.withValues(alpha: 0.2),
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
                style: textTheme.bodyLarge?.copyWith(color: colorScheme.onPrimary.withValues(alpha: 0.9)),
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
                            user.gym!.logoUrl!.startsWith('http') 
                                ? user.gym!.logoUrl! 
                                : 'http://localhost:3001${user.gym!.logoUrl}',
                            height: 55, // Increased to 55px as requested
                            width: 55,
                            fit: BoxFit.contain,
                            errorBuilder: (c,e,s) => const Icon(Icons.fitness_center, color: Colors.grey),
                         ),
                      ),
                     const SizedBox(height: 8),
                     Text(
                       user.gym!.businessName,
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
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
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
      {required String title, String? subtitle, Widget? subtitleWidget, required IconData icon, required VoidCallback onTap}) {
    
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
                    if (subtitleWidget != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: subtitleWidget,
                      )
                    else if (subtitle != null)
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

  String _getTodayScheduleText(BuildContext context) {
      final schedules = context.watch<GymScheduleProvider>().schedules;
      if (schedules.isEmpty) return AppLocalizations.of(context)!.get('gymScheduleSub');

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
      final loc = AppLocalizations.of(context)!;
      String dayName = '';
      switch (dayKey) {
        case 'MONDAY': dayName = loc.get('day_monday'); break;
        case 'TUESDAY': dayName = loc.get('day_tuesday'); break;
        case 'WEDNESDAY': dayName = loc.get('day_wednesday'); break;
        case 'THURSDAY': dayName = loc.get('day_thursday'); break;
        case 'FRIDAY': dayName = loc.get('day_friday'); break;
        case 'SATURDAY': dayName = loc.get('day_saturday'); break;
        case 'SUNDAY': dayName = loc.get('day_sunday'); break;
        default: dayName = dayKey;
      }

      if (todaySchedule.isClosed || todaySchedule.displayHours == 'Closed') {
          return 'Hoy $dayName: CERRADO';
      }
      
      return 'Hoy $dayName: ${todaySchedule.displayHours}';
  }
}

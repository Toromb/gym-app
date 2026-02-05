import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/plan_provider.dart';
import '../../providers/theme_provider.dart';
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
import '../../widgets/dashboard_payment_button.dart';
import '../../utils/constants.dart'; // Import constants

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
       // Refresh user to get latest Gym Logo
       await context.read<AuthProvider>().refreshUser();

       if (!mounted) return;

       // Load Dashboard Data
       final planProvider = context.read<PlanProvider>();
       planProvider.fetchMyHistory();
       planProvider.computeWeeklyStats();
       planProvider.computeMonthlyStats();
       
       context.read<GymScheduleProvider>().fetchSchedule();
       
       context.read<StatsProvider>().fetchProgress().catchError((e) {
          debugPrint('StudentHomeScreen - fetchProgress FAILED: $e');
       });
    });
  }

  @override
  Widget build(BuildContext context) {
    // debugPrint('StudentHomeScreen build called');
    final app_models.User? user = context.watch<AuthProvider>().user;

    return Scaffold(

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
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
                        ).then((_) {
                           _refreshDashboardStats();
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
                        ).then((_) {
                           _refreshDashboardStats();
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
    // 1. Calculate Expiration Logic (Preserved)
    String? expirationFormatted;
    bool isExpired = false;
    bool isNearExpiration = false;
    
    if (user?.membershipExpirationDate != null) {
        try {
            final date = DateTime.parse(user!.membershipExpirationDate!);
            expirationFormatted = DateFormat('dd/MM', 'es').format(date);
             final daysLeft = date.difference(DateTime.now()).inDays;
             if (daysLeft < 0) isExpired = true;
             else if (daysLeft <= 5) isNearExpiration = true;
        } catch (_) {}
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, 
      children: [
        // New Header Layout: Avatar Left | Text Middle | Status/Logout Right
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
             // Avatar
             Container(
               decoration: BoxDecoration(
                 shape: BoxShape.circle,
                 border: Border.all(color: Colors.blueAccent, width: 2),
               ),
               child: Builder(
                 builder: (context) {
                   final String? profilePic = user?.profilePictureUrl;
                   final bool hasProfilePic = profilePic != null && profilePic.isNotEmpty;
                   
                   return CircleAvatar(
                     radius: 28,
                     backgroundColor: Colors.grey[200],
                     backgroundImage: hasProfilePic
                      ? NetworkImage(resolveImageUrl(profilePic))
                      : null,
                     child: !hasProfilePic
                      ? Icon(Icons.person, size: 30, color: Colors.grey[400])
                      : null,
                   );
                 }
               ),
             ),
             const SizedBox(width: 16),
             
             // Texts
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                     'Panel de Alumno',
                     style: Theme.of(context).textTheme.titleMedium?.copyWith(
                       fontWeight: FontWeight.bold,
                       color: Theme.of(context).colorScheme.onSurface 
                     ),
                   ),
                   Text(
                     '¡Hola, ${user?.firstName ?? "Alumno"}!',
                     style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                   ),
                 ],
               ),
             ),

             // Logout / Actions
             Row(
               children: [
                 // Theme Toggle
                 Consumer<ThemeProvider>(
                   builder: (_, theme, __) {
                     final isDark = theme.isDarkMode;
                     return Container(
                       decoration: BoxDecoration(
                         color: isDark ? Colors.grey[800] : Colors.grey[100], 
                         shape: BoxShape.circle,
                       ),
                       child: IconButton(
                         onPressed: () => theme.toggleTheme(!isDark),
                         icon: Icon(
                           isDark ? Icons.light_mode : Icons.dark_mode,
                           color: isDark ? Colors.white : Colors.black87,
                         ),
                         tooltip: 'Cambiar Tema',
                       ),
                     );
                   }
                 ),
                 const SizedBox(width: 8),

                 // Logout
                 Builder(
                   builder: (context) {
                     final isDark = Theme.of(context).brightness == Brightness.dark;
                     return Container(
                       decoration: BoxDecoration(
                         color: isDark ? Colors.grey[800] : Colors.grey[100],
                         borderRadius: BorderRadius.circular(12),
                       ),
                       child: IconButton(
                         icon: Icon(Icons.logout, color: isDark ? Colors.white : Colors.black87),
                         onPressed: () {
                            context.read<AuthProvider>().logout();
                            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                         },
                         tooltip: 'Cerrar Sesión',
                       ),
                     );
                   }
                 ),
               ],
             )
          ],
        ),
        
        const SizedBox(height: 24),

        // User Name & Membership Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   if (user?.gym?.logoUrl != null && user!.gym!.logoUrl!.isNotEmpty)
                       Padding(
                         padding: const EdgeInsets.only(bottom: 6.0),
                         child: ConstrainedBox(
                           constraints: const BoxConstraints(maxHeight: 60, maxWidth: 200), // Increased size
                           // child: Image.network(
                           //   resolveImageUrl(user!.gym!.logoUrl),
                           child: Image.network(
                             resolveImageUrl(user!.gym!.logoUrl),
                             fit: BoxFit.contain,
                             alignment: Alignment.centerLeft,
                             errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                           ),
                         ),
                       ),

                   Text(
                      user?.gym?.businessName ?? 'GYM MEMBER',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.grey,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600
                      ),
                   ),
                 ],
               ),
             ),
             
             // Payment Status Badge & Date Group
             Column(
               crossAxisAlignment: CrossAxisAlignment.end,
               children: [
                  if (expirationFormatted != null)
                   DashboardPaymentButton(
                     user: user!,
                     isExpired: isExpired, 
                     isNearExpiration: isNearExpiration,
                     onTap: () => _showPaymentInfo(context, user),
                   ),
                 
                 if (expirationFormatted != null)
                   Padding(
                     padding: const EdgeInsets.only(top: 2.0, right: 4.0), // Very small gap
                     child: Text(
                       'Vencimiento: $expirationFormatted', 
                       style: TextStyle(fontSize: 10, color: Colors.grey[500])
                     )
                   ),
               ],
             )
      ],
    ),
  ],
);
  }

  Widget _buildNextWorkoutCard(BuildContext context, PlanProvider provider) {
    final textTheme = Theme.of(context).textTheme;

    if (provider.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final next = provider.nextWorkout;
    // ... (Keep existing empty/finished checks if needed, simplistic view here assumes functionality is key)

    if (next == null) {
       // ... (Keep existing Empty State logic)
       if (provider.assignments.isEmpty) {
        return _buildGenericInfoCard(context, 'Sin plan asignado', 'Consultá con tu profesor.', Icons.info_outline, Colors.grey);
       }
       return _buildGenericInfoCard(context, 'Seleccioná un plan', 'Tocá para elegir.', Icons.touch_app, Colors.blue, onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentPlansListScreen())).then((_) => context.read<PlanProvider>().fetchMyHistory());
       });
    }

    if (next['finished'] == true) {
       final assignment = next['assignment'] as StudentAssignment?;
       
       return Card(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                   Icon(Icons.emoji_events, color: Theme.of(context).colorScheme.primary, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text('¡Plan Completado!', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Felicitaciones. Has completado todos los entrenamientos de este plan.', style: Theme.of(context).textTheme.bodyMedium),
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

    // Active Workout
    final week = next['week'] as PlanWeek;
    final day = next['day'] as PlanDay; 
    final assignment = next['assignment'] as StudentAssignment; 
    final planId = assignment.plan.id!;

    return InkWell(
      onTap: () async {
          // SAME LOGIC
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
          if (mounted && result == true) _refreshDashboardStats();
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF5B8C98), // Muted Teal/Blue
              Color(0xFF3A6B78), // Darker Shade
            ],
          ),
          boxShadow: [
             BoxShadow(color: const Color(0xFF5B8C98).withOpacity(0.6), blurRadius: 16, offset: const Offset(0, 8))
          ]
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0), // Reduced from 24
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('PRÓXIMO ENTRENAMIENTO', style: textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
              const SizedBox(height: 16), // Reduced from 24
              Text(
                (day.title ?? 'Día ${day.dayOfWeek}').replaceAll('Day', 'Día'),
                style: const TextStyle(
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w800,
                  fontSize: 32 // Reduced from 36
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Inicio • Semana ${week.weekNumber}', 
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14), // Reduced from 16
              ),
              const SizedBox(height: 24), // Reduced from 32
              
              // Button Look-alike
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), // Reduced vertical to 8
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Comenzar entrenamiento',
                      style: TextStyle(
                        color: const Color(0xFF2d5acc), // Blue Text
                        fontWeight: FontWeight.bold,
                        fontSize: 16 // Restored to 16
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, color: Color(0xFF2d5acc), size: 20)
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
 
  Widget _buildDashboardCard(BuildContext context,
      {required String title, String? subtitle, Widget? subtitleWidget, required IconData icon, required VoidCallback onTap}) {
    
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
         color: isDark ? colorScheme.surfaceContainer : Colors.white, // Dark mode aware
         borderRadius: BorderRadius.circular(20),
         border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
         boxShadow: [
           BoxShadow(
             color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1), 
             blurRadius: 15, 
             offset: const Offset(0, 5)
           )
         ]
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Row(
                   children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E7FF), // Light Purple/Blue background
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, size: 24, color: const Color(0xFF4338ca)), // Darker Purple/Blue Icon
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title, 
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 16, 
                            color: colorScheme.onSurface // Theme aware text
                          )
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 18, color: isDark ? Colors.grey[600] : Colors.grey[300]),
                   ],
                 ),
                 
                 // Content below icon (for Progress Bar or Subtitle)
                 if (subtitleWidget != null || subtitle != null) ...[
                    const SizedBox(height: 12),
                    if (subtitleWidget != null)
                      subtitleWidget
                    else 
                      Text(
                        subtitle!, 
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[500], 
                          fontSize: 14
                        )
                      ),
                 ]
              ],
            ),
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
  Future<void> _refreshDashboardStats() async {
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

          context.read<PlanProvider>().fetchMyHistory();
          context.read<PlanProvider>().computeWeeklyStats();
          context.read<PlanProvider>().computeMonthlyStats();
      }
  }
  void _showPaymentInfo(BuildContext context, app_models.User? user) {
    if (user?.gym == null) return;
    
    final gym = user!.gym!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.payment, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Datos de Pago'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Para renovar tu cuota, podés transferir a:', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            if (gym.paymentBankName != null && gym.paymentBankName!.isNotEmpty)
              _infoRow(Icons.account_balance, 'Banco: ${gym.paymentBankName}'),
            if (gym.paymentAlias != null && gym.paymentAlias!.isNotEmpty)
              _infoRow(Icons.link, 'Alias: ${gym.paymentAlias}'),
             if (gym.paymentCbu != null && gym.paymentCbu!.isNotEmpty)
              _infoRow(Icons.numbers, 'CBU: ${gym.paymentCbu}'),
             if (gym.paymentAccountName != null && gym.paymentAccountName!.isNotEmpty)
              _infoRow(Icons.person, 'Titular: ${gym.paymentAccountName}'),
              
             if (gym.paymentNotes != null && gym.paymentNotes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[800] 
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    gym.paymentNotes!, 
                    style: TextStyle(
                      fontSize: 12, 
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                )
             ]
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }
}

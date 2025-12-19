import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/plan_model.dart';
import '../../models/student_assignment_model.dart';
import '../../providers/plan_provider.dart';
import '../../localization/app_localizations.dart';
import '../../utils/app_colors.dart'; // Added
import 'day_detail_screen.dart';
import '../teacher/create_plan_screen.dart';

class PlanDetailsScreen extends StatefulWidget {
  final Plan plan;
  final bool canEdit;
  final bool readOnly;
  final StudentAssignment? assignment;
  final String? studentId;

  const PlanDetailsScreen({
    super.key, 
    required this.plan, 
    this.canEdit = true,
    this.readOnly = false,
    this.assignment,
    this.studentId,
  });

  @override
  State<PlanDetailsScreen> createState() => _PlanDetailsScreenState();
}

class _PlanDetailsScreenState extends State<PlanDetailsScreen> {
  late StudentAssignment? _currentAssignment;
  late Plan _plan;

  @override
  void initState() {
    super.initState();
    _plan = widget.plan;
    _currentAssignment = widget.assignment;
  }

  Future<void> _handleProgressUpdate(String type, String id, bool completed, {String? date}) async {
    if (_currentAssignment == null) return;

    // Optimistic Update
    setState(() {
      Map<String, dynamic> newProgress = Map.from(_currentAssignment!.progress);
      
      if (type == 'exercise') {
        Map<String, dynamic> exercises = Map.from(newProgress['exercises'] ?? {});
        if (completed) {
          exercises[id] = true;
        } else {
          exercises.remove(id);
        }
        newProgress['exercises'] = exercises;
      } else if (type == 'day') {
        Map<String, dynamic> days = Map.from(newProgress['days'] ?? {});
        if (completed) {
          days[id] = {'completed': true, 'date': date};
        } else {
          days.remove(id);
        }
        newProgress['days'] = days;
      }

      _currentAssignment = _currentAssignment!.copyWithProgress(newProgress: newProgress);
    });

    final success = await context.read<PlanProvider>().updateProgress(
      _currentAssignment!.id,
      type,
      id,
      completed,
      date: date
    );

    if (!success) {
      if (mounted) {
        // Revert (could just reload from server or use simple toggle back logic)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.get('errorUpdateProgress'))));
        // Ideally revert state here, but for MVP keep it simple
      }
    }
  }

  void _onDayCheckboxChanged(bool? value, String dayId) async {
    if (value == true) {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        helpText: AppLocalizations.of(context)!.get('selectDate'),
      );
      if (picked != null) {
        _handleProgressUpdate('day', dayId, true, date: DateFormat('yyyy-MM-dd').format(picked));
      }
    } else {
      _handleProgressUpdate('day', dayId, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If canEdit is false, we assume it might be a student view.
    // However, widget.assignment is the source of truth for tracking.
    return Scaffold(
      appBar: AppBar(
        title: Text(_plan.name),
        actions: [
          if (widget.canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreatePlanScreen(planToEdit: _plan)),
                );
                if (result == true && mounted) {
                   // Refresh plan specifically from server to ensure fresh data
                   if (_plan.id != null) {
                       final updatedPlan = await context.read<PlanProvider>().getPlanById(_plan.id!);
                       if (updatedPlan != null) {
                         setState(() {
                           _plan = updatedPlan;
                         });
                       }
                   }
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlanSummaryCard(context, _plan),
            const SizedBox(height: 24),
            Text(AppLocalizations.of(context)!.get('weeklySchedule'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ..._plan.weeks.map((week) => _buildWeekCard(context, week)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanSummaryCard(BuildContext context, Plan plan) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.get('planOverview'),
            style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary.withOpacity(0.8)),
          ),
          const SizedBox(height: 8),
          Text(
            plan.name,
            style: textTheme.headlineMedium?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
          ),
          if (plan.objective != null) ...[
            const SizedBox(height: 12),
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
               decoration: BoxDecoration(
                 color: colorScheme.onPrimary,
                 borderRadius: BorderRadius.circular(20),
               ),
               child: Text(
                 plan.objective!,
                 style: textTheme.labelMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
               ),
             ),
          ],
          if (plan.durationWeeks > 0) ...[
             const SizedBox(height: 12),
             Text(
               AppLocalizations.of(context)!.get('durationWeeks').replaceAll('{weeks}', '${plan.durationWeeks}'),
               style: textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimary.withOpacity(0.9)),
             ),
          ]
        ],
      ),
    );
  }

  Widget _buildWeekCard(BuildContext context, dynamic week) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text('${AppLocalizations.of(context)!.get('week').toUpperCase()} ${week.weekNumber}', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
        ),
        ...week.days.map<Widget>((day) => _buildDayCard(context, day, week.weekNumber)).toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDayCard(BuildContext context, dynamic day, int weekNumber) {
    bool isCompleted = false;
    if (_currentAssignment != null && day.id != null) {
      isCompleted = _currentAssignment!.isDayCompleted(day.id!);
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isCompleted ? AppColors.success.withOpacity(0.05) : null, // Subtle green tint if completed
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCompleted ? BorderSide(color: AppColors.success.withOpacity(0.5), width: 1) : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          if (_plan.id == null) return;
          
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DayDetailScreen(
                day: day,
                planId: _plan.id!,
                weekNumber: weekNumber,
                readOnly: widget.readOnly,
                studentId: widget.studentId, 
                assignedAt: widget.assignment?.assignedAt,
              ),
            ),
          );

          if (result == true && !widget.readOnly && mounted) {
             // User finished workout. 
             await context.read<PlanProvider>().fetchMyHistory();
             if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (!widget.readOnly && mounted) {
             // Refresh
             context.read<PlanProvider>().fetchMyHistory().then((assignments) {
                   if (mounted) {
                       try {
                           StudentAssignment updated;
                           if (_currentAssignment?.id != null) {
                             updated = assignments.firstWhere((a) => a.id == _currentAssignment!.id);
                           } else {
                             updated = assignments.firstWhere((a) => a.plan.id == _plan.id);
                           }
                           setState(() {
                               _currentAssignment = updated;
                           });
                       } catch (e) {
                           // Plan mismatch
                       }
                   }
             });
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.success : colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_today, 
                  color: isCompleted ? Colors.white : colorScheme.primary
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day.title ?? '${AppLocalizations.of(context)!.get('day')} ${day.dayOfWeek}',
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${day.exercises.length} ${AppLocalizations.of(context)!.get('exercisesCount')}',
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    if (isCompleted && day.id != null && _currentAssignment!.progress['days'][day.id]['date'] != null)
                      Text(
                         '${AppLocalizations.of(context)!.get('completedOn')} ${_currentAssignment!.progress['days'][day.id]['date']}',
                         style: textTheme.labelSmall?.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
                      )
                  ],
                ),
              ),
              // We remove the legacy checkbox here to avoid confusion? 
              // Or keep it read-only? 
              // Let's keep the tick icon but not the interactable checkbox for now, as logic is moving to DayScreen "Finish".
              if (isCompleted)
                 const Icon(Icons.check_circle, color: AppColors.success)
              else
                 Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

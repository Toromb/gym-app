import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/plan_model.dart';
import '../../models/student_assignment_model.dart';
import '../../providers/plan_provider.dart';
import 'day_detail_screen.dart';
import '../teacher/create_plan_screen.dart';

class PlanDetailsScreen extends StatefulWidget {
  final Plan plan;
  final bool canEdit;
  final StudentAssignment? assignment;

  const PlanDetailsScreen({
    super.key, 
    required this.plan, 
    this.canEdit = true,
    this.assignment,
  });

  @override
  State<PlanDetailsScreen> createState() => _PlanDetailsScreenState();
}

class _PlanDetailsScreenState extends State<PlanDetailsScreen> {
  late StudentAssignment? _currentAssignment;

  @override
  void initState() {
    super.initState();
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update progress')));
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
        helpText: 'Select Completion Date',
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
        title: Text(widget.plan.name),
        actions: [
          if (widget.canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreatePlanScreen(planToEdit: widget.plan)),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlanSummaryCard(context, widget.plan),
            const SizedBox(height: 24),
            const Text('Weekly Schedule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...widget.plan.weeks.map((week) => _buildWeekCard(context, week)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanSummaryCard(BuildContext context, Plan plan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plan Overview',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            plan.name,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          if (plan.objective != null) ...[
            const SizedBox(height: 8),
             Chip(
               label: Text(plan.objective!),
               backgroundColor: Colors.white,
               labelStyle: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
               side: BorderSide.none,
             ),
          ],
          if (plan.durationWeeks > 0) ...[
             const SizedBox(height: 8),
             Text(
               'Duration: ${plan.durationWeeks} Weeks',
               style: const TextStyle(color: Colors.white70),
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
          child: Text(week.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
        ),
        ...week.days.map<Widget>((day) => _buildDayCard(context, day)).toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDayCard(BuildContext context, dynamic day) {
    bool isCompleted = false;
    if (_currentAssignment != null && day.id != null) {
      isCompleted = _currentAssignment!.isDayCompleted(day.id!);
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      color: isCompleted ? Colors.green[50] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCompleted ? const BorderSide(color: Colors.green, width: 1.5) : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Prepare progress for DayDetail
          Map<String, bool> exerciseProgress = {};
          if (_currentAssignment != null && _currentAssignment!.progress['exercises'] != null) {
            _currentAssignment!.progress['exercises'].forEach((k, v) {
              if (v == true) exerciseProgress[k] = true;
            });
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DayDetailScreen(
                day: day,
                isTracking: _currentAssignment != null,
                completedExercises: exerciseProgress,
                onToggleExercise: (exId, val) {
                   _handleProgressUpdate('exercise', exId, val);
                },
              ),
            ),
          ).then((_) {
            setState(() {}); // Refresh if returned (though Provider update propagates via _handle, setState ensures simple refresh)
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green.withOpacity(0.2) : Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.calendar_today, color: isCompleted ? Colors.green : Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day.title ?? 'Day ${day.dayOfWeek}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${day.exercises.length} Exercises',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    if (isCompleted && day.id != null && _currentAssignment!.progress['days'][day.id]['date'] != null)
                      Text(
                         'Completed: ${_currentAssignment!.progress['days'][day.id]['date']}',
                         style: TextStyle(color: Colors.green[800], fontSize: 12, fontWeight: FontWeight.bold),
                      )
                  ],
                ),
              ),
              if (_currentAssignment != null && day.id != null)
                 Transform.scale(
                   scale: 1.2,
                   child: Checkbox(
                     value: isCompleted,
                     activeColor: Colors.green,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                     onChanged: (val) => _onDayCheckboxChanged(val, day.id!),
                   ),
                 )
              else
                 const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

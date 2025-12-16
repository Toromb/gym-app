import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../models/plan_model.dart';
import '../../providers/plan_provider.dart';
import '../../models/execution_model.dart'; // Import Execution Model
import '../../localization/app_localizations.dart';
import 'exercise_execution_card.dart';

class DayDetailScreen extends StatefulWidget {
  final PlanDay day;
  final String planId;
  final int weekNumber;
  final bool readOnly; 
  final String? studentId;
  final String? assignedAt;

  const DayDetailScreen({
    super.key, 
    required this.day,
    required this.planId,
    required this.weekNumber,
    this.readOnly = false,
    this.studentId,
    this.assignedAt,
  });

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  bool _isInit = true;
  bool _isLoadingReadOnly = false;
  PlanExecution? _readOnlyExecution; 

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      if (!widget.readOnly) {
         WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<PlanProvider>().startExecution(
            widget.planId, 
            widget.weekNumber, 
            widget.day.order
          );
        });
      } else if (widget.readOnly && widget.studentId != null) {
          debugPrint('DayDetailScreen: Fetching execution for student ${widget.studentId}, Plan ${widget.planId}, W${widget.weekNumber} D${widget.day.order}');
          // Fetch specific student execution for Teacher View
          setState(() => _isLoadingReadOnly = true);
          context.read<PlanProvider>().fetchStudentExecution(
            studentId: widget.studentId!,
            planId: widget.planId,
            week: widget.weekNumber,
            day: widget.day.order,
            startDate: widget.assignedAt,
          ).then((execution) {
             debugPrint('DayDetailScreen: Fetched execution: ${execution?.id ?? "NULL"}');
             if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                 content: Text('DEBUG: Fetched? ${execution != null ? "YES" : "NO"} FirstExReps: ${execution?.exercises.first.repsDone} / ${execution?.exercises.first.targetRepsSnapshot}'),
                 duration: const Duration(seconds: 8),
               ));
               setState(() {
                 _readOnlyExecution = execution;
                 _isLoadingReadOnly = false;
               });
             }
          });
      }
      _isInit = false;
    }
  }

  Future<void> _handleFinishWorkout() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: AppLocalizations.of(context)!.get('confirmCompletion'),
    );

    if (picked != null && mounted) {
      final dateStr = DateFormat('yyyy-MM-dd').format(picked);
      try {
        await context.read<PlanProvider>().completeExecution(dateStr);
        if (mounted) {
           Navigator.pop(context, true); // Return success
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(AppLocalizations.of(context)!.get('workoutFinished'), style: const TextStyle(color: Colors.white)), backgroundColor: Colors.green),
           );
        }
      } catch (e) {
        if (mounted) {
          // Check for conflict message (naive string check, ideally parse error object)
          String msg = AppLocalizations.of(context)!.get('errorFinish');
          if (e.toString().contains('Conflict')) {
            msg = 'Date already has a completed workout!';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('DayDetailScreen BUILD: readOnly=${widget.readOnly}, studentId=${widget.studentId}'); // DEBUG

    if (_isLoadingReadOnly) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    List<ExerciseExecution> exercisesToRender = [];
    String status = 'READ_ONLY';

    if (widget.readOnly) {
        if (_readOnlyExecution != null) {
            // Case 1: Professor viewing student's actual execution
            exercisesToRender = _readOnlyExecution!.exercises;
            status = 'ALUMNO REGISTRO: ${_readOnlyExecution!.status}'; // Or just show completion label
        } else {
            // Case 2: No execution recorded yet -> Show Plan Definition (clean slate)
            exercisesToRender = widget.day.exercises.map((pe) => ExerciseExecution.fromPlanExercise(pe)).toList();
            status = 'SIN DATOS';
        }
    } else {
        // Student Mode (Standard)
        final execution = context.watch<PlanProvider>().currentExecution;
        if (execution == null) {
            if (context.read<PlanProvider>().isLoading) {
                 return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
             return Scaffold(
                 appBar: AppBar(title: Text(widget.day.title ?? 'Día ${widget.day.dayOfWeek}')),
                 body: Center(
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Text(AppLocalizations.of(context)!.get('errorLoadExecution')),
                       ElevatedButton(
                         onPressed: () {
                            context.read<PlanProvider>().startExecution(
                              widget.planId, 
                              widget.weekNumber, 
                              widget.day.order
                            );
                         }, 
                         child: const Text('Retry')
                       )
                     ],
                   ),
                 ),
            );
        }
        exercisesToRender = execution.exercises;
        status = execution.status;
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.day.title ?? 'Día ${widget.day.dayOfWeek}'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.get('trainingSession'),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (!widget.readOnly)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: status == 'COMPLETED' ? Colors.green[100] : Colors.blue[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: status == 'COMPLETED' ? Colors.green[900] : Colors.blue[900],
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${exercisesToRender.length} ${AppLocalizations.of(context)!.get('exercisesToComplete')}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ...exercisesToRender.asMap().entries.map((entry) {
                  final index = entry.key;
                  final exExec = entry.value;
                  // If readOnly, we might should treat it differently in the Card?
                  // passing readOnly (pointer-events: none) or making the card readonly?
                  // For now, let's just make the card ignores input if we passed a dummy.
                  // But `ExerciseExecutionCard` has local state and calls provider.
                  // We should wrap it in IgnorePointer if readOnly.
                  return _buildExerciseCard(context, exExec, index + 1, widget.readOnly);
                }),
                const SizedBox(height: 80), // Space for FAB
              ],
            ),
          ),
      floatingActionButton: !widget.readOnly 
        ? FloatingActionButton.extended(
            onPressed: _handleFinishWorkout,
            label: Text(AppLocalizations.of(context)!.get('finishWorkout')),
            icon: const Icon(Icons.check_circle),
            backgroundColor: Colors.green,
          )
        : null,
    );
  }

  Widget _buildExerciseCard(BuildContext context, ExerciseExecution exExec, int index, bool readOnly) {
    return IgnorePointer(
      ignoring: readOnly,
      child: ExerciseExecutionCard(
        key: ValueKey(exExec.id),
        execution: exExec, 
        index: index
      ),
    );
  }

  Widget _buildMetric(BuildContext context, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ],
    );
  }

  Future<void> _launchVideo(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.get('errorVideo'))),
        );
      }
    }
  }
}

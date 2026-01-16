import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../models/plan_model.dart';
import '../../providers/plan_provider.dart';
import '../../models/execution_model.dart'; // Import Execution Model
import '../../localization/app_localizations.dart';
import 'exercise_execution_card.dart';
import 'exercise_selection_dialog.dart';

class DayDetailScreen extends StatefulWidget {
  final PlanDay? day; // Nullable
  final String? planId; // Nullable
  final int? weekNumber; // Nullable
  final bool readOnly; 
  final String? studentId;
  final String? assignedAt;
  final String? freeTrainingId; // NEW

  const DayDetailScreen({
    super.key, 
    this.day,
    this.planId,
    this.weekNumber,
    this.readOnly = false,
    this.studentId,
    this.assignedAt,
    this.freeTrainingId,
  });

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  bool _isInit = true;
  bool _isLoadingReadOnly = false;
  TrainingSession? _readOnlySession; 

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      if (!widget.readOnly) {
         WidgetsBinding.instance.addPostFrameCallback((_) {
          // If freeTrainingId is present, start session with it
          if (widget.freeTrainingId != null) {
              context.read<PlanProvider>().startSession(
                null, 
                null, 
                null,
                freeTrainingId: widget.freeTrainingId
              );
          } else if (widget.planId != null && widget.weekNumber != null && widget.day != null) {
              context.read<PlanProvider>().startSession(
                widget.planId, 
                widget.weekNumber, 
                widget.day!.order
              );
          }
        });
      } else if (widget.readOnly && widget.studentId != null && widget.planId != null && widget.day != null) {
          debugPrint('DayDetailScreen: Fetching session for student ${widget.studentId}, Plan ${widget.planId}, W${widget.weekNumber} D${widget.day!.order}');
          setState(() => _isLoadingReadOnly = true);
          context.read<PlanProvider>().fetchStudentSession(
            studentId: widget.studentId!,
            planId: widget.planId!,
            week: widget.weekNumber!,
            day: widget.day!.order,
            startDate: widget.assignedAt,
          ).then((session) {
             debugPrint('DayDetailScreen: Fetched session: ${session?.id ?? "NULL"}');
             if (mounted) {
               setState(() {
                 _readOnlySession = session;
                 _isLoadingReadOnly = false;
               });
             }
          });
      }
      _isInit = false;
    }
  }

  Future<void> _handleFinishWorkout() async {
    DateTime? picked;
    
    // Fix: Validar ejercicios incompletos
    final currentSession = context.read<PlanProvider>().currentSession;
    if (currentSession != null) {
        final hasIncomplete = currentSession.exercises.any((e) => !e.isCompleted);
        if (hasIncomplete) {
            final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                    title: const Text('Ejercicios incompletos'),
                    content: const Text('Hay ejercicios sin completar. ¿Estás seguro de que deseas finalizar?'),
                    actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancelar'),
                        ),
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Finalizar'),
                        ),
                    ],
                ),
            );
            if (confirm != true) return;
        }
    }

    // Fix: Enforce TODAY for ALL sessions (Free & Plan)
    picked = DateTime.now();

    if (picked != null && mounted) {
      final dateStr = DateFormat('yyyy-MM-dd').format(picked);
      try {
          // If we are in standard mode, we have _currentSession in provider
          // We need to pass the ID.
          final currentSession = context.read<PlanProvider>().currentSession;
           if (currentSession != null) {
              await context.read<PlanProvider>().completeSession(dateStr, dayId: widget.day?.id);
          }
        
        if (mounted) {
           Navigator.pop(context, true); 
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(AppLocalizations.of(context)!.get('workoutFinished'), style: const TextStyle(color: Colors.white)), backgroundColor: Colors.green),
           );
        }
      } catch (e) {
        if (mounted) {
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
    if (_isLoadingReadOnly) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    List<SessionExercise> exercisesToRender = [];
    String status = 'READ_ONLY';

    if (widget.readOnly) {
        if (_readOnlySession != null) {
            exercisesToRender = _readOnlySession!.exercises;
            status = 'ALUMNO REGISTRO: ${_readOnlySession!.status}'; 
        } else if (widget.day != null) {
            exercisesToRender = widget.day!.exercises.map((pe) => SessionExercise.fromPlanExercise(pe)).toList();
            status = 'SIN DATOS';
        }
    } else {
        final session = context.watch<PlanProvider>().currentSession;
        if (session == null) {
            if (context.read<PlanProvider>().isLoading) {
                 return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
             return Scaffold(
                 appBar: AppBar(title: Text(widget.day?.title ?? 'Entrenamiento')),
                 body: Center(
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Text(AppLocalizations.of(context)!.get('errorLoadExecution')),
                       ElevatedButton(
                         onPressed: () {
                            if (widget.freeTrainingId != null) {
                                context.read<PlanProvider>().startSession(
                                  null, 
                                  null, 
                                  null,
                                  freeTrainingId: widget.freeTrainingId
                                );
                            } else {
                                context.read<PlanProvider>().startSession(
                                  widget.planId, 
                                  widget.weekNumber, 
                                  widget.day!.order
                                );
                            }
                         }, 
                         child: const Text('Retry')
                       )
                     ],
                   ),
                 ),
            );
        }
        exercisesToRender = session.exercises;
        status = session.status;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.day?.title ?? (widget.freeTrainingId != null ? 'Entrenamiento Libre' : 'Día ${widget.day?.dayOfWeek}')),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
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
                        if (!widget.readOnly && status == 'COMPLETED')
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
                    // NEW: Training Intent Badge
                    if (widget.day?.trainingIntent != null)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple.shade200),
                        ),
                        child: Text(
                          widget.day!.trainingIntent!.label,
                          style: TextStyle(color: Colors.purple.shade900, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
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
                      return _buildExerciseCard(context, exExec, index + 1, widget.readOnly);
                    }),
                    
                    // Fix: Hide Add Exercise button for Plan Sessions
                    if (!widget.readOnly && (widget.planId == 'FREE_SESSION' || widget.freeTrainingId != null))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: OutlinedButton.icon(
                            onPressed: _handleAddExercise,
                            icon: const Icon(Icons.add),
                            label: Text(AppLocalizations.of(context)!.get('addExercise')),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ),
                      ),
      
                    const SizedBox(height: 100), // Ensures scroll space
                  ],
                ),
                ),
          ),
        ),
      ),

      bottomNavigationBar: !widget.readOnly
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: _handleFinishWorkout,
                  icon: const Icon(Icons.check_circle),
                  label: Text(AppLocalizations.of(context)!.get('finishWorkout')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _handleAddExercise() async {
    final Exercise? selected = await showDialog<Exercise>(
      context: context,
      builder: (ctx) => const ExerciseSelectionDialog(),
    );

    if (selected != null && mounted) {
      await context.read<PlanProvider>().addSessionExercise(selected.id);
    }
  }

  Widget _buildExerciseCard(BuildContext context, SessionExercise exExec, int index, bool readOnly) {
    return ExerciseExecutionCard(
        key: ValueKey(exExec.id),
        execution: exExec, 
        index: index,
        intent: widget.day?.trainingIntent ?? TrainingIntent.GENERAL,
        readOnly: readOnly,
        canDelete: !readOnly && (widget.planId == 'FREE_SESSION' || widget.freeTrainingId != null), // Only allowed in Free Session
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

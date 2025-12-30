import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/execution_model.dart';
import 'package:provider/provider.dart';
import '../../providers/plan_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../localization/app_localizations.dart';
import '../../models/plan_model.dart';
import '../../utils/swap_exercise_logic.dart';
import 'swap_confirmation_dialog.dart';

class ExerciseExecutionCard extends StatefulWidget {
  final SessionExercise execution;
  final int index;
  final TrainingIntent intent;
  final bool readOnly;

  const ExerciseExecutionCard({
    super.key,
    required this.execution,
    required this.index,
    this.intent = TrainingIntent.GENERAL,
    this.readOnly = false,
  });

  @override
  State<ExerciseExecutionCard> createState() => _ExerciseExecutionCardState();
}

class _ExerciseExecutionCardState extends State<ExerciseExecutionCard> {
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late TextEditingController _setsController; 
  late bool _isCompleted;
  
  @override
  void initState() {
    super.initState();
    _isCompleted = widget.execution.isCompleted;
    
    _repsController = TextEditingController(text: widget.execution.repsDone ?? widget.execution.targetRepsSnapshot ?? '');
    _weightController = TextEditingController(text: widget.execution.weightUsed ?? widget.execution.targetWeightSnapshot ?? '');
    _setsController = TextEditingController(text: widget.execution.setsDone?.toString() ?? widget.execution.targetSetsSnapshot?.toString() ?? '');
  }

  @override
  void didUpdateWidget(ExerciseExecutionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.execution != oldWidget.execution) {
       // Update controllers if the underlying execution data changed
       // We only update if the USER hasn't typed? Or do we overwrite?
       // Since this is a sync from backend, we generally want to reflect it.
       // However, to avoid overriding user typing, one might check if focused.
       // But for this issue (sync), let's update.
       
       final newSets = widget.execution.setsDone?.toString() ?? widget.execution.targetSetsSnapshot?.toString() ?? '';
       if (_setsController.text != newSets) {
          _setsController.text = newSets;
       }
       
       final newReps = widget.execution.repsDone ?? widget.execution.targetRepsSnapshot ?? '';
       if (_repsController.text != newReps) {
          _repsController.text = newReps;
       }

       final newWeight = widget.execution.weightUsed ?? widget.execution.targetWeightSnapshot ?? '';
       if (_weightController.text != newWeight) {
          _weightController.text = newWeight;
       }
       
       // Also update completion state
       if (widget.execution.isCompleted != oldWidget.execution.isCompleted) {
          _isCompleted = widget.execution.isCompleted;
       }
    }
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    _setsController.dispose();
    super.dispose();
  }

  Future<void> _toggleCompletion(bool? value) async {
    if (value == null) return;

    setState(() {
      _isCompleted = value;
    });

    final updateData = {
      'isCompleted': value,
      'repsDone': _repsController.text,
      'weightUsed': _weightController.text,
      'setsDone': _setsController.text, 
    };

    final success = await context.read<PlanProvider>().updateSessionExercise(widget.execution.id, updateData);
    
    if (!success && mounted) {
      setState(() {
        _isCompleted = !value;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.get('errorUpdate')), backgroundColor: Colors.red)
      );
    }
  }

  // Debounce timer
  Timer? _debounce;

  void _onFieldChanged(String val) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      _saveChanges();
    });
  }

  Future<void> _saveChanges() async {
    final updateData = {
      'repsDone': _repsController.text,
      'weightUsed': _weightController.text,
      'setsDone': _setsController.text,
    };
    
    await context.read<PlanProvider>().updateSessionExercise(widget.execution.id, updateData);
  }

  @override
  Widget build(BuildContext context) {
    // Colors
    const completedColor = Colors.green;
    final defaultColor = Theme.of(context).primaryColor;

    final bool readOnly = widget.readOnly;

    return Card(
      elevation: _isCompleted ? 1 : 4,
      margin: const EdgeInsets.only(bottom: 20),
      color: _isCompleted ? Colors.green.withValues(alpha: 0.15) : null, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: _isCompleted ? const BorderSide(color: Colors.green, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Number + Name + Checkbox
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Container(
                    padding: const EdgeInsets.all(8), 
                    decoration: BoxDecoration(
                      color: _isCompleted ? completedColor.withValues(alpha: 0.2) : defaultColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '#${widget.index}',
                      style: TextStyle(
                        color: _isCompleted 
                            ? completedColor 
                            : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).primaryColor),
                        fontWeight: FontWeight.bold,
                        fontSize: 14, 
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                
                // Name & Video & Swap
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + Inline Swap Button
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: widget.execution.exerciseNameSnapshot,
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.bold,
                                decoration: _isCompleted ? TextDecoration.lineThrough : null,
                                color: _isCompleted ? Colors.green : Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                            if (!readOnly && (widget.execution.exercise?.muscles.any((m) => m.role == 'PRIMARY') ?? false))
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Transform.scale(
                                    scale: 0.9,
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                      icon: const Icon(Icons.swap_horiz, color: Colors.blueGrey, size: 16),
                                      label: const Text('Cambiar ejercicio', style: TextStyle(color: Colors.blueGrey, fontSize: 11)),
                                      onPressed: () => _showSwapDialog(context),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0), 
                                        minimumSize: Size.zero, 
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      if ((widget.execution.videoUrl ?? widget.execution.exercise?.videoUrl) != null)
                        InkWell(
                          onTap: () => _launchVideo(context, (widget.execution.videoUrl ?? widget.execution.exercise?.videoUrl)!),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.play_circle_outline, size: 16, color: Colors.red),
                              const SizedBox(width: 4),
                              Text(
                                AppLocalizations.of(context)!.get('watchVideo'),
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Checkbox 
                const SizedBox(width: 8),
                Transform.scale(
                  scale: 1.3,
                  child: Checkbox(
                    value: _isCompleted,
                    activeColor: completedColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: readOnly ? null : _toggleCompletion,
                  ),
                ),
              ],
            ),

            // Muscles & Equipment (Side by Side)
            if ((widget.execution.exercise?.muscles.isNotEmpty ?? false) || widget.execution.equipmentsSnapshot.isNotEmpty) ...[
               const SizedBox(height: 8),
               Row(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   // Muscles (Left)
                   if (widget.execution.exercise?.muscles.isNotEmpty ?? false)
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                             'Músculos a trabajar',
                             style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                           ),
                           const SizedBox(height: 4),
                           Wrap(
                             spacing: 4,
                             runSpacing: 4,
                             children: widget.execution.exercise!.muscles.map((em) {
                               final isPrimary = em.role == 'PRIMARY'; 
                               final color = Theme.of(context).primaryColor;
                               return Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                 decoration: BoxDecoration(
                                   color: isPrimary ? color.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
                                   borderRadius: BorderRadius.circular(4),
                                   border: isPrimary ? Border.all(color: color.withOpacity(0.5), width: 0.5) : null,
                                 ),
                                 child: Text(
                                   em.muscle.name,
                                   style: TextStyle(
                                     fontSize: 10,
                                     fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
                                     color: isPrimary ? color : Colors.grey[700],
                                   ),
                                 ),
                               );
                             }).toList(),
                           ),
                         ],
                       ),
                     ),
                   
                   // Spacer if both exist
                   if ((widget.execution.exercise?.muscles.isNotEmpty ?? false) && widget.execution.equipmentsSnapshot.isNotEmpty)
                     const SizedBox(width: 12),

                   // Equipment (Right)
                   if (widget.execution.equipmentsSnapshot.isNotEmpty)
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                            Text(
                             'Equipamiento a utilizar',
                             style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: widget.execution.equipmentsSnapshot.map((eq) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    eq.name,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                         ],
                       ),
                     ),
                 ],
               ),
            ],
            
            const SizedBox(height: 16),
            const Divider(height: 1), 
            const SizedBox(height: 16),

            // Inputs Row
            Row(
              children: [
                Expanded(
                  child: _buildInputMetric(
                    context, 
                    controller: _setsController, 
                    label: AppLocalizations.of(context)!.get('sets'),
                    hint: widget.execution.targetSetsSnapshot?.toString() ?? '-',
                    icon: Icons.repeat,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInputMetric(
                    context, 
                    controller: _repsController, 
                    label: AppLocalizations.of(context)!.get('reps'),
                    hint: widget.execution.targetRepsSnapshot ?? '-',
                    icon: Icons.refresh,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInputMetric(
                    context, 
                    controller: _weightController, 
                    label: AppLocalizations.of(context)!.get('load'),
                    hint: widget.execution.targetWeightSnapshot ?? '-',
                    icon: Icons.fitness_center,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputMetric(BuildContext context, {
    required TextEditingController controller, 
    required String label, 
    required String hint,
    required IconData icon
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.text, 
      decoration: InputDecoration(
        labelText: '$label (Sugg: $hint)', 
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        isDense: true,
        suffixIcon: Icon(icon, size: 16, color: Colors.grey),
      ),
      style: const TextStyle(fontWeight: FontWeight.bold),

      onChanged: widget.readOnly ? null : _onFieldChanged,
      readOnly: widget.readOnly,
      enabled: !widget.readOnly,
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

  void _showSwapDialog(BuildContext context) {
    if (widget.execution.exercise == null) return;
    
    final muscles = widget.execution.exercise!.muscles;
    final primary = muscles.firstWhere(
      (m) => m.role == 'PRIMARY', 
      orElse: () => muscles.isNotEmpty 
          ? muscles.first 
          : throw 'No muscles' 
    );
    
    if (muscles.isEmpty) return; 

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar ejercicio'),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<Exercise>>(
            future: ctx.read<PlanProvider>().fetchExercisesByMuscle(primary.muscle.id),
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) {
                return const Text('Error loading exercises');
              }
              final list = snapshot.data ?? [];
              if (list.isEmpty) return const Text('No alternatives found.');

              return ListView.builder(
                shrinkWrap: true,
                itemCount: list.length,
                itemBuilder: (ctx, i) {
                  final ex = list[i];
                  if (ex.id == widget.execution.exercise?.id) return const SizedBox.shrink();

                  return ListTile(
                    leading: const Icon(Icons.fitness_center),
                    title: Text(ex.name),
                    subtitle: Text(ex.muscleGroup),
                    trailing: const Icon(Icons.swap_horiz, color: Colors.blue),
                    onTap: () {
                      Navigator.pop(ctx);
                      _performSwap(ex);
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          )
        ],
      ),
    );
  }

  Future<void> _performSwap(Exercise newEx) async {
    // 1. Calculate Suggestions
    final suggestion = SwapExerciseLogic.calculate(
      oldExercise: widget.execution.exercise!, 
      newExercise: newEx,
      execution: widget.execution,
      intent: widget.intent,
    );

    // 2. Show Confirmation Dialog
    if (!mounted) return;
    
    final confirmed = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => SwapConfirmationDialog(
        newExercise: newEx,
        suggestion: suggestion,
        oldExerciseName: widget.execution.exerciseNameSnapshot,
      ),
    );

    if (confirmed == null) return; 

    // 3. Apply Changes
    final updateData = {
      'exercise': {
        'id': newEx.id,
        'muscles': newEx.muscles,
        'equipments': newEx.equipments 
      },
      'exerciseNameSnapshot': newEx.name,
      'videoUrl': newEx.videoUrl,
      'planExerciseId': null, 
      
      'targetSetsSnapshot': int.tryParse(confirmed['sets']!),
      'targetRepsSnapshot': confirmed['reps'],
      'targetWeightSnapshot': confirmed['weight'],
    };
    
    final success = await context.read<PlanProvider>().updateSessionExercise(widget.execution.id, updateData);
    
    if (success && mounted) {
       setState(() {
          _setsController.text = confirmed['sets']!;
          _repsController.text = confirmed['reps']!;
          _weightController.text = confirmed['weight']!;
       });
    }
  }
}

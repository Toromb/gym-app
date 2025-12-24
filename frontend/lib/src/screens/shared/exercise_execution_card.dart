import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/execution_model.dart';
import 'package:provider/provider.dart';
import '../../providers/plan_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../localization/app_localizations.dart';
import '../../models/plan_model.dart';

class ExerciseExecutionCard extends StatefulWidget {
  final ExerciseExecution execution;
  final int index;

  const ExerciseExecutionCard({
    super.key,
    required this.execution,
    required this.index,
  });

  @override
  State<ExerciseExecutionCard> createState() => _ExerciseExecutionCardState();
}

class _ExerciseExecutionCardState extends State<ExerciseExecutionCard> {
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late TextEditingController _setsController; // New Controller
  late bool _isCompleted;
  
  // Debounce helper could be added, but for now we update on simple events
  
  @override
  void initState() {
    super.initState();
    _isCompleted = widget.execution.isCompleted;
    
    // Initialize with Real values if present, else empty (or we could pre-fill with Target)
    _repsController = TextEditingController(text: widget.execution.repsDone ?? widget.execution.targetRepsSnapshot ?? '');
    _weightController = TextEditingController(text: widget.execution.weightUsed ?? widget.execution.targetWeightSnapshot ?? '');
    
    // Initialize Sets Controller. Convert Number to String if needed.
    // If widget.execution.setsDone is available (and is now String from backend, or we cast).
    // Note: widget.execution model might still think setsDone is number until we update frontend model.
    // We will assume backend returns new structure, but frontend model parses it.
    // Ideally we update frontend model too, but dynamic might handle it.
    _setsController = TextEditingController(text: widget.execution.setsDone?.toString() ?? widget.execution.targetSetsSnapshot?.toString() ?? '');
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

    // Send update
    // We send current text values as realized values when completing
    final updateData = {
      'isCompleted': value,
      'repsDone': _repsController.text,
      'weightUsed': _weightController.text,
      'setsDone': _setsController.text, // Include Sets
    };

    final success = await context.read<PlanProvider>().updateExerciseExecution(widget.execution.id, updateData);
    
    if (!success && mounted) {
      // Revert UI on failure
      setState(() {
        _isCompleted = !value;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.get('errorUpdate')), backgroundColor: Colors.red)
      );
    }
  }

  // Auto-save on focus lost equivalent or manual edit? 
  // For MVP, simply saving when checkbox is clicked is usually enough, 
  // BUT if they edit text *after* checking, we should also save. 
  // Let's attach listeners or use `onChanged` with simple debounce or save-on-submit.
  // Simplest valid UX: Edit fields -> Click Checkbox -> Saves Everything.
  // If already checked and editing -> We should probably save on field submit or blur.

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
      // We don't necessarily send isCompleted here unless we want to enforce it? 
      // Just sending fields corresponds to partial update.
      'repsDone': _repsController.text,
      'weightUsed': _weightController.text,
      'setsDone': _setsController.text,
    };
    
    // We do NOT optimize by checking equality because _repsController.text vs execution.repsDone might differ 
    // if backend hasn't refreshed yet. But generally good practice.
    // For now, just save.
    
    await context.read<PlanProvider>().updateExerciseExecution(widget.execution.id, updateData);
  }

  @override
  Widget build(BuildContext context) {
    // Colors
    const completedColor = Colors.green;
    final defaultColor = Theme.of(context).primaryColor;
    // We assume if Wrap is ignoring pointer (parent), we can't click swap anyway.
    // But better to hide it if we knew it's readOnly. 
    // We don't have readOnly passed to Card explicitly except via IgnorePointer.
    // But we can check if we want to pass it.
    // Or just rely on IgnorePointer which disables the IconButton.
    // Let's assume IgnorePointer handles interaction prevention.
    
    final bool readOnly = false; // logic handled by parent IgnorePointer


    return Card(
      elevation: _isCompleted ? 1 : 4,
      margin: const EdgeInsets.only(bottom: 20),
      color: _isCompleted ? Colors.green.withValues(alpha: 0.15) : null, // Theme aware tint logic
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: _isCompleted ? const BorderSide(color: Colors.green, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Number + Name + Checkbox
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Number Badge
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isCompleted ? completedColor.withValues(alpha: 0.2) : defaultColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#${widget.index}',
                    style: TextStyle(
                      color: _isCompleted 
                          ? completedColor 
                          : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).primaryColor),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Name & Video
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.execution.exerciseNameSnapshot,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          decoration: _isCompleted ? TextDecoration.lineThrough : null,
                          color: _isCompleted ? Colors.green : Theme.of(context).textTheme.bodyLarge?.color,
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


                
                // Swap Button
                if (!readOnly && (widget.execution.exercise?.muscles.any((m) => m.role == 'PRIMARY') ?? false))
                  IconButton(
                    icon: const Icon(Icons.swap_horiz, color: Colors.blueGrey),
                    onPressed: () => _showSwapDialog(context),
                  ),

                // Checkbox
                Transform.scale(
                  scale: 1.3,
                  child: Checkbox(
                    value: _isCompleted,
                    activeColor: completedColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: _toggleCompletion,
                  ),
                ),
              ],
            ),

            // Muscle Tags
            if (widget.execution.exercise?.muscles.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: widget.execution.exercise!.muscles.map((em) {
                  final isPrimary = em.role == 'PRIMARY'; // Should match Enum string from backend
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
            
            const SizedBox(height: 16),
            const Divider(height: 1), // Theme-aware divider
            const SizedBox(height: 16),

            // Inputs Row: Plan vs Real
            // We show "Suggested" as a label/hint, and "Real" as the input.
            Row(
              children: [
                // Sets (Now Editable)
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

                // Reps (Editable)
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

                // Weight (Editable)
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
      keyboardType: TextInputType.text, // Could be number, but sometimes "10-12"
      decoration: InputDecoration(
        labelText: '$label (Sugg: $hint)', 
        // Showing suggestion in label or hint is tricky. 
        // "Reps (Plan: 10)" is clear.
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
        suffixIcon: Icon(icon, size: 16, color: Colors.grey),
      ),
      style: const TextStyle(fontWeight: FontWeight.bold),
      onChanged: _onFieldChanged,
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
    
    // Find Primary Muscle
    // We assume backend returns 'PRIMARY' string.
    final muscles = widget.execution.exercise!.muscles;
    final primary = muscles.firstWhere(
      (m) => m.role == 'PRIMARY', 
      orElse: () => muscles.isNotEmpty 
          ? muscles.first 
          : throw 'No muscles' // Handled by try/catch or checks
    );
    
    // Check if "No muscles" case (shouldn't happen if button verified)
    // But if it throws string, handle it (or just return)
    if (muscles.isEmpty) return; 

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${AppLocalizations.of(ctx)!.get('changeExercise') ?? "Change Exercise"}'),
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
    final updateData = {
      'exercise': {'id': newEx.id},
      'exerciseNameSnapshot': newEx.name,
      'videoUrl': newEx.videoUrl,
      'planExerciseId': null, 
    };
    
    await context.read<PlanProvider>().updateExerciseExecution(widget.execution.id, updateData);
  }
}

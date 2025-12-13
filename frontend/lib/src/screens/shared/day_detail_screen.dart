import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/plan_model.dart';

class DayDetailScreen extends StatefulWidget {
  final PlanDay day;
  // Optional tracking parameters
  final bool isTracking;
  final Map<String, bool>? completedExercises;
  final Function(String exerciseId, bool isCompleted)? onToggleExercise;

  const DayDetailScreen({
    super.key, 
    required this.day,
    this.isTracking = false,
    this.completedExercises,
    this.onToggleExercise,
  });

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  late Map<String, bool> _localCompletedExercises;

  @override
  void initState() {
    super.initState();
    _localCompletedExercises = Map.from(widget.completedExercises ?? {});
  }

  @override
  void didUpdateWidget(DayDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.completedExercises != oldWidget.completedExercises) {
       _localCompletedExercises = Map.from(widget.completedExercises ?? {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.day.title ?? 'Day ${widget.day.dayOfWeek}'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Training Session',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
             const SizedBox(height: 8),
            Text(
              '${widget.day.exercises.length} Exercises to complete',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ...widget.day.exercises.asMap().entries.map((entry) {
              final index = entry.key;
              final exercise = entry.value;
              return _buildExerciseCard(context, exercise, index + 1);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, dynamic exercise, int index) {
    bool isCompleted = false;
    if (widget.isTracking && exercise.id != null) {
      isCompleted = _localCompletedExercises[exercise.id] == true;
    }

    return Card(
      elevation: isCompleted ? 1 : 4, // Flatten if done
      margin: const EdgeInsets.only(bottom: 20),
      color: isCompleted ? Colors.green[50] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isCompleted ? const BorderSide(color: Colors.green, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green.withOpacity(0.2) : Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#$index',
                    style: TextStyle(
                      color: isCompleted ? Colors.green : Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.exercise?.name ?? 'Unknown Exercise',
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                          color: isCompleted ? Colors.green[900] : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                       // Placeholder for muscle group if we had it
                      Text('Target Muscle', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    ],
                  ),
                ),
                // Tracking Checkbox
                if (widget.isTracking)
                  Checkbox(
                    value: isCompleted,
                    activeColor: Colors.green,
                    onChanged: (val) {
                      if (exercise.id != null) {
                        setState(() {
                          if (val == true) {
                            _localCompletedExercises[exercise.id!] = true;
                          } else {
                            _localCompletedExercises.remove(exercise.id!);
                          }
                        });
                        
                        if (widget.onToggleExercise != null) {
                          widget.onToggleExercise!(exercise.id!, val == true);
                        }
                      }
                    },
                  ),

                if (exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty && !widget.isTracking)
                   // Keep video button if strictly viewing, or maybe beside checkbox?
                   // Space is tight. Let's move video button to bottom if tracking.
                   Container(), 
              ],
            ),
            // Video Button (Row separate if tracking enabled)
             if (exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                       child: ElevatedButton.icon(
                        onPressed: () => _launchVideo(context, exercise.videoUrl!),
                        icon: const Icon(Icons.play_circle_outline, color: Colors.white, size: 16),
                        label: const Text('Instruction Video', style: TextStyle(color: Colors.white, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero, 
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ),

            const SizedBox(height: 12),
            
            // Metrics Grid
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                   _buildMetric(context, Icons.repeat, '${exercise.sets}', 'Sets'),
                   _buildMetric(context, Icons.refresh, '${exercise.reps}', 'Reps'), // Using refresh as reps icon
                   if (exercise.suggestedLoad != null && exercise.suggestedLoad!.isNotEmpty)
                     _buildMetric(context, Icons.fitness_center, exercise.suggestedLoad!, 'Load (Kg)'),
                    if (exercise.rest != null && exercise.rest!.isNotEmpty)
                     _buildMetric(context, Icons.timer, exercise.rest!, 'Rest'),
                ],
              ),
            ),
            
            if (exercise.notes != null && exercise.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber[100]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        exercise.notes!,
                        style: TextStyle(color: Colors.amber[900], fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
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
          const SnackBar(content: Text('Could not launch video URL')),
        );
      }
    }
  }
}

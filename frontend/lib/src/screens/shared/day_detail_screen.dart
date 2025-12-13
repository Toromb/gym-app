import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/plan_model.dart';

class DayDetailScreen extends StatelessWidget {
  final PlanDay day;

  const DayDetailScreen({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(day.title ?? 'Day ${day.dayOfWeek}'),
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
              '${day.exercises.length} Exercises to complete',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ...day.exercises.asMap().entries.map((entry) {
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
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#$index',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
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
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                       // Placeholder for muscle group if we had it
                      Text('Target Muscle', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    ],
                  ),
                ),
                if (exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty)
                   ElevatedButton.icon(
                    onPressed: () => _launchVideo(context, exercise.videoUrl!),
                    icon: const Icon(Icons.play_circle_outline, color: Colors.white),
                    label: const Text('Video instructivo', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            
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

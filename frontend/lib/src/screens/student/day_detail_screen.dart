import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/plan_model.dart';

class DayDetailScreen extends StatelessWidget {
  final PlanDay day;

  const DayDetailScreen({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(day.title ?? 'Day ${day.dayOfWeek}')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: day.exercises.length,
        itemBuilder: (context, index) {
          final exercise = day.exercises[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.exercise?.name ?? 'Unknown Exercise',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Sets: ${exercise.sets}'),
                      Text('Reps: ${exercise.reps}'),
                      if (exercise.suggestedLoad != null && exercise.suggestedLoad!.isNotEmpty)
                        Text('Load: ${exercise.suggestedLoad}'),
                    ],
                  ),
                  if (exercise.rest != null && exercise.rest!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Rest: ${exercise.rest}'),
                  ],
                  if (exercise.notes != null && exercise.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Notes: ${exercise.notes}', style: const TextStyle(fontStyle: FontStyle.italic)),
                  ],
                  if (exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(exercise.videoUrl!);
                         if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        } else {
                           if (context.mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('Could not launch video URL')),
                            );
                           }
                        }
                      },
                      icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                      label: const Text('Watch Video'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../models/plan_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'create_exercise_screen.dart'; // For edit navigation

class ExerciseDetailScreen extends StatelessWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateExerciseScreen(exercise: exercise)),
              );
              if (result == true) {
                 Navigator.pop(context, true); // Pop back to list with refresh signal
              }
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildDefaultsSection(context),
            const SizedBox(height: 20),
            _buildNotesSection(context),
            const SizedBox(height: 20),
            if (exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty)
              _buildVideoSection(context),
          ],
        ),
      ),
      ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  child: Text(exercise.name[0], style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exercise.name, style: Theme.of(context).textTheme.headlineSmall),
                      Text(exercise.muscleGroup, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            if (exercise.type != null) ...[
              const SizedBox(height: 10),
              Chip(label: Text(exercise.type!), backgroundColor: Colors.blue.shade50),
            ],
            if (exercise.equipments.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: exercise.equipments.map((e) => 
                  Chip(
                    label: Text(e.name, style: const TextStyle(fontSize: 12)), 
                    backgroundColor: Colors.orange.shade50,
                    visualDensity: VisualDensity.compact,
                  )
                ).toList(),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Valores por Defecto', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        
        // Métrica Label
        if (exercise.metricType != 'REPS')
            Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Chip(
                    label: Text('Métrica: ${exercise.metricType}'), 
                    backgroundColor: Colors.purple.shade50,
                    avatar: Icon(
                        exercise.metricType == 'TIME' ? Icons.timer : Icons.directions_run, 
                        size: 16, color: Colors.purple
                    ),
                ),
            ),

        Wrap(
          spacing: 16,
          runSpacing: 10,
          children: [
             _buildInfoCard('Series', exercise.sets?.toString() ?? exercise.defaultSets?.toString() ?? '-'),
             _buildInfoCard('Descanso', exercise.rest ?? '-'),
             
             if (exercise.metricType == 'REPS') ...[
                _buildInfoCard('Reps', exercise.reps ?? '-'),
                _buildInfoCard('Carga', exercise.load ?? '-'),
                if (exercise.minReps != null) _buildInfoCard('Min Reps', exercise.minReps.toString()),
                if (exercise.maxReps != null) _buildInfoCard('Max Reps', exercise.maxReps.toString()),
             ] else if (exercise.metricType == 'TIME') ...[
                _buildInfoCard('Tiempo', exercise.defaultTime != null ? '${exercise.defaultTime}s' : '-'),
                if (exercise.minTime != null) _buildInfoCard('Min T', '${exercise.minTime}s'),
                if (exercise.maxTime != null) _buildInfoCard('Max T', '${exercise.maxTime}s'),
             ] else if (exercise.metricType == 'DISTANCE') ...[
                _buildInfoCard('Distancia', exercise.defaultDistance != null ? '${exercise.defaultDistance}m' : '-'),
                if (exercise.minDistance != null) _buildInfoCard('Min Dist', '${exercise.minDistance}m'),
                if (exercise.maxDistance != null) _buildInfoCard('Max Dist', '${exercise.maxDistance}m'),
             ]
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    if (exercise.notes == null || exercise.notes!.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notas', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.yellow.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.yellow.shade200),
          ),
          child: Text(exercise.notes!),
        ),
      ],
    );
  }

  Widget _buildVideoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Video', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
         ListTile(
            leading: const Icon(Icons.video_library, color: Colors.red),
            title: const Text('Ver Video de Instrucción'),
            subtitle: Text(exercise.videoUrl!),
            onTap: () async {
               if (exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty) {
                 final uri = Uri.parse(exercise.videoUrl!);
                 if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                 } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open video link')));
                    }
                 }
               }
            },
         ),
      ],
    );
  }
}

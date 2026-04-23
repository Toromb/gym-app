import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/plan_provider.dart';
import '../../models/completed_plan_model.dart';
import '../../widgets/background_page_wrapper.dart';
import '../../utils/app_colors.dart';
import '../../models/execution_model.dart';

class StudentHistoryScreen extends StatefulWidget {
  const StudentHistoryScreen({super.key});

  @override
  State<StudentHistoryScreen> createState() => _StudentHistoryScreenState();
}

class _StudentHistoryScreenState extends State<StudentHistoryScreen> {
  bool _isLoading = true;
  String? _error;
  List<CompletedPlan> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await context.read<PlanProvider>().fetchCompletedHistory();
      if (mounted) {
        setState(() {
          _history = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar el historial';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundPageWrapper(
      overlayOpacity: 0.85,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Mi Historial'),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_history.isEmpty) {
      return Center(
        child: Text(
          'No hay historial disponible aún.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final plan = _history[index];
        return _buildHistoryCard(plan, context);
      },
    );
  }

  Widget _buildHistoryCard(CompletedPlan plan, BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          plan.planNameSnapshot,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${plan.translatedReason} • ${plan.formattedStartDate} - ${plan.formattedEndDate}',
              style: textTheme.bodySmall?.copyWith(color: AppColors.textSoft),
            ),
            const SizedBox(height: 4),
            Text(
              '${plan.sessions.length} sesiones realizadas',
              style: textTheme.bodySmall?.copyWith(color: AppColors.textMain),
            ),
          ],
        ),
        children: plan.sessions.map((session) {
          return Container(
            color: Colors.black.withValues(alpha: 0.1),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sesión ${session.date} (${session.status})',
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...session.exercises.map((ex) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: AppColors.accent)),
                        Expanded(
                          child: Text(
                            '${ex.exerciseNameSnapshot}: ${_buildMetricsString(ex)}',
                            style: textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
  String _buildMetricsString(SessionExercise ex) {
    // 1. Determine Metric Type
    String metricType = ex.exercise?.metricType ?? 'REPS';
    if (ex.exercise == null) {
      if (ex.targetTimeSnapshot != null || ex.timeSpent != null) metricType = 'TIME';
      if (ex.targetDistanceSnapshot != null || ex.distanceCovered != null) metricType = 'DISTANCE';
    }

    // 2. Determinate if Body Weight
    bool isBodyWeight = ex.equipmentsSnapshot.any((e) => e.isBodyWeight) ||
        (ex.exercise?.equipments.any((e) => e.isBodyWeight) ?? false);

    final setsStr = '${ex.setsDone ?? '-'} series';

    if (metricType == 'DISTANCE') {
      return '$setsStr • ${ex.distanceCovered ?? '-'} m';
    }

    if (metricType == 'TIME') {
      final timeStr = '${ex.timeSpent ?? '-'} seg';
      if (isBodyWeight) {
        return '$setsStr • $timeStr • Peso corporal';
      } else if (ex.weightUsed != null && ex.weightUsed!.isNotEmpty && ex.weightUsed != '0') {
        return '$setsStr • $timeStr • ${ex.weightUsed} kg';
      }
      return '$setsStr • $timeStr'; // No weight info
    }

    // Default: REPS
    final repsStr = '${ex.repsDone ?? '-'} reps';
    if (isBodyWeight) {
      return '$setsStr • $repsStr • Peso corporal';
    } else {
      String weightStr = '';
      if (ex.weightUsed != null && ex.weightUsed!.isNotEmpty) {
        weightStr = ' • ${ex.weightUsed} kg';
      } else {
        weightStr = ' • - kg';
      }
      return '$setsStr • $repsStr$weightStr';
    }
  }
}

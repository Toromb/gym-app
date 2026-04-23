import 'package:gym_app/src/models/execution_model.dart';
import 'package:intl/intl.dart';

class CompletedPlan {
  final String id;
  final String originalPlanId;
  final String planNameSnapshot;
  final String completedReason;
  final String startedAt;
  final String completedAt;
  final List<TrainingSession> sessions;

  CompletedPlan({
    required this.id,
    required this.originalPlanId,
    required this.planNameSnapshot,
    required this.completedReason,
    required this.startedAt,
    required this.completedAt,
    required this.sessions,
  });

  factory CompletedPlan.fromJson(Map<String, dynamic> json) {
    return CompletedPlan(
      id: json['id'],
      originalPlanId: json['originalPlanId'] ?? '',
      planNameSnapshot: json['planNameSnapshot'] ?? 'Unknown Plan',
      completedReason: json['completedReason'] ?? 'COMPLETED',
      startedAt: json['startedAt'] ?? '',
      completedAt: json['completedAt'] ?? '',
      sessions: (json['sessions'] as List?)
              ?.map((e) => TrainingSession.fromJson(e))
              .toList() ??
          [],
    );
  }
  
  String get formattedStartDate {
    if (startedAt.isEmpty) return 'Desconocida';
    try {
      final date = DateTime.parse(startedAt);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return startedAt;
    }
  }

  String get formattedEndDate {
    if (completedAt.isEmpty) return 'Desconocida';
    try {
      final date = DateTime.parse(completedAt);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return completedAt;
    }
  }
  
  String get translatedReason {
    switch(completedReason) {
      case 'CANCELLED': return 'Cancelado';
      case 'RESTARTED': return 'Reiniciado';
      case 'COMPLETED': return 'Completado';
      default: return completedReason;
    }
  }
}

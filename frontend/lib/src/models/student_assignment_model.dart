import 'plan_model.dart';

class StudentAssignment {
  final String id;
  final Plan plan;
  final String? assignedAt;
  final bool isActive;
  final Map<String, dynamic> progress; // { exercises: {}, days: {} }

  StudentAssignment({
    required this.id,
    required this.plan,
    this.assignedAt,
    required this.isActive,
    required this.progress,
  });

  factory StudentAssignment.fromJson(Map<String, dynamic> json) {
    return StudentAssignment(
      id: json['id'],
      plan: Plan.fromJson(json['plan']),
      assignedAt: json['assignedAt'],
      isActive: json['isActive'] ?? false,
      progress: json['progress'] ?? {'exercises': {}, 'days': {}},
    );
  }

  bool isExerciseCompleted(String exerciseId) {
    if (progress['exercises'] == null) return false;
    return progress['exercises'][exerciseId] == true;
  }

  bool isDayCompleted(String dayId) {
    if (progress['days'] == null) return false;
    return progress['days'][dayId] != null;
  }

  // Helper to clone with new progress for optimistic updates
  StudentAssignment copyWithProgress({Map<String, dynamic>? newProgress}) {
    return StudentAssignment(
      id: id,
      plan: plan,
      assignedAt: assignedAt,
      isActive: isActive,
      progress: newProgress ?? progress,
    );
  }
}

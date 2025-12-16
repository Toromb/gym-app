import 'plan_model.dart';

class PlanExecution {
  final String id;
  final String date;
  final String dayKey;
  final String status; // 'IN_PROGRESS', 'COMPLETED'
  final List<ExerciseExecution> exercises;

  PlanExecution({
    required this.id,
    required this.date,
    required this.dayKey,
    required this.status,
    required this.exercises,
  });

  factory PlanExecution.fromJson(Map<String, dynamic> json) {
    return PlanExecution(
      id: json['id'],
      date: json['date'],
      dayKey: json['dayKey'],
      status: json['status'],
      exercises: (json['exercises'] as List)
          .map((e) => ExerciseExecution.fromJson(e))
          .toList(),
    );
  }
  PlanExecution copyWith({
    String? status,
    List<ExerciseExecution>? exercises,
  }) {
    return PlanExecution(
      id: id,
      date: date,
      dayKey: dayKey,
      status: status ?? this.status,
      exercises: exercises ?? this.exercises,
    );
  }
}

class ExerciseExecution {
  final String id;
  // Snapshots
  final String exerciseNameSnapshot;
  final int? targetSetsSnapshot;
  final String? targetRepsSnapshot;
  final String? targetWeightSnapshot;
  final String? videoUrl;
  
  final Exercise? exercise;
  
  // Real Data
  final bool isCompleted;
  final int setsDone;
  final String? repsDone;
  final String? weightUsed;
  final String? notes;

  ExerciseExecution({
    required this.id,
    required this.exerciseNameSnapshot,
    this.targetSetsSnapshot,
    this.targetRepsSnapshot,
    this.targetWeightSnapshot,
    this.videoUrl,
    this.exercise,
    required this.isCompleted,
    required this.setsDone,
    this.repsDone,
    this.weightUsed,
    this.notes,
  });

  ExerciseExecution copyWith({
    bool? isCompleted,
    int? setsDone,
    String? repsDone,
    String? weightUsed,
    String? notes,
  }) {
    return ExerciseExecution(
      id: id,
      exerciseNameSnapshot: exerciseNameSnapshot,
      targetSetsSnapshot: targetSetsSnapshot,
      targetRepsSnapshot: targetRepsSnapshot,
      targetWeightSnapshot: targetWeightSnapshot,
      videoUrl: videoUrl,
      exercise: exercise,
      isCompleted: isCompleted ?? this.isCompleted,
      setsDone: setsDone ?? this.setsDone,
      repsDone: repsDone ?? this.repsDone,
      weightUsed: weightUsed ?? this.weightUsed,
      notes: notes ?? this.notes,
    );
  }

  factory ExerciseExecution.fromJson(Map<String, dynamic> json) {

    return ExerciseExecution(
      id: json['id'],
      // Fallback to empty string if snapshot missing (shouldn't happen per strict rules)
      exerciseNameSnapshot: json['exerciseNameSnapshot'] ?? 'Unknown Exercise',
      targetSetsSnapshot: json['targetSetsSnapshot'],
      targetRepsSnapshot: json['targetRepsSnapshot'],
      targetWeightSnapshot: json['targetWeightSnapshot'],
      videoUrl: json['videoUrl'],
      exercise: json['exercise'] != null ? Exercise.fromJson(json['exercise']) : null,
      isCompleted: json['isCompleted'] ?? false,
      setsDone: json['setsDone'] ?? 0,
      repsDone: json['repsDone'],
      weightUsed: json['weightUsed'],
      notes: json['notes'],
    );
  }

  factory ExerciseExecution.fromPlanExercise(PlanExercise pe) {
    return ExerciseExecution(
      id: 'dummy-${pe.id}', // Dummy ID
      exerciseNameSnapshot: pe.exercise?.name ?? 'Unknown Exercise',
      targetSetsSnapshot: pe.sets,
      targetRepsSnapshot: pe.reps,
      targetWeightSnapshot: pe.suggestedLoad,
      videoUrl: pe.videoUrl ?? pe.exercise?.videoUrl,
      exercise: pe.exercise,
      isCompleted: false,
      setsDone: 0,
    );
  }
}

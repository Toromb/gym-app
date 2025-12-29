import 'plan_model.dart';

class TrainingSession {
  final String id;
  final String date;
  final String? planId; // Nullable for free sessions
  final String source; // 'PLAN', 'FREE', 'CLASS'
  final String status; // 'IN_PROGRESS', 'COMPLETED', 'ABANDONED'
  final List<SessionExercise> exercises;
  // Legacy fields adapting to new model
  final String? dayKey; 

  TrainingSession({
    required this.id,
    required this.date,
    this.planId,
    this.source = 'PLAN',
    required this.status,
    required this.exercises,
    this.dayKey,
  });

  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    return TrainingSession(
      id: json['id'],
      date: json['date'],
      planId: json['plan'] != null ? (json['plan'] is String ? json['plan'] : json['plan']['id']) : null,
      source: json['source'] ?? 'PLAN',
      status: json['status'],
      dayKey: json['dayKey'], // Might be null
      exercises: (json['exercises'] as List)
          .map((e) => SessionExercise.fromJson(e))
          .toList(),
    );
  }
  TrainingSession copyWith({
    String? status,
    List<SessionExercise>? exercises,
  }) {
    return TrainingSession(
      id: id,
      date: date,
      planId: planId,
      source: source,
      status: status ?? this.status,
      exercises: exercises ?? this.exercises,
      dayKey: dayKey,
    );
  }
}

class SessionExercise {
  final String id;
  // Snapshots
  final String exerciseNameSnapshot;
  final int? targetSetsSnapshot;
  final String? targetRepsSnapshot;
  final String? targetWeightSnapshot;
  final String? videoUrl;
  final List<Equipment> equipmentsSnapshot;
  
  final Exercise? exercise;
  
  // Real Data
  final bool isCompleted;
  final String? setsDone; 
  final String? repsDone;
  final String? weightUsed;
  final String? notes;

  SessionExercise({
    required this.id,
    required this.exerciseNameSnapshot,
    this.targetSetsSnapshot,
    this.targetRepsSnapshot,
    this.targetWeightSnapshot,
    this.videoUrl,
    required this.equipmentsSnapshot, 
    this.exercise,
    required this.isCompleted,
    this.setsDone, 
    this.repsDone,
    this.weightUsed,
    this.notes,
  });

  SessionExercise copyWith({
    bool? isCompleted,
    String? setsDone,
    String? repsDone,
    String? weightUsed,
    String? notes,
    // Add swap support
    Exercise? exercise,
    String? exerciseNameSnapshot,
    String? videoUrl,
    List<Equipment>? equipmentsSnapshot,
  }) {
    return SessionExercise(
      id: id,
      exerciseNameSnapshot: exerciseNameSnapshot ?? this.exerciseNameSnapshot,
      targetSetsSnapshot: targetSetsSnapshot,
      targetRepsSnapshot: targetRepsSnapshot,
      targetWeightSnapshot: targetWeightSnapshot,
      videoUrl: videoUrl ?? this.videoUrl,
      equipmentsSnapshot: equipmentsSnapshot ?? this.equipmentsSnapshot,
      exercise: exercise ?? this.exercise,
      isCompleted: isCompleted ?? this.isCompleted,
      setsDone: setsDone ?? this.setsDone,
      repsDone: repsDone ?? this.repsDone,
      weightUsed: weightUsed ?? this.weightUsed,
      notes: notes ?? this.notes,
    );
  }

  factory SessionExercise.fromJson(Map<String, dynamic> json) {

    return SessionExercise(
      id: json['id'],
      exerciseNameSnapshot: json['exerciseNameSnapshot'] ?? 'Unknown Exercise',
      targetSetsSnapshot: json['targetSetsSnapshot'],
      targetRepsSnapshot: json['targetRepsSnapshot'],
      targetWeightSnapshot: json['targetWeightSnapshot'],
      videoUrl: json['videoUrl'],
      equipmentsSnapshot: (json['equipmentsSnapshot'] as List<dynamic>?)
              ?.map((e) => Equipment.fromJson(e))
              .toList() ??
          [],
      exercise: json['exercise'] != null ? Exercise.fromJson(json['exercise']) : null,
      isCompleted: json['isCompleted'] ?? false,
      setsDone: json['setsDone']?.toString(), 
      repsDone: json['repsDone'],
      weightUsed: json['weightUsed'],
      notes: json['notes'],
    );
  }

  // Helper for optimistically creating from PlanExercise before backend confirms
  factory SessionExercise.fromPlanExercise(PlanExercise pe) {
    return SessionExercise(
      id: 'dummy-${pe.id}', // Dummy ID
      exerciseNameSnapshot: pe.exercise?.name ?? 'Unknown Exercise',
      targetSetsSnapshot: pe.sets,
      targetRepsSnapshot: pe.reps,
      targetWeightSnapshot: pe.suggestedLoad,
      videoUrl: pe.videoUrl ?? pe.exercise?.videoUrl,
      equipmentsSnapshot: pe.equipments,
      exercise: pe.exercise,
      isCompleted: false,
      setsDone: pe.sets.toString(), 
    );
  }
}

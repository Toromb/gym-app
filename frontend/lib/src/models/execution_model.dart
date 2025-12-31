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
  final int? targetTimeSnapshot; // Seconds
  final double? targetDistanceSnapshot; // Meters
  final String? videoUrl;
  final List<Equipment> equipmentsSnapshot;
  
  final Exercise? exercise;
  
  // Real Data
  final bool isCompleted;
  final String? setsDone; 
  final String? repsDone;
  final String? weightUsed;
  final String? timeSpent; 
  final double? distanceCovered;
  final String? notes;

  SessionExercise({
    required this.id,
    required this.exerciseNameSnapshot,
    this.targetSetsSnapshot,
    this.targetRepsSnapshot,
    this.targetWeightSnapshot,
    this.targetTimeSnapshot,
    this.targetDistanceSnapshot,
    this.videoUrl,
    required this.equipmentsSnapshot, 
    this.exercise,
    required this.isCompleted,
    this.setsDone, 
    this.repsDone,
    this.weightUsed,
    this.timeSpent,
    this.distanceCovered,
    this.notes,
  });

  SessionExercise copyWith({
    bool? isCompleted,
    String? setsDone,
    String? repsDone,
    String? weightUsed,
    String? timeSpent,
    double? distanceCovered,
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
      targetTimeSnapshot: targetTimeSnapshot,
      targetDistanceSnapshot: targetDistanceSnapshot,
      videoUrl: videoUrl ?? this.videoUrl,
      equipmentsSnapshot: equipmentsSnapshot ?? this.equipmentsSnapshot,
      exercise: exercise ?? this.exercise,
      isCompleted: isCompleted ?? this.isCompleted,
      setsDone: setsDone ?? this.setsDone,
      repsDone: repsDone ?? this.repsDone,
      weightUsed: weightUsed ?? this.weightUsed,
      timeSpent: timeSpent ?? this.timeSpent,
      distanceCovered: distanceCovered ?? this.distanceCovered,
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
      targetTimeSnapshot: json['targetTimeSnapshot'],
      targetDistanceSnapshot: json['targetDistanceSnapshot'] != null ? (json['targetDistanceSnapshot'] as num).toDouble() : null,
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
      timeSpent: json['timeSpent'],
      distanceCovered: json['distanceCovered'] != null ? (json['distanceCovered'] as num).toDouble() : null,
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
      // PlanExercise doesn't have targetTime/Distance yet in my Plan update? 
      // I need to check PlanExercise update. Assuming I'll add them there too.
      // But for now, let's keep it robust.
      targetTimeSnapshot: pe.targetTime,
      targetDistanceSnapshot: pe.targetDistance,
      videoUrl: pe.videoUrl ?? pe.exercise?.videoUrl,
      equipmentsSnapshot: pe.equipments,
      exercise: pe.exercise,
      isCompleted: false,
      setsDone: pe.sets.toString(), 
    );
  }
}

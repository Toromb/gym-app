import 'user_model.dart';



class Equipment {
  final String id;
  final String name;

  Equipment({required this.id, required this.name});

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'],
      name: json['name'],
    );
  }
}

class Muscle {
  final String id;
  final String name;
  final String region;
  final String bodySide;
  final int order;

  Muscle({
    required this.id,
    required this.name,
    required this.region,
    required this.bodySide,
    required this.order,
  });

  factory Muscle.fromJson(Map<String, dynamic> json) {
    return Muscle(
      id: json['id'],
      name: json['name'],
      region: json['region'] ?? '',
      bodySide: json['bodySide'] ?? '',
      order: json['order'] ?? 0,
    );
  }
}

class ExerciseMuscle {
  final String id;
  final String role; // PRIMARY, SECONDARY, STABILIZER
  final Muscle muscle;

  ExerciseMuscle({
    required this.id,
    required this.role,
    required this.muscle,
  });

  factory ExerciseMuscle.fromJson(Map<String, dynamic> json) {
    return ExerciseMuscle(
      id: json['id'],
      role: json['role'],
      muscle: Muscle.fromJson(json['muscle']),
    );
  }
}

class Exercise {
  final String id;
  final String name;
  final String? description;
  final String? videoUrl;
  final String? imageUrl;
  final String muscleGroup;
  final String? type;
  
  // Defaults
  final int? sets;
  final String? reps;
  final String? rest;
  final String? load;
  final String? notes;
  final List<ExerciseMuscle> muscles;
  final List<Equipment> equipments;
  
  // Professional Change System Config
  final double? loadFactor;
  final int? defaultSets;
  final int? minReps;
  final int? maxReps;

  // Metric fields
  final String metricType; // 'REPS', 'TIME', 'DISTANCE'
  final int? defaultTime;
  final int? minTime;
  final int? maxTime;
  final double? defaultDistance;
  final double? minDistance;
  final double? maxDistance;

  Exercise({
    required this.id,
    required this.name,
    this.description,
    this.videoUrl,
    this.imageUrl,
    required this.muscleGroup,
    this.type,
    this.sets,
    this.reps,
    this.rest,
    this.load,
    this.notes,
    this.muscles = const [],
    this.equipments = const [],
    this.loadFactor,
    this.defaultSets,
    this.minReps,
    this.maxReps,
    this.metricType = 'REPS',
    this.defaultTime,
    this.minTime,
    this.maxTime,
    this.defaultDistance,
    this.minDistance,
    this.maxDistance,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    var musclesList = (json['exerciseMuscles'] as List<dynamic>?)
            ?.map((e) => ExerciseMuscle.fromJson(e))
            .toList() ??
        [];

    return Exercise(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      videoUrl: json['videoUrl'],
      imageUrl: json['imageUrl'],
      muscleGroup: json['muscleGroup'] ?? 'General',
      type: json['type'],
      sets: json['sets'],
      reps: json['reps'],
      rest: json['rest'],
      load: json['load'],
      notes: json['notes'],
      loadFactor: json['loadFactor'] != null ? (json['loadFactor'] as num).toDouble() : null,
      defaultSets: json['defaultSets'],
      minReps: json['minReps'],
      maxReps: json['maxReps'],
      muscles: musclesList,
      equipments: (json['equipments'] as List<dynamic>?)
              ?.map((e) => Equipment.fromJson(e))
              .toList() ??
          [],
      metricType: json['metricType'] ?? 'REPS',
      defaultTime: json['defaultTime'],
      minTime: json['minTime'],
      maxTime: json['maxTime'],
      defaultDistance: json['defaultDistance'] != null ? (json['defaultDistance'] as num).toDouble() : null,
      minDistance: json['minDistance'] != null ? (json['minDistance'] as num).toDouble() : null,
      maxDistance: json['maxDistance'] != null ? (json['maxDistance'] as num).toDouble() : null,
    );
  }
}

class PlanExercise {
  final String? id;
  final Exercise? exercise; // For reading
  final String? exerciseId; // For creation
  final int sets;
  final String reps;
  final String? suggestedLoad;
  final String? rest;
  final String? notes;
  final String? videoUrl;
  final int? targetTime; // New: For TIME exercises
  final double? targetDistance; // New: For DISTANCE exercises
  int order;
  final List<Equipment> equipments;

  PlanExercise({
    this.id,
    this.exercise,
    this.exerciseId,
    required this.sets,
    required this.reps, // Kept required for legacy, even if empty for Time
    this.suggestedLoad,
    this.rest,
    this.notes,
    this.videoUrl,
    this.targetTime,
    this.targetDistance,
    required this.order,
    this.equipments = const [],
  });

  factory PlanExercise.fromJson(Map<String, dynamic> json) {
    return PlanExercise(
      id: json['id'],
      exercise: json['exercise'] != null ? Exercise.fromJson(json['exercise']) : null,
      sets: json['sets'] ?? 0,
      reps: json['reps'] ?? '',
      suggestedLoad: json['suggestedLoad'],
      rest: json['rest'],
      notes: json['notes'],
      videoUrl: json['videoUrl'],
      targetTime: json['targetTime'],
      targetDistance: json['targetDistance'] != null ? (json['targetDistance'] as num).toDouble() : null,
      order: json['order'] ?? 0,
      equipments: (json['equipments'] as List<dynamic>?)
              ?.map((e) => Equipment.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exerciseId': exerciseId ?? exercise?.id,
      'sets': sets,
      'reps': reps,
      'suggestedLoad': suggestedLoad,
      'rest': rest,
      'notes': notes,
      'videoUrl': videoUrl,
      'targetTime': targetTime,
      'targetDistance': targetDistance,
      'order': order,
      'equipmentIds': equipments.map((e) => e.id).toList(),
    };
  }
}

enum TrainingIntent {
  STRENGTH,
  HYPERTROPHY,
  ENDURANCE,
  GENERAL;

  String get label {
    switch (this) {
      case TrainingIntent.STRENGTH: return 'Fuerza';
      case TrainingIntent.HYPERTROPHY: return 'Hipertrofia';
      case TrainingIntent.ENDURANCE: return 'Resistencia';
      case TrainingIntent.GENERAL: return 'General';
    }
  }

  // To/From String for API
  static TrainingIntent fromString(String? key) {
    if (key == null) return TrainingIntent.GENERAL;
    switch (key.toUpperCase()) {
      case 'STRENGTH': return TrainingIntent.STRENGTH;
      case 'HYPERTROPHY': return TrainingIntent.HYPERTROPHY;
      case 'ENDURANCE': return TrainingIntent.ENDURANCE;
      default: return TrainingIntent.GENERAL;
    }
  }

  String toApiString() {
    return this.name.toUpperCase();
  }
}

class PlanDay {
  final String? id;
  final String? title;
  int dayOfWeek;
  int order;
  final TrainingIntent trainingIntent;
  final String? dayNotes;
  final List<PlanExercise> exercises;

  PlanDay({
    this.id,
    this.title,
    required this.dayOfWeek,
    required this.order,
    this.trainingIntent = TrainingIntent.GENERAL,
    this.dayNotes,
    required this.exercises,
  });

  factory PlanDay.fromJson(Map<String, dynamic> json) {
    var exercisesList = (json['exercises'] as List<dynamic>?)
            ?.map((e) => PlanExercise.fromJson(e))
            .toList() ??
        [];
    exercisesList.sort((a, b) => a.order.compareTo(b.order));

    return PlanDay(
      id: json['id'],
      title: json['title'],
      dayOfWeek: json['dayOfWeek'] ?? 0,
      order: json['order'] ?? 0,
      trainingIntent: TrainingIntent.fromString(json['trainingIntent']),
      dayNotes: json['dayNotes'],
      exercises: exercisesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'dayOfWeek': dayOfWeek,
      'order': order,
      'trainingIntent': trainingIntent.toApiString(),
      'dayNotes': dayNotes,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }
}

class PlanWeek {
  final String? id;
  int weekNumber;
  final List<PlanDay> days;

  PlanWeek({
    this.id,
    required this.weekNumber,
    required this.days,
  });

  factory PlanWeek.fromJson(Map<String, dynamic> json) {
    var daysList = (json['days'] as List<dynamic>?)
            ?.map((d) => PlanDay.fromJson(d))
            .toList() ??
        [];
    daysList.sort((a, b) => a.order.compareTo(b.order));

    return PlanWeek(
      id: json['id'],
      weekNumber: json['weekNumber'] ?? 1,
      days: daysList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekNumber': weekNumber,
      'days': days.map((d) => d.toJson()).toList(),
    };
  }

  // Helper to get name (e.g. "Semana 1")
  String get name => 'Semana $weekNumber';
}

class Plan {
  final String? id;
  final String name;
  final String? objective;
  final int durationWeeks;
  final String? generalNotes;
  final List<PlanWeek> weeks;
  final User? teacher;
  final String? createdAt;

  Plan({
    this.id,
    required this.name,
    this.objective,
    required this.durationWeeks,
    this.generalNotes,
    required this.weeks,
    this.teacher,
    this.createdAt,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    var weeksList = (json['weeks'] as List<dynamic>?)
            ?.map((w) => PlanWeek.fromJson(w))
            .toList() ??
        [];
    weeksList.sort((a, b) => a.weekNumber.compareTo(b.weekNumber));

    return Plan(
      id: json['id'],
      name: json['name'],
      objective: json['objective'],
      durationWeeks: json['durationWeeks'] ?? 4,
      generalNotes: json['generalNotes'],
      weeks: weeksList,
      teacher: json['teacher'] != null ? User.fromJson(json['teacher']) : null,
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'objective': objective,
      'durationWeeks': durationWeeks,
      'generalNotes': generalNotes,
      'weeks': weeks.map((w) => w.toJson()).toList(),
      // Teacher and createdAt generally not sent on create
    };
  }
}

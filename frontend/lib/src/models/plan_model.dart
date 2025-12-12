import 'user_model.dart';

class Exercise {
  final String id;
  final String name;
  final String? description;
  final String? videoUrl;

  Exercise({
    required this.id,
    required this.name,
    this.description,
    this.videoUrl,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      videoUrl: json['videoUrl'],
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
  int order;

  PlanExercise({
    this.id,
    this.exercise,
    this.exerciseId,
    required this.sets,
    required this.reps,
    this.suggestedLoad,
    this.rest,
    this.notes,
    this.videoUrl,
    required this.order,
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
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId ?? exercise?.id,
      'sets': sets,
      'reps': reps,
      'suggestedLoad': suggestedLoad,
      'rest': rest,
      'notes': notes,
      'videoUrl': videoUrl,
      'order': order,
    };
  }
}

class PlanDay {
  final String? id;
  final String? title;
  int dayOfWeek;
  int order;
  final String? dayNotes;
  final List<PlanExercise> exercises;

  PlanDay({
    this.id,
    this.title,
    required this.dayOfWeek,
    required this.order,
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
      dayNotes: json['dayNotes'],
      exercises: exercisesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'dayOfWeek': dayOfWeek,
      'order': order,
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

  // Helper to get name (e.g. "Week 1")
  String get name => 'Week $weekNumber';
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

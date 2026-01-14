import 'package:gym_app/src/models/plan_model.dart';

enum FreeTrainingType {
  funcional,
  crossfit,
  cardio,
  musculacion,
  musculacionCardio,
}

enum TrainingLevel {
  inicial,
  medio,
  avanzado,
}

enum BodySector {
  piernas,
  zonaMedia,
  hombros,
  espalda,
  pecho,
  fullBody,
}

enum CardioLevel {
  inicial,
  medio,
  avanzado,
}

class FreeTraining {
  final String id;
  final String gymId;
  final String name; 
  final FreeTrainingType type;
  final TrainingLevel level;
  final BodySector? sector;
  final CardioLevel? cardioLevel;
  final List<FreeTrainingExercise> exercises;

  FreeTraining({
    required this.id,
    required this.gymId,
    required this.name,
    required this.type,
    required this.level,
    this.sector,
    this.cardioLevel,
    required this.exercises,
  });

  factory FreeTraining.fromJson(Map<String, dynamic> json) {
    return FreeTraining(
      id: json['id'],
      gymId: json['gymId'],
      name: json['name'],
      type: _parseType(json['type']),
      level: _parseLevel(json['level']),
      sector: json['sector'] != null ? _parseSector(json['sector']) : null,
      cardioLevel: json['cardioLevel'] != null ? _parseCardioLevel(json['cardioLevel']) : null,
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => FreeTrainingExercise.fromJson(e))
              .toList() ??
          [],
    );
  }

  static FreeTrainingType _parseType(String type) {
    if (type == 'MUSCULACION_CARDIO') return FreeTrainingType.musculacionCardio;
    return FreeTrainingType.values.firstWhere(
      (e) => e.name.toUpperCase() == type.toUpperCase(),
      orElse: () => FreeTrainingType.musculacion,
    );
  }

  static TrainingLevel _parseLevel(String level) {
    return TrainingLevel.values.firstWhere(
      (e) => e.name.toUpperCase() == level.toUpperCase(),
      orElse: () => TrainingLevel.inicial,
    );
  }

  static BodySector _parseSector(String sector) {
    if (sector == 'ZONA_MEDIA') return BodySector.zonaMedia;
    if (sector == 'FULL_BODY') return BodySector.fullBody;
    return BodySector.values.firstWhere(
      (e) => e.name.toUpperCase() == sector.toUpperCase(),
      orElse: () => BodySector.fullBody,
    );
  }

  static CardioLevel _parseCardioLevel(String level) {
   return CardioLevel.values.firstWhere(
      (e) => e.name.toUpperCase() == level.toUpperCase(),
      orElse: () => CardioLevel.inicial,
    );
  }
}

class FreeTrainingExercise {
  final String id;
  final Exercise exercise;
  final int order;
  final int sets;
  final String? reps;
  final String? suggestedLoad;
  final String? rest;
  final String? notes;
  final String? videoUrl;
  final List<Equipment>? equipments;

  FreeTrainingExercise({
    required this.id,
    required this.exercise,
    required this.order,
    this.sets = 3,
    this.reps,
    this.suggestedLoad,
    this.rest,
    this.notes,
    this.videoUrl,
    this.equipments,
  });

  factory FreeTrainingExercise.fromJson(Map<String, dynamic> json) {
    return FreeTrainingExercise(
      id: json['id'],
      exercise: Exercise.fromJson(json['exercise']),
      order: json['order'] ?? 0,
      sets: json['sets'] ?? 3,
      reps: json['reps'],
      suggestedLoad: json['suggestedLoad'],
      rest: json['rest'],
      notes: json['notes'],
      videoUrl: json['videoUrl'],
      equipments: (json['equipments'] as List<dynamic>?)
          ?.map((e) => Equipment.fromJson(e))
          .toList(),
    );
  }
}

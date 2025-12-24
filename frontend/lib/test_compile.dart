import 'package:flutter/material.dart';
import 'src/services/exercise_api_service.dart';

void main() async {
  final service = ExerciseService();
  await service.getExercises(muscleId: null);
  await service.getMuscles();
}

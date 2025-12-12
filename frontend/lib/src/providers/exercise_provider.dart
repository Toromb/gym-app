import 'package:flutter/material.dart';
import '../models/plan_model.dart';
import '../services/exercise_service.dart';

class ExerciseProvider with ChangeNotifier {
  final ExerciseService _exerciseService = ExerciseService();
  List<Exercise> _exercises = [];
  bool _isLoading = false;

  List<Exercise> get exercises => _exercises;
  bool get isLoading => _isLoading;

  Future<void> fetchExercises() async {
    _isLoading = true;
    notifyListeners();
    try {
      _exercises = await _exerciseService.getExercises();
    } catch (e) {
      print('Error fetching exercises: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

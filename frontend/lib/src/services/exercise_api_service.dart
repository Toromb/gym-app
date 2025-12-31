
import '../models/plan_model.dart';
import 'api_client.dart';

class ExerciseService {
  final ApiClient _api = ApiClient();

  // Helper to safely parse lists
  List<T> _parseList<T>(dynamic response, T Function(Map<String, dynamic>) fromJson) {
      if (response is List) {
          return response.map((json) => fromJson(json)).toList();
      }
      return [];
  }

  Future<List<Exercise>> getExercises({String? muscleId, List<String>? equipmentIds}) async {
    final uri = Uri(path: '/exercises', queryParameters: {
      if (muscleId != null) 'muscleId': muscleId,
      if (equipmentIds != null && equipmentIds.isNotEmpty) 'equipmentIds': equipmentIds,
    });

    final response = await _api.get(uri.toString());
    return _parseList(response, (json) => Exercise.fromJson(json));
  }

  Future<void> createExercise(Map<String, dynamic> exerciseData) async {
    await _api.post('/exercises', exerciseData);
  }

  Future<void> updateExercise(String id, Map<String, dynamic> exerciseData) async {
    await _api.patch('/exercises/$id', exerciseData);
  }

  Future<void> deleteExercise(String id) async {
    await _api.delete('/exercises/$id');
  }

  Future<List<Muscle>> getMuscles() async {
    final response = await _api.get('/exercises/muscles');
    return _parseList(response, (json) => Muscle.fromJson(json));
  }

  Future<List<Equipment>> getEquipments() async {
    final response = await _api.get('/exercises/equipments');
    return _parseList(response, (json) => Equipment.fromJson(json));
  }
}

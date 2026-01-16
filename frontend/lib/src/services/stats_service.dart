import '../models/stats_model.dart';
import 'api_client.dart';

class StatsService {
  final ApiClient _api = ApiClient();

  List<T> _parseList<T>(dynamic response, T Function(Map<String, dynamic>) fromJson) {
      if (response is List) {
          return response.map((json) => fromJson(json)).toList();
      }
      return [];
  }

  Future<List<MuscleLoad>> getMyMuscleLoads() async {
    final response = await _api.get('/students/me/muscle-loads');
    return _parseList(response, (json) => MuscleLoad.fromJson(json));
  }

  Future<List<MuscleLoad>> getStudentMuscleLoads(String studentId) async {
    final response = await _api.get('/students/$studentId/muscle-loads');
    return _parseList(response, (json) => MuscleLoad.fromJson(json));
  }
  
  Future<UserProgress> getProgress() async {
    final response = await _api.get('/stats/progress');
    print('DEBUG: getProgress response: $response'); // Use print for now to ensure visibility in standard output
    return UserProgress.fromJson(response ?? {});
  }

  Future<UserProgress> getStudentProgress(String userId) async {
    final response = await _api.get('/stats/progress/$userId');
    print('DEBUG: getStudentProgress response: $response');
    return UserProgress.fromJson(response ?? {});
  }
}

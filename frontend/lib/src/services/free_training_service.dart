import 'dart:convert';
import '../models/free_training_model.dart';
import 'api_client.dart';

class FreeTrainingService {
  final ApiClient _api = ApiClient();

  Future<List<FreeTraining>> getFreeTrainings({
    String? type,
    String? level,
    String? sector,
    String? cardioLevel,
  }) async {
    final queryParams = <String, String>{};
    if (type != null) queryParams['type'] = type;
    if (level != null) queryParams['level'] = level;
    if (sector != null) queryParams['sector'] = sector;
    if (cardioLevel != null) queryParams['cardioLevel'] = cardioLevel;

    final queryString = Uri(queryParameters: queryParams).query;
    final url = '/free-trainings${queryString.isNotEmpty ? '?$queryString' : ''}';

    final response = await _api.get(url);

    if (response is List) {
      return response.map((e) => FreeTraining.fromJson(e)).toList();
    } else {
       // If ApiClient returns bare response (dynamic), we assume it's List for this endpoint
       // But ApiClient.get usually returns dynamic decoded JSON.
       throw Exception('Failed to load free trainings');
    }
  }

  Future<FreeTraining> getFreeTraining(String id) async {
    final response = await _api.get('/free-trainings/$id');
    return FreeTraining.fromJson(response);
  }
  Future<void> deleteFreeTraining(String id) async {
    await _api.delete('/free-trainings/$id');
  }

  Future<void> createFreeTraining(Map<String, dynamic> data) async {
      await _api.post('/free-trainings', data);
  }

  Future<void> updateFreeTraining(String id, Map<String, dynamic> data) async {
      await _api.patch('/free-trainings/$id', data);
  }
}

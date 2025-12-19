import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plan_model.dart'; // Using Exercise from plan_model for now
import '../utils/constants.dart';

class ExerciseService {
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('jwt');
    }
    return await _storage.read(key: 'jwt');
  }

  Future<List<Exercise>> getExercises() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/exercises'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Exercise.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load exercises');
    }
  }
  Future<void> createExercise(Map<String, dynamic> exerciseData) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/exercises'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(exerciseData),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create exercise: ${response.body}');
    }
  }

  Future<void> updateExercise(String id, Map<String, dynamic> exerciseData) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/exercises/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(exerciseData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update exercise: ${response.body}');
    }
  }

  Future<void> deleteExercise(String id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/exercises/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete exercise: ${response.body}');
    }
  }
}

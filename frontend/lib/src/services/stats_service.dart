import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/stats_model.dart';
import '../utils/constants.dart';

class StatsService {
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('jwt');
    }
    return await _storage.read(key: 'jwt');
  }

  Future<List<MuscleLoad>> getMyMuscleLoads() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/students/me/muscle-loads'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => MuscleLoad.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load muscle loads');
    }
  }

  Future<List<MuscleLoad>> getStudentMuscleLoads(String studentId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/students/$studentId/muscle-loads'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => MuscleLoad.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load student muscle loads');
    }
  }
}

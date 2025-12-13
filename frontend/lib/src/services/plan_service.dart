import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/plan_model.dart';
import '../models/student_assignment_model.dart';

class PlanService {
  final _storage = const FlutterSecureStorage();

  String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt');
  }

  Future<List<Plan>> getPlans() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/plans'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      // Backend returns plans directly
      return data.map((json) => Plan.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load plans');
    }
  }

  Future<Plan?> createPlan(Plan plan) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/plans'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(plan.toJson()),
    );

    if (response.statusCode == 201) {
      return Plan.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<bool> updatePlan(String id, Plan plan) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/plans/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(plan.toJson()),
    );

    return response.statusCode == 200;
  }
  
  // Method to get student's plan (active only - simplified)
  Future<Plan?> getMyPlan() async {
     // Legacy call or for specific usage
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/plans/student/my-plan'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return Plan.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  // Method to get student's plan history - RETURNS StudentAssignment objects (with progress)
  Future<List<StudentAssignment>> getMyHistory() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/plans/student/history'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => StudentAssignment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load plan history');
    }
  }

  Future<bool> updateProgress(String studentPlanId, String type, String id, bool completed, {String? date}) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/plans/student/progress'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'studentPlanId': studentPlanId,
        'type': type,
        'id': id,
        'completed': completed,
        'date': date,
      }),
    );

    return response.statusCode == 200;
  }

  Future<bool> assignPlan(String planId, String studentId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/plans/assign'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'studentId': studentId,
        'planId': planId,
      }),
    );

    return response.statusCode == 201;
  }

  Future<List<dynamic>> getStudentAssignments(String studentId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/plans/assignments/student/$studentId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); 
    } else {
      throw Exception('Failed to load assignments');
    }
  }

  Future<bool> deleteAssignment(String assignmentId) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/plans/assignments/$assignmentId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200;
  }

  Future<bool> deletePlan(String id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/plans/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200;
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/plan_model.dart';
import '../models/student_assignment_model.dart';
import '../models/execution_model.dart';

class PlanService {
  final _storage = const FlutterSecureStorage();

  String get baseUrl {
    if (kIsWeb) {
      if (kReleaseMode) return '/api';
      return 'http://localhost:3000';
    }
    // Mobile/Simulator
    return 'http://10.0.2.2:3000';
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

  Future<Plan?> getPlan(String id) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/plans/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return Plan.fromJson(jsonDecode(response.body));
    }
    return null;
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

  Future<bool> restartPlan(String assignmentId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/plans/student/restart/$assignmentId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 201 || response.statusCode == 200;
  }

  // --- EXECUTION ENGINE API ---

  Future<PlanExecution?> startExecution(String planId, int weekNumber, int dayOrder, {String? date}) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/executions/start'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'planId': planId,
        'weekNumber': weekNumber,
        'dayOrder': dayOrder,
        'date': date,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return PlanExecution.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<bool> updateExerciseExecution(String exerciseExecId, Map<String, dynamic> updates) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/executions/exercises/$exerciseExecId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(updates),
    );

    return response.statusCode == 200;
  }

  Future<void> completeExecution(String executionId, String date) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/executions/$executionId/complete'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'date': date,
      }),
    );

    if (response.statusCode == 409) {
      throw Exception('Conflict: Workout already exists on this date');
    }
    
    if (response.statusCode != 200) {
      throw Exception('Failed to complete execution');
    }
  }

  Future<List<PlanExecution>> getCalendarHistory(String from, String to) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/executions/calendar?from=$from&to=$to'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body); // Restored
      return data.map((json) => PlanExecution.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load calendar');
    }
  }

  Future<PlanExecution?> getStudentExecution({
    required String studentId,
    required String planId,
    required int week,
    required int day,
    String? startDate,
  }) async {
    final token = await _getToken();
    String url = '$baseUrl/executions/history/structure?studentId=$studentId&planId=$planId&week=$week&day=$day';
    if (startDate != null) {
      url += '&startDate=$startDate';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 && response.body.isNotEmpty) {
      return PlanExecution.fromJson(jsonDecode(response.body));
    }
    return null;
  }
}

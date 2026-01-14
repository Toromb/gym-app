
import '../models/plan_model.dart';
import '../models/student_assignment_model.dart';
import '../models/execution_model.dart';
import 'api_client.dart';
import 'api_exceptions.dart';

class PlanService {
  final ApiClient _api = ApiClient();

  List<T> _parseList<T>(dynamic response, T Function(Map<String, dynamic>) fromJson) {
      if (response is List) {
          return response.map((json) => fromJson(json)).toList();
      }
      return [];
  }

  Future<List<Plan>> getPlans() async {
    final response = await _api.get('/plans');
    return _parseList(response, (json) => Plan.fromJson(json));
  }

  Future<Plan?> getPlan(String id) async {
    try {
      final response = await _api.get('/plans/$id');
      return Plan.fromJson(response);
    } catch (_) { // 404 handled by ApiClient? ApiClient throws NotFoundException.
      return null;
    }
  }

  Future<Plan?> createPlan(Plan plan) async {
    final response = await _api.post('/plans', plan.toJson());
    return Plan.fromJson(response);
  }

  Future<bool> updatePlan(String id, Plan plan) async {
    await _api.patch('/plans/$id', plan.toJson());
    return true; 
  }
  
  Future<Plan?> getMyPlan() async {
    final response = await _api.get('/plans/student/my-plan');
    return Plan.fromJson(response);
  }

  Future<List<StudentAssignment>> getMyHistory() async {
    final response = await _api.get('/plans/student/history');
    return _parseList(response, (json) => StudentAssignment.fromJson(json));
  }

  Future<bool> updateProgress(String studentPlanId, String type, String id, bool completed, {String? date}) async {
    await _api.patch('/plans/student/progress', {
        'studentPlanId': studentPlanId,
        'type': type,
        'id': id,
        'completed': completed,
        'date': date,
    });
    return true;
  }

  Future<String?> assignPlan(String planId, String studentId) async {
    try {
        await _api.post('/plans/assign', {
            'studentId': studentId,
            'planId': planId,
        });
        return null;
    } on ApiException catch (e) {
        if (e.statusCode == 409) {
             // In ApiClient, response body IS included in message?
             // Not currently. ApiClient logic: throw ApiException('Unknown Error', code).
             // I should IMPROVE ApiClient to include body in ApiException.
             return 'Conflicto en la asignación.';
        }
        return 'Error al asignar el plan.';
    } catch (e) {
        return 'Error al asignar el plan.';
    }
  }

  Future<List<dynamic>> getStudentAssignments(String studentId) async {
    final response = await _api.get('/plans/assignments/student/$studentId');
    return response as List<dynamic>;
  }

  Future<bool> deleteAssignment(String assignmentId) async {
    await _api.delete('/plans/assignments/$assignmentId');
    return true;
  }

  Future<String?> deletePlan(String id) async {
    try {
        await _api.delete('/plans/$id');
        return null; 
    } on ApiException catch (e) {
        if (e.statusCode == 409) {
            return 'El plan está en uso y no puede eliminarse.';
        }
        return 'Error al eliminar el plan.';
    } catch (e) {
        return 'Error al eliminar el plan.';
    }
  }

  Future<bool> restartPlan(String assignmentId) async {
    await _api.post('/plans/student/restart/$assignmentId', {});
    return true;
  }

  // --- EXECUTION ENGINE API ---

  Future<TrainingSession?> startSession(String? planId, int? weekNumber, int? dayOrder, {String? date, String? freeTrainingId}) async {
     final response = await _api.post('/executions/start', {
        'planId': planId,
        'weekNumber': weekNumber,
        'dayOrder': dayOrder,
        'date': date,
        'freeTrainingId': freeTrainingId,
     });
     return TrainingSession.fromJson(response);
  }

  Future<SessionExercise?> addSessionExercise(String sessionId, String exerciseId) async {
    final response = await _api.post('/executions/$sessionId/exercises', {
        'exerciseId': exerciseId,
    });
    return SessionExercise.fromJson(response);
  }

  Future<bool> updateSessionExercise(String sessionExerciseId, Map<String, dynamic> updates) async {
    await _api.patch('/executions/exercises/$sessionExerciseId', updates);
    return true;
  }

  Future<bool> completeSession(String sessionId, String date) async {
    await _api.patch('/executions/$sessionId/complete', {'date': date});
    return true;
  }

  Future<List<TrainingSession>> getCalendarHistory(String from, String to) async {
    final uri = Uri(path: '/executions/calendar', queryParameters: {'from': from, 'to': to});
    final response = await _api.get(uri.toString());
    return _parseList(response, (json) => TrainingSession.fromJson(json));
  }

  Future<TrainingSession?> getStudentSession({
    required String studentId,
    required String planId,
    required int week,
    required int day,
    String? startDate,
  }) async {
     final params = {
        'studentId': studentId,
        'planId': planId,
        'week': week.toString(),
        'day': day.toString(),
        if (startDate != null) 'startDate': startDate,
     };
     final uri = Uri(path: '/executions/history/structure', queryParameters: params);
     
     final response = await _api.get(uri.toString());
     if (response == null) return null;
     return TrainingSession.fromJson(response);
  }
}

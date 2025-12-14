import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/plan_model.dart';
import '../models/student_assignment_model.dart';
import '../services/plan_service.dart';

class PlanProvider with ChangeNotifier {
  final PlanService _planService = PlanService();
  List<Plan> _plans = [];
  Plan? _myPlan;
  bool _isLoading = false;

  List<Plan> get plans => _plans;
  Plan? get myPlan => _myPlan;
  bool get isLoading => _isLoading;

  Future<void> fetchPlans() async {
    _isLoading = true;
    notifyListeners();
    try {
      _plans = await _planService.getPlans();
    } catch (e) {
    debugPrint('Error fetching plans: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPlan(Plan plan) async {
    _isLoading = true;
    notifyListeners();
    try {
      final newPlan = await _planService.createPlan(plan);
      if (newPlan != null) {
        _plans.add(newPlan);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
    debugPrint('Error creating plan: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePlan(String id, Plan plan) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _planService.updatePlan(id, plan);
      if (success) {
        await fetchPlans(); // Or manually update the item in list
        return true;
      }
      return false;
    } catch (e) {
    debugPrint('Error updating plan: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyPlan() async {
    _isLoading = true;
    notifyListeners();
    try {
      _myPlan = await _planService.getMyPlan();
    } catch (e) {
    debugPrint('Error fetching my plan: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Changed to return typed list
  Future<List<StudentAssignment>> fetchMyHistory() async {
    try {
      return await _planService.getMyHistory();
    } catch (e) {
    debugPrint('Error fetching my history: $e');
      return [];
    }
  }

  Future<bool> updateProgress(String studentPlanId, String type, String id, bool completed, {String? date}) async {
    try {
        return await _planService.updateProgress(studentPlanId, type, id, completed, date: date);
    } catch (e) {
        debugPrint('Error updating progress: $e');
        return false;
    }
  }

  Future<bool> assignPlan(String planId, String studentId) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await _planService.assignPlan(planId, studentId);
    } catch (e) {
    debugPrint('Error assigning plan: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<dynamic>> fetchStudentAssignments(String studentId) async {
    try {
      return await _planService.getStudentAssignments(studentId);
    } catch (e) {
    debugPrint('Error fetching assignments: $e');
      return [];
    }
  }

  Future<bool> deleteAssignment(String assignmentId) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await _planService.deleteAssignment(assignmentId);
    } catch (e) {
    debugPrint('Error deleting assignment: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deletePlan(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _planService.deletePlan(id);
      if (success) {
        await fetchPlans();
        return true;
      }
      return false;
    } catch (e) {
    debugPrint('Error deleting plan: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

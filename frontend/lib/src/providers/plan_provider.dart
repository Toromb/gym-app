import 'package:flutter/material.dart';
import '../models/plan_model.dart';
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
      print('Error fetching plans: $e');
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
      print('Error creating plan: $e');
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
        // Refresh plans
        await fetchPlans(); // Or manually update the item in list
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating plan: $e');
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
      print('Error fetching my plan: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<dynamic>> fetchMyHistory() async {
    try {
      return await _planService.getMyHistory();
    } catch (e) {
      print('Error fetching my history: $e');
      return [];
    }
  }

  Future<bool> assignPlan(String planId, String studentId) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await _planService.assignPlan(planId, studentId);
    } catch (e) {
      print('Error assigning plan: $e');
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
      print('Error fetching assignments: $e');
      return [];
    }
  }

  Future<bool> deleteAssignment(String assignmentId) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await _planService.deleteAssignment(assignmentId);
    } catch (e) {
      print('Error deleting assignment: $e');
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
      print('Error deleting plan: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

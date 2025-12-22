import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/plan_model.dart';
import '../models/student_assignment_model.dart';
import '../models/execution_model.dart';
import '../services/plan_service.dart';

class PlanProvider with ChangeNotifier {
  final PlanService _planService = PlanService();
  List<Plan> _plans = [];
  Plan? _myPlan;
  bool _isLoading = false;

  List<Plan> get plans => _plans;
  Plan? get myPlan => _myPlan;
  List<StudentAssignment> get assignments => _assignments;
  bool get isLoading => _isLoading;

  int _weeklyWorkoutCount = 0;
  int get weeklyWorkoutCount => _weeklyWorkoutCount;

  List<StudentAssignment> _assignments = [];
  
  StudentAssignment? _activeAssignment;
  StudentAssignment? get activeAssignment => _activeAssignment;
  
  void _calculateActiveAssignment() {
    if (_assignments.isEmpty) {
        _activeAssignment = null;
        return;
    }
    
    // Logic:
    // 1. Filter assignments with isActive = true
    final active = _assignments.where((a) => a.isActive).toList();
    if (active.isEmpty) {
        _activeAssignment = null;
        return;
    }
    
    // 2. If only one, return it
    if (active.length == 1) {
        _activeAssignment = active.first;
        return;
    }
    
    // 3. If multiple, check if any has progress
    final withProgress = active.where((a) => a.progress['days'] != null && (a.progress['days'] as Map).isNotEmpty).toList();
    
    if (withProgress.length == 1) {
        _activeAssignment = withProgress.first;
        return;
    }
    
    // 4. Fallback:
    // If multiple active plans and none have progress, ask user to choose (return null).
    if (active.length > 1 && withProgress.isEmpty) {
       _activeAssignment = null;
       return;
    }
    
    // If multiple have progress (rare), or just one active total, return default (latest).
    _activeAssignment = active.first;
  }

  // Returns { week: PlanWeek, day: PlanDay } or null if finished/none
  Map<String, dynamic>? get nextWorkout {
    final assignment = activeAssignment;
    if (assignment == null) return null;

    final plan = assignment.plan;
    if (plan.weeks.isEmpty) return null;

    // Traverse to find first non-completed day
    for (var week in plan.weeks) {
      for (var day in week.days) {
        if (day.id != null && !assignment.isDayCompleted(day.id!)) {
           return {'week': week, 'day': day, 'assignment': assignment};
        }
      }
    }
    
    // All completed
    return {'finished': true, 'assignment': assignment};
  }

  bool _isPlansLoaded = false;
  bool _isMyPlanLoaded = false;

  Future<void> fetchPlans({bool forceRefresh = false}) async {
    if (_isPlansLoaded && !forceRefresh) return;
    
    _isLoading = true;
    notifyListeners();
    try {
      _plans = await _planService.getPlans();
      _isPlansLoaded = true;
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
        // We could manually update the list item here to avoid full refetch
        // But for safety/completeness we can force refresh specific item or just invalidate
        _isPlansLoaded = false; // Invalidate cache to force refresh on next visit if needed, or:
        await fetchPlans(forceRefresh: true); 
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

  Future<void> fetchMyPlan({bool forceRefresh = false}) async {
    if (_isMyPlanLoaded && !forceRefresh) return;

    _isLoading = true;
    notifyListeners();
    try {
      _myPlan = await _planService.getMyPlan();
      _isMyPlanLoaded = true;
    } catch (e) {
      debugPrint('Error fetching my plan: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Changed to return typed list
  Future<List<StudentAssignment>> fetchMyHistory() async {
    _isLoading = true;
    notifyListeners();
    try {
      _assignments = await _planService.getMyHistory();
      return _assignments;
    } catch (e) {
      debugPrint('Error fetching my history: $e');
      return [];
    } finally {
      _calculateActiveAssignment(); // Recalculate only when list changes
      _isLoading = false;
      notifyListeners();
    }
  }

  PlanExecution? _currentExecution;
  PlanExecution? get currentExecution => _currentExecution;

  // --- EXECUTION ENGINE START ---

  Future<void> startExecution(String planId, int weekNumber, int dayOrder) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Pass today's date automatically or let backend handle? 
      // Requirement: Start finds or creates. Date is needed. 
      // We'll use local time YYYY-MM-DD.
      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      
      _currentExecution = await _planService.startExecution(planId, weekNumber, dayOrder, date: dateStr);
    } catch (e) {
      debugPrint('Error starting execution: $e');
      _currentExecution = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateExerciseExecution(String exerciseExecId, Map<String, dynamic> updates) async {
    try {
      final success = await _planService.updateExerciseExecution(exerciseExecId, updates);
      if (success && _currentExecution != null) {
        
        final updatedExercises = _currentExecution!.exercises.map((e) {
            if (e.id == exerciseExecId) {
                // Apply updates locally
                return e.copyWith(
                    isCompleted: updates['isCompleted'],
                    setsDone: updates['setsDone'], 
                    repsDone: updates['repsDone'],
                    weightUsed: updates['weightUsed'],
                    notes: updates['notes'] // etc
                );
            }
            return e;
        }).toList();

        _currentExecution = _currentExecution!.copyWith(exercises: updatedExercises);
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error updating exercise execution: $e');
      return false;
    }
  }

  Future<void> completeExecution(String date) async {
    if (_currentExecution == null) return;
    try {
      await _planService.completeExecution(_currentExecution!.id, date);
      // Update local state to COMPLETED
      // Or just clear it? User might want to see summary.
      // _currentExecution = ... (update status)
    } catch (e) {
      rethrow; // Pass error to UI for snackbar (Conflict 409)
    }
  }

  Future<List<PlanExecution>> fetchCalendar(DateTime from, DateTime to) async {
    try {
      final fromStr = "${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}";
      final toStr = "${to.year}-${to.month.toString().padLeft(2, '0')}-${to.day.toString().padLeft(2, '0')}";
      return await _planService.getCalendarHistory(fromStr, toStr);
    } catch (e) {
      debugPrint('Error fetching calendar: $e');
      return [];
    }
  }

  Future<void> computeWeeklyStats() async {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      try {
          final executions = await fetchCalendar(startOfWeek, endOfWeek);
          _weeklyWorkoutCount = executions.where((e) => e.status == 'COMPLETED').length;
          notifyListeners();
      } catch (e) {
          debugPrint('Error computing stats: $e');
      }
  }

  // --- EXECUTION ENGINE END ---

  Future<bool> updateProgress(String studentPlanId, String type, String id, bool completed, {String? date}) async {
    try {
        return await _planService.updateProgress(studentPlanId, type, id, completed, date: date);
    } catch (e) {
        debugPrint('Error updating progress: $e');
        return false;
    }
  }

  Future<String?> assignPlan(String planId, String studentId) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await _planService.assignPlan(planId, studentId);
    } catch (e) {
      debugPrint('Error assigning plan: $e');
      return 'Error de conexión';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> restartPlan(String assignmentId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _planService.restartPlan(assignmentId);
      if (success) {
        await fetchMyHistory(); // Refresh assignments list
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error restarting plan: $e');
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

  Future<String?> deletePlan(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      final error = await _planService.deletePlan(id);
      if (error == null) {
        await fetchPlans(); // Refresh list on success
        return null;
      }
      return error;
    } catch (e) {
      debugPrint('Error deleting plan: $e');
      return 'Error de conexión';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Plan?> getPlanById(String id) async {
    try {
      return await _planService.getPlan(id);
    } catch (e) {
      debugPrint('Error fetching plan details: $e');
      return null;
    }
  }
  Future<PlanExecution?> fetchStudentExecution({
    required String studentId,
    required String planId,
    required int week,
    required int day,
    String? startDate,
  }) async {
    try {
      return await _planService.getStudentExecution(
        studentId: studentId,
        planId: planId,
        week: week,
        day: day,
        startDate: startDate,
      );
    } catch (e) {
      debugPrint('Error fetching student execution: $e');
      return null;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/plan_model.dart';
import '../models/student_assignment_model.dart';
import '../models/execution_model.dart';

import '../models/logic/student_assignment_logic.dart';
import '../models/logic/plan_traversal_logic.dart';
import '../services/plan_service.dart';
import '../services/exercise_api_service.dart';

class PlanProvider with ChangeNotifier {
  final PlanService _planService = PlanService();
  List<Plan> _plans = [];
  Plan? _myPlan;
  bool _isLoading = false;

  List<Plan> get plans => _plans;
  Plan? get myPlan => _myPlan;
  List<StudentAssignment> get assignments => _assignments;
  bool get isLoading => _isLoading;

  // Exercise Service
  final ExerciseService _exerciseService = ExerciseService();
  Future<List<Exercise>> fetchExercises({String? muscleId, List<String>? equipmentIds}) async {
    try {
      return await _exerciseService.getExercises(muscleId: muscleId, equipmentIds: equipmentIds);
    } catch (e) {
      debugPrint('Error fetching exercises: $e');
      return [];
    }
  }

  // Legacy/Convenience wrapper
  Future<List<Exercise>> fetchExercisesByMuscle(String muscleId) => fetchExercises(muscleId: muscleId);

  int _weeklyWorkoutCount = 0;
  int get weeklyWorkoutCount => _weeklyWorkoutCount;

  int _monthlyWorkoutCount = 0;
  int get monthlyWorkoutCount => _monthlyWorkoutCount;

  List<StudentAssignment> _assignments = [];
  
  // Computed property via Extension
  StudentAssignment? get activeAssignment => _assignments.activeAssignment;

  // Returns { week: PlanWeek, day: PlanDay, assignment: StudentAssignment } or finished map
  Map<String, dynamic>? get nextWorkout {
    final assignment = activeAssignment;
    if (assignment == null) return null;
    if (assignment.plan.weeks.isEmpty) return null;

    // Use Extension Logic
    final next = assignment.nextWorkout;
    
    if (next != null) {
        // Inject assignment for UI usage (StudentHomeScreen)
        return {
           ...next,
           'assignment': assignment 
        };
    }
    
    // If extension returns null but we have a plan, it means Finished
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
      _isLoading = false;
      notifyListeners();
    }
  }

  TrainingSession? _currentSession;
  TrainingSession? get currentSession => _currentSession;

  // --- EXECUTION ENGINE START ---

  Future<void> startSession(String? planId, int? weekNumber, int? dayOrder) async {
    _currentSession = null; // Clear previous session to avoid "flash" of old data
    _isLoading = true;
    notifyListeners();
    try {
      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      
      // Handle Free Session Logic
      final String? effectivePlanId = (planId == 'FREE_SESSION') ? null : planId;

      _currentSession = await _planService.startSession(effectivePlanId, weekNumber, dayOrder, date: dateStr);
    } catch (e) {
      debugPrint('Error starting session: $e');
      _currentSession = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateSessionExercise(String sessionExerciseId, Map<String, dynamic> updates) async {
    try {
      // Prepare API payload (backend likely only needs ID for exercise)
      final apiUpdates = Map<String, dynamic>.from(updates);
      if (apiUpdates['exercise'] != null && apiUpdates['exercise'] is Map) {
          apiUpdates['exercise'] = {'id': apiUpdates['exercise']['id']}; 
      }

      final success = await _planService.updateSessionExercise(sessionExerciseId, apiUpdates);
      if (success && _currentSession != null) {
        
        final updatedExercises = _currentSession!.exercises.map((e) {
            if (e.id == sessionExerciseId) {
                // Apply updates locally
                return e.copyWith(
                    isCompleted: updates['isCompleted'],
                    setsDone: updates['setsDone'], 
                    repsDone: updates['repsDone'],
                    weightUsed: updates['weightUsed'],
                    notes: updates['notes'],
                    // Handle Swap Exercise updates - Preserve Muscles & Equipments
                    exercise: updates['exercise'] != null ? Exercise(
                        id: updates['exercise']['id'], 
                        name: updates['exerciseNameSnapshot'] ?? '', 
                        description: '', 
                        muscleGroup: '', 
                        muscles: updates['exercise']['muscles'] ?? [], // Use muscles passed from UI
                        equipments: updates['exercise']['equipments'] ?? [] // Use equipments passed from UI
                    ) : e.exercise,
                    exerciseNameSnapshot: updates['exerciseNameSnapshot'],
                    videoUrl: updates['videoUrl'],
                    equipmentsSnapshot: updates['exercise'] != null ? updates['exercise']['equipments'] : e.equipmentsSnapshot, // Update snapshot
                );
            }
            return e;
        }).toList();

        _currentSession = _currentSession!.copyWith(exercises: updatedExercises);
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error updating session exercise: $e');
      return false;
    }
  }

  Future<void> addSessionExercise(String exerciseId) async {
    if (_currentSession == null) return;
    try {
      final newExercise = await _planService.addSessionExercise(_currentSession!.id, exerciseId);
      if (newExercise != null) {
        // Add to local list
        final updatedList = List<SessionExercise>.from(_currentSession!.exercises)..add(newExercise);
        _currentSession = _currentSession!.copyWith(exercises: updatedList);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error adding exercise: $e');
    }
  }

  Future<void> completeSession(String date) async {
    if (_currentSession == null) return;
    try {
      await _planService.completeSession(_currentSession!.id, date);
      // Update local state to COMPLETED
      _currentSession = _currentSession!.copyWith(status: 'COMPLETED');
      notifyListeners();
    } catch (e) {
      rethrow; 
    }
  }

  Future<List<TrainingSession>> fetchCalendar(DateTime from, DateTime to) async {
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
          // Count unique days by date string
          final uniqueDays = executions
              .where((e) => e.status == 'COMPLETED')
              .map((e) => e.date) // e.date is YYYY-MM-DD
              .toSet();
          
          _weeklyWorkoutCount = uniqueDays.length;
          debugPrint('Weekly Stats: ${executions.length} executions -> $_weeklyWorkoutCount unique days');
          notifyListeners();
      } catch (e) {
          debugPrint('Error computing stats: $e');
      }
  }

  Future<void> computeMonthlyStats() async {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      try {
          final executions = await fetchCalendar(startOfMonth, endOfMonth);
          _monthlyWorkoutCount = executions.where((e) => e.status == 'COMPLETED').length;
          notifyListeners();
      } catch (e) {
          debugPrint('Error computing monthly stats: $e');
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

  Future<TrainingSession?> fetchStudentSession({
    required String studentId,
    required String planId,
    required int week,
    required int day,
    String? startDate,
  }) async {
    try {
      return await _planService.getStudentSession(
        studentId: studentId,
        planId: planId,
        week: week,
        day: day,
        startDate: startDate,
      );
    } catch (e) {
      debugPrint('Error fetching student session: $e');
      return null;
    }
  }

  void clear() {
    _plans = [];
    _myPlan = null;
    _assignments = [];

    _currentSession = null;
    _isPlansLoaded = false;
    _isMyPlanLoaded = false;
    notifyListeners();
  }
}

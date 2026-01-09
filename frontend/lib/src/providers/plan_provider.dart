import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/plan_model.dart';
import '../models/student_assignment_model.dart';
import '../models/execution_model.dart';

import '../models/logic/student_assignment_logic.dart';
import '../models/logic/plan_traversal_logic.dart';
import '../services/plan_service.dart';
import '../services/exercise_api_service.dart';
import '../services/local_storage_service.dart';
import '../services/sync_service.dart';

class PlanProvider with ChangeNotifier {
  final PlanService _planService = PlanService();
  final LocalStorageService _localStorage = LocalStorageService();
  final SyncService _syncService = SyncService();
  
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

  // --- EXECUTION ENGINE START (OFFLINE-AWARE) ---

  Future<void> startSession(String? planId, int? weekNumber, int? dayOrder) async {
    _currentSession = null; 
    _isLoading = true;
    notifyListeners();
    
    // 1. Try Load Cache FIRST (Always)
    TrainingSession? cachedSession;
    try {
        final json = _localStorage.getSession();
        if (json != null) {
            cachedSession = TrainingSession.fromJson(json);
        }
    } catch (e) {
        debugPrint('❌ Error parsing cache: $e');
    }

    // 2. Determine Validity of Cache
    bool useCache = false;
    
    // Check if we have pending changes in Queue
    final queue = _localStorage.getQueue();
    final hasPendingChanges = queue.isNotEmpty; 

    if (cachedSession != null && cachedSession.status == 'IN_PROGRESS') {
         // VALIDATION: Ensure cached session matches the INTENT (Plan vs Free)
         bool matchesIntent = false;
         
         if (planId == 'FREE_SESSION') {
             // Expecting a Free Session
             // cachedSession should have source='FREE' OR planId=null
             if (cachedSession.source == 'FREE' || cachedSession.planId == null) {
                 matchesIntent = true;
             }
         } else {
             // Expecting a specific Plan Session
             // cachedSession should have matching planID
             if (cachedSession.planId == planId) {
                 matchesIntent = true;
             }
         }

         if (matchesIntent) {
             _currentSession = cachedSession;
             useCache = true;
             debugPrint('✅ Loaded cached session (Initial): ${_currentSession?.id}');
         } else {
             debugPrint('⚠️ Cache Mismatch: Cached=${cachedSession.id} (Plan=${cachedSession.planId}, Src=${cachedSession.source}) vs Requested=$planId');
         }
    }

    // Check Connectivity
    final connectivity = await Connectivity().checkConnectivity();
    final bool isOffline = (connectivity.contains(ConnectivityResult.none));

    if (isOffline) {
       if (useCache) {
          _isLoading = false;
          notifyListeners();
          return;
       } else {
           // No cache, and offline -> Error or Empty
           debugPrint('📴 Offline and no cache.');
       }
    }

    // 3. Online Fetch (if needed or safe to refresh)
    try {
      if (useCache && hasPendingChanges) {
          debugPrint('⚠️ Pending offline changes detected. Skipping Server Fetch to preserve state.');
          _isLoading = false;
          notifyListeners();
          
          // Trigger sync to try flushing them
          _syncService.triggerSync();
          return;
      }

      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final String? effectivePlanId = (planId == 'FREE_SESSION') ? null : planId;

      final serverSession = await _planService.startSession(effectivePlanId, weekNumber, dayOrder, date: dateStr);
      
      if (serverSession != null) {
          // If we were using cache, only overwrite if server is "fresher" or we had no pending changes.
          // Since we checked hasPendingChanges above, we can overwrite here safely?
          // CAUTION: 'startSession' on backend might RETURN the existing session or CREATE a new one.
          // If we had a cached session ID A, and server returns ID B, we swaped sessions.
          // If server returns ID A, it's an update.
          
          _currentSession = serverSession;
          await _localStorage.saveSession(_currentSession!.toJson());
          debugPrint('☁️ Synced with Server Session: ${_currentSession?.id}');
      }
      
    } catch (e) {
      debugPrint('Error starting session (Online): $e');
      // If we failed to fetch but had cache, we stick with cache (already set).
      if (!useCache) {
          // Retry cache as last resort if not already loaded
          /* ... logic covered by initial load ... */
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateSessionExercise(String sessionExerciseId, Map<String, dynamic> updates) async {
      // 1. Optimistic Update (Local State)
      if (_currentSession != null) {
        final updatedExercises = _currentSession!.exercises.map((e) {
            if (e.id == sessionExerciseId) {
                return e.copyWith(
                    isCompleted: updates['isCompleted'],
                    setsDone: updates['setsDone'], 
                    repsDone: updates['repsDone'],
                    weightUsed: updates['weightUsed'],
                    timeSpent: updates['timeSpent'], // Added timeSpent
                    distanceCovered: updates['distanceCovered'], // Added distanceCovered
                    notes: updates['notes'],
                    // Handle Swap Exercise updates
                    exercise: updates['exercise'] != null ? Exercise(
                        id: updates['exercise']['id'], 
                        name: updates['exerciseNameSnapshot'] ?? '', 
                        description: '', 
                        muscleGroup: '', 
                        muscles: updates['exercise']['muscles'] ?? [],
                        equipments: updates['exercise']['equipments'] ?? [],
                        metricType: updates['exercise']['metricType'] ?? 'REPS'
                    ) : e.exercise,
                    exerciseNameSnapshot: updates['exerciseNameSnapshot'],
                    videoUrl: updates['videoUrl'],
                    
                    targetSetsSnapshot: updates['targetSetsSnapshot'] ?? e.targetSetsSnapshot,
                    targetRepsSnapshot: updates['targetRepsSnapshot'],
                    targetWeightSnapshot: updates['targetWeightSnapshot'],
                    targetTimeSnapshot: updates['targetTimeSnapshot'],
                    targetDistanceSnapshot: updates['targetDistanceSnapshot'],
                    
                    equipmentsSnapshot: updates['exercise'] != null ? updates['exercise']['equipments'] : e.equipmentsSnapshot, 
                );
            }
            return e;
        }).toList();

        _currentSession = _currentSession!.copyWith(exercises: updatedExercises);
        notifyListeners();
        
        // 2. Persist to Local Cache
        await _localStorage.saveSession(_currentSession!.toJson());
      }

    try {
      // 3. Prepare API Request
      final apiUpdates = Map<String, dynamic>.from(updates);
      if (apiUpdates['exercise'] != null && apiUpdates['exercise'] is Map) {
          apiUpdates['exercise'] = {'id': apiUpdates['exercise']['id']}; 
      }

      // 4. Queue Request
      // final activeUser = _myPlan?.creator ?? 'unknown'; 
      final request = {
          'id': const Uuid().v4(),
          'method': 'PATCH',
          'endpoint': '/executions/exercises/$sessionExerciseId',
          // Using ApiClient logic, we usually pass endpoint. 
          // Check PlanService: return await _api.patch('/training-sessions/exercise/$id', data);
          'body': apiUpdates,
          'timestamp': DateTime.now().toIso8601String(),
      };
      
      await _localStorage.addToQueue(request);
      
      // 5. Trigger Sync (Fire & Forget)
      _syncService.triggerSync();
      
      return true; // Always return true for Optimistic UI

    } catch (e) {
      debugPrint('Error updating session exercise logic: $e');
      return false;
    }
  }

  Future<void> addSessionExercise(String exerciseId) async {
    if (_currentSession == null) return;
    // Note: Addition is Structural change. We are treating this as "Online Only" for now based on scope?
    // Actually, user says "Excluded: Edición Estructural".
    // But if we want to allow it, we'd need to mock the adding locally.
    // For now, let's keep it simple: Try Online. If fails, error.
    
    try {
      final newExercise = await _planService.addSessionExercise(_currentSession!.id, exerciseId);
      if (newExercise != null) {
        // Add to local list
        final updatedList = List<SessionExercise>.from(_currentSession!.exercises)..add(newExercise);
        _currentSession = _currentSession!.copyWith(exercises: updatedList);
         // Update Cache
        await _localStorage.saveSession(_currentSession!.toJson());
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error adding exercise: $e');
    }
  }

  Future<void> completeSession(String date) async {
    if (_currentSession == null) return;
    
    // 1. Optimistic Local Update
    _currentSession = _currentSession!.copyWith(status: 'COMPLETED');
    notifyListeners();
    
    // 2. Persist Cache (with COMPLETED status, so if they reopen, it shows done or clears?)
    // Usually on completion we might wanna clear cache or keep it as history.
    // Let's keep it for now.
    await _localStorage.saveSession(_currentSession!.toJson());

    try {
      // 3. Queue Request
      final request = {
          'id': const Uuid().v4(),
          'method': 'PATCH', 
          'endpoint': '/executions/${_currentSession!.id}/complete',
          'body': {'date': date},
          'timestamp': DateTime.now().toIso8601String(),
      };
      
      await _localStorage.addToQueue(request);

      // 4. Trigger Sync
      _syncService.triggerSync();
      
      // 5. Clear Cache? 
      // If we clear cache now, and sync fails, effectively user can't see "Active Session" anymore.
      // Maybe we clear cache only if we move away from screen?
      // Ideally, startSession checks cache. If cache is COMPLETED, it might safely ignore it or show "Last session finished".
      
    } catch (e) {
       debugPrint('Error completing session logic: $e');
       rethrow; 
    }
  }
  
  // Clean cache manually if needed (e.g. leaving screen)
  Future<void> clearLocalSession() async {
      await _localStorage.clearSession();
      _currentSession = null;
      notifyListeners();
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

// Helper class for UI feedback (if needed, or move to utils)
class ScaffoldMessengerHelper {
    static void showOfflineSnack(String msg) {
        // Implementation depends on access to BuildContext or GlobalKey
        // For Provider, usually we return status and let UI handle showing Snackbars.
        // We ignored this for now in logic, just using debugPrint.
    }
}

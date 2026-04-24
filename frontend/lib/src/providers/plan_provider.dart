import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../models/plan_model.dart';
import '../models/student_assignment_model.dart';
import '../models/execution_model.dart';
import '../models/completed_plan_model.dart';

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
  bool _isLoading = false;

  List<Plan> get plans => _plans;
  List<StudentAssignment> get assignments => _assignments;
  bool get isLoading => _isLoading;

  // Exercise Service
  final ExerciseService _exerciseService = ExerciseService();
  Future<List<Exercise>> fetchExercises(
      {String? muscleId, String? role, List<String>? equipmentIds}) async {
    try {
      return await _exerciseService.getExercises(
          muscleId: muscleId, role: role, equipmentIds: equipmentIds);
    } catch (e) {
      debugPrint('Error fetching exercises: $e');
      return [];
    }
  }

  int _weeklyWorkoutCount = 0;
  int get weeklyWorkoutCount => _weeklyWorkoutCount;

  Future<List<Exercise>> fetchExercisesByMuscle(String muscleId) =>
      fetchExercises(muscleId: muscleId, role: 'PRIMARY');

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
      if (next['empty'] == true)
        return null; // Treat plan with 0 days as essentially empty.

      // Inject assignment for UI usage (StudentHomeScreen)
      return {...next, 'assignment': assignment};
    }

    // If extension returns null but we have a plan, it means Finished
    return {'finished': true, 'assignment': assignment};
  }

  bool _isPlansLoaded = false;

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
        _isPlansLoaded =
            false; // Invalidate cache to force refresh on next visit if needed, or:
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

  // Changed to return typed list
  Future<List<StudentAssignment>> fetchMyAssignments(
      {bool notify = true}) async {
    _isLoading = true;
    if (notify) notifyListeners();
    try {
      _assignments = await _planService.getMyAssignments();
      return _assignments;
    } catch (e) {
      debugPrint('Error fetching my assignments: $e');
      return [];
    } finally {
      _isLoading = false;
      if (notify) notifyListeners();
    }
  }

  Future<void> refreshDashboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        fetchMyAssignments(notify: false),
        computeWeeklyStats(notify: false),
      ]);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- COMPLETED PLAN HISTORY (FASE 2) --- //
  List<CompletedPlan> _completedHistory = [];
  List<CompletedPlan> get completedHistory => _completedHistory;

  Future<List<CompletedPlan>> fetchCompletedHistory() async {
    _isLoading = true;
    notifyListeners();
    try {
      _completedHistory = await _planService.getCompletedHistory();
      return _completedHistory;
    } catch (e) {
      debugPrint('Error fetching completed history: $e');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  TrainingSession? _currentSession;
  TrainingSession? get currentSession => _currentSession;

  // --- EXECUTION ENGINE START (OFFLINE-AWARE) ---

  Future<void> startSession(String? planId, int? weekNumber, int? dayOrder,
      {String? freeTrainingId}) async {
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

      if (freeTrainingId != null) {
        // Expecting specific Free Training
        // Note: If definition wasn't persisted, this might be null and cause cache miss, which is safe.
        if (cachedSession.freeTrainingDefinition?.id == freeTrainingId) {
          matchesIntent = true;
        }
      } else if (planId == 'FREE_SESSION') {
        // Expecting a GENERIC Free Session (no template)
        // cachedSession should have source='FREE' and NO definition (or ignore it?)
        // Let's match if source is FREE.
        if (cachedSession.source == 'FREE') {
          matchesIntent = true;
        }
      } else {
        // Expecting a specific Plan Session.
        // `planId` here is the *effective* plan ID from the assignment \u2014 which
        // is an AssignedPlan UUID since Phase 1 (not the master Plan UUID).
        // `cachedSession.planId` is resolved the same way in TrainingSession.fromJson,
        // so this comparison is correct for both legacy and snapshot-based sessions.
        if (cachedSession.planId == planId) {
          matchesIntent = true;
        }
      }

      if (matchesIntent) {
        _currentSession = cachedSession;
        useCache = true;
        debugPrint('✅ Loaded cached session (Initial): ${_currentSession?.id}');
      } else {
        debugPrint(
            '⚠️ Cache Mismatch: Cached=${cachedSession.id} (Plan=${cachedSession.planId}, Src=${cachedSession.source}) vs Requested=$planId / Free=$freeTrainingId');
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
        debugPrint(
            '⚠️ Pending offline changes detected. Skipping Server Fetch to preserve state.');
        _isLoading = false;
        notifyListeners();

        // Trigger sync to try flushing them
        _syncService.triggerSync();
        return;
      }

      final now = DateTime.now();
      final dateStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final String? effectivePlanId =
          (planId == 'FREE_SESSION') ? null : planId;

      final serverSession = await _planService.startSession(
          effectivePlanId, weekNumber, dayOrder,
          date: dateStr, freeTrainingId: freeTrainingId);

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

  Future<bool> updateSessionExercise(
      String sessionExerciseId, Map<String, dynamic> updates) async {
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
            distanceCovered:
                updates['distanceCovered'], // Added distanceCovered
            addedWeight: updates['addedWeight'], // Added Lastre
            notes: updates['notes'],
            // Handle Swap Exercise updates
            exercise: updates['exercise'] != null
                ? Exercise(
                    id: updates['exercise']['id'],
                    name: updates['exerciseNameSnapshot'] ?? '',
                    description: '',
                    muscleGroup: '',
                    muscles: updates['exercise']['muscles'] ?? [],
                    equipments: updates['exercise']['equipments'] ?? [],
                    metricType: updates['exercise']['metricType'] ?? 'REPS')
                : e.exercise,
            exerciseNameSnapshot: updates['exerciseNameSnapshot'],
            videoUrl: updates['videoUrl'],

            targetSetsSnapshot:
                updates['targetSetsSnapshot'] ?? e.targetSetsSnapshot,
            targetRepsSnapshot: updates['targetRepsSnapshot'],
            targetWeightSnapshot: updates['targetWeightSnapshot'],
            targetTimeSnapshot: updates['targetTimeSnapshot'],
            targetDistanceSnapshot: updates['targetDistanceSnapshot'],

            equipmentsSnapshot: updates['exercise'] != null
                ? updates['exercise']['equipments']
                : e.equipmentsSnapshot,
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
      final newExercise = await _planService.addSessionExercise(
          _currentSession!.id, exerciseId);
      if (newExercise != null) {
        // Add to local list
        final updatedList =
            List<SessionExercise>.from(_currentSession!.exercises)
              ..add(newExercise);
        _currentSession = _currentSession!.copyWith(exercises: updatedList);
        // Update Cache
        await _localStorage.saveSession(_currentSession!.toJson());

        notifyListeners();
      }
    } catch (e) {}
  }

  Future<void> deleteSessionExercise(String sessionExerciseId) async {
    if (_currentSession == null) return;

    // 1. Optimistic Update (Local State)
    final updatedList = _currentSession!.exercises
        .where((e) => e.id != sessionExerciseId)
        .toList();
    _currentSession = _currentSession!.copyWith(exercises: updatedList);
    notifyListeners();

    // 2. Persist to Local Cache
    await _localStorage.saveSession(_currentSession!.toJson());

    try {
      // 3. Queue Request
      final request = {
        'id': const Uuid().v4(),
        'method': 'DELETE',
        'endpoint': '/executions/exercises/$sessionExerciseId',
        'body': {},
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _localStorage.addToQueue(request);

      // 4. Trigger Sync
      _syncService.triggerSync();
    } catch (e) {
      debugPrint('Error deleting session exercise: $e');
    }
  }

  // Sync Future Tracker
  Future<List<Map<String, dynamic>>>? _activeSyncRequest;

  // 3. Complete Session
  Future<void> completeSession(String date, {String? dayId}) async {
    if (_currentSession == null) return;

    // On web, InternetConnectionChecker throws, so we assume online.
    bool hasInternet = true;
    if (!kIsWeb) {
      try {
        hasInternet = await InternetConnectionChecker.instance.hasConnection;
      } catch (_) {}
    }

    if (hasInternet) {
      // 1. Fire-and-forget the offline queue flush so pending exercise metrics
      //    reach the backend. We do NOT await it here — awaiting each queued
      //    PATCH one-by-one causes the noticeable freeze the user reported.
      //    The completeSession call below is independent and fast.
      unawaited(_syncService.triggerSync());

      // 2. Direct Online Call
      try {
        await _planService.completeSession(_currentSession!.id, date);
      } catch (e) {
        rethrow;
      }
    } else {
      // Offline fallback: Queue Request
      final request = {
        'id': const Uuid().v4(),
        'method': 'PATCH',
        'endpoint': '/executions/${_currentSession!.id}/complete',
        'body': {'date': date},
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _localStorage.addToQueue(request);
      _activeSyncRequest = _syncService.triggerSync();
    }

    // 2. Optimistic Local Update (Session Status)
    _currentSession = _currentSession!.copyWith(status: 'COMPLETED');
    notifyListeners();

    // 3. Optimistic Local Update (Assignment Progress)
    if (dayId != null && activeAssignment != null) {
      final index =
          _assignments.indexWhere((a) => a.id == activeAssignment!.id);
      if (index != -1) {
        final assignment = _assignments[index];
        final newProgress = Map<String, dynamic>.from(assignment.progress);

        if (newProgress['days'] == null) newProgress['days'] = {};
        final daysMap = Map<String, dynamic>.from(newProgress['days']);

        daysMap[dayId] = {'completed': true, 'date': date};
        newProgress['days'] = daysMap;

        final updatedAssignment =
            assignment.copyWithProgress(newProgress: newProgress);
        _assignments[index] = updatedAssignment;
        notifyListeners();
      }
    }

    // 4. Persist Cache
    await _localStorage.saveSession(_currentSession!.toJson());
  }

  // Clean cache manually if needed (e.g. leaving screen)
  Future<void> clearLocalSession() async {
    await _localStorage.clearSession();
    _currentSession = null;
    notifyListeners();
  }

  Future<List<TrainingSession>> fetchCalendar(
      DateTime from, DateTime to) async {
    try {
      final fromStr =
          "${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}";
      final toStr =
          "${to.year}-${to.month.toString().padLeft(2, '0')}-${to.day.toString().padLeft(2, '0')}";
      return await _planService.getCalendarHistory(fromStr, toStr);
    } catch (e) {
      debugPrint('Error fetching calendar: $e');
      return [];
    }
  }

  Future<void> computeWeeklyStats({bool notify = true}) async {
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
      if (notify) notifyListeners();
    } catch (e) {
      debugPrint('Error computing stats: $e');
    }
  }

  // --- EXECUTION ENGINE END ---

  Future<bool> updateProgress(
      String studentPlanId, String type, String id, bool completed,
      {String? date}) async {
    try {
      return await _planService
          .updateProgress(studentPlanId, type, id, completed, date: date);
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
        // CRITICAL: Refresh assignments from backend so in-memory progress
        // is replaced with the empty progress returned by restartAssignment.
        // Without this, nextWorkout() keeps reading the old completed progress.
        await fetchMyAssignments(notify: false);
      }
      return success;
    } catch (e) {
      debugPrint('Error restarting plan: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> finishAssignment(String assignmentId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _planService.finishAssignment(assignmentId);
      if (success) {
        await fetchMyAssignments(); // Refresh assignments list
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error finishing plan: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> activateAssignment(String assignmentId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _planService.activateAssignment(assignmentId);
      await fetchMyAssignments(); // Refresh assignments list and active tracker
      return true;
    } catch (e) {
      debugPrint('Error activating plan: $e');
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

  Future<List<CompletedPlan>> fetchStudentHistory(String studentId) async {
    try {
      return await _planService.getStudentHistory(studentId);
    } catch (e) {
      debugPrint('Error fetching student history: $e');
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

  Future<Map<String, dynamic>?> waitForPendingUpdates() async {
    List<Map<String, dynamic>> results;

    // If there was an active sync initiated by completeSession, wait for it.
    if (_activeSyncRequest != null) {
      results = await _activeSyncRequest!;
      _activeSyncRequest = null;

      // Race Condition Check: Did we get the completion result?
      bool found =
          results.any((r) => (r['endpoint'] as String).endsWith('/complete'));

      if (!found) {
        final queue = _localStorage.getQueue();
        if (queue.isNotEmpty) {
          // The item might have been added just as the previous sync finished.
          // Trigger a fresh sync to pick it up.
          results = await _syncService.triggerSync();
        }
      }
    } else {
      results = await _syncService.triggerSync();
    }

    // Look for completion response
    for (final result in results) {
      final endpoint = result['endpoint'] as String;
      if (endpoint.endsWith('/complete') && result['response'] != null) {
        final response = result['response'];
        if (response is Map<String, dynamic> && response.containsKey('stats')) {
          return response['stats'] as Map<String, dynamic>;
        }
      }
    }
    return null;
  }

  void clear() {
    _plans = [];
    _assignments = [];
    _currentSession = null;
    _isPlansLoaded = false;
    notifyListeners();
  }
}

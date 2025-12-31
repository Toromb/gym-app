
import '../student_assignment_model.dart';

extension StudentAssignmentLogic on List<StudentAssignment> {
  /// Determines the currently active assignment based on business rules.
  /// 
  /// Logic:
  /// 1. Filter assignments with [isActive] = true.
  /// 2. If filtering yields 0 or 1, return that result (or null).
  /// 3. If multiple active, prioritize any with progress.
  /// 4. Fallback: Return the first active one found.
  StudentAssignment? get activeAssignment {
    if (isEmpty) return null;

    final active = where((a) => a.isActive).toList();

    if (active.isEmpty) return null;
    if (active.length == 1) return active.first;

    // Disambiguation Logic: Prioritize assignment with progress
    final withProgress = active.where((a) {
        final hasDays = a.progress['days'] != null;
        if (!hasDays) return false;
        return (a.progress['days'] as Map).isNotEmpty;
    }).toList();

    if (withProgress.length == 1) return withProgress.first;
    
    // Fallback: If multiple with progress, or none with progress, 
    // we stick to the first active one (usually the latest created if sorted by backend).
    return active.first;
  }
}

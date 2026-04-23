import '../student_assignment_model.dart';
import '../../models/plan_model.dart'; // Ensure Plan models are imported

extension PlanTraversalLogic on StudentAssignment {
  /// Determines the next workout details (weekNumber, dayOrder, dayId)
  /// by traversing the plan structure and checking against progress.
  Map<String, dynamic>? get nextWorkout {
    if (plan == null) return { 'empty': true, 'error': 'Plan definition missing' };

    final weeks = plan!.weeks ?? [];
    if (weeks.isEmpty) return { 'empty': true };

    // Defend against null progress structure
    final daysProgress = (progress['days'] as Map<String, dynamic>?) ?? {};

    int totalDays = 0;

    for (var week in weeks) {
      final days = week.days ?? [];
      totalDays += days.length;
      // Ensure sorted by day order to recommend correct sequence
      days.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));

      for (var day in days) {
        final dayId = day.id;
        // Check completion
        final isCompleted = daysProgress[dayId]?['completed'] == true;

        if (!isCompleted) {
          return {
            'week': week,
            'day': day,
            'dayId': day.id,
            'title': day.title ?? 'Día ${day.dayOfWeek}',
          };
        }
      }
    }

    if (totalDays == 0) {
      // If the plan has 0 days, it is empty, NOT completed.
      return { 'empty': true }; // Use a custom tag so provider can handle it
    }

    // If all actual days were completed, return null to indicate 'Plan Completed'.
    return null;
  }
}

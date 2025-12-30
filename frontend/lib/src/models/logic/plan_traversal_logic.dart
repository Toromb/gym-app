
import '../student_assignment_model.dart';
import '../../models/plan_model.dart'; // Ensure Plan models are imported

extension PlanTraversalLogic on StudentAssignment {
  /// Determines the next workout details (weekNumber, dayOrder, dayId)
  /// by traversing the plan structure and checking against progress.
  Map<String, dynamic>? get nextWorkout {
    if (plan == null) return null;

    final weeks = plan!.weeks ?? [];
    if (weeks.isEmpty) return null;

    // Defend against null progress structure
    final daysProgress = (progress['days'] as Map<String, dynamic>?) ?? {};

    for (var week in weeks) {
        final days = week.days ?? [];
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

    // If all completed, return null or maybe the last one? 
    // Current logic usually implies "Plan Completed".
    return null;
  }
}

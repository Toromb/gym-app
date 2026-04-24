import '../student_assignment_model.dart';
// plan_model.dart types are transitively available via StudentAssignment

extension PlanTraversalLogic on StudentAssignment {
  /// Determines the next workout details (week, day, dayId, title)
  /// by traversing the plan structure and checking against progress.
  ///
  /// Returns:
  ///  - A map with 'week', 'day', 'dayId', 'title' if an incomplete day exists.
  ///  - A map with 'empty': true if the plan has no weeks/days.
  ///  - null if all days are completed (plan finished).
  Map<String, dynamic>? get nextWorkout {
    // `plan` and `plan.weeks` are both non-nullable fields (required in model).
    final weeks = plan.weeks;
    if (weeks.isEmpty) return {'empty': true};

    // Defend against null progress structure
    final daysProgress = (progress['days'] as Map<String, dynamic>?) ?? {};

    int totalDays = 0;

    for (final week in weeks) {
      // `week.days` is List<PlanDay> — non-nullable, no ?? needed
      final days = List.of(week.days); // copy to sort without mutating model
      totalDays += days.length;
      // Ensure sorted by day order to recommend correct sequence
      days.sort((a, b) => (a.order).compareTo(b.order));

      for (final day in days) {
        final dayId = day.id;
        // Check completion status from local progress map
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
      // The plan exists but has 0 days — treat as empty, not completed.
      return {'empty': true};
    }

    // All days completed → signal 'Plan Finished' to the caller.
    return null;
  }
}

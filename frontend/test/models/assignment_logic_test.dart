
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/src/models/student_assignment_model.dart';
import 'package:gym_app/src/models/plan_model.dart';
import 'package:gym_app/src/models/logic/student_assignment_logic.dart';
import 'package:gym_app/src/models/logic/plan_traversal_logic.dart';

void main() {
  group('StudentAssignmentLogic (Active Selection)', () {
    late Plan dummyPlan;
    
    setUp(() {
      dummyPlan = Plan(
        id: 'dummy', 
        name: 'Dummy', 
        weeks: <PlanWeek>[], 
        durationWeeks: 4
      );
    });

    test('returns null for empty list', () {
      List<StudentAssignment> list = [];
      expect(list.activeAssignment, isNull);
    });

    test('returns null if no assignment is active', () {
       final a1 = StudentAssignment(id: '1', isActive: false, plan: dummyPlan, progress: {});
       expect([a1].activeAssignment, isNull);
    });

    test('returns the single active assignment', () {
       final a1 = StudentAssignment(id: '1', isActive: true, plan: dummyPlan, progress: {});
       expect([a1].activeAssignment?.id, '1');
    });

    test('prioritizes assignment with progress among multiple active', () {
       final a1 = StudentAssignment(id: '1', isActive: true, plan: dummyPlan, progress: {});
       final a2 = StudentAssignment(id: '2', isActive: true, plan: dummyPlan, progress: {'days': {'d1': {'completed': true}}});
       
       // Regardless of order in list
       expect([a1, a2].activeAssignment?.id, '2');
       expect([a2, a1].activeAssignment?.id, '2');
    });

    test('falls back to first active if tie (no progress)', () {
       final a1 = StudentAssignment(id: '1', isActive: true, plan: dummyPlan, progress: {});
       final a2 = StudentAssignment(id: '2', isActive: true, plan: dummyPlan, progress: {});
       
       // Returns first found
       expect([a1, a2].activeAssignment?.id, '1');
    });
  });

  group('PlanTraversalLogic (Next Workout)', () {
      final day1 = PlanDay(id: 'd1', dayOfWeek: 1, order: 1, exercises: <PlanExercise>[]);
      final day2 = PlanDay(id: 'd2', dayOfWeek: 3, order: 2, exercises: <PlanExercise>[]);
      final week1 = PlanWeek(id: 'w1', weekNumber: 1, days: <PlanDay>[day1, day2]);
      final plan = Plan(
          id: 'p1', 
          name: 'Test Plan', 
          weeks: <PlanWeek>[week1], 
          durationWeeks: 4
      );

      test('returns first day if no progress', () {
          final assign = StudentAssignment(
              id: 'a1', isActive: true, plan: plan, progress: {}
          );
          
          final next = assign.nextWorkout;
          expect(next, isNotNull);
          expect(next?['dayId'], 'd1');
      });

      test('returns second day if first completed', () {
          final assign = StudentAssignment(
              id: 'a1', isActive: true, plan: plan, 
              progress: {'days': {'d1': {'completed': true}}}
          );
          
          final next = assign.nextWorkout;
          expect(next, isNotNull);
          expect(next?['dayId'], 'd2');
      });

      test('returns null if all completed', () {
          final assign = StudentAssignment(
              id: 'a1', isActive: true, plan: plan, 
              progress: {'days': {'d1': {'completed': true}, 'd2': {'completed': true}}}
          );
          
          final next = assign.nextWorkout;
          expect(next, isNull);
      });
  });
}

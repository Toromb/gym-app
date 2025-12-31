import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/src/utils/swap_exercise_logic.dart';
import 'package:gym_app/src/models/execution_model.dart';
import 'package:gym_app/src/models/plan_model.dart';

void main() {
  group('Swap Metric Logic', () {
    
    // Mocks
    final barbell = Equipment(id: 'eq-bar', name: 'Barbell');

    final benchPress = Exercise(
      id: 'ex-bench',
      name: 'Bench Press',
      muscleGroup: 'Chest',
      metricType: 'REPS',
      loadFactor: 1.0,
      equipments: [barbell],
    );

    final plank = Exercise(
      id: 'ex-plank',
      name: 'Plank',
      muscleGroup: 'Core',
      metricType: 'TIME',
      defaultTime: 60,
      equipments: [],
    );

    final run = Exercise(
      id: 'ex-run',
      name: 'Run',
      muscleGroup: 'Legs',
      metricType: 'DISTANCE',
      defaultDistance: 1000,
      equipments: [],
    );

    test('Swap REPS -> TIME (Incompatible)', () {
       final execution = SessionExercise(
         id: 'exec-1',
         exerciseNameSnapshot: 'Bench Press',
         equipmentsSnapshot: [barbell],
         exercise: benchPress,
         isCompleted: false,
         targetSetsSnapshot: 3,
         targetRepsSnapshot: '10',
         targetWeightSnapshot: '50',
       );

       final result = SwapExerciseLogic.calculate(
         oldExercise: benchPress,
         newExercise: plank,
         execution: execution,
       );

       expect(result.warning, isNotNull);
       expect(result.warning, contains('TIME'));
       expect(result.suggestedTime, isNull);
    });

    test('Swap TIME -> TIME (Compatible)', () {
       final execution = SessionExercise(
         id: 'exec-2',
         exerciseNameSnapshot: 'Plank',
         equipmentsSnapshot: [],
         exercise: plank,
         isCompleted: false,
         targetTimeSnapshot: 45, // Old target
         timeSpent: '50', // Actual done
       );
       
       // New Time Exercise (e.g. Side Plank)
       final sidePlank = Exercise(
          id: 'ex-side-plank',
          name: 'Side Plank',
          muscleGroup: 'Core',
          metricType: 'TIME',
          defaultTime: 30,
       );

       final result = SwapExerciseLogic.calculate(
         oldExercise: plank,
         newExercise: sidePlank,
         execution: execution,
       );

       expect(result.warning, isNull);
       // Should suggest previous performed time ('50') or target ('45') if available.
       // Logic preference: timeSpent > targetTimeSnapshot
       expect(result.suggestedTime, '50');
    });

    test('Swap DISTANCE -> DISTANCE (Compatible)', () {
       final execution = SessionExercise(
         id: 'exec-3',
         exerciseNameSnapshot: 'Run',
         equipmentsSnapshot: [],
         exercise: run,
         isCompleted: false,
         targetDistanceSnapshot: 2000,
       );
       
       // New Distance Exercise (e.g. Row)
       final rowDist = Exercise(
          id: 'ex-row-dist',
          name: 'Row',
          muscleGroup: 'Back',
          metricType: 'DISTANCE',
          defaultDistance: 500,
       );

       final result = SwapExerciseLogic.calculate(
         oldExercise: run,
         newExercise: rowDist,
         execution: execution,
       );

       expect(result.warning, isNull);
       expect(result.suggestedDistance, '2000.0');
    });

  });
}

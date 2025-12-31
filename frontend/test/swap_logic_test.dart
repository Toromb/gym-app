import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/src/utils/swap_exercise_logic.dart';
import 'package:gym_app/src/models/execution_model.dart';
import 'package:gym_app/src/models/plan_model.dart';

void main() {
  group('Smart Swap Bodyweight Logic', () {
    
    // Mocks
    final bodyweightEquipment = Equipment(id: 'eq-bw', name: 'Bodyweight');
    final barbellEquipment = Equipment(id: 'eq-bar', name: 'Barbell');

    final pullUp = Exercise(
      id: 'ex-pullup',
      name: 'Dominadas',
      muscleGroup: 'Back',
      equipments: [bodyweightEquipment],
      loadFactor: 1.0, 
    );

    final row = Exercise(
      id: 'ex-row',
      name: 'Remo',
      muscleGroup: 'Back',
      equipments: [barbellEquipment],
      loadFactor: 0.6,
    );

    test('Scenario 1: Bodyweight (User 80kg) + 0kg External -> Target (0.6)', () {
       // Execution: Pullups with 0kg added
       final execution = SessionExercise(
         id: 'exec-1',
         exerciseNameSnapshot: 'Dominadas',
         equipmentsSnapshot: [bodyweightEquipment],
         exercise: pullUp,
         isCompleted: false,
         weightUsed: '0', 
       );

       final result = SwapExerciseLogic.calculate(
         oldExercise: pullUp,
         newExercise: row,
         execution: execution,
         userBodyWeight: 80.0,
       );

       // Reference = 80 + 0 = 80
       // Target = 80 * (0.6 / 1.0) = 48.0
       // Logic converts x.0 to x
       expect(result.suggestedWeight, '48');
       expect(result.isWeightEstimated, true);
    });

    test('Scenario 2: Bodyweight (User 80kg) + 10kg External -> Target (0.6)', () {
       // Execution: Pullups with 10kg added
       final execution = SessionExercise(
         id: 'exec-2',
         exerciseNameSnapshot: 'Dominadas',
         equipmentsSnapshot: [bodyweightEquipment],
         exercise: pullUp,
         isCompleted: false,
         weightUsed: '10', 
       );

       final result = SwapExerciseLogic.calculate(
         oldExercise: pullUp,
         newExercise: row,
         execution: execution,
         userBodyWeight: 80.0,
       );

       // Reference = 80 + 10 = 90
       // Target = 90 * 0.6 = 54.0
       expect(result.suggestedWeight, '54');
    });

    test('Scenario 3: Missing User Weight -> No Suggestion', () {
       final execution = SessionExercise(
         id: 'exec-3',
         exerciseNameSnapshot: 'Dominadas',
         equipmentsSnapshot: [bodyweightEquipment],
         exercise: pullUp,
         isCompleted: false,
         weightUsed: '0', 
       );

       final result = SwapExerciseLogic.calculate(
         oldExercise: pullUp,
         newExercise: row,
         execution: execution,
         // userBodyWeight is null
       );

       // Fallback: Reference = 0 (external). 
       // If oldExternal is 0, target is 0. But practically usually we want specific handling?
       // Current logic: Ref = 0 (external) -> Target = 0 * 0.6 = 0.
       // It suggests "0" or similar if external is explicit.
       // However, isBodyweight logic: "Fallback: If no user weight... reference remains null."
       // So result.suggestedWeight should be null.
       
       expect(result.suggestedWeight, isNull);
       expect(result.isWeightEstimated, false);
    });
    
    test('Scenario 4: Non-Bodyweight Exercise -> Ignores User Weight', () {
       final benchPress = Exercise(
         id: 'ex-bench', 
         name: 'Bench', 
         muscleGroup: 'Chest',
         loadFactor: 1.0,
         equipments: [barbellEquipment]
       );
       
       final execution = SessionExercise(
         id: 'exec-4',
         exerciseNameSnapshot: 'Bench',
         equipmentsSnapshot: [barbellEquipment],
         exercise: benchPress,
         isCompleted: false,
         weightUsed: '100', 
       );

       final result = SwapExerciseLogic.calculate(
         oldExercise: benchPress,
         newExercise: row, // reuse row (0.6)
         execution: execution,
         userBodyWeight: 150.0, // Should be ignored
       );

       // Reference = 100 (external)
       // Target = 100 * 0.6 = 60
       expect(result.suggestedWeight, '60');
    });

  });
}

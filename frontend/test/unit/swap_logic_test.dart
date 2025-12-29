
import 'package:flutter_test/flutter_test.dart';
import '../../lib/src/utils/swap_exercise_logic.dart';
import '../../lib/src/models/plan_model.dart';
import '../../lib/src/models/execution_model.dart';

void main() {
  group('SwapExerciseLogic Intelligent Reps', () {
    
    // Mock Data
    final Exercise oldEx = Exercise(id: 'old', name: 'Old', muscleGroup: 'Chest');
    final SessionExercise execution = SessionExercise(
      id: 'exec1', 
      exerciseNameSnapshot: oldEx.name,
      equipmentsSnapshot: [],
      exercise: oldEx, 
      setsDone: '3', 
      repsDone: '10', 
      weightUsed: '50',
      isCompleted: false, 
    );

    test('Strength Intent (3-6) suggests low reps', () {
        final newEx = Exercise(id: 'new', name: 'New Heavy', muscleGroup: 'Chest', minReps: 1, maxReps: 15);
        
        final result = SwapExerciseLogic.calculate(
            oldExercise: oldEx, 
            newExercise: newEx, 
            execution: execution,
            intent: TrainingIntent.STRENGTH
        );
        
        // Target: 3-6. Old: 10.
        // Effective: 3-6.
        // Old (10) is outside. 
        // Suggestion: Range "3-6" or similar logic?
        // Logic says: if old (10) outside, suggest range.
        expect(result.suggestedReps, '3-6');
    });

    test('Hypertrophy Intent (8-12) keeps old reps (10) which fit', () {
        final newEx = Exercise(id: 'new', name: 'New Hyper', muscleGroup: 'Chest', minReps: 1, maxReps: 15);
        
        final result = SwapExerciseLogic.calculate(
            oldExercise: oldEx, 
            newExercise: newEx, 
            execution: execution, // repsDone: 10
            intent: TrainingIntent.HYPERTROPHY
        );
        
        // Target: 8-12. Old: 10. Fits.
        expect(result.suggestedReps, '10');
    });

    test('Endurance Intent (15-20) suggests high reps', () {
        final newEx = Exercise(id: 'new', name: 'New Endu', muscleGroup: 'Chest', minReps: 1, maxReps: 30);
        
        final result = SwapExerciseLogic.calculate(
            oldExercise: oldEx, 
            newExercise: newEx, 
            execution: execution, 
            intent: TrainingIntent.ENDURANCE
        );
        
        // Target: 15-20. Old: 10. Outside.
        expect(result.suggestedReps, '15-20');
    });

    test('General Intent keeps old reps (10) if fit', () {
        final newEx = Exercise(id: 'new', name: 'New Gen', muscleGroup: 'Chest'); // No limits
        
        final result = SwapExerciseLogic.calculate(
            oldExercise: oldEx, 
            newExercise: newEx, 
            execution: execution, 
            intent: TrainingIntent.GENERAL
        );
        
        // General logic: Keep old if fit.
        expect(result.suggestedReps, '10');
    });

    test('Strength Intent BUT Exercise Limited (Min 10) -> Respects Exercise', () {
        // e.g. Abs, can't do 3 reps
        final newEx = Exercise(id: 'new', name: 'Abs', muscleGroup: 'Abs', minReps: 10, maxReps: 20);
        
        final result = SwapExerciseLogic.calculate(
            oldExercise: oldEx, 
            newExercise: newEx, 
            execution: execution,
            intent: TrainingIntent.STRENGTH
        );
        
        // Target Strength: 3-6.
        // Exercise: 10-20.
        // Overlap: None. 
        // Logic: Clamp to Min.
        // Effective Range -> [10, 10] (clamped because exMin > targetMax)
        
        // Old reps: 10. Fits in [10, 10]? Yes.
        expect(result.suggestedReps, '10');
    });
    
    test('Fallback when no overlap and no old reps', () {
        final newEx = Exercise(id: 'new', name: 'Abs', muscleGroup: 'Abs', minReps: 12, maxReps: 20);
        final emptyExecution = SessionExercise(
             id: 'exec2', 
             exerciseNameSnapshot: oldEx.name,
             equipmentsSnapshot: [],
             exercise: oldEx, 
             setsDone: '3', 
             repsDone: null, // No old reps
             weightUsed: '50',
             isCompleted: false, 
        );

        final result = SwapExerciseLogic.calculate(
            oldExercise: oldEx, 
            newExercise: newEx, 
            execution: emptyExecution,
            intent: TrainingIntent.STRENGTH
        );

        // Strength 3-6. Ex 12-20.
        // Clamp to 12.
        // Result: 12.
        expect(result.suggestedReps, '12'); 
    });

  });
}

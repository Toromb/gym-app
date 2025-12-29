import '../models/plan_model.dart';
import '../models/execution_model.dart';

class SwapSuggestion {
  final String? suggestedWeight;
  final String suggestedSets;
  final String suggestedReps;
  final bool isWeightEstimated;

  SwapSuggestion({
    this.suggestedWeight,
    required this.suggestedSets,
    required this.suggestedReps,
    required this.isWeightEstimated,
  });
}

class SwapExerciseLogic {
  
  static SwapSuggestion calculate({
    required Exercise oldExercise,
    required Exercise newExercise,
    required SessionExercise execution,
  }) {
    // 1. Weight Calculation
    String? newWeight;
    bool isEstimated = false;

    // Parse old weight
    // Prioritize weightUsed (actual) over targetWeightSnapshot (plan)
    final oldWeightStr = execution.weightUsed ?? execution.targetWeightSnapshot;
    
    if (oldWeightStr != null && oldWeightStr.isNotEmpty) {
      // Try to parse number
      final oldVal = double.tryParse(oldWeightStr.replaceAll(RegExp(r'[^0-9.]'), ''));
      
      if (oldVal != null && oldExercise.loadFactor != null && newExercise.loadFactor != null) {
        // Formula: New = Old * (NewFactor / OldFactor)
        if (oldExercise.loadFactor! > 0) { // Avoid division by zero
           final ratio = newExercise.loadFactor! / oldExercise.loadFactor!;
           final calculated = oldVal * ratio;
           
           // Round to nearest 0.5 or integer for cleanliness
           // e.g. 23.4 -> 23.5, 23.1 -> 23.0
           final rounded = (calculated * 2).round() / 2;
           
           // If integer, remove decimal
           newWeight = rounded % 1 == 0 ? rounded.toInt().toString() : rounded.toString();
           isEstimated = true;
        }
      } else {
        // Fallback: Keep old weight string if we can't calculate?
        // Requirement: "Si NO hay datos suficientes: No sugerir peso (null / 0)."
        // So we leave newWeight null.
      }
    }

    // 2. Sets Calculation
    // Use defaultSets if available, else fallback to 3 (safe default)
    // Or should we keep old sets? 
    // Plan says: "Usar defaultSets del ejercicio destino (si existe). Si no, fallback global seguro (ej: 3)."
    final int setsVal = newExercise.defaultSets ?? 3;
    final String newSets = setsVal.toString();

    // 3. Reps Calculation
    String newReps;
    
    // Get old reps (done or target)
    final oldRepsStr = execution.repsDone ?? execution.targetRepsSnapshot;
    
    if (newExercise.minReps != null && newExercise.maxReps != null) {
      if (oldRepsStr != null) {
        // Try to parse single number or range
        // If range "10-12", take average or lower? Let's try to parse first int.
        final oldRepsVal = int.tryParse(oldRepsStr.replaceAll(RegExp(r'[^0-9].*'), '')); // simple parse first number
        
        if (oldRepsVal != null) {
           if (oldRepsVal < newExercise.minReps!) {
             newReps = newExercise.minReps.toString();
           } else if (oldRepsVal > newExercise.maxReps!) {
             newReps = newExercise.maxReps.toString();
           } else {
             newReps = oldRepsVal.toString(); // Keep
           }
        } else {
          // Could not parse old reps, use default range
           newReps = '${newExercise.minReps}-${newExercise.maxReps}';
        }
      } else {
         // No old reps, use range
         newReps = '${newExercise.minReps}-${newExercise.maxReps}';
      }
    } else {
       // Destination has no range configuration
       // Fallback: Keep old reps if exist
       if (oldRepsStr != null && oldRepsStr.isNotEmpty) {
         newReps = oldRepsStr;
       } else {
         // Fallback global safe
         newReps = "10-12";
       }
    }

    return SwapSuggestion(
      suggestedWeight: newWeight,
      suggestedSets: newSets,
      suggestedReps: newReps,
      isWeightEstimated: isEstimated,
    );
  }
}

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
    TrainingIntent intent = TrainingIntent.GENERAL,
  }) {
    // 1. Weight Calculation (Unchanged)
    String? newWeight;
    bool isEstimated = false;

    final oldWeightStr = execution.weightUsed ?? execution.targetWeightSnapshot;
    
    if (oldWeightStr != null && oldWeightStr.isNotEmpty) {
      final oldVal = double.tryParse(oldWeightStr.replaceAll(RegExp(r'[^0-9.]'), ''));
      
      if (oldVal != null && oldExercise.loadFactor != null && newExercise.loadFactor != null) {
        if (oldExercise.loadFactor! > 0) {
           final ratio = newExercise.loadFactor! / oldExercise.loadFactor!;
           final calculated = oldVal * ratio;
           final rounded = (calculated * 2).round() / 2;
           newWeight = rounded % 1 == 0 ? rounded.toInt().toString() : rounded.toString();
           isEstimated = true;
        }
      }
    }

    // 2. Sets Calculation (Unchanged)
    final int setsVal = newExercise.defaultSets ?? 3;
    final String newSets = setsVal.toString();

    // 3. Reps Calculation (Intelligent Swap)
    String newReps;
    final oldRepsStr = execution.repsDone ?? execution.targetRepsSnapshot;
    final int? oldRepsVal = oldRepsStr != null 
        ? int.tryParse(oldRepsStr.replaceAll(RegExp(r'[^0-9].*'), '')) 
        : null;

    // Define Base Target based on Intent
    int targetMin, targetMax;
    switch (intent) {
      case TrainingIntent.STRENGTH:
        targetMin = 3; targetMax = 6;
        break;
      case TrainingIntent.HYPERTROPHY:
        targetMin = 8; targetMax = 12;
        break;
      case TrainingIntent.ENDURANCE:
        targetMin = 15; targetMax = 20;
        break;
      case TrainingIntent.GENERAL:
      default:
        targetMin = 10; targetMax = 12; // Fallback only if no other info
        break;
    }

    // Apply Exercise Hardware Limits
    // If exercise forces higher reps (e.g. Abs min 15), we respect that even if Intent is Strength.
    final int exMin = newExercise.minReps ?? 1;
    final int exMax = newExercise.maxReps ?? 99;

    // Intersect Intent Range with Exercise Range
    // Effective Range = [max(targetMin, exMin), min(targetMax, exMax)]
    int effectiveMin = (targetMin < exMin) ? exMin : targetMin;
    int effectiveMax = (targetMax > exMax) ? exMax : targetMax;

    // Handle invalid range (e.g. Strength 3-6 but Exercise min 10 -> [10, 6] -> fix to [10, 10] or just [10, 10])
    if (effectiveMin > effectiveMax) {
        // Exercise limits strictly override Intent
        // If Exercise Min (10) > Intent Max (6) -> Use 10
        // If Exercise Max (5) < Intent Min (8) -> Use 5
        if (exMin > targetMax) {
             effectiveMin = exMin;
             effectiveMax = exMin; // clamp to min
        } else if (exMax < targetMin) {
             effectiveMin = exMax;
             effectiveMax = exMax; // clamp to max
        }
    }

    if (intent == TrainingIntent.GENERAL) {
        // GENERAL Specific Logic:
        // 1. If previous reps exist AND fit in Exercise Limits -> Keep them.
        if (oldRepsVal != null && oldRepsVal >= exMin && oldRepsVal <= exMax) {
            newReps = oldRepsVal.toString();
        } 
        // 2. Else -> Use Exercise Min (if defined) or fallback (10-12)
        else {
             if (newExercise.minReps != null && newExercise.maxReps != null) {
                 newReps = '${newExercise.minReps}-${newExercise.maxReps}';
             } else {
                 newReps = "10-12";
             }
        }
    } else {
        // SPECIFIC INTENT Logic (Strength, Hypertrophy, Endurance):
        // 1. If effective range is valid (effectiveMin <= effectiveMax)
        if (effectiveMin <= effectiveMax) {
             // If old reps fit in effective range, keep them to minimize friction
             if (oldRepsVal != null && oldRepsVal >= effectiveMin && oldRepsVal <= effectiveMax) {
                 newReps = oldRepsVal.toString();
             } else {
                 // Suggest the range or the midpoint/min?
                 // Suggest range "Min-Max"
                 if (effectiveMin == effectiveMax) {
                     newReps = effectiveMin.toString();
                 } else {
                     newReps = '$effectiveMin-$effectiveMax';
                 }
             }
        } else {
             // Should not happen due to clamp logic above, but fallback
             newReps = '$exMin-$exMax';
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

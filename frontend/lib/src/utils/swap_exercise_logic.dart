import '../models/plan_model.dart';
import '../models/execution_model.dart';

class SwapSuggestion {
  final String? suggestedWeight;
  final String suggestedSets;
  final String suggestedReps;
  final String? suggestedTime; // New
  final String? suggestedDistance; // New
  final bool isWeightEstimated;
  final String? warning; // New

  SwapSuggestion({
    this.suggestedWeight,
    required this.suggestedSets,
    required this.suggestedReps,
    this.suggestedTime,
    this.suggestedDistance,
    required this.isWeightEstimated,
    this.warning,
  });
}

class SwapExerciseLogic {
  
  static SwapSuggestion calculate({
    required Exercise oldExercise,
    required Exercise newExercise,
    required SessionExercise execution,
    TrainingIntent intent = TrainingIntent.GENERAL,
    double? userBodyWeight,
  }) {
    // 0. Check Metric Compatibility
    if (oldExercise.metricType != newExercise.metricType) {
        return SwapSuggestion(
            suggestedSets: newExercise.defaultSets?.toString() ?? '3',
            suggestedReps: '', 
            isWeightEstimated: false,
            warning: 'El ejercicio tiene un tipo de medición diferente (${newExercise.metricType}).',
        );
    }
    
    // Initialize common defaults
    final int setsVal = newExercise.defaultSets ?? 3;
    final String newSets = setsVal.toString();
    
    // Handle specific metrics
    if (newExercise.metricType == 'TIME') {
        // Suggest time
        String? newTime;
        // reuse old time if avail
        final oldTime = execution.timeSpent ?? execution.targetTimeSnapshot?.toString();
        if (oldTime != null) {
            newTime = oldTime; 
            // Clamp if needed
            // (Simple implementation for Phase 1: Keep same time)
        } else {
            newTime = newExercise.defaultTime?.toString();
        }
        
        return SwapSuggestion(
            suggestedSets: newSets,
            suggestedReps: '',
            suggestedTime: newTime,
            isWeightEstimated: false,
        );
    } else if (newExercise.metricType == 'DISTANCE') {
        String? newDist;
        final oldDist = execution.distanceCovered?.toString() ?? execution.targetDistanceSnapshot?.toString();
        if (oldDist != null) {
            newDist = oldDist;
        } else {
             newDist = newExercise.defaultDistance?.toString();
        }
        
         return SwapSuggestion(
            suggestedSets: newSets,
            suggestedReps: '',
            suggestedDistance: newDist,
            isWeightEstimated: false,
        );
    }

    // --- REPS LOGIC (Existing) ---

    // 1. Weight Calculation
    String? newWeight;
    bool isEstimated = false;

    // Determine Old External Weight (Priority: WeightUsed > TargetSnapshot)
    final oldWeightStr = execution.weightUsed ?? execution.targetWeightSnapshot;
    
    // Parse Old External Load
    double? oldExternalLoad;
    if (oldWeightStr != null && oldWeightStr.isNotEmpty) {
      oldExternalLoad = double.tryParse(oldWeightStr.replaceAll(RegExp(r'[^0-9.]'), ''));
    }

    // Determine Reference Weight (Old Exercise)
    double? referenceWeight;
    
    // Check if Old Exercise is Bodyweight
    final isBodyweight = oldExercise.equipments.any((e) => e.name.toUpperCase().contains('BODYWEIGHT') || e.id.toUpperCase().contains('BODYWEIGHT')); 
    
    if (isBodyweight) {
      if (userBodyWeight != null) {
         // Reference = BodyWeight + ExternalLoad (if any)
         referenceWeight = userBodyWeight + (oldExternalLoad ?? 0);
      } 
    } else {
      // Standard Exercise: Reference is just external load
      referenceWeight = oldExternalLoad;
    }

    // Calculate New Weight
    if (referenceWeight != null && oldExercise.loadFactor != null && newExercise.loadFactor != null) {
       if (oldExercise.loadFactor! > 0) {
          final ratio = newExercise.loadFactor! / oldExercise.loadFactor!;
          final calculated = referenceWeight * ratio;
          final rounded = (calculated * 2).round() / 2;
          newWeight = rounded % 1 == 0 ? rounded.toInt().toString() : rounded.toString();
          isEstimated = true;
       }
    }

    // 2. Reps Calculation (Intelligent Swap)
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
    final int exMin = newExercise.minReps ?? 1;
    final int exMax = newExercise.maxReps ?? 99;

    // Intersect Intent Range with Exercise Range
    int effectiveMin = (targetMin < exMin) ? exMin : targetMin;
    int effectiveMax = (targetMax > exMax) ? exMax : targetMax;

    if (effectiveMin > effectiveMax) {
        if (exMin > targetMax) {
             effectiveMin = exMin;
             effectiveMax = exMin; // clamp to min
        } else if (exMax < targetMin) {
             effectiveMin = exMax;
             effectiveMax = exMax; // clamp to max
        }
    }

    if (intent == TrainingIntent.GENERAL) {
        if (oldRepsVal != null && oldRepsVal >= exMin && oldRepsVal <= exMax) {
            newReps = oldRepsVal.toString();
        } 
        else {
             if (newExercise.minReps != null && newExercise.maxReps != null) {
                 newReps = '${newExercise.minReps}-${newExercise.maxReps}';
             } else {
                 newReps = "10-12";
             }
        }
    } else {
        if (effectiveMin <= effectiveMax) {
             if (oldRepsVal != null && oldRepsVal >= effectiveMin && oldRepsVal <= effectiveMax) {
                 newReps = oldRepsVal.toString();
             } else {
                 if (effectiveMin == effectiveMax) {
                     newReps = effectiveMin.toString();
                 } else {
                     newReps = '$effectiveMin-$effectiveMax';
                 }
             }
        } else {
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

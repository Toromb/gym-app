import 'package:flutter/material.dart';
import '../../models/plan_model.dart';
import '../../utils/swap_exercise_logic.dart';

class SwapConfirmationDialog extends StatefulWidget {
  final Exercise newExercise;
  final SwapSuggestion suggestion;
  final String oldExerciseName;

  const SwapConfirmationDialog({
    super.key,
    required this.newExercise,
    required this.suggestion,
    required this.oldExerciseName,
  });

  @override
  State<SwapConfirmationDialog> createState() => _SwapConfirmationDialogState();
}

class _SwapConfirmationDialogState extends State<SwapConfirmationDialog> {
  late TextEditingController _weightController;
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  // New Controllers
  late TextEditingController _timeController;
  late TextEditingController _distanceController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: widget.suggestion.suggestedWeight ?? '');
    _setsController = TextEditingController(text: widget.suggestion.suggestedSets);
    _repsController = TextEditingController(text: widget.suggestion.suggestedReps);
    _timeController = TextEditingController(text: widget.suggestion.suggestedTime ?? '');
    _distanceController = TextEditingController(text: widget.suggestion.suggestedDistance ?? '');
  }

  @override
  void dispose() {
    _weightController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _timeController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metricType = widget.newExercise.metricType;

    return AlertDialog(
      title: const Text('Confirmar Cambio'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vas a cambiar:'),
            Text(widget.oldExerciseName, style: const TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.lineThrough, color: Colors.grey)),
            const Icon(Icons.arrow_downward, size: 16),
            Text(widget.newExercise.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 16),
            
            // Warning
            if (widget.suggestion.warning != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber)
                ),
                child: Row(
                    children: [
                        const Icon(Icons.warning_amber, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(widget.suggestion.warning!, style: const TextStyle(fontSize: 12, color: Colors.black87))),
                    ]
                ),
              ),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: const Text(
                'Estos valores son una estimación inicial basada en el ejercicio anterior. Podés modificarlos antes de continuar.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                 Expanded(
                   child: TextField(
                     controller: _setsController,
                     decoration: const InputDecoration(labelText: 'Series', isDense: true),
                     keyboardType: TextInputType.number,
                   ),
                 ),
                 const SizedBox(width: 8),
                 
                 // METRIC SPECIFIC INPUTS
                 if (metricType == 'REPS') ...[
                     Expanded(
                        child: TextField(
                            controller: _repsController,
                            decoration: const InputDecoration(labelText: 'Reps', isDense: true),
                        ),
                     ),
                 ] else if (metricType == 'TIME') ...[
                     Expanded(
                         flex: 2,
                        child: TextField(
                            controller: _timeController,
                            decoration: const InputDecoration(labelText: 'Tiempo (seg)', isDense: true),
                            keyboardType: TextInputType.number,
                        ),
                     ),
                 ] else if (metricType == 'DISTANCE') ...[
                     Expanded(
                         flex: 2,
                        child: TextField(
                            controller: _distanceController,
                            decoration: const InputDecoration(labelText: 'Distancia (m)', isDense: true),
                            keyboardType: TextInputType.number,
                        ),
                     ),
                 ],

              ],
            ),
            const SizedBox(height: 12),
            
            if (metricType == 'REPS')
             TextField(
               controller: _weightController,
               decoration: InputDecoration(
                 labelText: widget.suggestion.isWeightEstimated ? 'Peso Sugerido (Est)' : 'Peso Sugerido', 
                 helperText: widget.suggestion.isWeightEstimated ? 'Calculado por equivalencia de fuerza' : 'Sin datos suficientes para sugerir',
                 isDense: true
               ),
             ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'sets': _setsController.text,
              'reps': _repsController.text,
              'weight': _weightController.text,
               // New
              'time': _timeController.text,
              'distance': _distanceController.text,
            });
          },
          child: const Text('Confirmar Cambio'),
        ),
      ],
    );
  }
}

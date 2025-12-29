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

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: widget.suggestion.suggestedWeight ?? '');
    _setsController = TextEditingController(text: widget.suggestion.suggestedSets);
    _repsController = TextEditingController(text: widget.suggestion.suggestedReps);
  }

  @override
  void dispose() {
    _weightController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmar Cambio'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vas a cambiar:'),
            Text(widget.oldExerciseName, style: const TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.lineThrough, color: Colors.grey)),
            const Icon(Icons.arrow_downward, size: 16),
            Text(widget.newExercise.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 16),
            
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
                 Expanded(
                   child: TextField(
                     controller: _repsController,
                     decoration: const InputDecoration(labelText: 'Reps', isDense: true),
                   ),
                 ),
              ],
            ),
            const SizedBox(height: 12),
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
            });
          },
          child: const Text('Confirmar Cambio'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../../models/free_training_model.dart';
import '../../../models/plan_model.dart';
import '../../../services/free_training_service.dart';
import '../../shared/exercise_selection_dialog.dart';

class FreeTrainingEditorScreen extends StatefulWidget {
  final FreeTraining? training;

  const FreeTrainingEditorScreen({super.key, this.training});

  @override
  State<FreeTrainingEditorScreen> createState() => _FreeTrainingEditorScreenState();
}

class _FreeTrainingEditorScreenState extends State<FreeTrainingEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = FreeTrainingService();
  
  late TextEditingController _nameController;
  FreeTrainingType _type = FreeTrainingType.musculacion;
  TrainingLevel _level = TrainingLevel.medio;
  BodySector? _sector;
  CardioLevel? _cardioLevel;
  
  List<FreeTrainingExercise> _exercises = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final t = widget.training;
    _nameController = TextEditingController(text: t?.name ?? '');
    if (t != null) {
      _type = t.type;
      _level = t.level;
      _sector = t.sector;
      _cardioLevel = t.cardioLevel;
      _exercises = List.from(t.exercises); 
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_exercises.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agregá al menos un ejercicio')));
        return;
    }

    setState(() => _isLoading = true);
    
    // Construct DTO
    final dto = {
      'name': _nameController.text,
      'type': _type.name, 
      'level': _level.name,
      'sector': _sector?.name,
      'cardioLevel': _cardioLevel?.name,
      'exercises': _exercises.asMap().entries.map((e) {
         final i = e.key;
         final ex = e.value;
         return {
            'exerciseId': ex.exercise.id,
            'order': i,
            'sets': ex.sets,
            'reps': ex.reps,
            'suggestedLoad': ex.suggestedLoad,
            'rest': ex.rest,
            'notes': ex.notes,
            'videoUrl': ex.videoUrl,
         };
      }).toList(),
    };

    try {
        if (widget.training == null) {
            await _service.createFreeTraining(dto);
        } else {
            await _service.updateFreeTraining(widget.training!.id, dto);
        }
        if (mounted) Navigator.pop(context, true);
    } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
        if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addOrEditExercise([FreeTrainingExercise? existing, int? index]) async {
    final Exercise? selected;
    if (existing == null) {
        selected = await showDialog<Exercise>(
            context: context,
            builder: (ctx) => const ExerciseSelectionDialog(),
        );
        if (selected == null) return;
    } else {
        selected = existing.exercise;
    }

    if (!mounted) return;

    // Controllers
    final setsController = TextEditingController(text: existing?.sets.toString() ?? selected?.defaultSets?.toString() ?? '3');
    final repsController = TextEditingController(text: existing?.reps ?? selected?.reps ?? '12'); // Default reps
    final loadController = TextEditingController(text: existing?.suggestedLoad ?? selected?.load ?? '');
    final restController = TextEditingController(text: existing?.rest ?? selected?.rest ?? '60s');
    final notesController = TextEditingController(text: existing?.notes ?? selected?.notes ?? '');
    final videoUrlController = TextEditingController(text: existing?.videoUrl ?? selected?.videoUrl ?? '');

    await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
            title: Text(existing == null ? 'Agregar: ${selected!.name}' : 'Editar: ${selected!.name}'),
            content: SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        TextField(controller: setsController, decoration: const InputDecoration(labelText: 'Series'), keyboardType: TextInputType.number),
                        TextField(controller: repsController, decoration: const InputDecoration(labelText: 'Repeticiones')),
                        TextField(controller: loadController, decoration: const InputDecoration(labelText: 'Carga Sugerida')),
                        TextField(controller: restController, decoration: const InputDecoration(labelText: 'Descanso')),
                        TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notas')),
                        TextField(controller: videoUrlController, decoration: const InputDecoration(labelText: 'URL Video')),
                    ],
                ),
            ),
            actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                FilledButton(
                    onPressed: () {
                        setState(() {
                            final newEx = FreeTrainingExercise(
                                id: existing?.id ?? '', // ID handled by backend on create, empty for new
                                exercise: selected!,
                                order: existing?.order ?? _exercises.length,
                                sets: int.tryParse(setsController.text) ?? 3,
                                reps: repsController.text,
                                suggestedLoad: loadController.text,
                                rest: restController.text,
                                notes: notesController.text,
                                videoUrl: videoUrlController.text,
                            );

                            if (existing != null && index != null) {
                                _exercises[index] = newEx;
                            } else {
                                _exercises.add(newEx);
                            }
                        });
                        Navigator.pop(ctx);
                    }, 
                    child: const Text('Guardar')
                ),
            ],
        )
    );
  }

  void _addExercise() => _addOrEditExercise();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.training == null ? 'Crear Entrenamiento' : 'Editar Entrenamiento'),
        actions: [
            IconButton(icon: const Icon(Icons.save), onPressed: _save)
        ],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Form(
        key: _formKey,
        child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
                TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (v) => v?.isEmpty == true ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<FreeTrainingType>(
                    value: _type,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: FreeTrainingType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name.toUpperCase()))).toList(),
                    onChanged: (v) => setState(() => _type = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TrainingLevel>(
                    value: _level,
                    decoration: const InputDecoration(labelText: 'Nivel'),
                    items: TrainingLevel.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name.toUpperCase()))).toList(),
                    onChanged: (v) => setState(() => _level = v!),
                ),
                 const SizedBox(height: 16),
                DropdownButtonFormField<BodySector>(
                    value: _sector,
                    decoration: const InputDecoration(labelText: 'Sector (Opcional)'),
                    items: [
                        const DropdownMenuItem(value: null, child: Text('Ninguno')),
                        ...BodySector.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name.toUpperCase()))),
                    ],
                    onChanged: (v) => setState(() => _sector = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<CardioLevel>(
                    value: _cardioLevel,
                    decoration: const InputDecoration(labelText: 'Nivel Cardio (Opcional)'),
                    items: [
                         const DropdownMenuItem(value: null, child: Text('Ninguno')),
                        ...CardioLevel.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name.toUpperCase()))),
                    ],
                    onChanged: (v) => setState(() => _cardioLevel = v),
                ),
                const SizedBox(height: 24),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                        const Text('Ejercicios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.add_circle), onPressed: _addExercise)
                    ],
                ),
                if (_exercises.isEmpty) 
                    const Padding(padding: EdgeInsets.all(16), child: Text('Sin ejercicios', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))),
                
                ..._exercises.asMap().entries.map((e) {
                    final i = e.key;
                    final ex = e.value;
                    return Card(
                        child: ListTile(
                            leading: CircleAvatar(child: Text('${i+1}')),
                            title: Text(ex.exercise.name),
                            subtitle: Text('${ex.sets}x${ex.reps ?? "?"} ${ex.suggestedLoad != null ? "@ ${ex.suggestedLoad}" : ""}'),
                            trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => setState(() => _exercises.removeAt(i)),
                            ),
                            onTap: () => _addOrEditExercise(ex, i),
                        ),
                    );
                }),
                const SizedBox(height: 80),
            ],
        ),
      ),
    );
  }
}

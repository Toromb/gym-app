import 'package:flutter/material.dart';
import '../../models/plan_model.dart'; // Exercise model
import '../../services/exercise_service.dart';

class CreateExerciseScreen extends StatefulWidget {
  final Exercise? exercise; // Null = Create Mode, Not Null = Edit Mode
  const CreateExerciseScreen({super.key, this.exercise});

  @override
  State<CreateExerciseScreen> createState() => _CreateExerciseScreenState();
}

class _CreateExerciseScreenState extends State<CreateExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _exerciseService = ExerciseService();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _muscleGroupController;
  late TextEditingController _typeController;
  late TextEditingController _videoUrlController;
  late TextEditingController _notesController;
  
  // Defaults
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _restController;
  late TextEditingController _loadController;

  @override
  void initState() {
    super.initState();
    final e = widget.exercise;
    _nameController = TextEditingController(text: e?.name ?? '');
    _muscleGroupController = TextEditingController(text: e?.muscleGroup ?? '');
    _typeController = TextEditingController(text: e?.type ?? '');
    _videoUrlController = TextEditingController(text: e?.videoUrl ?? '');
    _notesController = TextEditingController(text: e?.notes ?? '');
    
    _setsController = TextEditingController(text: e?.sets?.toString() ?? '');
    _repsController = TextEditingController(text: e?.reps ?? '');
    _restController = TextEditingController(text: e?.rest ?? '');
    _loadController = TextEditingController(text: e?.load ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _muscleGroupController.dispose();
    _typeController.dispose();
    _videoUrlController.dispose();
    _notesController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _restController.dispose();
    _loadController.dispose();
    super.dispose();
  }

  Future<void> _saveExercise() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final exerciseData = {
        'name': _nameController.text,
        'muscleGroup': _muscleGroupController.text,
        'type': _typeController.text.isNotEmpty ? _typeController.text : null,
        'videoUrl': _videoUrlController.text.isNotEmpty ? _videoUrlController.text : null,
        'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
        
        // Defaults
        'sets': int.tryParse(_setsController.text),
        'reps': _repsController.text.isNotEmpty ? _repsController.text : null,
        'rest': _restController.text.isNotEmpty ? _restController.text : null,
        'load': _loadController.text.isNotEmpty ? _loadController.text : null,
      };

      if (widget.exercise == null) {
        await _exerciseService.createExercise(exerciseData);
      } else {
        await _exerciseService.updateExercise(widget.exercise!.id, exerciseData);
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to refresh list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.exercise == null ? 'Ejercicio creado exitosamente' : 'Ejercicio actualizado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.exercise == null ? 'Crear Ejercicio' : 'Editar Ejercicio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Información Básica', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre *'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _muscleGroupController,
                decoration: const InputDecoration(labelText: 'Grupo Muscular *', hintText: 'Ej: Piernas, Pecho, Espalda'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'Tipo', hintText: 'Ej: Fuerza, Hipertrofia, Cardio'),
              ),
              const SizedBox(height: 20),
               
              Text('Parámetros por Defecto (Opcional)', style: Theme.of(context).textTheme.titleMedium),
              const Text('Estos valores se precargarán al agregar el ejercicio a un plan.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _setsController, decoration: const InputDecoration(labelText: 'Series'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(controller: _repsController, decoration: const InputDecoration(labelText: 'Reps'))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _loadController, decoration: const InputDecoration(labelText: 'Peso/Int'))),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(controller: _restController, decoration: const InputDecoration(labelText: 'Descanso'))),
                ],
              ),

              const SizedBox(height: 20),
              Text('Multimedia y Notas', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              TextFormField(
                controller: _videoUrlController,
                decoration: const InputDecoration(labelText: 'URL de Video (YouTube)', prefixIcon: Icon(Icons.video_library)),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notas / Instrucciones'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveExercise,
                  child: _isLoading ? const CircularProgressIndicator() : Text(widget.exercise == null ? 'Guardar Ejercicio' : 'Actualizar Ejercicio'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

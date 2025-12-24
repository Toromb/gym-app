import 'package:flutter/material.dart';
import '../../models/plan_model.dart'; // Exercise model
import '../../services/exercise_api_service.dart';

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
  // late TextEditingController _muscleGroupController; // Removed
  late TextEditingController _typeController;
  late TextEditingController _videoUrlController;
  late TextEditingController _notesController;
  
  // Defaults
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _restController;
  late TextEditingController _loadController;

  // Muscle Mapping State
  List<Muscle> _allMuscles = [];
  bool _isLoadingMuscles = true;
  Muscle? _primaryMuscle;
  List<Muscle> _secondaryMuscles = [];

  @override
  void initState() {
    super.initState();
    final e = widget.exercise;
    _nameController = TextEditingController(text: e?.name ?? '');
    // _muscleGroupController = TextEditingController(text: e?.muscleGroup ?? '');
    _typeController = TextEditingController(text: e?.type ?? '');
    _videoUrlController = TextEditingController(text: e?.videoUrl ?? '');
    _notesController = TextEditingController(text: e?.notes ?? '');
    
    _setsController = TextEditingController(text: e?.sets?.toString() ?? '');
    _repsController = TextEditingController(text: e?.reps ?? '');
    _restController = TextEditingController(text: e?.rest ?? '');
    _loadController = TextEditingController(text: e?.load ?? '');

    _loadMuscles();
  }

  Future<void> _loadMuscles() async {
    try {
      final muscles = await _exerciseService.getMuscles();
      muscles.sort((a, b) => a.order.compareTo(b.order));
      
      setState(() {
        _allMuscles = muscles;
        _isLoadingMuscles = false;

        // Initialize Selection for Edit Mode
        if (widget.exercise != null) {
          final e = widget.exercise!;
          
          // Try to match Primary Muscle by ID or Name (legacy compatibility)
          if (e.muscles.isNotEmpty) {
            try {
              final dbPrimary = e.muscles.firstWhere((m) => m.role == 'PRIMARY');
              _primaryMuscle = _allMuscles.firstWhere((m) => m.id == dbPrimary.muscle.id, orElse: () => _allMuscles.first);
            } catch (_) {
               // No explicitly marked primary
            }
            // Secondaries
             final dbSecondaries = e.muscles.where((m) => m.role == 'SECONDARY').map((em) => em.muscle.id).toSet();
             _secondaryMuscles = _allMuscles.where((m) => dbSecondaries.contains(m.id)).toList();
          }

          // Fallback: If no relations found, try matching 'muscleGroup' string to a muscle name
          if (_primaryMuscle == null && e.muscleGroup.isNotEmpty) {
             try {
                _primaryMuscle = _allMuscles.firstWhere((m) => m.name.toLowerCase() == e.muscleGroup.toLowerCase());
             } catch (_) {
                // No match found
             }
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading muscles: $e');
      setState(() => _isLoadingMuscles = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    // _muscleGroupController.dispose();
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
    if (_primaryMuscle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar un Músculo Primario')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Calculate Load Percentages
      // Heuristic: Primary takes the majority. If secondaries exist, they share ~= 30%.
      int secondaryCount = _secondaryMuscles.length;
      int secondaryShare = secondaryCount > 0 ? (30 / secondaryCount).floor() : 0;
      int primaryShare = 100 - (secondaryShare * secondaryCount);

      List<Map<String, dynamic>> musclesPayload = [];
      
      // Add Primary
      musclesPayload.add({
        'muscleId': _primaryMuscle!.id,
        'role': 'PRIMARY',
        'loadPercentage': primaryShare,
      });

      // Add Secondaries
      for (var m in _secondaryMuscles) {
        musclesPayload.add({
          'muscleId': m.id,
          'role': 'SECONDARY',
          'loadPercentage': secondaryShare,
        });
      }

      final exerciseData = {
        'name': _nameController.text,
        // 'muscleGroup': _primaryMuscle!.name, // Legacy field handled by backend now
        'muscles': musclesPayload,
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

  // --- UI Helpers for Muscle Selection ---

  String _translateRegion(String region) {
    switch(region) {
      case 'UPPER': return 'Superior';
      case 'CORE': return 'Core';
      case 'LOWER': return 'Inferior';
      default: return region;
    }
  }

  String _translateSide(String side) {
    switch(side) {
      case 'FRONT': return 'Frente';
      case 'BACK': return 'Espalda';
      default: return side;
    }
  }

  Map<String, Map<String, List<Muscle>>> _groupMuscles() {
    final grouped = <String, Map<String, List<Muscle>>>{};
    
    // Define order of regions
    final regions = ['UPPER', 'CORE', 'LOWER'];
    
    for (var r in regions) {
      grouped[r] = {'FRONT': [], 'BACK': []};
    }

    for (var m in _allMuscles) {
      if (!grouped.containsKey(m.region)) {
        grouped[m.region] = {};
      }
      if (!grouped[m.region]!.containsKey(m.bodySide)) {
         grouped[m.region]![m.bodySide] = [];
      }
      grouped[m.region]![m.bodySide]!.add(m);
    }
    return grouped;
  }

  void _showMuscleSelector({required bool isPrimary}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final grouped = _groupMuscles();
        
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        isPrimary ? 'Seleccionar Músculo Primario' : 'Seleccionar Músculos Secundarios',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children: grouped.entries.map((regionEntry) {
                          final regionKey = regionEntry.key;
                          final sides = regionEntry.value;
                          
                          // Hide empty regions
                          if (sides.values.every((l) => l.isEmpty)) return const SizedBox.shrink();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? Colors.grey.shade800 
                                      : Colors.grey.shade200,
                                  width: double.infinity,
                                  child: Text(
                                    _translateRegion(regionKey), 
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).textTheme.bodyLarge?.color
                                    )
                                  ),
                                ),
                                ...sides.entries.map((sideEntry) {
                                  final sideKey = sideEntry.key;
                                  final muscles = sideEntry.value;
                                  if (muscles.isEmpty) return const SizedBox.shrink();

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 16, top: 8),
                                        child: Text(
                                          _translateSide(sideKey), 
                                          style: TextStyle(
                                            color: Theme.of(context).brightness == Brightness.dark 
                                                ? Colors.grey.shade400 
                                                : Colors.grey.shade700,
                                            fontStyle: FontStyle.italic
                                          )
                                        ),
                                      ),
                                    ...muscles.map((muscle) {
                                      final isSelected = isPrimary 
                                          ? _primaryMuscle?.id == muscle.id
                                          : _secondaryMuscles.any((m) => m.id == muscle.id);
                                          
                                      return ListTile(
                                        title: Text(muscle.name),
                                        leading: isPrimary 
                                            ? Radio<String>(
                                                value: muscle.id, 
                                                groupValue: _primaryMuscle?.id, 
                                                onChanged: (_) {
                                                  setState(() => _primaryMuscle = muscle);
                                                  setModalState((){});
                                                  Navigator.pop(context); // Close on primary selection
                                                }
                                              )
                                            : Checkbox(
                                                value: isSelected, 
                                                onChanged: (val) {
                                                  setState(() {
                                                    if (val == true) {
                                                      _secondaryMuscles.add(muscle);
                                                    } else {
                                                      _secondaryMuscles.removeWhere((m) => m.id == muscle.id);
                                                    }
                                                  });
                                                  setModalState((){});
                                                }
                                              ),
                                        onTap: () {
                                          if (isPrimary) {
                                            setState(() => _primaryMuscle = muscle);
                                            Navigator.pop(context);
                                          } else {
                                            setState(() {
                                              if (isSelected) {
                                                _secondaryMuscles.removeWhere((m) => m.id == muscle.id);
                                              } else {
                                                _secondaryMuscles.add(muscle);
                                              }
                                            });
                                            setModalState((){});
                                          }
                                        },
                                      );
                                    }),
                                  ],
                                );
                              }),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    if (!isPrimary)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Confirmar Selección'),
                          ),
                        ),
                      ),
                  ],
                );
              }
            );
          }
        );
      },
    );
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
              const SizedBox(height: 20),
              
              // --- MUSCLE MAPPING SECTION ---
              Text('Mapeo Muscular', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              
              // Primary Muscle (Required)
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  title: const Text('Músculo Primario *'),
                  subtitle: Text(_primaryMuscle?.name ?? 'Seleccionar...'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showMuscleSelector(isPrimary: true),
                ),
              ),
              if (_primaryMuscle == null)
                 const Padding(
                   padding: EdgeInsets.only(left: 12, top: 4),
                   child: Text('Requerido', style: TextStyle(color: Colors.red, fontSize: 12)),
                 ),
              
              const SizedBox(height: 10),

              // Secondary Muscles (Optional)
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  title: const Text('Músculos Secundarios (Opcional)'),
                  subtitle: Text(_secondaryMuscles.isEmpty 
                      ? 'Ninguno' 
                      : _secondaryMuscles.map((m) => m.name).join(', ')),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showMuscleSelector(isPrimary: false),
                ),
              ),

              const SizedBox(height: 20),
              
              // --- END MUSCLE MAPPING ---

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
                  onPressed: _isLoading || _isLoadingMuscles ? null : _saveExercise,
                  child: _isLoading 
                      ? const CircularProgressIndicator() 
                      : Text(widget.exercise == null ? 'Guardar Ejercicio' : 'Actualizar Ejercicio'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

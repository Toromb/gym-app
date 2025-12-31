import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/plan_provider.dart';
import '../../providers/exercise_provider.dart';
import '../../models/plan_model.dart';
// Needed if we used User in Plan, but PlanModel imports it? Check imports.

class CreatePlanScreen extends StatefulWidget {
  final Plan? planToEdit;

  const CreatePlanScreen({super.key, this.planToEdit});

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _objectiveController;
  late TextEditingController _durationController;
  late TextEditingController _notesController;
  
  List<PlanWeek> _weeks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final plan = widget.planToEdit;
    _nameController = TextEditingController(text: plan?.name ?? '');
    _objectiveController = TextEditingController(text: plan?.objective ?? '');
    _durationController = TextEditingController(text: plan?.durationWeeks.toString() ?? '4');
    _notesController = TextEditingController(text: plan?.generalNotes ?? '');

    if (plan != null) {
      // Deep copy weeks to allow editing without mutating original until save
      _weeks = plan.weeks.map((w) => PlanWeek(
        weekNumber: w.weekNumber,
        days: w.days.map((d) => PlanDay(
          title: d.title,
          dayOfWeek: d.dayOfWeek,
          order: d.order,
          dayNotes: d.dayNotes,
          trainingIntent: d.trainingIntent, // Copy intent
          exercises: d.exercises.map((e) => PlanExercise(
            id: e.id,
            exerciseId: e.exerciseId ?? e.exercise?.id,
            exercise: e.exercise,
            sets: e.sets,
            reps: e.reps,
            suggestedLoad: e.suggestedLoad,
            rest: e.rest,
            notes: e.notes,
            videoUrl: e.videoUrl,
            order: e.order,
            equipments: e.equipments, // Preserve equipments
          )).toList(),
        )).toList(),
      )).toList();
    } else {
      _addWeek(); // Start with 1 week for new plan
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExerciseProvider>().fetchExercises();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _objectiveController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addWeek() {
    setState(() {
      _weeks.add(PlanWeek(
        weekNumber: _weeks.length + 1,
        days: [],
      ));
    });
  }

  void _addDay(int weekIndex) {
    setState(() {
      _weeks[weekIndex].days.add(PlanDay(
        dayOfWeek: _weeks[weekIndex].days.length + 1,
        order: _weeks[weekIndex].days.length + 1,
        exercises: [],
        title: 'Día ${_weeks[weekIndex].days.length + 1}',
      ));
    });
  }

  void _removeWeek(int weekIndex) {
    setState(() {
      _weeks.removeAt(weekIndex);
      // Re-index remaining weeks
      for (int i = 0; i < _weeks.length; i++) {
        _weeks[i].weekNumber = i + 1;
      }
    });
  }

  void _removeDay(int weekIndex, int dayIndex) {
    setState(() {
      _weeks[weekIndex].days.removeAt(dayIndex);
      // Re-index days
      for (int i = 0; i < _weeks[weekIndex].days.length; i++) {
          _weeks[weekIndex].days[i].dayOfWeek = i + 1;
          _weeks[weekIndex].days[i].order = i + 1;
      }
    });
  }

  void _removeExercise(int weekIndex, int dayIndex, int exerciseIndex) {
    setState(() {
      _weeks[weekIndex].days[dayIndex].exercises.removeAt(exerciseIndex);
      // Re-order
      for(int i=0; i < _weeks[weekIndex].days[dayIndex].exercises.length; i++) {
          _weeks[weekIndex].days[dayIndex].exercises[i].order = i + 1;
      }
    });
  }

  void _addOrEditExercise(int weekIndex, int dayIndex, [PlanExercise? existingExercise, int? exerciseIndex]) async {
    final exerciseProvider = context.read<ExerciseProvider>();
    final exercises = exerciseProvider.exercises;

    if (exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay ejercicios disponibles. Crea algunos primero.')),
      );
      return;
    }

    Exercise? selectedExercise;
    if (existingExercise?.exerciseId != null) {
      try {
        selectedExercise = exercises.firstWhere((e) => e.id == existingExercise!.exerciseId);
      } catch (_) {}
    } else if (existingExercise?.exercise != null) {
       try {
        selectedExercise = exercises.firstWhere((e) => e.id == existingExercise!.exercise!.id);
      } catch (_) {}
    }

    final setsController = TextEditingController(text: existingExercise?.sets.toString() ?? '3');
    final repsController = TextEditingController(text: existingExercise?.reps ?? '10');
    final loadController = TextEditingController(text: existingExercise?.suggestedLoad ?? '');
    final restController = TextEditingController(text: existingExercise?.rest ?? '60s');
    
    // New Controllers
    final timeController = TextEditingController(text: existingExercise?.targetTime?.toString() ?? '');
    final distanceController = TextEditingController(text: existingExercise?.targetDistance?.toString() ?? '');

    final notesController = TextEditingController(text: existingExercise?.notes ?? '');
    final videoUrlController = TextEditingController(text: existingExercise?.videoUrl ?? existingExercise?.exercise?.videoUrl ?? '');
    
    // Equipment Selection State
    List<Equipment> selectedPlanEquipments = existingExercise?.equipments.toList() ?? [];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder( 
        builder: (context, setStateDialog) {
          final metricType = selectedExercise?.metricType ?? 'REPS';

          return AlertDialog(
            title: Text(existingExercise == null ? 'Agregar Ejercicio' : 'Editar Ejercicio'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Exercise>(
                    decoration: const InputDecoration(labelText: 'Ejercicio'),
                    initialValue: selectedExercise,
                    items: exercises.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
                    onChanged: (value) {
                       setStateDialog(() {
                         selectedExercise = value;
                         if (value != null) {
                           setsController.text = value.sets?.toString() ?? value.defaultSets?.toString() ?? '3';
                           restController.text = value.rest ?? '60s';
                           videoUrlController.text = value.videoUrl ?? '';
                           notesController.text = value.notes ?? '';
                           
                           // Populate Defaults based on metric
                           if (value.metricType == 'REPS') {
                              repsController.text = value.reps ?? '10';
                              loadController.text = value.load ?? '';
                           } else if (value.metricType == 'TIME') {
                              timeController.text = value.defaultTime?.toString() ?? '';
                           } else if (value.metricType == 'DISTANCE') {
                              distanceController.text = value.defaultDistance?.toString() ?? '';
                           }

                           selectedPlanEquipments = []; 
                         }
                       });
                    },
                    validator: (value) => value == null ? 'Requerido' : null,
                  ),
                  
                  if (selectedExercise != null) ...[
                      const SizedBox(height: 5),
                      Align(
                          alignment: Alignment.centerLeft, 
                          child: Chip(
                              label: Text('Métrica: $metricType', style: const TextStyle(fontSize: 10)),
                              visualDensity: VisualDensity.compact,
                          )
                      ),
                  ],

                  if (selectedExercise != null && selectedExercise!.equipments.isNotEmpty) ...[
                     const SizedBox(height: 10),
                     Align(alignment: Alignment.centerLeft, child: Text('Equipamiento/s en este ejercicio', style: TextStyle(color: Colors.grey[700], fontSize: 12))),
                     Wrap(
                       spacing: 6.0,
                       runSpacing: 0.0,
                       children: selectedExercise!.equipments.map((eq) {
                         final isSelected = selectedPlanEquipments.any((s) => s.id == eq.id);
                         return FilterChip(
                           label: Text(eq.name),
                           selected: isSelected,
                           onSelected: (bool selected) {
                             setStateDialog(() {
                               if (selected) {
                                 selectedPlanEquipments.add(eq);
                               } else {
                                 selectedPlanEquipments.removeWhere((s) => s.id == eq.id);
                               }
                             });
                           },
                         );
                       }).toList(),
                     ),
                  ],
                  
                  TextField(controller: setsController, decoration: const InputDecoration(labelText: 'Series'), keyboardType: TextInputType.number),
                  
                  // CONDITIONAL FIELDS
                  if (metricType == 'REPS') ...[
                      TextField(controller: repsController, decoration: const InputDecoration(labelText: 'Repeticiones')),
                      TextField(controller: loadController, decoration: const InputDecoration(labelText: 'Peso (kg)')),
                  ] else if (metricType == 'TIME') ...[
                      TextField(controller: timeController, decoration: const InputDecoration(labelText: 'Tiempo Objetivo (segundos)'), keyboardType: TextInputType.number),
                  ] else if (metricType == 'DISTANCE') ...[
                      TextField(controller: distanceController, decoration: const InputDecoration(labelText: 'Distancia Objetivo (metros)'), keyboardType: TextInputType.number),
                  ],

                  TextField(controller: restController, decoration: const InputDecoration(labelText: 'Descanso (seg)')),
                  
                  // Collapsible or bottom fields
                  TextField(controller: videoUrlController, decoration: const InputDecoration(labelText: 'URL de Video')),
                  TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notas')),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              TextButton(
                onPressed: () {
                  if (selectedExercise != null) {
                    setState(() {
                      final newExercise = PlanExercise(
                        id: existingExercise?.id,
                        exerciseId: selectedExercise!.id,
                        exercise: selectedExercise,
                        sets: int.tryParse(setsController.text.trim()) ?? 3,
                        // Always send default '0' or '' if hidden, but prefer null handling in backend if possible.
                        // For now we persist "" if not REPS, but PlanExercise model expects required string reps?
                        // Model says: required reps. So we send "0" or "-" if not REPS.
                        reps: metricType == 'REPS' ? repsController.text : '', 
                        suggestedLoad: metricType == 'REPS' ? loadController.text : null,
                        
                        targetTime: metricType == 'TIME' ? int.tryParse(timeController.text) : null,
                        targetDistance: metricType == 'DISTANCE' ? double.tryParse(distanceController.text) : null,

                        rest: restController.text,
                        notes: notesController.text,
                        videoUrl: videoUrlController.text.isNotEmpty ? videoUrlController.text : null,
                        order: existingExercise?.order ?? _weeks[weekIndex].days[dayIndex].exercises.length + 1,
                        equipments: selectedPlanEquipments,
                      );

                      if (existingExercise != null && exerciseIndex != null) {
                        _weeks[weekIndex].days[dayIndex].exercises[exerciseIndex] = newExercise;
                      } else {
                        _weeks[weekIndex].days[dayIndex].exercises.add(newExercise);
                      }
                    });
                    Navigator.pop(context);
                  }
                },
                child: Text(existingExercise == null ? 'Agregar' : 'Actualizar'),
              ),
            ],
          );
        }
      ),
    );
  }

  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.planToEdit == null ? 'Crear Plan' : 'Editar Plan')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Text(
              "Definí una estructura de entrenamiento reutilizable.",
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepTapped: (index) => setState(() => _currentStep = index),
          onStepContinue: () {
             if (_currentStep < 1) setState(() => _currentStep += 1);
          },
          onStepCancel: () {
             if (_currentStep > 0) setState(() => _currentStep -= 1);
          },
          controlsBuilder: (context, details) {
            if (_currentStep == 0) {
               return Padding(
                 padding: const EdgeInsets.only(top: 16.0),
                 child: Row(
                   children: [
                     ElevatedButton(
                       onPressed: details.onStepContinue,
                        child: const Text('Siguiente'),
                     ),
                   ],
                 ),
               );
            }
            // On last step, we hide default controls because we have the main Save button
            return const SizedBox.shrink();
          },
          steps: [
            Step(
              title: const Text('Datos del Plan'),
              content: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Plan',
                      hintText: 'Ej: Fuerza Inicial · Adaptación',
                    ),
                    validator: (value) => value!.isEmpty ? 'Requerido' : null,
                  ),
                  TextFormField(
                    controller: _objectiveController,
                    decoration: const InputDecoration(
                      labelText: 'Objetivo',
                      hintText: 'Ej: Fuerza · Hipertrofia · Volver a entrenar',
                    ),
                  ),
                  TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duración (semanas)',
                      hintText: 'Ej: 4',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notas',
                      hintText: 'Indicaciones o recomendaciones generales',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.editing,
            ),
            Step(
              title: const Text('Estructura del Plan'),
              content: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Organizá semanas y días de entrenamiento.",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ),
                  ),
                  ..._weeks.asMap().entries.map((entry) {
                    final weekIndex = entry.key;
                    final week = entry.value;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      // color: Colors.grey[50], // Removed to respect Theme
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Semana ${week.weekNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _removeWeek(weekIndex),
                                  tooltip: 'Eliminar Semana',
                                ),
                              ],
                            ),
                            const Divider(),
                            ...week.days.asMap().entries.map((dayEntry) {
                              final dayIndex = dayEntry.key;
                              final day = dayEntry.value;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    title: Text(day.title ?? 'Día ${day.dayOfWeek}'),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Row(
                                        children: [
                                          const Text("Objetivo: ", style: TextStyle(fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 8),
                                          DropdownButton<TrainingIntent>(
                                            value: day.trainingIntent,
                                            isDense: true,
                                            underline: Container(height: 1, color: Colors.grey),
                                            items: TrainingIntent.values.map((intent) {
                                              return DropdownMenuItem(
                                                value: intent,
                                                child: Text(intent.label),
                                              );
                                            }).toList(),
                                            onChanged: (newIntent) {
                                              if (newIntent != null) {
                                                setState(() {
                                                   _weeks[weekIndex].days[dayIndex] = PlanDay(
                                                     id: day.id,
                                                     title: day.title,
                                                     dayOfWeek: day.dayOfWeek,
                                                     order: day.order,
                                                     dayNotes: day.dayNotes,
                                                     exercises: day.exercises,
                                                     trainingIntent: newIntent,
                                                   );
                                                });
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.add_circle, color: Colors.blue),
                                          onPressed: () => _addOrEditExercise(weekIndex, dayIndex),
                                          tooltip: 'Agregar Ejercicio',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                                          onPressed: () => _removeDay(weekIndex, dayIndex),
                                          tooltip: 'Eliminar Día',
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (day.exercises.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 16.0, bottom: 8),
                                      child: Column(
                                        children: day.exercises.asMap().entries.map((exEntry) {
                                          final exIndex = exEntry.key;
                                          final ex = exEntry.value;
                                          return Card(
                                            child: ListTile(
                                              dense: true,
                                              title: Text(
                                                  ex.exercise?.metricType == 'TIME' ? '${ex.exercise?.name ?? "Unknown"}: ${ex.sets} x ${ex.targetTime ?? "-"}s'
                                                  : ex.exercise?.metricType == 'DISTANCE' ? '${ex.exercise?.name ?? "Unknown"}: ${ex.sets} x ${ex.targetDistance ?? "-"}m'
                                                  : '${ex.exercise?.name ?? "Unknown"}: ${ex.sets}x${ex.reps}'
                                              ),
                                              subtitle: Text(
                                                '${ex.exercise?.metricType == 'REPS' && ex.suggestedLoad != null ? " ${ex.suggestedLoad}kg |" : ""}'
                                                '${ex.rest != null ? " Rest: ${ex.rest}" : ""}'
                                                '${ex.notes != null && ex.notes!.isNotEmpty ? "\n📝 ${ex.notes}" : ""}',
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (ex.videoUrl != null && ex.videoUrl!.isNotEmpty)
                                                    IconButton(
                                                      icon: const Icon(Icons.play_circle_fill, size: 24, color: Colors.red),
                                                      tooltip: 'Ver Video',
                                                      onPressed: () async {
                                                        final url = Uri.parse(ex.videoUrl!);
                                                        if (await canLaunchUrl(url)) {
                                                          await launchUrl(url);
                                                        } else {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(content: Text('No se pudo abrir la URL del video')),
                                                          );
                                                        }
                                                      },
                                                    ),
                                                  IconButton(
                                                    icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                                                    onPressed: () => _addOrEditExercise(weekIndex, dayIndex, ex, exIndex),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.close, size: 20, color: Colors.red),
                                                    onPressed: () => _removeExercise(weekIndex, dayIndex, exIndex),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                ],
                              );
                            }),
                            TextButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Agregar Día'),
                              onPressed: () => _addDay(weekIndex),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _addWeek,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Semana'),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                    child: Center(
                      child: Text(
                        "Este plan luego podrá asignarse o adaptarse.",
                        style: TextStyle(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ),
                ],
              ),
              isActive: _currentStep >= 1,
            ),
          ],
        ),
      ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              setState(() => _isLoading = true);
              final plan = Plan(
                id: widget.planToEdit?.id, // Keep ID if editing
                name: _nameController.text,
                objective: _objectiveController.text,
                durationWeeks: int.tryParse(_durationController.text) ?? 4,
                generalNotes: _notesController.text,
                weeks: _weeks,
              );
              
              bool success;
              if (widget.planToEdit != null) {
                success = await context.read<PlanProvider>().updatePlan(widget.planToEdit!.id!, plan);
              } else {
                success = await context.read<PlanProvider>().createPlan(plan);
              }

              if (!mounted) return;
              setState(() => _isLoading = false);
              
              if (success) {
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(widget.planToEdit != null ? 'Plan actualizado' : 'Plan creado')),
                );
              }
            }
          },
          child: _isLoading 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
            : Text(widget.planToEdit != null ? 'Actualizar Plan' : 'Crear Plan', style: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}



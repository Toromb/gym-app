import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/plan_provider.dart';
import '../../providers/exercise_provider.dart';
import '../../models/plan_model.dart';
import '../../models/user_model.dart'; // Needed if we used User in Plan, but PlanModel imports it? Check imports.

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
        title: 'Day ${_weeks[weekIndex].days.length + 1}',
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
        const SnackBar(content: Text('No exercises available. Create some first.')),
      );
      return;
    }

    // Correctly find the initial selection object from the provider list based on ID
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

    final notesController = TextEditingController(text: existingExercise?.notes ?? '');
    final videoUrlController = TextEditingController(text: existingExercise?.videoUrl ?? existingExercise?.exercise?.videoUrl ?? '');

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder( // Use StatefulBuilder to update dropdown in Dialog if needed, though usually not for just selection
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(existingExercise == null ? 'Add Exercise' : 'Edit Exercise'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Exercise>(
                    decoration: const InputDecoration(labelText: 'Exercise'),
                    value: selectedExercise,
                    items: exercises.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
                    onChanged: (value) {
                       setStateDialog(() {
                         selectedExercise = value;
                       });
                    },
                    validator: (value) => value == null ? 'Required' : null,
                  ),
                  TextField(controller: setsController, decoration: const InputDecoration(labelText: 'Sets'), keyboardType: TextInputType.number),
                  TextField(controller: repsController, decoration: const InputDecoration(labelText: 'Reps')),
                  TextField(controller: loadController, decoration: const InputDecoration(labelText: 'Weight (kg)')),
                  TextField(controller: restController, decoration: const InputDecoration(labelText: 'Rest Time (sec)')),
                  TextField(controller: videoUrlController, decoration: const InputDecoration(labelText: 'Video URL', hintText: 'https://youtube.com/...')),
                  TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes')),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  if (selectedExercise != null) {
                    // Update the main state
                    setState(() {
                      final newExercise = PlanExercise(
                        id: existingExercise?.id,
                        exerciseId: selectedExercise!.id,
                        exercise: selectedExercise,
                        sets: int.tryParse(setsController.text) ?? 3,
                        reps: repsController.text,
                        suggestedLoad: loadController.text,
                        rest: restController.text,

                        notes: notesController.text,
                        videoUrl: videoUrlController.text.isNotEmpty ? videoUrlController.text : null,
                        order: existingExercise?.order ?? _weeks[weekIndex].days[dayIndex].exercises.length + 1,
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
                child: Text(existingExercise == null ? 'Add' : 'Update'),
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
      appBar: AppBar(title: Text(widget.planToEdit == null ? 'Create Plan' : 'Edit Plan')),
      body: Form(
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
                       child: const Text('Next'),
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
              title: const Text('General Info'),
              content: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Plan Name'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _objectiveController,
                    decoration: const InputDecoration(labelText: 'Objective'),
                  ),
                  TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(labelText: 'Duration (Weeks)'),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(labelText: 'General Notes'),
                    maxLines: 3,
                  ),
                ],
              ),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.editing,
            ),
            Step(
              title: const Text('Structure'),
              content: Column(
                children: [
                  ..._weeks.asMap().entries.map((entry) {
                    final weekIndex = entry.key;
                    final week = entry.value;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      color: Colors.grey[50],
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Week ${week.weekNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _removeWeek(weekIndex),
                                  tooltip: 'Delete Week',
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
                                    title: Text(day.title ?? 'Day ${day.dayOfWeek}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.add_circle, color: Colors.blue),
                                          onPressed: () => _addOrEditExercise(weekIndex, dayIndex),
                                          tooltip: 'Add Exercise',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                                          onPressed: () => _removeDay(weekIndex, dayIndex),
                                          tooltip: 'Delete Day',
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
                                              title: Text('${ex.exercise?.name ?? "Unknown"}: ${ex.sets}x${ex.reps}'),
                                              subtitle: Text(
                                                '${ex.suggestedLoad != null ? " ${ex.suggestedLoad}kg" : ""}'
                                                '${ex.rest != null ? " | Rest: ${ex.rest}" : ""}'
                                                '${ex.notes != null && ex.notes!.isNotEmpty ? "\n📝 ${ex.notes}" : ""}',
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (ex.videoUrl != null && ex.videoUrl!.isNotEmpty)
                                                    IconButton(
                                                      icon: const Icon(Icons.play_circle_fill, size: 24, color: Colors.red),
                                                      tooltip: 'Watch Video',
                                                      onPressed: () async {
                                                        final url = Uri.parse(ex.videoUrl!);
                                                        if (await canLaunchUrl(url)) {
                                                          await launchUrl(url);
                                                        } else {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(content: Text('Could not launch video URL')),
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
                              label: const Text('Add Day'),
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
                    label: const Text('Add Week'),
                  ),
                ],
              ),
              isActive: _currentStep >= 1,
            ),
          ],
        ),
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

              setState(() => _isLoading = false);
              
              if (success && mounted) {
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(widget.planToEdit != null ? 'Plan updated' : 'Plan created')),
                );
              }
            }
          },
          child: _isLoading 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
            : Text(widget.planToEdit != null ? 'Update Plan' : 'Create Plan', style: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}



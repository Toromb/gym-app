import 'package:flutter/material.dart';
import '../../services/exercise_service.dart';
import '../../models/plan_model.dart';
import 'create_exercise_screen.dart';
import 'exercise_detail_screen.dart';

class ExercisesListScreen extends StatefulWidget {
  const ExercisesListScreen({super.key});

  @override
  State<ExercisesListScreen> createState() => _ExercisesListScreenState();
}

class _ExercisesListScreenState extends State<ExercisesListScreen> {
  final _exerciseService = ExerciseService();
  List<Exercise> _exercises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);
    try {
      final exercises = await _exerciseService.getExercises();
      setState(() {
        _exercises = exercises;
      });
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Biblioteca de Ejercicios')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _exercises.isEmpty
              ? const Center(child: Text('No hay ejercicios registrados.'))
              : ListView.builder(
                  itemCount: _exercises.length,
                  itemBuilder: (context, index) {
                    final ex = _exercises[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(child: Text(ex.name[0])),
                        title: Text(ex.name),
                        subtitle: Text('${ex.muscleGroup} ${ex.type != null ? "• ${ex.type}" : ""}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Ver Detalles',
                              icon: const Icon(Icons.remove_red_eye, color: Colors.green),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => ExerciseDetailScreen(exercise: ex)),
                                );
                                if (result == true) {
                                  _loadExercises();
                                }
                              },
                            ),
                            IconButton(
                              tooltip: 'Editar',
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => CreateExerciseScreen(exercise: ex)),
                                );
                                if (result == true) {
                                  _loadExercises();
                                }
                              },
                            ),
                            IconButton(
                              tooltip: 'Eliminar',
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Confirmar eliminación'),
                                    content: Text('¿Estás seguro de que deseas eliminar "${ex.name}"?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  try {
                                    await _exerciseService.deleteExercise(ex.id);
                                    _loadExercises();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ejercicio eliminado')));
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                        onTap: () async {
                           final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ExerciseDetailScreen(exercise: ex)),
                          );
                          if (result == true) {
                            _loadExercises();
                          }
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateExerciseScreen()),
          );
          if (result == true) {
            _loadExercises();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

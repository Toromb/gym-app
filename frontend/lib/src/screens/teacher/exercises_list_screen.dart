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
  String _searchQuery = '';


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
      body: Column(
        children: [
          _buildSearch(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _getFilteredExercises().isEmpty
                    ? const Center(child: Text('No hay ejercicios registrados.'))
                    : ListView.builder(
                        itemCount: _getFilteredExercises().length,
                        itemBuilder: (context, index) {
                          final ex = _getFilteredExercises()[index];
                          final colorScheme = Theme.of(context).colorScheme;
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2), // Compact margin
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                               borderRadius: BorderRadius.circular(12),
                               side: BorderSide(color: colorScheme.outlineVariant),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Compact padding
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: colorScheme.primaryContainer,
                                    radius: 20, // Smaller avatar
                                    child: Text(
                                      ex.name.isNotEmpty ? ex.name[0].toUpperCase() : '?', 
                                      style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold)
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ex.name, 
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)
                                        ),
                                        Text(
                                          '${ex.muscleGroup} ${ex.type != null ? "• ${ex.type}" : ""}',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        iconSize: 20,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Ver Detalles',
                                        icon: const Icon(Icons.remove_red_eye), // Removed specific colors to match other screens
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
                                      const SizedBox(width: 8),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        iconSize: 20,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Editar',
                                        icon: const Icon(Icons.edit),
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
                                      const SizedBox(width: 8),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        iconSize: 20,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Eliminar',
                                        icon: Icon(Icons.delete_outline, color: colorScheme.error),
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
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
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
  List<Exercise> _getFilteredExercises() {
      if (_searchQuery.isEmpty) return _exercises;
      return _exercises.where((ex) => ex.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  Widget _buildSearch() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
          decoration: InputDecoration(
            hintText: 'Buscar ejercicio por nombre...',
            prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          ),
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
      ),
    );
  }
}

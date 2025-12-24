import 'package:flutter/material.dart';
import '../../services/exercise_api_service.dart';
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
  List<Muscle> _muscles = []; // New
  String? _selectedMuscleId; // New
  bool _isLoading = true;
  String _searchQuery = '';


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Parallel fetch
      final results = await Future.wait([
        _exerciseService.getExercises(muscleId: _selectedMuscleId),
        _exerciseService.getMuscles(), 
      ]);
      
      if (mounted) {
        setState(() {
          _exercises = results[0] as List<Exercise>;
           if (_muscles.isEmpty) {
              _muscles = results[1] as List<Muscle>;
           }
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  // Reload only exercises (e.g. after filter change)
  Future<void> _itemsChanged() async {
     setState(() => _isLoading = true);
     try {
       final ex = await _exerciseService.getExercises(muscleId: _selectedMuscleId);
       setState(() => _exercises = ex);
     } catch(e) { /* ignore */ }
     finally { if(mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Biblioteca de Ejercicios')),
      body: Column(
        children: [
          _buildSearchAndFilter(), // Combined
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
                          
                          // Identify Primary Muscle for display highlight
                          // We use the `muscles` list from the model
                          
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), 
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: colorScheme.primaryContainer,
                                    radius: 20, 
                                    child: Text(
                                      ex.name.isNotEmpty ? ex.name[0].toUpperCase() : '?', 
                                      style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold)
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min, // Fix vertical expansion
                                      children: [
                                        Text(
                                          ex.name, 
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)
                                        ),
                                        const SizedBox(height: 4),
                                        // Muscle Tags
                                        if (ex.muscles.isNotEmpty)
                                          Wrap(
                                            spacing: 4,
                                            runSpacing: 4,
                                            children: ex.muscles.map((m) {
                                                final isPrimary = m.role == 'PRIMARY';
                                                return Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isPrimary ? colorScheme.primary.withOpacity(0.1) : colorScheme.surfaceContainerHighest,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    m.muscle.name,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
                                                      color: isPrimary ? colorScheme.primary : colorScheme.onSurfaceVariant
                                                    ),
                                                  ),
                                                );
                                            }).toList(),
                                          )
                                        else
                                           Text(
                                            'Sin músculos definidos',
                                            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: colorScheme.onSurfaceVariant),
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
                                        icon: const Icon(Icons.remove_red_eye), 
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => ExerciseDetailScreen(exercise: ex)),
                                          );
                                          if (result == true) {
                                            _itemsChanged(); // Refresh
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
                                            _loadData(); // Updated call
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
                                              _loadData(); // Updated call
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
            _loadData(); // Updated call
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

  Widget _buildSearchAndFilter() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Field
              TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar...',
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
              const SizedBox(height: 12),
              // Filter Dropdown
              Container(
                 padding: const EdgeInsets.symmetric(horizontal: 12),
                 decoration: BoxDecoration(
                   color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(color: colorScheme.outline.withOpacity(0.5))
                 ),
                 child: DropdownButtonHideUnderline(
                   child: DropdownButton<String?>(
                     value: _selectedMuscleId,
                     hint: Text('Filtrar por músculo', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                     isExpanded: true, // Safe to use in vertical column
                     icon: Icon(Icons.fitness_center, color: colorScheme.secondary, size: 20),
                     dropdownColor: colorScheme.surface,
                     style: TextStyle(color: colorScheme.onSurface, fontSize: 13),
                     items: [
                       DropdownMenuItem<String?>(
                         value: null, 
                         child: Text('Todos los músculos', style: TextStyle(fontWeight: FontWeight.bold)),
                       ),
                       ..._muscles.map((m) => DropdownMenuItem<String?>(
                         value: m.id, 
                         child: Text(m.name),
                       )),
                     ],
                     onChanged: (val) {
                       setState(() {
                         _selectedMuscleId = val;
                       });
                       _itemsChanged(); // Fetch filtered list
                     },
                   ),
                 ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

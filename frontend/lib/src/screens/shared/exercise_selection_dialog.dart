import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/plan_model.dart';
import '../../providers/plan_provider.dart';

class ExerciseSelectionDialog extends StatefulWidget {
  const ExerciseSelectionDialog({super.key});

  @override
  State<ExerciseSelectionDialog> createState() => _ExerciseSelectionDialogState();
}

class _ExerciseSelectionDialogState extends State<ExerciseSelectionDialog> {
  List<Exercise>? _allExercises;
  List<Exercise>? _filteredExercises;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchExercises();
  }

  Future<void> _fetchExercises() async {
    final exercises = await context.read<PlanProvider>().fetchExercises();
    if (mounted) {
      setState(() {
        _allExercises = exercises;
        _filteredExercises = exercises;
        _isLoading = false;
      });
    }
  }

  void _filter(String query) {
    if (_allExercises == null) return;
    if (query.isEmpty) {
      setState(() => _filteredExercises = _allExercises);
    } else {
      setState(() {
        _filteredExercises = _allExercises!.where((e) {
          return e.name.toLowerCase().contains(query.toLowerCase()) || 
                 e.muscleGroup.toLowerCase().contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Exercise'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             TextField(
               controller: _searchController,
               decoration: const InputDecoration(
                 labelText: 'Search',
                 prefixIcon: Icon(Icons.search),
               ),
               onChanged: _filter,
             ),
             const SizedBox(height: 10),
             Expanded(
               child: _isLoading 
                 ? const Center(child: CircularProgressIndicator())
                 : _filteredExercises!.isEmpty 
                    ? const Center(child: Text('No exercises found'))
                    : ListView.builder(
                        itemCount: _filteredExercises!.length,
                        itemBuilder: (ctx, i) {
                          final ex = _filteredExercises![i];
                          return ListTile(
                            leading: const Icon(Icons.fitness_center),
                            title: Text(ex.name),
                            subtitle: Text(ex.muscleGroup),
                            onTap: () {
                              Navigator.pop(ctx, ex);
                            },
                          );
                        },
                      ),
             ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ],
    );
  }
}

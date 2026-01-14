import 'package:flutter/material.dart';
import '../../../models/free_training_model.dart'; // Keep model just in case? Or remove if unused. kept for types.
// import '../../../services/free_training_service.dart'; // Consumed by Selector internally now.
import '../../student/free_training/free_training_selector_screen.dart';
import 'free_training_editor_screen.dart';

class ManageFreeTrainingsScreen extends StatefulWidget {
  const ManageFreeTrainingsScreen({super.key});

  @override
  State<ManageFreeTrainingsScreen> createState() => _ManageFreeTrainingsScreenState();
}

class _ManageFreeTrainingsScreenState extends State<ManageFreeTrainingsScreen> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FreeTrainingSelectorScreen(
          isAdminMode: true,
          onTrainingSelected: (training) {
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => FreeTrainingEditorScreen(training: training)
              ));
          },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
             Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const FreeTrainingEditorScreen()
              ));
        },
        child: const Icon(Icons.add),
        tooltip: "Crear Nuevo Entrenamiento", // Debug marker
      ),
    );
  }
}

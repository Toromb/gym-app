import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/plan_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';

class AssignPlanModal extends StatefulWidget {
  final User? preselectedStudent;

  const AssignPlanModal({super.key, this.preselectedStudent});

  @override
  State<AssignPlanModal> createState() => _AssignPlanModalState();
}

class _AssignPlanModalState extends State<AssignPlanModal> {
  String? _selectedStudentId;
  String? _selectedPlanId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedStudentId = widget.preselectedStudent?.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchStudents();
      context.read<PlanProvider>().fetchPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Asignar Plan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Consumer<UserProvider>(
              builder: (context, userProvider, _) {
                if (userProvider.isLoading) return const CircularProgressIndicator();
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Seleccionar Alumno'),
                  initialValue: _selectedStudentId,
                  items: userProvider.students
                      .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                      .toList(),
                  onChanged: widget.preselectedStudent == null
                      ? (value) => setState(() => _selectedStudentId = value)
                      : null, // Disable if preselected
                );
              },
            ),
            const SizedBox(height: 16),
            Consumer<PlanProvider>(
              builder: (context, planProvider, _) {
                if (planProvider.isLoading) return const CircularProgressIndicator();
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Seleccionar Plan'),
                  initialValue: _selectedPlanId,
                  items: planProvider.plans
                      .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedPlanId = value),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (_selectedStudentId != null && _selectedPlanId != null) {
                    setState(() => _isLoading = true);
                    final error = await context.read<PlanProvider>().assignPlan(
                          _selectedPlanId!,
                          _selectedStudentId!,
                        );
                    
                    if (!mounted) return;
                    setState(() => _isLoading = false);

                    if (error == null) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Plan asignado exitosamente')),
                        );
                    } else {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Error de Asignación'),
                            content: Text(error),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                    }
                  }
                },
          child: _isLoading ? const CircularProgressIndicator() : const Text('Asignar'),
        ),
      ],
    );
  }
}

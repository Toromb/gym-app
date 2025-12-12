import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/plan_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../models/plan_model.dart';

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
      title: const Text('Assign Plan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Consumer<UserProvider>(
              builder: (context, userProvider, _) {
                if (userProvider.isLoading) return const CircularProgressIndicator();
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Select Student'),
                  value: _selectedStudentId,
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
                  decoration: const InputDecoration(labelText: 'Select Plan'),
                  value: _selectedPlanId,
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
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (_selectedStudentId != null && _selectedPlanId != null) {
                    setState(() => _isLoading = true);
                    final success = await context.read<PlanProvider>().assignPlan(
                          _selectedPlanId!,
                          _selectedStudentId!,
                        );
                    setState(() => _isLoading = false);
                    if (success && mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Plan assigned successfully')),
                      );
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to assign plan')),
                      );
                    }
                  }
                },
          child: _isLoading ? const CircularProgressIndicator() : const Text('Assign'),
        ),
      ],
    );
  }
}

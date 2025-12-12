import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/plan_provider.dart';
import '../../models/user_model.dart';
import 'package:intl/intl.dart';

class StudentPlansScreen extends StatefulWidget {
  final User student;

  const StudentPlansScreen({super.key, required this.student});

  @override
  State<StudentPlansScreen> createState() => _StudentPlansScreenState();
}

class _StudentPlansScreenState extends State<StudentPlansScreen> {
  // We can perform the fetch directly here or add a method to PlanProvider.
  // Given PlanProvider usually manages state, let's see if we can just fetch.
  // For simplicity and since this feels like a specific admin view, we'll fetch via context read of service or just use future builder.
  // Actually, let's use the Service directly or add a getter in provider. 
  // Code cleanliness: Use PlanProvider. BUT PlanProvider currently stores "plans" (global).
  // Storing "studentAssignments" in global provider might be messy.
  // Let's use a FutureBuilder here with the Service for now, accessed via Provider context if possible or direct instantiation if needed.
  // We should prefer using the Provider if we want to centralize logic.
  // Let's call the service method we just added. We can access the service via the Provider if it exposes it, or just create instance/import.
  // The PlanProvider probably holds the service. Let's assume we can add a method to PlanProvider wrapper or just use Service.
  // Let's modify PlanProvider to expose a `getAssignments` method? Or just use service. 
  // Let's use FutureBuilder wrapping the service call for now.
  
  // Wait, I should probably add `getStudentPlans` to PlanProvider to be consistent.
  // But to avoid too many file edits, I will construct a `plan_service` instance here or get it from context if avail.
  // Ideally: Provider.of<PlanService>(context) if registered.
  // For MVP speed: Import PlanService.
  
  List<dynamic>? _assignments;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAssignments();
  }

  Future<void> _fetchAssignments() async {
    setState(() => _isLoading = true);
    try {
      // Assuming we can get PlanProvider or Service.
      // Let's rely on PlanProvider exposing assignment fetching or just use the service instance if simpler.
      // I will update PlanProvider quickly to include this passthrough or just use the service manually.
      // Let's Import PlanService (it's stateless mostly).
      final assignments = await context.read<PlanProvider>().fetchStudentAssignments(widget.student.id!);
      setState(() {
        _assignments = assignments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Plans: ${widget.student.firstName}')),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _assignments == null || _assignments!.isEmpty
              ? const Center(child: Text('No plans assigned.'))
              : ListView.builder(
                  itemCount: _assignments!.length,
                  itemBuilder: (context, index) {
                    final assignment = _assignments![index];
                    final plan = assignment['plan'];
                    final isActive = assignment['isActive'] == true;
                    final assignedAt = assignment['assignedAt'];

                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        leading: Icon(Icons.assignment, color: isActive ? Colors.green : Colors.grey),
                        title: Text(plan['name'] ?? 'Unnamed Plan'),
                        subtitle: Text('Assigned: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(assignedAt))}\nStatus: ${isActive ? "Active" : "Inactive"}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(assignment['id']),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _confirmDelete(String assignmentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Assignment'),
        content: const Text('Are you sure you want to remove this plan from the student? This will not delete the plan itself.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              setState(() => _isLoading = true);
              final success = await context.read<PlanProvider>().deleteAssignment(assignmentId);
              if (success) {
                _fetchAssignments(); // Refresh
                if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assignment removed')));
                }
              } else {
                setState(() => _isLoading = false);
                if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to remove')));
                }
              }
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

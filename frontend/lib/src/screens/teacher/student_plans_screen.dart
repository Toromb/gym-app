import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/plan_provider.dart';
import '../../models/user_model.dart';
import '../../models/student_assignment_model.dart';
import '../shared/plan_details_screen.dart';
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
      final assignments = await context.read<PlanProvider>().fetchStudentAssignments(widget.student.id);
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
    // Filter assignments
    final activeAssignments = _assignments?.where((a) => a['isActive'] == true).toList() ?? [];
    final historyAssignments = _assignments?.where((a) => a['isActive'] != true).toList() ?? [];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Planes: ${widget.student.firstName}'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Planes Asignados'),
              Tab(text: 'Historial'),
            ],
          ),
        ),
        body: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildassignmentsList(activeAssignments, true),
                  _buildassignmentsList(historyAssignments, false),
                ],
              ),
      ),
    );
  }

  Widget _buildassignmentsList(List<dynamic> assignments, bool isActiveList) {
    if (assignments.isEmpty) {
      return Center(child: Text(isActiveList ? 'No hay planes activos.' : 'No hay historial de planes.'));
    }

    return ListView.builder(
      itemCount: assignments.length,
      itemBuilder: (context, index) {
        final assignment = assignments[index];
        final plan = assignment['plan'];
        final isActive = assignment['isActive'] == true;
        final assignedAt = assignment['assignedAt'];

        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            leading: Icon(Icons.assignment, color: isActive ? Colors.green : Colors.grey),
            title: Text(plan['name'] ?? 'Plan sin nombre'),
            subtitle: Text('Asignado: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(assignedAt))}\nEstado: ${isActive ? "Activo" : "Finalizado"}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.blue),
                  onPressed: () async {
                      // Fetch full plan details
                      final planId = plan['id'];
                      final fullPlan = await context.read<PlanProvider>().getPlanById(planId);
                      
                      if (fullPlan != null && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlanDetailsScreen(
                              plan: fullPlan, 
                              readOnly: true,
                              canEdit: false,
                              assignment: StudentAssignment.fromJson(assignment), 
                              studentId: widget.student.id, 
                            ),
                          ),
                        );
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error cargando detalles del plan')));
                      }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(assignment['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(String assignmentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Asignación'),
        content: const Text('¿Estás seguro de que quieres eliminar este plan del alumno? Esto no eliminará el plan en sí.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              setState(() => _isLoading = true);
              final success = await context.read<PlanProvider>().deleteAssignment(assignmentId);
              if (success) {
                _fetchAssignments(); // Refresh
                if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asignación eliminada')));
                }
              } else {
                setState(() => _isLoading = false);
                if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al eliminar')));
                }
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

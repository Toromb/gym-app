import 'package:flutter/material.dart';
import '../../widgets/constrained_app_bar.dart';
import 'package:provider/provider.dart';
import '../../providers/plan_provider.dart';
import '../../models/completed_plan_model.dart';
import '../../models/user_model.dart';
import '../../models/student_assignment_model.dart';
import '../../models/execution_model.dart';
import '../../models/plan_model.dart';
import '../../utils/app_colors.dart';
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
  List<CompletedPlan>? _history;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAssignments();
  }

  Future<void> _fetchAssignments() async {
    setState(() => _isLoading = true);
    try {
      final assignments = await context
          .read<PlanProvider>()
          .fetchStudentAssignments(widget.student.id);
      final history = await context
          .read<PlanProvider>()
          .fetchStudentHistory(widget.student.id);
      
      if (mounted) {
        setState(() {
          _assignments = assignments;
          _history = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    // No filtramos nada de las asignaciones, mostramos TODAS (Vivas/Pendientes)
    final allAssignments = _assignments ?? [];
    final historyList = _history ?? [];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: ConstrainedAppBar(
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
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: TabBarView(
                    children: [
                      _buildAssignmentsList(allAssignments),
                      _buildHistoryList(historyList),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildAssignmentsList(List<dynamic> assignments) {
    if (assignments.isEmpty) {
      return const Center(child: Text('No hay planes asignados ni pendientes.'));
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
            leading: Icon(
              isActive ? Icons.play_circle_filled : Icons.pause_circle_outline,
              color: isActive ? Colors.green : Colors.orange,
              size: 32,
            ),
            title: Text(plan['name'] ?? 'Plan sin nombre'),
            subtitle: Text(
                'Asignado: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(assignedAt))}\nEstado: ${isActive ? "ACTIVO" : "PENDIENTE/REUTILIZABLE"}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.blue),
                  onPressed: () {
                    // Fetch full plan details
                    try {
                      final fullPlan = Plan.fromJson(plan);
                      if (context.mounted) {
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
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Error cargando detalles del plan')));
                      }
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  onPressed: () => _confirmCancel(assignment['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryList(List<CompletedPlan> history) {
    if (history.isEmpty) {
      return const Center(child: Text('No hay historial de planes.'));
    }

    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (context, index) {
        final plan = history[index];
        return _buildHistoryCard(plan, context);
      },
    );
  }

  Widget _buildHistoryCard(CompletedPlan plan, BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          plan.planNameSnapshot,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${plan.translatedReason} • ${plan.formattedStartDate} - ${plan.formattedEndDate}',
              style: textTheme.bodySmall?.copyWith(color: AppColors.textSoft),
            ),
            const SizedBox(height: 4),
            Text(
              '${plan.sessions.length} sesiones realizadas',
              style: textTheme.bodySmall?.copyWith(color: AppColors.textMain),
            ),
          ],
        ),
        children: plan.sessions.map((session) {
          return Container(
            color: Colors.black.withValues(alpha: 0.1),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sesión ${session.date} (${session.status})',
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...session.exercises.map((ex) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: AppColors.accent)),
                        Expanded(
                          child: Text(
                            '${ex.exerciseNameSnapshot}: ${_buildMetricsString(ex)}',
                            style: textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _buildMetricsString(SessionExercise ex) {
    String metricType = ex.exercise?.metricType ?? 'REPS';
    if (ex.exercise == null) {
      if (ex.targetTimeSnapshot != null || ex.timeSpent != null) metricType = 'TIME';
      if (ex.targetDistanceSnapshot != null || ex.distanceCovered != null) metricType = 'DISTANCE';
    }

    bool isBodyWeight = ex.equipmentsSnapshot.any((e) => e.isBodyWeight) ||
        (ex.exercise?.equipments.any((e) => e.isBodyWeight) ?? false);

    final setsStr = '${ex.setsDone ?? '-'} series';

    if (metricType == 'DISTANCE') {
      return '$setsStr • ${ex.distanceCovered ?? '-'} m';
    }

    if (metricType == 'TIME') {
      final timeStr = '${ex.timeSpent ?? '-'} seg';
      if (isBodyWeight) {
        return '$setsStr • $timeStr • Peso corporal';
      } else if (ex.weightUsed != null && ex.weightUsed!.isNotEmpty && ex.weightUsed != '0') {
        return '$setsStr • $timeStr • ${ex.weightUsed} kg';
      }
      return '$setsStr • $timeStr'; // No weight info
    }

    // Default: REPS
    final repsStr = '${ex.repsDone ?? '-'} reps';
    if (isBodyWeight) {
      return '$setsStr • $repsStr • Peso corporal';
    } else {
      String weightStr = '';
      if (ex.weightUsed != null && ex.weightUsed!.isNotEmpty) {
        weightStr = ' • ${ex.weightUsed} kg';
      } else {
        weightStr = ' • - kg';
      }
      return '$setsStr • $repsStr$weightStr';
    }
  }

  void _confirmCancel(String assignmentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Ciclo de Plan'),
        content: const Text(
            '¿Estás seguro de que quieres cancelar el ciclo en curso de este plan? El plan quedará disponible para reasignarse y el progreso actual se guardará en el historial.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              setState(() => _isLoading = true);
              final success = await context
                  .read<PlanProvider>()
                  .deleteAssignment(assignmentId);
              if (success) {
                _fetchAssignments(); // Refresh
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ciclo cancelado correctamente')));
                }
              } else {
                setState(() => _isLoading = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error al cancelar el ciclo')));
                }
              }
            },
            child: const Text('Sí, Cancelar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

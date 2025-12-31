import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/plan_provider.dart';
import '../shared/day_detail_screen.dart';
import '../../localization/app_localizations.dart';

class StudentPlanScreen extends StatefulWidget {
  const StudentPlanScreen({super.key});

  @override
  State<StudentPlanScreen> createState() => _StudentPlanScreenState();
}

class _StudentPlanScreenState extends State<StudentPlanScreen> {

  @override
  void initState() {
    super.initState();
    // Fetch history to get the active assignment structure (ID needed for restart)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlanProvider>().fetchMyHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Plan Actual'),
      ),
      body: Consumer<PlanProvider>(
        builder: (context, planProvider, _) {
          if (planProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final assignment = planProvider.activeAssignment;
          // Fallback to _myPlan if assignment not explicitly calculated but myPlan exists (legacy)
          final plan = assignment?.plan ?? planProvider.myPlan;
          
          if (plan == null) {
            return const Center(child: Text('No hay plan asignado.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPlanSummaryCard(context, plan, assignment?.id),
                const SizedBox(height: 24),
                const Text('Cronograma Semanal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...plan.weeks.map((week) => _buildWeekCard(context, week, plan.id!)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlanSummaryCard(BuildContext context, dynamic plan, String? assignmentId) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan Actual',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plan.name,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (assignmentId != null) 
                 IconButton(
                   icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
                   onPressed: () => _confirmRestart(context, assignmentId),
                   tooltip: 'Reiniciar Plan',
                 ),
            ],
          ),
          if (plan.objective != null) ...[
            const SizedBox(height: 8),
             Chip(
               label: Text(plan.objective!),
               backgroundColor: Colors.white, 
               labelStyle: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
               side: BorderSide.none,
             ),
          ],
        ],
      ),
    );
  }

  void _confirmRestart(BuildContext context, String assignmentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reiniciar Plan'),
        content: const Text(
          '¿Estás seguro de que deseas reiniciar este plan? \n\n'
          'Se borrarán los checks de progreso actual, pero tu historial de ejecuciones se guardará para que puedas consultarlo en el calendario.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await context.read<PlanProvider>().restartPlan(assignmentId);
              if (success && context.mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('El plan se ha reiniciado correctamente.')),
                 );
              } else if (context.mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Error al reiniciar el plan.')),
                 );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekCard(BuildContext context, dynamic week, String planId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text('${AppLocalizations.of(context)!.get('week').toUpperCase()} ${week.weekNumber}', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
        ),
        ...week.days.map<Widget>((day) => _buildDayCard(context, day, planId, week.weekNumber)).toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDayCard(BuildContext context, dynamic day, String planId, int weekNumber) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DayDetailScreen(
                day: day, 
                planId: planId,
                weekNumber: weekNumber,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_today, color: Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day.title ?? 'Día ${day.dayOfWeek}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${day.exercises.length} Ejercicios',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

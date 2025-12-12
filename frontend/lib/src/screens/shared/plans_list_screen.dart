import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/plan_provider.dart';
import '../../models/plan_model.dart';
import 'package:intl/intl.dart';
import '../teacher/create_plan_screen.dart';

class PlansListScreen extends StatefulWidget {
  const PlansListScreen({super.key});

  @override
  State<PlansListScreen> createState() => _PlansListScreenState();
}

class _PlansListScreenState extends State<PlansListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlanProvider>().fetchPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plans Library')),
      body: Consumer<PlanProvider>(
        builder: (context, planProvider, _) {
          if (planProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (planProvider.plans.isEmpty) {
            return const Center(child: Text('No plans found.'));
          }

          // Group plans by creator
          final Map<String, List<Plan>> groupedPlans = {};
          
          for (var plan in planProvider.plans) {
            final creatorName = plan.teacher != null 
                ? '${plan.teacher!.firstName} ${plan.teacher!.lastName}' 
                : 'Sin Autor'; // Or "Unknown"
            
            if (!groupedPlans.containsKey(creatorName)) {
              groupedPlans[creatorName] = [];
            }
            groupedPlans[creatorName]!.add(plan);
          }
          
          // Sort keys (Creators) potentially? Or keep order of appearance? 
          // Let's sort alphabetically for cleanliness
          final sortedKeys = groupedPlans.keys.toList()..sort();

          return ListView.builder(
            itemCount: sortedKeys.length,
            itemBuilder: (context, index) {
              final creatorName = sortedKeys[index];
              final plans = groupedPlans[creatorName]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, creatorName, plans.length),
                  ...plans.map((plan) => _buildPlanCard(context, plan)).toList(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        '$title ($count)',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, Plan plan) {
    final date = plan.createdAt != null
        ? DateFormat('yyyy-MM-dd').format(DateTime.parse(plan.createdAt!))
        : 'N/A';
    
    // We don't need to show "By: Creator" inside the card anymore since it's grouped header, 
    // but maybe keep it? Requirement implies separation is key. I'll remove redundancy if implied.
    // Keeping it doesn't hurt.
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plan.name, style: Theme.of(context).textTheme.titleLarge),
            if (plan.objective != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Objective: ${plan.objective}', style: Theme.of(context).textTheme.bodyMedium),
              ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Text('By: $creator', style: Theme.of(context).textTheme.bodySmall), // Redundant?
                Text('Created: $date', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDeletePlan(context, plan),
                  tooltip: 'Delete Plan',
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _showPlanDetails(context, plan),
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPlanDetails(BuildContext context, Plan plan) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(plan.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: plan.weeks.map((week) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Week ${week.weekNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ...week.days.map((day) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 16.0, top: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(day.title ?? 'Day ${day.dayOfWeek}'),
                                  ...day.exercises.map((ex) {
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 16.0),
                                      child: Text('- ${ex.exercise?.name ?? 'Exercise'}: ${ex.sets}x${ex.reps}'),
                                    );
                                  }),
                                ],
                              ),
                            );
                          }),
                          const Divider(),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                      TextButton(
                        onPressed: () {
                           Navigator.pop(context);
                           Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CreatePlanScreen(planToEdit: plan)),
                           );
                        },
                        child: const Text('Edit Plan'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                   ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _confirmDeletePlan(BuildContext context, Plan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan'),
        content: Text('Are you sure you want to delete "${plan.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context.read<PlanProvider>().deletePlan(plan.id!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Plan deleted' : 'Failed to delete plan. You may only delete your own plans.')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

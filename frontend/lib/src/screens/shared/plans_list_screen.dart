import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../localization/app_localizations.dart';
import '../../providers/plan_provider.dart';
import '../../models/plan_model.dart';
import 'package:intl/intl.dart';
import '../teacher/create_plan_screen.dart';
import 'plan_details_screen.dart';

class PlansListScreen extends StatefulWidget {
  const PlansListScreen({super.key});

  @override
  State<PlansListScreen> createState() => _PlansListScreenState();
}

class _PlansListScreenState extends State<PlansListScreen> {
  String _searchQuery = '';

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
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.get('plansLibrary'))),
      body: Consumer<PlanProvider>(
        builder: (context, planProvider, _) {
          if (planProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (planProvider.plans.isEmpty) {
            return Center(child: Text(AppLocalizations.of(context)!.get('noPlansFound')));
          }

          // Group plans by creator
          final Map<String, List<Plan>> groupedPlans = {};
          
          for (var plan in planProvider.plans) {
            // Search Filter
            if (_searchQuery.isNotEmpty && !plan.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
               continue;
            }

            final creatorName = plan.teacher != null 
                ? '${plan.teacher!.firstName} ${plan.teacher!.lastName}' 
                : AppLocalizations.of(context)!.get('withoutAuthor');
            
            if (!groupedPlans.containsKey(creatorName)) {
              groupedPlans[creatorName] = [];
            }
            groupedPlans[creatorName]!.add(plan);
          }
          
          final sortedKeys = groupedPlans.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemBuilder: (context, index) {
              // Header index
              if (index == 0) {
                 return _buildSearch();
              }
              final creatorName = sortedKeys[index - 1]; // Offset by 1 for search
              final plans = groupedPlans[creatorName]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, creatorName, plans.length),
                  ...plans.map((plan) => _buildPlanCard(context, plan)).toList(),
                ],
              );
            },
            itemCount: sortedKeys.length + 1, // +1 for Search
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePlanScreen()),
          );
          if (result == true && context.mounted) {
            context.read<PlanProvider>().fetchPlans();
          }
        },
        child: const Icon(Icons.add),
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

  Widget _buildSearch() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
          decoration: InputDecoration(
            hintText: 'Buscar plan por nombre...',
            prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, Plan plan) {
    final date = plan.createdAt != null
        ? DateFormat('yyyy-MM-dd').format(DateTime.parse(plan.createdAt!))
        : 'N/A';
    
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2), // Compact margin
      elevation: 0,
      shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(12),
         side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Compact padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(plan.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)), // Smaller title
                ),
                if (plan.objective != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      plan.objective ?? 'General',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.onSecondaryContainer),
                    ),
                  ),
              ],
            ),
             const SizedBox(height: 8),
             Text(
                '${AppLocalizations.of(context)!.get('created')} $date', 
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)
             ),
             const SizedBox(height: 12),
             const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showPlanDetails(context, plan),
                  icon: const Icon(Icons.visibility, size: 16), // Smaller icon
                  label: Text(AppLocalizations.of(context)!.get('viewDetails'), style: const TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // Compact layout
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDeletePlan(context, plan),
                  tooltip: AppLocalizations.of(context)!.get('deletePlanTitle'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPlanDetails(BuildContext context, Plan plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlanDetailsScreen(plan: plan, readOnly: true),
      ),
    );
  }
  void _confirmDeletePlan(BuildContext context, Plan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.get('deletePlanTitle')),
        content: Text(AppLocalizations.of(context)!.get('deletePlanConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.get('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final error = await context.read<PlanProvider>().deletePlan(plan.id!);
              if (mounted) {
                if (error == null) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.get('deletePlanSuccess'))),
                   );
                } else {
                   // Show error dialog for conflicts (assigned plans)
                   showDialog(
                     context: context,
                     builder: (context) => AlertDialog(
                       title: Text(AppLocalizations.of(context)!.get('error')),
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
            child: Text(AppLocalizations.of(context)!.get('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

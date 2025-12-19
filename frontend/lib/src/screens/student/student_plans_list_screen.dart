import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/plan_provider.dart';
import '../../models/plan_model.dart'; // Keep for Plan refs if needed
import '../../models/student_assignment_model.dart';
import '../../utils/app_colors.dart'; // Corrected path
import 'package:intl/intl.dart';
import '../../localization/app_localizations.dart';
import '../shared/plan_details_screen.dart';
import '../shared/day_detail_screen.dart';

class StudentPlansListScreen extends StatefulWidget {
  const StudentPlansListScreen({super.key});

  @override
  State<StudentPlansListScreen> createState() => _StudentPlansListScreenState();
}

class _StudentPlansListScreenState extends State<StudentPlansListScreen> {
  bool _isLoading = true;
  List<StudentAssignment> _assignments = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await context.read<PlanProvider>().fetchMyHistory();
    if (mounted) {
      setState(() {
        _assignments = history.where((a) => a.isActive).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.get('navPlans'))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assignments.isEmpty
              ? Center(child: Text(AppLocalizations.of(context)!.get('noPlans')))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _assignments.length,
                  itemBuilder: (context, index) {
                    final assignment = _assignments[index];
                    final plan = assignment.plan;
                    final isActive = assignment.isActive;
                    final assignedDate = assignment.assignedAt != null
                        ? DateFormat.yMMMd(AppLocalizations.of(context)!.locale.languageCode).format(DateTime.parse(assignment.assignedAt!))
                        : 'Unknown Date';

                    final colorScheme = Theme.of(context).colorScheme;
                    final textTheme = Theme.of(context).textTheme;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlanDetailsScreen(
                                  plan: plan, 
                                  canEdit: false,
                                  assignment: assignment, 
                              ),
                            ),
                          ).then((_) => _loadHistory()); 
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      plan.name,
                                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Container(
                                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                     decoration: BoxDecoration(
                                       color: AppColors.success.withOpacity(0.1), 
                                       borderRadius: BorderRadius.circular(20),
                                       border: Border.all(color: AppColors.success.withOpacity(0.2)),
                                     ),
                                     child: Text(
                                       AppLocalizations.of(context)!.get('statusActive'), 
                                       style: textTheme.labelSmall?.copyWith(color: AppColors.success, fontWeight: FontWeight.bold)
                                     ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (plan.objective != null)
                                Text(
                                  '${AppLocalizations.of(context)!.get('objective')} ${plan.objective}', 
                                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)
                                ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 16, color: colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${AppLocalizations.of(context)!.get('assignedOn')} $assignedDate', 
                                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

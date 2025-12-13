import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/plan_provider.dart';
import '../../models/plan_model.dart';
import 'package:intl/intl.dart';
import '../shared/plan_details_screen.dart';

class StudentPlansListScreen extends StatefulWidget {
  const StudentPlansListScreen({super.key});

  @override
  State<StudentPlansListScreen> createState() => _StudentPlansListScreenState();
}

class _StudentPlansListScreenState extends State<StudentPlansListScreen> {
  bool _isLoading = true;
  List<dynamic> _assignments = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await context.read<PlanProvider>().fetchMyHistory();
    if (mounted) {
      setState(() {
        _assignments = history;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Plans')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assignments.isEmpty
              ? const Center(child: Text('No plans assigned yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _assignments.length,
                  itemBuilder: (context, index) {
                    final assignment = _assignments[index];
                    final planJson = assignment['plan'];
                    final plan = Plan.fromJson(planJson);
                    final isActive = assignment['isActive'] == true;
                    final assignedDate = assignment['assignedAt'] != null
                        ? DateFormat('MMM d, yyyy').format(DateTime.parse(assignment['assignedAt']))
                        : 'Unknown Date';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlanDetailsScreen(plan: plan, canEdit: false),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      plan.name,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                     decoration: BoxDecoration(
                                       color: Colors.green[100],
                                       borderRadius: BorderRadius.circular(12),
                                     ),
                                     child: const Text('ACTIVE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (plan.objective != null)
                                Text('Objective: ${plan.objective}', style: TextStyle(color: Colors.grey[700])),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 6),
                                  Text('Assigned on: $assignedDate', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
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

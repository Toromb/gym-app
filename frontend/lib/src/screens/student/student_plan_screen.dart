import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/plan_provider.dart';
import '../shared/day_detail_screen.dart';

class StudentPlanScreen extends StatefulWidget {
  const StudentPlanScreen({super.key});

  @override
  State<StudentPlanScreen> createState() => _StudentPlanScreenState();
}

class _StudentPlanScreenState extends State<StudentPlanScreen> {

  @override
  void initState() {
    super.initState();
    // Fetch plan on init to ensure fresh data if navigated directly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlanProvider>().fetchMyPlan();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Current Plan'),
      ),
      body: Consumer<PlanProvider>(
        builder: (context, planProvider, _) {
          if (planProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final plan = planProvider.myPlan;
          
          if (plan == null) {
            return const Center(child: Text('No plan assigned.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPlanSummaryCard(context, plan),
                const SizedBox(height: 24),
                const Text('Weekly Schedule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...plan.weeks.map((week) => _buildWeekCard(context, week)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlanSummaryCard(BuildContext context, dynamic plan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Plan',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            plan.name,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          if (plan.objective != null) ...[
            const SizedBox(height: 8),
             // FIX: Changed background and text color for better contrast
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

  Widget _buildWeekCard(BuildContext context, dynamic week) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(week.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
        ),
        ...week.days.map<Widget>((day) => _buildDayCard(context, day)).toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDayCard(BuildContext context, dynamic day) {
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
              builder: (context) => DayDetailScreen(day: day),
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
                      day.title ?? 'Day ${day.dayOfWeek}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${day.exercises.length} Exercises',
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

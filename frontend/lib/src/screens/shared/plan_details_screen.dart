import 'package:flutter/material.dart';
import '../../models/plan_model.dart';
import 'day_detail_screen.dart';
import '../teacher/create_plan_screen.dart';

class PlanDetailsScreen extends StatelessWidget {
  final Plan plan;
  final bool canEdit;

  const PlanDetailsScreen({super.key, required this.plan, this.canEdit = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(plan.name),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreatePlanScreen(planToEdit: plan)),
                ).then((_) {
                  // If we need to refresh, usually the parent list handles it or we use provider.
                  // Since this screen just displays the passed Plan object, it won't auto-update if edited
                  // unless we re-fetch or pop. For now, pop is robust.
                  // Navigator.pop(context); // Optional: close detail on edit start or keep open?
                  // Better: keep it open but it might show stale data until refreshed. 
                  // Let's just leave it, user can back out.
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
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
      ),
    );
  }

  Widget _buildPlanSummaryCard(BuildContext context, Plan plan) {
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
            'Plan Overview',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            plan.name,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
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
          if (plan.durationWeeks > 0) ...[
             const SizedBox(height: 8),
             Text(
               'Duration: ${plan.durationWeeks} Weeks',
               style: const TextStyle(color: Colors.white70),
             ),
          ]
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

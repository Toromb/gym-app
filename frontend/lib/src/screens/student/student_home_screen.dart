import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/plan_provider.dart';
import '../../providers/auth_provider.dart';
import 'day_detail_screen.dart';
import '../shared/gym_schedule_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlanProvider>().fetchMyPlan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Gym Plan'),
         actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: Consumer<PlanProvider>(
        builder: (context, planProvider, _) {
          if (planProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final plan = planProvider.myPlan;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${user?.firstName ?? "Student"}!',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 20),
                if (plan == null) 
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: Text('No plan assigned yet. Ask your professor!')),
                    ),
                  )
                else
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.assignment, size: 30, color: Colors.blue),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(plan.name, style: Theme.of(context).textTheme.headlineSmall),
                              ),
                            ],
                          ),
                          if (plan.objective != null) ...[
                            const SizedBox(height: 8),
                            Text('Objective: ${plan.objective}', style: Theme.of(context).textTheme.bodyMedium),
                          ],
                          const Divider(height: 30),
                          const Text('Weekly Schedule:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          ...plan.weeks.map((week) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ExpansionTile(
                              title: Text(week.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              backgroundColor: Colors.grey[50],
                              collapsedBackgroundColor: Colors.grey[50], // Consistent look
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              children: week.days
                                  .map((day) => ListTile(
                                        title: Text(day.title ?? 'Day ${day.dayOfWeek}'),
                                        subtitle: Text('${day.exercises.length} exercises'),
                                        trailing: const Icon(Icons.chevron_right),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => DayDetailScreen(day: day),
                                            ),
                                          );
                                        },
                                      ))
                                  .toList(),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20), // Spacing between plan card and new cards
                _buildDashboardCard(
                  context,
                  title: 'My Profile',
                  icon: Icons.person,
                  onTap: () {
                       // Navigate to profile
                  },
                ),
                const SizedBox(height: 16),
                _buildDashboardCard(
                  context,
                  title: 'Gym Schedule',
                  icon: Icons.access_time,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const GymScheduleScreen()),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context,
      {required String title, required IconData icon, required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Theme.of(context).primaryColor),
              const SizedBox(width: 20),
              Text(title, style: const TextStyle(fontSize: 20)),
            ],
          ),
        ),
      ),
    );
  }
}

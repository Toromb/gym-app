
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/stats_provider.dart';

class PlatformStatsScreen extends StatefulWidget {
  const PlatformStatsScreen({super.key});

  @override
  State<PlatformStatsScreen> createState() => _PlatformStatsScreenState();
}

class _PlatformStatsScreenState extends State<PlatformStatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatsProvider>().fetchStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Stats'),
      ),
      body: Consumer<StatsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text(provider.error!));
          }

          final stats = provider.stats;
          if (stats == null) {
            return const Center(child: Text('No stats available'));
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildStatCard(
                icon: Icons.fitness_center,
                label: 'Total Gyms',
                value: stats.totalGyms.toString(),
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                icon: Icons.check_circle,
                label: 'Active Gyms',
                value: stats.activeGyms.toString(),
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                icon: Icons.people,
                label: 'Total Users',
                value: stats.totalUsers.toString(),
                color: Colors.orange,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.2),
              radius: 30,
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

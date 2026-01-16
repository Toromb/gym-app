import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/stats_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/user_service.dart'; // Import UserService
import '../../../models/user_model.dart';
import '../../../models/stats_model.dart';
import '../../../models/onboarding_model.dart'; // Import OnboardingModel
import '../../../services/onboarding_service.dart'; // Import Service
import '../../../services/api_client.dart'; // Import Client
import '../../../theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart'; // Import for firstWhereOrNull
import '../calendar_screen.dart'; // Import CalendarScreen for embedding

class ProfileProgressScreen extends StatefulWidget {
  final String? userId; // Optional: If null, shows current user's progress

  const ProfileProgressScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<ProfileProgressScreen> createState() => _ProfileProgressScreenState();
}

class _ProfileProgressScreenState extends State<ProfileProgressScreen> {
  String? _fallbackGoal; // State to hold fetched goal

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final statsProvider = Provider.of<StatsProvider>(context, listen: false);
    await statsProvider.fetchProgress(userId: widget.userId);

    // Check if we need to fetch goal
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userService = UserService(); // Instantiate locally for specific fetch
    
    User? targetUser;
    
    if (widget.userId == null) {
        // Force refresh current user info to get latest fields (like trainingGoal)
        // AuthProvider might be stale if it only loaded on login.
        print('ProfileProgress: Improving data freshness for current user...');
        try {
             final freshUser = await userService.getProfile();
             if (freshUser != null) {
                 // Update the local resolved user. 
                 // Note: This won't update AuthProvider unless we call refreshUser on it, 
                 // but for this screen's purpose, we just need the data.
                 authProvider.refreshUser(); // Should update global state too
                 // user = freshUser; // Removed erroneous line
                 targetUser = freshUser;
             } else {
                 targetUser = authProvider.user; // Fallback
             }
        } catch (e) {
             print('ProfileProgress: Error refreshing profile: $e');
             targetUser = authProvider.user;
        }
    } else {
        targetUser = userProvider.students.firstWhereOrNull((u) => u.id == widget.userId);
    }
    
    if (targetUser != null && (targetUser.trainingGoal == null || targetUser.trainingGoal!.isEmpty)) {
        print('ProfileProgress: User goal IS STILL missing after refresh. Fetching onboarding...');
        try {
            final service = OnboardingService(ApiClient()); 
            final profile = await service.getUserOnboarding(targetUser.id);
            print('ProfileProgress: Onboarding result: ${profile?.goal}');
            if (profile != null && profile.goal != null) {
                if (mounted) {
                    setState(() {
                        _fallbackGoal = profile.goal;
                    });
                }
            }
        } catch (e) {
            print('ProfileProgress: Error fetching fallback goal: $e');
        }
    } else {
        print('ProfileProgress: User goal IS present: ${targetUser?.trainingGoal}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsProvider = Provider.of<StatsProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    
    User? user;
    if (widget.userId == null) {
      // Prioritize AuthProvider for current user to ensure we have the latest profile data including onboarding
      user = authProvider.user; 
    } else {
      try {
        user = userProvider.students.firstWhere((u) => u.id == widget.userId);
      } catch (_) {
        user = null;
      }
    }

    final progress = statsProvider.progress;
    final isLoading = statsProvider.isLoading;

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (progress == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi Progreso')),
        body: const Center(child: Text('No se pudieron cargar los datos de progreso.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Progreso'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _safelyBuild(() => _buildOnboardingSection(user)),
                const SizedBox(height: 24),
                _safelyBuild(() => const CalendarScreen(isEmbedded: true)), // Embedded Calendar
                const SizedBox(height: 24),
                _safelyBuild(() => _buildStatusCards(progress)),
                const SizedBox(height: 24),
                _safelyBuild(() => _buildVolumeChart(progress.volume)),
                // Muscle Load removed for V1
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _safelyBuild(Widget Function() builder) {
      try {
          return builder();
      } catch (e, stack) {
          debugPrint('UI Error: $e\n$stack');
          return Container(
            color: Colors.red.shade100, 
            padding: const EdgeInsets.all(8), 
            child: Text('Error de renderizado: $e', style: const TextStyle(color: Colors.red))
          );
      }
  }

  Widget _buildOnboardingSection(User? user) {
    if (user == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Perfil Inicial',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow('Objetivo', user.trainingGoal ?? _fallbackGoal ?? 'No definido'),
            _buildInfoRow('Experiencia', 'Nivel Intermedio'), // Hardcoded/Logic needed if logic in FE
            _buildInfoRow('Frecuencia', '3 veces por semana'), // Hardcoded/Logic needed
            _buildInfoRow('Inicio', user.membershipStartDate ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    // Basic translation map for known goals
    const goalTranslations = {
      'sport': 'Deporte',
      'health': 'Salud',
      'aesthetics': 'Estética',
      'strength': 'Fuerza',
      'hypertrophy': 'Hipertrofia',
      'endurance': 'Resistencia',
      'flexibility': 'Flexibilidad',
      'weight_loss': 'Pérdida de peso',
      'general': 'General',
    };

    final translatedValue = goalTranslations[value.toLowerCase()] ?? value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(translatedValue, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatusCards(UserProgress progress) {
    final width = MediaQuery.of(context).size.width;
    double aspectRatio = 1.4;
    if (width < 400) {
      aspectRatio = 0.95; // More height for very small screens (iPhone SE etc) to be safe
    } else if (width < 600) {
      aspectRatio = 1.2;
    }

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: aspectRatio, 
      children: [
        _buildWorkoutsCard(progress.workouts),
        _buildHistoryCard(progress.workouts),
        _buildWeightCard(progress.weight),
        _buildVolumeCard(progress.volume),
      ],
    );
  }

  Widget _buildHistoryCard(WorkoutStats workouts) {
    return _buildUnifiedCard(
      title: "Total Sesiones",
      icon: Icons.history,
      color: Colors.purple,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // Centered
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          _buildDataLine('${workouts.total}', 'Histórico', isPrimary: true),
          const SizedBox(height: 4),
          _buildDataLine('${workouts.weeklyAverage}', 'Prom. Semanal Hist.'),
        ],
      ),
    );
  }

  Widget _buildWorkoutsCard(WorkoutStats workouts) {
    return _buildUnifiedCard(
      title: "Entrenamientos",
      icon: Icons.fitness_center,
      color: Colors.blue,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // Centered
        children: [
          _buildDataLine('${workouts.thisWeek}', 'Esta Semana', isPrimary: true),
          const SizedBox(height: 4),
          _buildDataLine('${workouts.thisMonth}', 'Este Mes'),
        ],
      ),
    );
  }

  Widget _buildVolumeCard(VolumeStats volume) {
    return _buildUnifiedCard(
      title: "Volumen Levantado",
      icon: Icons.line_weight, 
      color: Colors.green,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // Centered
        children: [
          _buildDataLine(_formatSmartVolume(volume.thisWeek), 'Esta Semana', isPrimary: true),
          const SizedBox(height: 4),
          _buildDataLine(_formatSmartVolume(volume.thisMonth), 'Este Mes'),
          const SizedBox(height: 4),
          _buildDataLine(_formatSmartVolume(volume.lifetime), 'Acumulado'),
        ],
      ),
    );
  }

  Widget _buildWeightCard(WeightStats weight) {
    final initial = weight.initial > 0 ? weight.initial : weight.current;
    final diff = weight.current - initial;
    final sign = diff > 0 ? '+' : '';
    final diffText = '$sign${diff.toStringAsFixed(1)}';
    
    return _buildUnifiedCard(
      title: "Peso Corporal",
      icon: Icons.monitor_weight,
      color: Colors.orange,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // Centered
        children: [
          _buildDataLine('${weight.current} Kg', 'Actual', isPrimary: true),
          const SizedBox(height: 4),
          _buildDataLine('${initial} Kg', 'Inicial'),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // Centered
            children: [
              Text(
                 diffText,
                 style: TextStyle(
                   fontSize: 14, 
                   fontWeight: FontWeight.bold,
                   color: diff > 0 ? Colors.red : (diff < 0 ? Colors.green : Colors.grey),
                 ),
               ),
               const SizedBox(width: 4),
               Text(
                 'Diferencia',
                 style: TextStyle(fontSize: 12, color: Colors.grey[600]),
               ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    return _buildUnifiedCard(
      title: title,
      icon: icon,
      color: color,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // Centered
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          _buildDataLine(value, subtitle, isPrimary: true),
        ],
      ),
    );
  }

  // Shared Widget Implementation for maximum consistency
  Widget _buildUnifiedCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           Icon(icon, color: color, size: 24),
           Expanded(child: Center(child: SizedBox(width: double.infinity, child: content))),
           Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDataLine(String value, String label, {bool isPrimary = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center, // Centered
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 5), // Small space between Value and Label
        Text(
          ' $label', // Leading space to separate
          style: TextStyle(fontSize: 12, color: Colors.grey[700]), 
        ),
      ],
    );
  }

  String _formatSmartVolume(double volume) {
    // Logic: <= 4 digits (9999) -> Kg. > 4 digits (10000) -> Ton.
    if (volume > 9999) {
      return '${(volume / 1000).toStringAsFixed(1)} ton';
    }
    return '${volume.toStringAsFixed(0)} kg';
  }



  Widget _buildVolumeChart(VolumeStats volumeStats) {
     if (volumeStats.chart.isEmpty) {
       return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text("No hay datos recientes de volumen.")));
     }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Volumen semanal – Últimas 4 semanas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Text(
              'Cada barra representa el volumen total de una semana.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1.7,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: volumeStats.chart.map((e) => e.volume).reduce((a, b) => a > b ? a : b) * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          const style = TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          );
                          if (value.toInt() < volumeStats.chart.length) {
                              final dateStr = volumeStats.chart[value.toInt()].date;
                              final dateLabel = dateStr.length >= 5 ? dateStr.substring(5) : dateStr;
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(dateLabel, style: style),
                              );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: volumeStats.chart.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.volume,
                          color: Theme.of(context).colorScheme.primary,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        )
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



}

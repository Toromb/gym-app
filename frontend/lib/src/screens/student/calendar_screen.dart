import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/plan_provider.dart';
import '../../models/execution_model.dart';
import 'package:collection/collection.dart';
import '../../localization/app_localizations.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, List<TrainingSession>> _events = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day);
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() => _isLoading = true);
    final start = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final end = DateTime(_focusedDay.year, _focusedDay.month + 1, 0); 
    
    try {
      final executions = await context.read<PlanProvider>().fetchCalendar(start, end);
      
      final newEvents = groupBy(executions, (TrainingSession e) => e.date);
      
      if (mounted) {
        setState(() {
          _events = newEvents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onMonthChanged(int offset) {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + offset, 1);
      _events.clear(); 
    });
    _fetchEvents();
  }

  List<TrainingSession> _getEventsForDay(DateTime day) {
    final key = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
    // Debug logging
    print('Checking key: $key. Available keys: ${_events.keys.toList()}'); 
    return _events[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final startingWeekday = firstDayOfMonth.weekday; 

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.get('workoutHistory')),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Month Navigation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => _onMonthChanged(-1)),
                  Text(
                    DateFormat.yMMMM(AppLocalizations.of(context)!.locale.languageCode).format(_focusedDay),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(icon: const Icon(Icons.arrow_forward_ios), onPressed: () => _onMonthChanged(1)),
                ],
              ),
            ),
            
            // Days Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                AppLocalizations.of(context)!.get('mon'),
                AppLocalizations.of(context)!.get('tue'),
                AppLocalizations.of(context)!.get('wed'),
                AppLocalizations.of(context)!.get('thu'),
                AppLocalizations.of(context)!.get('fri'),
                AppLocalizations.of(context)!.get('sat'),
                AppLocalizations.of(context)!.get('sun')
              ].map((d) =>  
                 Expanded(child: Center(child: Text(d, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))))
              ).toList(),
            ),
            const SizedBox(height: 8),

            // Calendar Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1.3),
                itemCount: daysInMonth + (startingWeekday - 1),
                itemBuilder: (context, index) {
                  if (index < startingWeekday - 1) return const SizedBox();
                  
                  final dayNum = index - (startingWeekday - 1) + 1;
                  final date = DateTime(_focusedDay.year, _focusedDay.month, dayNum);
                  final events = _getEventsForDay(date);
                  final isSelected = _selectedDay != null && isSameDay(_selectedDay!, date);
                  final isToday = isSameDay(DateTime.now(), date);

                  return InkWell(
                    onTap: () => setState(() => _selectedDay = date),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary 
                            : (isToday ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15) : null), // Theme aware tint
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected 
                            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                            : (isToday ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null), // Standardize Today border
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayNum',
                            style: TextStyle(
                              fontSize: 16,
                              color: isSelected 
                                  ? Theme.of(context).colorScheme.onPrimary 
                                  : (isToday ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface),
                              fontWeight: isSelected || isToday ? FontWeight.w900 : FontWeight.w600,
                            ),
                          ),
                          if (events.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.verified, // Or check_circle
                                size: 16,
                                color: isSelected ? Colors.white : Colors.green,
                              ),
                            )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(),

            // Event List
            _isLoading 
                ? const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _selectedDay == null 
                  ? Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(child: Text(AppLocalizations.of(context)!.get('selectDay'))),
                    )
                  : _buildEventList(),
          ],
        ),
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay!);
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(child: Text('${AppLocalizations.of(context)!.get('noWorkoutsOn')} ${DateFormat.yMMMd(AppLocalizations.of(context)!.locale.languageCode).format(_selectedDay!)}', style: TextStyle(color: Colors.grey[500]))),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final execution = events[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text(AppLocalizations.of(context)!.get('workoutCompleted'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800])),
            subtitle: Text('${execution.exercises.length} ${AppLocalizations.of(context)!.get('exercisesCount')}'),
            children: execution.exercises.map((ex) {
              String metricText = '';
              // Determine metric based on data presence or exercise type if available
              // Priority: Time > Distance > Reps
              
              if (ex.timeSpent != null && ex.timeSpent!.isNotEmpty && ex.timeSpent != '0' && ex.timeSpent != '00:00') {
                 metricText = '${AppLocalizations.of(context)!.get('time')}: ${ex.timeSpent}';
              } else if (ex.distanceCovered != null && ex.distanceCovered! > 0) {
                 metricText = '${AppLocalizations.of(context)!.get('distance')}: ${ex.distanceCovered} m'; // User asked for "Metros"
              } else {
                 // Default to Reps/Load
                 metricText = '${AppLocalizations.of(context)!.get('sets')}: ${ex.setsDone}/${ex.targetSetsSnapshot ?? "?"} • ${AppLocalizations.of(context)!.get('reps')}: ${ex.repsDone ?? ex.targetRepsSnapshot ?? "-"} • ${AppLocalizations.of(context)!.get('load')}: ${ex.weightUsed ?? ex.targetWeightSnapshot ?? "-"}';
              }

              return ListTile(
              title: Text(ex.exerciseNameSnapshot, style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(
                metricText,
                 style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              trailing: ex.isCompleted 
                 ? const Icon(Icons.check, size: 16, color: Colors.green) 
                 : const Icon(Icons.close, size: 16, color: Colors.red),
            );
            }).toList(),
          ),
        );
      },
    );
  }
}

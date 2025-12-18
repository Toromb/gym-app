import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_schedule_provider.dart';
import '../../models/gym_schedule_model.dart';
import '../../localization/app_localizations.dart';

class GymScheduleScreen extends StatefulWidget {
  const GymScheduleScreen({super.key});

  @override
  State<GymScheduleScreen> createState() => _GymScheduleScreenState();
}

class _GymScheduleScreenState extends State<GymScheduleScreen> {
  bool _isEditing = false;
  List<GymSchedule> _editedSchedules = [];

  @override
  void initState() {
    super.initState();
    // Fetch schedule on init
    Future.microtask(() =>
        context.read<GymScheduleProvider>().fetchSchedule());
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final scheduleProvider = context.watch<GymScheduleProvider>();
    final isAdmin = authProvider.user?.role == AppRoles.admin;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.get('gymSchedule')),
        actions: [
          if (isAdmin && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                  // Clone list for editing (simple way)
                  _editedSchedules = scheduleProvider.schedules
                      .map((s) => GymSchedule.fromJson(s.toJson()))
                      .toList();
                });
              },
            ),
        ],
      ),
      body: scheduleProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : scheduleProvider.error != null
              ? Center(child: Text(scheduleProvider.error!))
              : _isEditing
                  ? _buildEditList(context)
                  : _buildViewList(scheduleProvider.schedules),
      floatingActionButton: _isEditing
          ? FloatingActionButton(
              child: const Icon(Icons.save),
              onPressed: () async {
                final success = await context
                    .read<GymScheduleProvider>()
                    .updateSchedule(_editedSchedules);
                if (success) {
                  setState(() {
                    _isEditing = false;
                  });
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.get('scheduleUpdated'))));
                  }
                }
              },
            )
          : null,
    );
  }

  String _getLocalizedDayName(BuildContext context, String dayOfWeek) {
    final loc = AppLocalizations.of(context)!;
    switch (dayOfWeek.toUpperCase()) {
      case 'MONDAY': return loc.get('day_monday');
      case 'TUESDAY': return loc.get('day_tuesday');
      case 'WEDNESDAY': return loc.get('day_wednesday');
      case 'THURSDAY': return loc.get('day_thursday');
      case 'FRIDAY': return loc.get('day_friday');
      case 'SATURDAY': return loc.get('day_saturday');
      case 'SUNDAY': return loc.get('day_sunday');
      default: return dayOfWeek;
    }
  }

  Widget _buildViewList(List<GymSchedule> schedules) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        final displayTime = schedule.isClosed
            ? AppLocalizations.of(context)!.get('closed')
            : schedule.displayHours == 'Closed'
                ? AppLocalizations.of(context)!.get('closed')
                : schedule.displayHours;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    _getLocalizedDayName(context, schedule.dayOfWeek), // Localized Day
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayTime,
                        style: TextStyle(
                          color: schedule.isClosed ? Colors.red : Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (schedule.notes != null && schedule.notes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            schedule.notes!,
                            style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _editedSchedules.length,
      itemBuilder: (context, index) {
        final schedule = _editedSchedules[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(_getLocalizedDayName(context, schedule.dayOfWeek),
                            style: const TextStyle(fontWeight: FontWeight.bold))),
                    Text(AppLocalizations.of(context)!.get('closed')),
                    Checkbox(
                      value: schedule.isClosed,
                      onChanged: (val) {
                        setState(() {
                          schedule.isClosed = val ?? false;
                        });
                      },
                    ),
                  ],
                ),
                if (!schedule.isClosed) ...[
                  // Morning Section
                  Row(
                     children: [
                       const Text('Mañana', style: TextStyle(fontWeight: FontWeight.bold)),
                       const SizedBox(width: 8),
                       Text(AppLocalizations.of(context)!.get('closed')),
                       Checkbox(
                          value: schedule.openTimeMorning == null && schedule.closeTimeMorning == null,
                          onChanged: (val) {
                             setState(() {
                                if (val == true) {
                                   schedule.openTimeMorning = null;
                                   schedule.closeTimeMorning = null;
                                } else {
                                   schedule.openTimeMorning = '08:00';
                                   schedule.closeTimeMorning = '12:00';
                                }
                             });
                          },
                       ),
                     ],
                  ),
                  if (schedule.openTimeMorning != null || schedule.closeTimeMorning != null)
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: schedule.openTimeMorning,
                          decoration: InputDecoration(labelText: AppLocalizations.of(context)!.get('openAM')),
                          onChanged: (val) => schedule.openTimeMorning = val,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: schedule.closeTimeMorning,
                          decoration: InputDecoration(labelText: AppLocalizations.of(context)!.get('closeAM')),
                          onChanged: (val) => schedule.closeTimeMorning = val,
                        ),
                      ),
                    ],
                  ),
                  
                  // Afternoon Section
                   Row(
                     children: [
                       const Text('Tarde', style: TextStyle(fontWeight: FontWeight.bold)),
                       const SizedBox(width: 24),
                       Text(AppLocalizations.of(context)!.get('closed')),
                       Checkbox(
                          value: schedule.openTimeAfternoon == null && schedule.closeTimeAfternoon == null,
                          onChanged: (val) {
                             setState(() {
                                if (val == true) {
                                   schedule.openTimeAfternoon = null;
                                   schedule.closeTimeAfternoon = null;
                                } else {
                                   schedule.openTimeAfternoon = '16:00';
                                   schedule.closeTimeAfternoon = '21:00';
                                }
                             });
                          },
                       ),
                     ],
                  ),
                  if (schedule.openTimeAfternoon != null || schedule.closeTimeAfternoon != null)
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: schedule.openTimeAfternoon,
                          decoration: InputDecoration(labelText: AppLocalizations.of(context)!.get('openPM')),
                          onChanged: (val) => schedule.openTimeAfternoon = val,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: schedule.closeTimeAfternoon,
                          decoration: InputDecoration(labelText: AppLocalizations.of(context)!.get('closePM')),
                          onChanged: (val) => schedule.closeTimeAfternoon = val,
                        ),
                      ),
                    ],
                  ),
                ],
                TextFormField(
                  initialValue: schedule.notes,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.get('notes')),
                  onChanged: (val) => schedule.notes = val,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

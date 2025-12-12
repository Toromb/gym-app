import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_schedule_provider.dart';
import '../../models/gym_schedule_model.dart';

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
    final isAdmin = authProvider.user?.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym Schedule'),
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
                        const SnackBar(content: Text('Schedule updated!')));
                  }
                }
              },
            )
          : null,
    );
  }

  Widget _buildViewList(List<GymSchedule> schedules) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
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
                    schedule.dayOfWeek,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(
                            schedule.displayHours,
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
                        child: Text(schedule.dayOfWeek,
                            style: const TextStyle(fontWeight: FontWeight.bold))),
                    const Text('Closed'),
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
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: schedule.openTimeMorning,
                          decoration: const InputDecoration(labelText: 'Open AM'),
                          onChanged: (val) => schedule.openTimeMorning = val,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: schedule.closeTimeMorning,
                          decoration: const InputDecoration(labelText: 'Close AM'),
                          onChanged: (val) => schedule.closeTimeMorning = val,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: schedule.openTimeAfternoon,
                          decoration: const InputDecoration(labelText: 'Open PM'),
                          onChanged: (val) => schedule.openTimeAfternoon = val,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: schedule.closeTimeAfternoon,
                          decoration: const InputDecoration(labelText: 'Close PM'),
                          onChanged: (val) => schedule.closeTimeAfternoon = val,
                        ),
                      ),
                    ],
                  ),
                ],
                TextFormField(
                  initialValue: schedule.notes,
                  decoration: const InputDecoration(labelText: 'Notes'),
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

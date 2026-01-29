import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/stats_provider.dart';
import '../../models/stats_model.dart';

import 'muscle_flow/muscle_flow_summary.dart';
import 'muscle_flow/muscle_flow_body.dart';
import 'muscle_flow/muscle_flow_list.dart';

class MuscleFlowScreen extends StatefulWidget {
  final String? studentId; // If provided, read-only view for professor

  const MuscleFlowScreen({super.key, this.studentId});

  @override
  State<MuscleFlowScreen> createState() => _MuscleFlowScreenState();
}

class _MuscleFlowScreenState extends State<MuscleFlowScreen> {
  bool _isLoading = true;
  List<MuscleLoad> _loads = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      final provider = context.read<StatsProvider>();
      if (widget.studentId != null) {
        // Prof View
        _loads = await provider.fetchStudentMuscleLoads(widget.studentId!);
      } else {
        // Student View
        await provider.fetchMyMuscleLoads();
        _loads = provider.myLoads;
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Main Scaffold handling
    // If embedded (Professor view), we might not want another Scaffold, but keeping for AppBar consistency if pushed.
    return Scaffold(
      appBar: AppBar(title: const Text('Estado Muscular')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Align header left
            children: [
              // 1. Header (Subtitle only, title is in AppBar)
              if (widget.studentId == null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Text(
                    'Basado en tus entrenamientos recientes',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              // 2. Summary (Priority)
              MuscleFlowSummary(loads: _loads),

              const SizedBox(height: 24),

              // 3. Body (Visual Accompaniment)
              MuscleFlowBody(loads: _loads),

              const SizedBox(height: 24),
              const Divider(),

              // 4. Collapsible List
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent), // Hide internal divider
                child: ExpansionTile(
                  title: const Text(
                    'Ver detalle por músculo',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  children: [
                     MuscleFlowList(loads: _loads, isEmpty: _loads.isEmpty),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 5. Footer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Text(
                  'Usá esta información como referencia. Ante molestias o dolor, consultá con tu profesor.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
    );
  }
}

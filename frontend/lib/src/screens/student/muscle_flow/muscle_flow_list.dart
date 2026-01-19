import 'package:flutter/material.dart';
import '../../../models/stats_model.dart';
import 'muscle_flow_utils.dart';

class MuscleFlowList extends StatelessWidget {
  final List<MuscleLoad> loads;
  final bool isEmpty;

  const MuscleFlowList({super.key, required this.loads, this.isEmpty = false});

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
        return const Center(child: Text("No hay datos disponibles."));
    }

    // Ensure sorted
    final sortedLoads = List<MuscleLoad>.from(loads)..sort((a, b) => b.load.compareTo(a.load));

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: sortedLoads.length,
      itemBuilder: (ctx, i) {
        final item = sortedLoads[i];
        final color = MuscleFlowUtils.getColor(item.load);
        final status = MuscleFlowUtils.getStatus(item.load);

        return Card(
          elevation: 0,
          color: Colors.transparent,
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.muscleName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Text('${item.load.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color, width: 1),
                      ),
                      child: Text(status,
                          style: TextStyle(
                              color: color.withOpacity(1), // Opaque text
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import '../../../models/stats_model.dart';
import 'muscle_flow_utils.dart';

class MuscleFlowSummary extends StatelessWidget {
  final List<MuscleLoad> loads;

  const MuscleFlowSummary({super.key, required this.loads});

  @override
  Widget build(BuildContext context) {
    int recovered = 0;
    int active = 0;
    int fatigued = 0;
    int overload = 0;

    for (var l in loads) {
      if (l.load <= 20) {
        recovered++;
      } else if (l.load <= 50) {
        active++;
      } else if (l.load <= 80) {
        fatigued++;
      } else {
        overload++;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _buildChip(context, overload, 'Sobrecarga', MuscleFlowUtils.getColor(90)),
          _buildChip(context, fatigued, 'Fatigado', MuscleFlowUtils.getColor(60)),
          _buildChip(context, active, 'Activo', MuscleFlowUtils.getColor(30)),
          _buildChip(context, recovered, 'Recuperado', MuscleFlowUtils.getColor(10)),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, int count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), // Soft background
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color, // Strong text color
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.9),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';

class PaymentStatusBadge extends StatelessWidget {
  final String? status; // 'paid', 'pending', 'overdue'
  final VoidCallback? onMarkAsPaid;
  final bool isEditable;

  const PaymentStatusBadge({
    super.key,
    required this.status,
    this.onMarkAsPaid,
    this.isEditable = false,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    IconData icon;

    // Normalize status just in case
    final s = status?.toLowerCase() ?? 'pending';

    switch (s) {
      case 'paid':
        color = Colors.green;
        text = 'CUOTA PAGA';
        icon = Icons.check_circle;
        break;
      case 'pending': // "Por vencer" (Grace Period)
        color = Colors.orange;
        text = 'CUOTA POR VENCER';
        icon = Icons.access_time;
        break;
      case 'overdue':
        color = Colors.red;
        text = 'CUOTA VENCIDA';
        icon = Icons.warning;
        break;
      default:
        color = Colors.grey;
        text = 'Desconocido';
        icon = Icons.help;
    }

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );

    if (isEditable && onMarkAsPaid != null && s != 'paid') {
      return PopupMenuButton<String>(
        child: badge,
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'pay',
            child: Row(
              children: [
                 Icon(Icons.payment, color: Colors.green),
                 SizedBox(width: 8),
                 Text('Mark as Paid (Abonado)'),
              ],
            ),
          ),
        ],
        onSelected: (v) {
          if (v == 'pay') onMarkAsPaid!();
        },
      );
    }

    return badge;
  }
}

import 'package:flutter/material.dart';
import '../../models/user_model.dart';

class StudentProfileScreen extends StatelessWidget {
  final User student;

  const StudentProfileScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${student.firstName} ${student.lastName}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Email', student.email),
            _buildDetailRow('Phone', student.phone ?? 'N/A'),
            _buildDetailRow('Age', student.age?.toString() ?? 'N/A'),
            _buildDetailRow('Gender', student.gender ?? 'N/A'),
            const Divider(),
            _buildDetailRow('Payment Status', student.paymentStatus?.toUpperCase() ?? 'PENDING'),
            _buildDetailRow('Last Payment', student.lastPaymentDate ?? 'N/A'),
            _buildDetailRow('Due Date', _calculateDueDate(student.lastPaymentDate)),
            const SizedBox(height: 20),
            const Text('Notes:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(student.notes ?? 'No notes available.'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  String _calculateDueDate(String? lastPaymentDate) {
    if (lastPaymentDate == null) return 'N/A';
    try {
      final date = DateTime.parse(lastPaymentDate);
      final dueDate = DateTime(date.year, date.month + 1, date.day + 10); // Logic: Next month + 10 days? Or just +10 days? 
      // Requirement: "10 dias despues del pago en el siguiente mes". 
      // Interpreted as: Pay Date + 1 Month + 10 Days ?? Or Pay Date + 10 Days?
      // "tomando como inicio el dia de su primer pago... 10 dias para pagar".
      // Let's assume standard monthly cycle: Due date is Same Day Next Month + 10 days tolerance?
      // Or simply: Date + 30 days. 
      // User said: "10 dias despues del pago en el siguiente mes".
      // Let's stick to simple logic: Next month same day.
      // Example: Paid 01/01. Next payment due 01/02. Tolerance until 10/02.
      // Let's display "Next msg: {Date + 1 Month}".
      
      final nextMonth = DateTime(date.year, date.month + 1, date.day);
      final dueLimit = nextMonth.add(const Duration(days: 10));
      return "${dueLimit.year}-${dueLimit.month.toString().padLeft(2, '0')}-${dueLimit.day.toString().padLeft(2, '0')}";
    } catch (e) {
      return 'Invalid Date';
    }
  }
}

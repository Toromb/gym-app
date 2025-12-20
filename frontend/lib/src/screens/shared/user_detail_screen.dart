import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../constants/app_constants.dart';

class UserDetailScreen extends StatelessWidget {
  final User user;

  const UserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${user.firstName} ${user.lastName}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'Información Personal'),
            _buildDetailRow('Email', user.email),
            _buildDetailRow('Teléfono', user.phone ?? 'N/A'),
            _buildDetailRow('Edad', user.age?.toString() ?? 'N/A'),
            _buildDetailRow('Género', user.gender ?? 'N/A'),
            _buildDetailRow('Rol', user.role.toUpperCase()),
            
            if (user.role == AppRoles.alumno) ...[
              const Divider(height: 30),
              _buildSectionHeader(context, 'Estado de Membresía'),
              _buildDetailRow('Estado', _translatePaymentStatus(user.paymentStatus)),
              _buildDetailRow('Último Pago', user.lastPaymentDate ?? 'N/A'),
              _buildDetailRow('Vencimiento', _calculateDueDate(user.lastPaymentDate)),
              
              const Divider(height: 30),
              _buildSectionHeader(context, 'Información Física'),
               _buildDetailRow('Peso Inicial', user.initialWeight != null ? '${user.initialWeight} kg' : 'N/A'),
              _buildDetailRow('Peso Actual', user.currentWeight != null ? '${user.currentWeight} kg' : 'N/A'),
              _buildDetailRow('Altura', user.height != null ? '${user.height} cm' : 'N/A'),
              _buildDetailRow('Objetivo', user.trainingGoal ?? 'N/A'),
            ],

            if (user.role == AppRoles.profe) ...[
               const Divider(height: 30),
               _buildSectionHeader(context, 'Perfil Profesional'),
               _buildDetailRow('Especialidad', user.specialty ?? 'N/A'),
            ],

            const SizedBox(height: 20),
            const Text('Notas:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)
              ),
              child: Text(
                user.notes ?? 'Sin notas disponibles.', 
                style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20, 
          fontWeight: FontWeight.bold, 
          color: Theme.of(context).colorScheme.primary
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120, 
            child: Text(
              '$label:', 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
            )
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 16))
          ),
        ],
      ),
    );
  }

  String _translatePaymentStatus(String? status) {
    switch (status) {
      case 'paid': return 'AL DÍA';
      case 'pending': return 'POR VENCER';
      case 'overdue': return 'VENCIDA';
      default: return 'PENDIENTE';
    }
  }

  String _calculateDueDate(String? lastPaymentDate) {
    if (lastPaymentDate == null) return 'N/A';
    try {
      final date = DateTime.parse(lastPaymentDate);
      final nextMonth = DateTime(date.year, date.month + 1, date.day);
      // Logic: Same day next month is the due date.
      return "${nextMonth.year}-${nextMonth.month.toString().padLeft(2, '0')}-${nextMonth.day.toString().padLeft(2, '0')}";
    } catch (e) {
      return 'Fecha Inválida';
    }
  }
}

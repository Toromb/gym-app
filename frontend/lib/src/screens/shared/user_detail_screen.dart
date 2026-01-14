import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../constants/app_constants.dart';
import '../../services/onboarding_service.dart';
import '../../services/api_client.dart';
import '../../models/onboarding_model.dart';

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
            _buildDetailRow('Fecha Nacimiento', user.birthDate ?? 'N/A'),
            _buildDetailRow('Género', user.gender ?? 'N/A'),
            _buildDetailRow('Rol', user.role.toUpperCase()),
            
            if (user.role == AppRoles.alumno) ...[
              const Divider(height: 30),
              _buildSectionHeader(context, 'Estado de Membresía'),
              _buildDetailRow('Estado', _translatePaymentStatus(user.paymentStatus)),
              _buildDetailRow('Último Pago', user.lastPaymentDate ?? 'N/A'),
              _buildDetailRow('Inicio de Membresia', user.membershipStartDate ?? 'N/A'),
              
              const Divider(height: 30),
              _buildSectionHeader(context, 'Información Física'),
               _buildDetailRow('Peso Inicial', user.initialWeight != null ? '${user.initialWeight} kg' : 'N/A'),
              _buildDetailRow('Peso Actual', user.currentWeight != null ? '${user.currentWeight} kg' : 'N/A'),
              _buildDetailRow('Altura', user.height != null ? '${user.height} cm' : 'N/A'),
              
              // Onboarding Section
              const Divider(height: 30),
              _buildSectionHeader(context, 'Perfil Inicial (Onboarding)'),
              FutureBuilder<OnboardingProfile?>(
                  future: OnboardingService(ApiClient()).getUserOnboarding(user.id),
                  builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                          return Text('Error cargando perfil: ${snapshot.error}');
                      }
                      final profile = snapshot.data;
                      if (profile == null) {
                          return const Text('El usuario no ha completado el onboarding.', style: TextStyle(fontStyle: FontStyle.italic));
                      }
                      return Column(
                          children: [
                              _buildDetailRow('Objetivo', _translateGoal(profile.goal)),
                              if (profile.goalDetails != null) _buildDetailRow('Detalles Objetivo', profile.goalDetails!),
                              _buildDetailRow('Experiencia', _translateExperience(profile.experience)),
                              _buildDetailRow('Nivel Actividad', _translateActivity(profile.activityLevel)),
                              _buildDetailRow('Frecuencia Deseada', _translateFrequency(profile.desiredFrequency) ?? 'N/A'),
                              _buildDetailRow('Lesiones', profile.injuries.isNotEmpty ? profile.injuries.join(', ') : 'Ninguna'),
                              if (profile.injuryDetails != null) _buildDetailRow('Detalles Lesión', profile.injuryDetails!),
                              _buildDetailRow('¿Puede recostarse y levantarse solo?', profile.canLieDown ? 'Sí' : 'No'),
                              _buildDetailRow('¿Puede arrodillarse y levantarse solo?', profile.canKneel ? 'Sí' : 'No'),
                              if (profile.preferences != null) _buildDetailRow('Preferencias', profile.preferences!),
                          ],
                      );
                  }
              ),
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


  String _translateGoal(String goal) {
      switch (goal) {
          case 'musculation': return 'Musculación';
          case 'health': return 'Salud';
          case 'cardio': return 'Cardio';
          case 'mixed': return 'Mixto';
          case 'mobility': return 'Movilidad';
          case 'sport': return 'Deporte';
          case 'rehab': return 'Rehabilitación';
          default: return goal;
      }
  }

  String _translateExperience(String exp) {
     switch (exp) {
         case 'none': return 'Ninguna';
         case 'less_than_year': return '< 1 año';
         case 'more_than_year': return '> 1 año';
         case 'current': return 'Actual';
         default: return exp;
     }
  }
  
  String _translateActivity(String act) {
      switch (act) {
          case 'sedentary': return 'Sedentario';
          case 'light': return 'Leve';
          case 'moderate': return 'Moderada';
          case 'high': return 'Alta';
          default: return act;
      }
  }

  String? _translateFrequency(String? freq) {
      if (freq == null) return null;
       switch (freq) {
          case 'once_per_week': return '1x Sem';
          case 'twice_per_week': return '2x Sem';
          case 'three_times_per_week': return '3x Sem';
          case 'four_or_more': return '4+ Sem';
          default: return freq;
      }
  }
}

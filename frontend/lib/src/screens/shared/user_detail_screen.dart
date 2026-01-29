import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../constants/app_constants.dart';
import '../../services/onboarding_service.dart';
import '../../services/api_client.dart';
import '../../models/onboarding_model.dart';
import '../../providers/stats_provider.dart';
import '../../models/stats_model.dart';
import '../student/muscle_flow/muscle_flow_summary.dart';
import '../student/muscle_flow/muscle_flow_body.dart';
import '../student/muscle_flow/muscle_flow_list.dart';
import '../../widgets/payment_status_badge.dart';

class UserDetailScreen extends StatefulWidget {
  final User user;

  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  List<MuscleLoad> _muscleLoads = [];
  bool _loadingMuscles = true;

  @override
  void initState() {
    super.initState();
    if (widget.user.role == AppRoles.alumno) {
      _fetchMuscleData();
    } else {
      _loadingMuscles = false;
    }
  }

  Future<void> _fetchMuscleData() async {
    try {
      final provider = context.read<StatsProvider>();
      final loads = await provider.fetchStudentMuscleLoads(widget.user.id);
      if (mounted) {
        setState(() {
          _muscleLoads = loads;
          _loadingMuscles = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching muscle loads: $e');
      if (mounted) {
        setState(() => _loadingMuscles = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Alumno')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              // --- HEADER ---
              // Nombre completo, Badge, Rol
              Center(
                child: Column(
                  children: [
                    Text(
                      '${widget.user.firstName} ${widget.user.lastName}',
                      style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         // Badge
                         PaymentStatusBadge(
                           status: widget.user.paymentStatus, 
                           isEditable: false,
                         ),
                         const SizedBox(width: 12),
                         // Rol Code
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                           decoration: BoxDecoration(
                             color: colorScheme.surfaceContainerHighest,
                             borderRadius: BorderRadius.circular(8),
                           ),
                           child: Text(
                             widget.user.role.toUpperCase(),
                             style: TextStyle(
                               fontSize: 12, 
                               fontWeight: FontWeight.bold,
                               color: colorScheme.onSurfaceVariant
                             ),
                           ),
                         ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- TARJETA 1: Información Personal ---
              _buildCard(
                context,
                title: 'Información Personal',
                child: Wrap(
                  spacing: 24,
                  runSpacing: 16,
                  children: [
                    _buildInfoItem(context, 'Email', widget.user.email, width: 250),
                    _buildInfoItem(context, 'Teléfono', widget.user.phone ?? 'N/A'),
                    _buildInfoItem(context, 'Género', widget.user.gender ?? 'N/A'),
                    _buildInfoItem(context, 'Fecha Nac.', widget.user.birthDate ?? 'N/A'),
                    _buildInfoItem(context, 'Edad', widget.user.age?.toString() ?? 'N/A'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- TARJETA 2: Membresía ---
              if (widget.user.role == AppRoles.alumno)
                _buildCard(
                  context,
                  title: 'Membresía',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                       Column(
                         children: [
                           const Text('Estado', style: TextStyle(fontSize: 12, color: Colors.grey)),
                           const SizedBox(height: 4),
                           PaymentStatusBadge(
                             status: widget.user.paymentStatus,
                             isEditable: false,
                             expirationDate: null, // Or pass if available
                           ),
                         ],
                       ),
                       _buildInfoItem(context, 'Inicio', widget.user.membershipStartDate ?? 'N/A', centered: true),
                       _buildInfoItem(context, 'Último Pago', widget.user.lastPaymentDate ?? 'N/A', centered: true),
                    ],
                  ),
                ),
                if (widget.user.role == AppRoles.alumno) const SizedBox(height: 16),


              // --- TARJETA 3: Perfil Físico ---
               if (widget.user.role == AppRoles.alumno)
                 _buildCard(
                   context,
                   title: 'Perfil Físico',
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceAround,
                     children: [
                       // Peso Actual Destacado
                       Column(
                         children: [
                           Text('Peso Actual', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                           Text(
                             widget.user.currentWeight != null ? '${widget.user.currentWeight} kg' : 'N/A',
                             style: textTheme.headlineSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
                           ),
                         ],
                       ),
                       _buildInfoItem(context, 'Peso Inicial', widget.user.initialWeight != null ? '${widget.user.initialWeight} kg' : 'N/A', centered: true),
                       _buildInfoItem(context, 'Altura', widget.user.height != null ? '${widget.user.height} cm' : 'N/A', centered: true),
                     ],
                   ),
                 ),
                 if (widget.user.role == AppRoles.alumno) const SizedBox(height: 16),


              // --- TARJETA 4: Onboarding ---
              if (widget.user.role == AppRoles.alumno)
                _buildCard(
                  context,
                  title: 'Perfil de Entrenamiento',
                  child: FutureBuilder<OnboardingProfile?>(
                    future: OnboardingService(ApiClient()).getUserOnboarding(widget.user.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                         return const Center(child: CircularProgressIndicator());
                      }
                      
                      final profile = snapshot.data;
                      
                      // Fallback Strategy
                      // If OnboardingProfile is null, we try to use data from User entity
                      String? backupGoal = widget.user.trainingGoal;
                      
                      // Determination: Do we have ANY data to show?
                      // 1. Profile exists
                      // 2. User has a goal
                      
                      if (profile == null && backupGoal == null) {
                         return const Text('Sin onboarding completo ni datos de objetivo.', style: TextStyle(fontStyle: FontStyle.italic));
                      }
                      
                      // Prepare data variables
                      String goal = profile?.goal ?? backupGoal ?? 'No definido';
                      String? goalReason = profile?.goalDetails;
                      String experience = profile != null ? _translateExperience(profile.experience) : 'No definido';
                      String level = profile != null ? _translateActivity(profile.activityLevel) : 'No definido';
                      String frequency = _translateFrequency(profile?.desiredFrequency) ?? 'No definido';
                      String injuries = profile?.injuries.isNotEmpty == true ? profile!.injuries.join(', ') : 'Ninguna';
                      String? injuryDetails = profile?.injuryDetails;
                      
                      // Render
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSubSectionTitle(context, 'OBJETIVO'),
                          Row(
                            children: [
                               Expanded(child: _buildInfoItem(context, 'Objetivo Principal', _translateGoal(goal))),
                            ],
                          ),
                          if (goalReason != null) ...[
                             const SizedBox(height: 8),
                             _buildInfoItem(context, 'Detalle', goalReason),
                          ],

                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),

                          _buildSubSectionTitle(context, 'PERFIL'),
                           Wrap(
                             spacing: 24,
                             runSpacing: 16,
                             children: [
                                _buildInfoItem(context, 'Nivel', level),
                                _buildInfoItem(context, 'Experiencia', experience),
                                _buildInfoItem(context, 'Frecuencia', frequency),
                                _buildInfoItem(context, 'Lesiones', injuries),
                             ],
                           ),
                           if (injuryDetails != null) ...[
                               const SizedBox(height: 8),
                               _buildInfoItem(context, 'Detalles Lesión', injuryDetails),
                           ]
                        ],
                      );
                    },
                  ),
                ),
                if (widget.user.role == AppRoles.alumno) const SizedBox(height: 16),

              // --- TARJETA 5: Estado Muscular ---
              if (widget.user.role == AppRoles.alumno)
                   _buildCard(
                      context,
                      title: 'Estado Muscular',
                      child: _loadingMuscles 
                        ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                        : Column(
                            children: [
                               MuscleFlowSummary(loads: _muscleLoads),
                               const SizedBox(height: 24),
                               ConstrainedBox(
                                 constraints: const BoxConstraints(maxHeight: 400),
                                 child: MuscleFlowBody(loads: _muscleLoads),
                               ),
                               const SizedBox(height: 16),
                               ExpansionTile(
                                  title: const Text('Ver detalle numérico', style: TextStyle(fontSize: 14)),
                                  children: [
                                     MuscleFlowList(loads: _muscleLoads, isEmpty: _muscleLoads.isEmpty),
                                  ],
                               )
                            ],
                          )
                   ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required String title, required Widget child}) {
     final colorScheme = Theme.of(context).colorScheme;
     return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
           padding: const EdgeInsets.all(16),
           child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface 
                    ),
                  ),
                  const Divider(height: 24),
                  child,
              ],
           ),
        ),
     );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value, {double? width, bool centered = false}) {
     return SizedBox(
       width: width, // If null, auto
       child: Column(
         crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
         children: [
           Text(
             label,
             style: TextStyle(
               fontSize: 12,
               color: Theme.of(context).colorScheme.onSurfaceVariant
             ),
           ),
           const SizedBox(height: 2),
           Text(
             value,
             style: const TextStyle(
               fontSize: 14,
               fontWeight: FontWeight.w500,
             ),
           ),
         ],
       ),
     );
  }

  Widget _buildSubSectionTitle(BuildContext context, String title) {
     return Padding(
       padding: const EdgeInsets.only(bottom: 8.0),
       child: Text(
         title,
         style: TextStyle(
           fontSize: 11,
           fontWeight: FontWeight.bold,
           letterSpacing: 1.0,
           color: Theme.of(context).colorScheme.primary,
         ),
       ),
     );
  }

  // --- Helpers ---

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


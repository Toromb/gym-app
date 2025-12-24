import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/gyms_provider.dart';

class PaymentStatusBadge extends StatefulWidget {
  final String? status; // 'paid', 'pending', 'overdue'
  final VoidCallback? onMarkAsPaid;
  final bool isEditable;
  final String? expirationDate;

  const PaymentStatusBadge({
    super.key,
    required this.status,
    this.onMarkAsPaid,
    this.isEditable = false,
    this.expirationDate,
  });

  @override
  State<PaymentStatusBadge> createState() => _PaymentStatusBadgeState();
}

class _PaymentStatusBadgeState extends State<PaymentStatusBadge> {

  Future<void> _showPaymentInfo() async {
      final authProvider = context.read<AuthProvider>();
      var user = authProvider.user;
      var gym = user?.gym;

      if (gym == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay información del gimnasio disponible.')));
          }
          return;
      }
      
      // Show loading indicator
      showDialog(
          context: context, 
          barrierDismissible: false,
          builder: (c) => const Center(child: CircularProgressIndicator())
      );

      try {
          final gymsProvider = context.read<GymsProvider>();
          final latestGym = await gymsProvider.fetchGym(gym.id);
          
          if (mounted) {
              Navigator.pop(context); // Close loading dialog
          }

          if (latestGym != null) {
              gym = latestGym;
              // Update local auth provider state to sync for this session
              authProvider.updateGym(latestGym); 
          }
      } catch (e) {
          if (mounted) {
              Navigator.pop(context); // Close loading dialog
          }
          debugPrint('Error fetching latest gym data: $e');
      }

      if (!mounted) return;

      showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
          ),
          backgroundColor: Colors.white,
          isScrollControlled: true,
          builder: (context) {
              final colorScheme = Theme.of(context).colorScheme;
              final primaryColor = Theme.of(context).primaryColor;
              
              final hasPaymentInfo = (gym!.paymentAlias?.isNotEmpty ?? false) ||
                                     (gym.paymentCbu?.isNotEmpty ?? false) ||
                                     (gym.paymentBankName?.isNotEmpty ?? false) ||
                                     (gym.paymentAccountName?.isNotEmpty ?? false);

              return Container(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                      top: 25, left: 25, right: 25
                  ),
                  decoration: BoxDecoration(
                      color: colorScheme.surface, // Theme surface
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
                  ),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Center(
                              child: Container(
                                  width: 50, height: 5,
                                  decoration: BoxDecoration(
                                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4), // Theme handle
                                      borderRadius: BorderRadius.circular(10)
                                  ),
                              ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                              children: [
                                  Icon(Icons.payment, color: primaryColor, size: 28),
                                  const SizedBox(width: 10),
                                  Text(
                                      'Datos para el Pago',
                                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                                  ),
                              ],
                          ),
                          const SizedBox(height: 25),
                          
                          if (gym.paymentAlias != null && gym.paymentAlias!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                    children: [
                                        Text("Alias: ${gym.paymentAlias}", style: TextStyle(color: colorScheme.onSurface)),
                                        IconButton(
                                            icon: Icon(Icons.copy, color: primaryColor),
                                            onPressed: () {
                                                Clipboard.setData(ClipboardData(text: gym!.paymentAlias!));
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Alias copiado'))
                                                );
                                            },
                                        ),
                                    ],
                                ),
                              ),
                              
                          if (gym.paymentCbu != null && gym.paymentCbu!.isNotEmpty)
                               Padding(
                                 padding: const EdgeInsets.only(bottom: 12.0),
                                 child: Row(
                                    children: [
                                        Text("CBU: ${gym.paymentCbu}", style: TextStyle(color: colorScheme.onSurface)),
                                        IconButton(
                                            icon: Icon(Icons.copy, color: primaryColor),
                                            onPressed: () {
                                                Clipboard.setData(ClipboardData(text: gym!.paymentCbu!));
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('CBU copiado'))
                                                );
                                            },
                                        ),
                                    ],
                                ),
                               ),
                               
                          if (gym.paymentBankName != null && gym.paymentBankName!.isNotEmpty)
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 12, left: 4),
                                  child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                          SizedBox(
                                              width: 80, 
                                              child: Text('Banco', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14))
                                          ),
                                          Expanded(
                                              child: Text(gym.paymentBankName!, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colorScheme.onSurface))
                                          ),
                                      ],
                                  ),
                              ),
                              
                          if (gym.paymentAccountName != null && gym.paymentAccountName!.isNotEmpty)
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 12, left: 4),
                                  child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                          SizedBox(
                                              width: 80, 
                                              child: Text('Titular', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14))
                                          ),
                                          Expanded(
                                              child: Text(gym.paymentAccountName!, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colorScheme.onSurface))
                                          ),
                                      ],
                                  ),
                              ),

                          if (!hasPaymentInfo)
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text('No data', style: TextStyle(color: colorScheme.onSurface)),
                              ),

                           const SizedBox(height: 20),
                           
                           if (gym.paymentNotes != null && gym.paymentNotes!.isNotEmpty)
                               Text(gym.paymentNotes!, style: TextStyle(color: colorScheme.onSurface)),

                          const SizedBox(height: 20),
                          SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.secondaryContainer,
                                      foregroundColor: colorScheme.onSecondaryContainer,
                                  ),
                                  child: const Text('Cerrar'),
                              ),
                          ),
                          const SizedBox(height: 10),
                      ],
                  ),
              );
          }
      );
  }

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    IconData icon;

    // Normalize status just in case
    final s = widget.status?.toLowerCase() ?? 'pending';

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

    final badge = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
              if (!widget.isEditable) ...[
                const SizedBox(width: 6),
                Icon(Icons.chevron_right, size: 16, color: color.withValues(alpha: 0.8)),
              ]
            ],
          ),
        ),
        if (widget.expirationDate != null && widget.expirationDate!.isNotEmpty)
           Padding(
             padding: const EdgeInsets.only(top: 4.0, left: 4.0),
             child: Text(
               'Vence: ${widget.expirationDate}',
               style: const TextStyle(fontSize: 11, color: Colors.grey),
             ),
           ),
        

      ],
    );

    if (widget.isEditable && widget.onMarkAsPaid != null && s != 'paid') {
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
          if (v == 'pay') widget.onMarkAsPaid!();
        },
      );
    }

    // New Requirement: If not editable (Student View), click to show Payment Info
    if (!widget.isEditable) {
        return InkWell(
            onTap: _showPaymentInfo,
            borderRadius: BorderRadius.circular(12),
            child: badge,
        );
    }

    return badge;
  }
}

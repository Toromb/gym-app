import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../models/user_model.dart' as app_models;
import 'package:intl/intl.dart';
import 'dashboard_payment_button.dart';
import 'payment_status_badge.dart'; // Ensure this is imported if used inside DashboardPaymentButton or elsewhere

class GymDashboardHeader extends StatelessWidget {
  final app_models.User? user;
  final bool showPaymentStatus; // Option to hide payment info for Admin/Teacher if needed

  const GymDashboardHeader({
    super.key, 
    required this.user,
    this.showPaymentStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();

    // 1. Calculate Expiration Logic
    String? expirationFormatted;
    bool isExpired = false;
    bool isNearExpiration = false;
    
    // Only calculate for ROLE_STUDENT or if explicitly desired
    if (showPaymentStatus && user?.membershipExpirationDate != null) {
        try {
            final date = DateTime.parse(user!.membershipExpirationDate!);
            expirationFormatted = DateFormat('dd/MM', 'es').format(date);
             final daysLeft = date.difference(DateTime.now()).inDays;
             if (daysLeft < 0) isExpired = true;
             else if (daysLeft <= 5) isNearExpiration = true;
        } catch (_) {}
    }

    // Role Display Name
    String roleDisplay = 'Panel de Usuario';
    if (user!.role == 'ROLE_ADMIN') roleDisplay = 'Panel de Administrador';
    else if (user!.role == 'ROLE_PROFESSOR') roleDisplay = 'Panel de Profesor';
    else if (user!.role == 'ROLE_STUDENT') roleDisplay = 'Panel de Alumno';
    else if (user!.role == 'ROLE_SUPER_ADMIN') roleDisplay = 'Super Admin';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, 
      children: [
        // Upper Row: Avatar | Greeting | Theme/Logout
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
             // Avatar
             Container(
               decoration: BoxDecoration(
                 shape: BoxShape.circle,
                 border: Border.all(color: Colors.blueAccent, width: 2),
               ),
               child: Builder(
                 builder: (context) {
                   final String? profilePic = user?.profilePictureUrl;
                   final bool hasProfilePic = profilePic != null && profilePic.isNotEmpty;
                   
                   return CircleAvatar(
                     radius: 28,
                     backgroundColor: Colors.grey[200],
                     backgroundImage: hasProfilePic
                      ? NetworkImage(profilePic!.startsWith('http') ? profilePic : 'http://localhost:3001$profilePic')
                      : null,
                     child: !hasProfilePic
                      ? Icon(Icons.person, size: 30, color: Colors.grey[400])
                      : null,
                   );
                 }
               ),
             ),
             const SizedBox(width: 16),
             
             // Texts
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                     roleDisplay,
                     style: Theme.of(context).textTheme.titleMedium?.copyWith(
                       fontWeight: FontWeight.bold,
                       color: Theme.of(context).colorScheme.onSurface 
                     ),
                   ),
                   Text(
                     '¡Hola, ${user?.firstName ?? "Usuario"}!',
                     style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                   ),
                 ],
               ),
             ),

             // Logout / Actions
             Row(
               children: [
                 // Theme Toggle
                 Consumer<ThemeProvider>(
                   builder: (_, theme, __) {
                     final isDark = theme.isDarkMode;
                     return Container(
                       decoration: BoxDecoration(
                         color: isDark ? Colors.grey[800] : Colors.grey[100], 
                         shape: BoxShape.circle,
                       ),
                       child: IconButton(
                         onPressed: () => theme.toggleTheme(!isDark),
                         icon: Icon(
                           isDark ? Icons.light_mode : Icons.dark_mode,
                           color: isDark ? Colors.white : Colors.black87,
                         ),
                         tooltip: 'Cambiar Tema',
                       ),
                     );
                   }
                 ),
                 const SizedBox(width: 8),

                 // Logout
                 Builder(
                   builder: (context) {
                     final isDark = Theme.of(context).brightness == Brightness.dark;
                     return Container(
                       decoration: BoxDecoration(
                         color: isDark ? Colors.grey[800] : Colors.grey[100],
                         borderRadius: BorderRadius.circular(12),
                       ),
                       child: IconButton(
                         icon: Icon(Icons.logout, color: isDark ? Colors.white : Colors.black87),
                         onPressed: () {
                            context.read<AuthProvider>().logout();
                            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                         },
                         tooltip: 'Cerrar Sesión',
                       ),
                     );
                   }
                 ),
               ],
             )
          ],
        ),
        
        const SizedBox(height: 24),

        // User Name & Gym/Membership Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                      '${user?.firstName} ${user?.lastName ?? ""}'.trim(),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 22),
                   ),
                   const SizedBox(height: 4),
                   Text(
                      user?.gym?.businessName ?? 'GYM APP',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.grey,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600
                      ),
                   ),
                 ],
               ),
             ),
             
             // Payment Status Badge & Date Group (Only if applicable)
             if (showPaymentStatus)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                   DashboardPaymentButton(
                     user: user!,
                     isExpired: isExpired, 
                     isNearExpiration: isNearExpiration,
                     hasMembership: expirationFormatted != null,
                     onTap: () {
                            _showPaymentInfo(context, user);
                     },
                   ),
                   
                   if (expirationFormatted != null)
                     Padding(
                       padding: const EdgeInsets.only(top: 2.0, right: 4.0), 
                       child: Text(
                         'Vencimiento: $expirationFormatted', 
                         style: TextStyle(fontSize: 10, color: Colors.grey[500])
                       )
                     ),
                ],
              )
          ],
        ),
      ],
    );
  }

  void _showPaymentInfo(BuildContext context, app_models.User? user) {
    if (user?.gym == null) return;
    
    final gym = user!.gym!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.payment, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Datos de Pago'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Para renovar tu cuota, podés transferir a:', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            if (gym.paymentBankName != null && gym.paymentBankName!.isNotEmpty)
              _infoRow(context, Icons.account_balance, 'Banco: ${gym.paymentBankName}'),
            if (gym.paymentAlias != null && gym.paymentAlias!.isNotEmpty)
              _infoRow(context, Icons.link, 'Alias: ${gym.paymentAlias}'),
             if (gym.paymentCbu != null && gym.paymentCbu!.isNotEmpty)
              _infoRow(context, Icons.numbers, 'CBU: ${gym.paymentCbu}'),
             if (gym.paymentAccountName != null && gym.paymentAccountName!.isNotEmpty)
              _infoRow(context, Icons.person, 'Titular: ${gym.paymentAccountName}'),
              
             if (gym.paymentNotes != null && gym.paymentNotes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[800] 
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    gym.paymentNotes!, 
                    style: TextStyle(
                      fontSize: 12, 
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                )
             ]
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String text) {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
              children: [
                  Icon(icon, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
              ],
          ),
      );
  }
}

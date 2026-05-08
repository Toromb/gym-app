import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../models/user_model.dart' as app_models;
import 'package:intl/intl.dart';
import 'dashboard_payment_button.dart';
import '../theme/background_styles.dart';
import '../utils/constants.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class GymDashboardHeader extends StatelessWidget {
  final app_models.User? user;
  final bool
      showPaymentStatus; // Option to hide payment info for Admin/Teacher if needed

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
        // El sistema usa ciclo fijo: vence el día 1 del mes siguiente
        expirationFormatted =
            '1 de ${DateFormat('MMMM yyyy', 'es').format(date)}';
        final daysLeft = date.difference(DateTime.now()).inDays;
        if (daysLeft < 0)
          isExpired = true;
        else if (daysLeft <= 5) isNearExpiration = true;
      } catch (_) {}
    }

    // Role Display Name
    String roleDisplay = 'Panel de Usuario';
    if (user!.role == 'ROLE_ADMIN')
      roleDisplay = 'Panel de Administrador';
    else if (user!.role == 'ROLE_PROFESSOR')
      roleDisplay = 'Panel de Profesor';
    else if (user!.role == 'ROLE_STUDENT')
      roleDisplay = 'Panel de Alumno';
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
              child: Builder(builder: (context) {
                final String? profilePic = user?.profilePictureUrl;
                final bool hasProfilePic =
                    profilePic != null && profilePic.isNotEmpty;

                return CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: hasProfilePic
                      ? NetworkImage(profilePic.startsWith('http')
                          ? profilePic
                          : 'http://localhost:3001$profilePic')
                      : null,
                  child: !hasProfilePic
                      ? Icon(Icons.person, size: 30, color: Colors.grey[400])
                      : null,
                );
              }),
            ),
            const SizedBox(width: 16),

            // Texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    roleDisplay,
                    style: BackgroundStyles.fromTheme(
                        Theme.of(context).textTheme.titleMedium),
                  ),
                  Text(
                    '¡Hola, ${user?.firstName ?? "Usuario"}!',
                    style: BackgroundStyles.fromTheme(
                        Theme.of(context).textTheme.bodyMedium,
                        color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Logout / Actions
            Row(
              children: [
                // Theme Toggle
                Consumer<ThemeProvider>(builder: (_, theme, __) {
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
                }),
                const SizedBox(width: 8),

                // Logout
                Builder(builder: (context) {
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  return Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.logout,
                          color: isDark ? Colors.white : Colors.black87),
                      onPressed: () async {
                        await context.read<AuthProvider>().logout();
                        if (context.mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              '/login', (route) => false);
                        }
                      },
                      tooltip: 'Cerrar Sesión',
                    ),
                  );
                }),
              ],
            )
          ],
        ),

        // ── SOCIAL ICONS (horizontal, derecha) — arriba del badge ────
        Builder(builder: (context) {
          final gym = user?.gym;
          final hasWhatsapp =
              gym?.whatsapp != null && gym!.whatsapp!.isNotEmpty;
          final hasInstagram =
              gym?.instagram != null && gym!.instagram!.isNotEmpty;
          final hasFacebook =
              gym?.facebook != null && gym!.facebook!.isNotEmpty;

          if (!hasWhatsapp && !hasInstagram && !hasFacebook) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (hasWhatsapp)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _buildSocialIcon(
                      context: context,
                      icon: Icons.chat_bubble_outline,
                      color: const Color(0xFF25D366),
                      url:
                          'https://wa.me/${gym!.whatsapp!.replaceAll(RegExp(r'[^\d]'), '')}',
                      tooltip: 'Enviar comprobante por WhatsApp',
                    ),
                  ),
                if (hasInstagram)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _buildSocialIcon(
                      context: context,
                      icon: Icons.camera_alt_outlined,
                      color: const Color(0xFFE1306C),
                      url:
                          'https://instagram.com/${gym!.instagram!.replaceAll('@', '')}',
                      tooltip: 'Ir a Instagram',
                    ),
                  ),
                if (hasFacebook)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _buildSocialIcon(
                      context: context,
                      icon: Icons.facebook,
                      color: const Color(0xFF1877F2),
                      url: gym!.facebook!.startsWith('http')
                          ? gym.facebook!
                          : 'https://facebook.com/${gym.facebook}',
                      tooltip: 'Ir a Facebook',
                    ),
                  ),
              ],
            ),
          );
        }),

        // ── GYM IDENTITY ROW: logo+nombre | badge de cuota ───────────
        Builder(builder: (context) {
          final gymLogoUrl = user?.gym?.logoUrl;
          final gymName = user?.gym?.businessName ?? 'GYM APP';
          final hasLogo = gymLogoUrl != null && gymLogoUrl.isNotEmpty;

          // Logo responsivo: grande en PC, chico en mobile
          final screenWidth = MediaQuery.of(context).size.width;
          final isDesktop = screenWidth >= 768;
          final logoSize = isDesktop ? 96.0 : 64.0;
          final gymNameFontSize =
              isDesktop ? (hasLogo ? 16.0 : 18.0) : (hasLogo ? 13.0 : 15.0);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo + nombre del gym (centrado en el espacio disponible)
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasLogo) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          resolveImageUrl(gymLogoUrl),
                          width: logoSize,
                          height: logoSize,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      gymName,
                      textAlign: TextAlign.center,
                      style: BackgroundStyles.fromTheme(
                        Theme.of(context).textTheme.labelLarge,
                        color: Colors.white70,
                      ).copyWith(
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w700,
                        fontSize: gymNameFontSize,
                      ),
                    ),
                  ],
                ),
              ),

              // Badge de cuota (solo alumnos)
              if (showPaymentStatus)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    DashboardPaymentButton(
                      user: user!,
                      isExpired: isExpired,
                      isNearExpiration: isNearExpiration,
                      hasMembership: expirationFormatted != null,
                      onTap: () => _showPaymentInfo(context, user),
                    ),
                    if (expirationFormatted != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0, right: 4.0),
                        child: Text(
                          'Vence: $expirationFormatted',
                          style:
                              TextStyle(fontSize: 10, color: Colors.grey[500]),
                        ),
                      ),
                  ],
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildSocialIcon({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String url,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => html.window.open(url, '_blank'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
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
            Text('Para renovar tu cuota, podés transferir a:',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            if (gym.paymentBankName != null && gym.paymentBankName!.isNotEmpty)
              _infoRow(context, Icons.account_balance,
                  'Banco: ${gym.paymentBankName}'),
            if (gym.paymentAlias != null && gym.paymentAlias!.isNotEmpty)
              _infoRow(context, Icons.link, 'Alias: ${gym.paymentAlias}'),
            if (gym.paymentCbu != null && gym.paymentCbu!.isNotEmpty)
              _infoRow(context, Icons.numbers, 'CBU: ${gym.paymentCbu}'),
            if (gym.paymentAccountName != null &&
                gym.paymentAccountName!.isNotEmpty)
              _infoRow(
                  context, Icons.person, 'Titular: ${gym.paymentAccountName}'),
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
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.8),
                  ),
                ),
              )
            ]
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar')),
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

import 'package:flutter/material.dart';

/// Envoltorio reutilizable para proveer un fondo consistente (imagen + overlay)
/// a las pantallas de la aplicación.
///
/// Prioridad de imagen:
/// 1. [backgroundNetworkUrl] — URL remota (imagen del gym desde el servidor)
/// 2. [backgroundAssetPath]  — asset local (fallback manual)
/// 3. 'assets/images/login_bg.jpg' — fallback por defecto
///
/// [child] debe ser típicamente un `Scaffold` con `backgroundColor: Colors.transparent`.
class BackgroundPageWrapper extends StatelessWidget {
  final Widget child;
  final String? backgroundAssetPath;
  final String? backgroundNetworkUrl;
  final double overlayOpacity;

  const BackgroundPageWrapper({
    super.key,
    required this.child,
    this.backgroundAssetPath,
    this.backgroundNetworkUrl,
    this.overlayOpacity = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    final Widget bgImage;

    if (backgroundNetworkUrl != null && backgroundNetworkUrl!.isNotEmpty) {
      bgImage = Image.network(
        backgroundNetworkUrl!,
        fit: BoxFit.cover,
        // Fallback a asset local si la URL de red falla
        errorBuilder: (context, error, stackTrace) => Image.asset(
          backgroundAssetPath ?? 'assets/images/login_bg.jpg',
          fit: BoxFit.cover,
        ),
      );
    } else {
      bgImage = Image.asset(
        backgroundAssetPath ?? 'assets/images/login_bg.jpg',
        fit: BoxFit.cover,
      );
    }

    return Stack(
      children: [
        // 1. Imagen de fondo
        Positioned.fill(child: bgImage),

        // 2. Overlay degradado para garantizar legibilidad en zonas críticas.
        // Más oscuro arriba (donde viven los headers/títulos flotantes),
        // manteniendo la opacidad base en el resto. Funciona con cualquier imagen.
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.35, 1.0],
                colors: [
                  Colors.black.withValues(
                      alpha: (overlayOpacity + 0.15).clamp(0.0, 1.0)),
                  Colors.black.withValues(alpha: overlayOpacity),
                  Colors.black.withValues(
                      alpha: (overlayOpacity + 0.05).clamp(0.0, 1.0)),
                ],
              ),
            ),
          ),
        ),

        // 3. Contenido principal (Scaffold con color transparente)
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}

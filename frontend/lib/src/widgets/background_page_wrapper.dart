import 'package:flutter/material.dart';

/// Envoltorio reutilizable para proveer un fondo consistente (imagen + overlay)
/// a las pantallas de la aplicación.
///
/// [child] debe ser típicamente un `Scaffold` con `backgroundColor: Colors.transparent`.
class BackgroundPageWrapper extends StatelessWidget {
  final Widget child;
  final String? backgroundAssetPath;
  final double overlayOpacity;

  const BackgroundPageWrapper({
    super.key,
    required this.child,
    this.backgroundAssetPath,
    this.overlayOpacity = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    // Si backgroundAssetPath es nulo, usamos el por defecto global.
    // Futuro: Aquí se puede inyectar un proveedor (ej: GymConfigProvider)
    // para obtener la URL del gimnasio y usar FadeInImage o CachedNetworkImage.
    final String assetPath =
        backgroundAssetPath ?? 'assets/images/login_bg.jpg';

    return Stack(
      children: [
        // 1. Imagen de fondo
        Positioned.fill(
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
          ),
        ),

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
                  Colors.black
                      .withOpacity((overlayOpacity + 0.15).clamp(0.0, 1.0)),
                  Colors.black.withOpacity(overlayOpacity),
                  Colors.black
                      .withOpacity((overlayOpacity + 0.05).clamp(0.0, 1.0)),
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

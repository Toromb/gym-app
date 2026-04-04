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

        // 2. Overlay oscuro para legibilidad (ajustable por pantalla)
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(overlayOpacity),
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

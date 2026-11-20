import 'package:flutter/material.dart';

/// Logo de Urban Flair (Login, Registro, Home, carga y encabezado azul).
/// Si el archivo no se puede cargar, muestra un recuadro "LOGO".
class UrbanFlairLogo extends StatelessWidget {
  /// Versión de 256 px del logo (se muestra a 48-64 px). El original de
  /// 1024 px sigue en assets/images/Logo_UrbanFlair.png.
  static const String assetPath = 'assets/images/Logo_UrbanFlair_256.png';

  final double height;

  /// true cuando el logo va sobre fondo oscuro (el recuadro se ve claro).
  final bool sobreOscuro;

  const UrbanFlairLogo({super.key, this.height = 60, this.sobreOscuro = true});

  @override
  Widget build(BuildContext context) {
    final color = sobreOscuro ? Colors.white : const Color(0xFF0A3568);
    return Image.asset(
      assetPath,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Container(
        height: height,
        width: height * 1.3,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.7)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('LOGO',
            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

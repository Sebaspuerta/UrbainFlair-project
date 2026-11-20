import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/navegacion.dart';
import 'urban_flair_logo.dart';

/// Barra azul superior: logo a la izquierda, título opcional al centro
/// y flecha que regresa al Home.
class EncabezadoAzul extends StatelessWidget {
  final String? titulo;

  const EncabezadoAzul({super.key, this.titulo});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.azulEncabezado,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const UrbanFlairLogo(height: 48),
          Expanded(
            child: titulo == null
                ? const SizedBox.shrink()
                : Center(
                    child: Text(titulo!,
                        style: AppTextStyles.archivo(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18)),
                  ),
          ),
          InkWell(
            onTap: () => volverAlHome(context),
            customBorder: const CircleBorder(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

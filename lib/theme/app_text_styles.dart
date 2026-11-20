import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Estilos de texto de la app (fuentes Archivo y Archivo Black).
///
/// Las fuentes vienen empaquetadas en assets/fonts (mismos archivos que
/// Google Fonts) y main.dart desactiva la descarga en tiempo de ejecución.
/// Los estilos que se repiten se crean una sola vez.
abstract final class AppTextStyles {
  /// Archivo con los parámetros dados.
  static TextStyle archivo({
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
    double? height,
  }) => GoogleFonts.archivo(
    color: color,
    fontWeight: fontWeight,
    fontSize: fontSize,
    height: height,
  );

  /// Archivo Black (títulos grandes).
  static TextStyle archivoBlack({
    Color? color,
    double? fontSize,
    double? height,
  }) => GoogleFonts.archivoBlack(
    color: color,
    fontSize: fontSize,
    height: height,
  );

  /// Tema de texto global (Material con Archivo).
  static TextTheme temaTexto() => GoogleFonts.archivoTextTheme();

  // ------------------------------------------------- Estilos repetidos

  static final negrita = archivo(fontWeight: FontWeight.w800);
  static final negrita12 = archivo(fontWeight: FontWeight.w800, fontSize: 12);
  static final negrita13 = archivo(fontWeight: FontWeight.w800, fontSize: 13);
  static final negrita15 = archivo(fontWeight: FontWeight.w800, fontSize: 15);
  static final normal12 = archivo(fontSize: 12);

  static final azulNegrita = archivo(
    color: AppColors.azulTitulo,
    fontWeight: FontWeight.w800,
  );
  static final azulNegrita15 = archivo(
    color: AppColors.azulTitulo,
    fontWeight: FontWeight.w800,
    fontSize: 15,
  );
  static final azulNegrita16 = archivo(
    color: AppColors.azulTitulo,
    fontWeight: FontWeight.w800,
    fontSize: 16,
  );

  /// Título de pantalla (Inventario, Registrar Producto, etc.).
  static final tituloPantalla = archivo(
    color: AppColors.azulTitulo,
    fontWeight: FontWeight.w800,
    fontSize: 20,
  );

  /// Títulos del Home (Bienvenido, Resumen General).
  static final tituloHome = archivo(
    color: AppColors.azulTitulo,
    fontWeight: FontWeight.w800,
    fontSize: 22,
  );

  static final grisBold = archivo(
    color: AppColors.textoGris,
    fontWeight: FontWeight.w700,
  );
  static final grisBold13 = archivo(
    color: AppColors.textoGris,
    fontWeight: FontWeight.w700,
    fontSize: 13,
  );

  static final blancoNegrita12 = archivo(
    color: Colors.white,
    fontWeight: FontWeight.w800,
    fontSize: 12,
  );
  static final blancoNegrita14 = archivo(
    color: Colors.white,
    fontWeight: FontWeight.w800,
    fontSize: 14,
  );

  /// Enlaces de login/registro.
  static final enlace12 = archivo(
    color: AppColors.celesteLink,
    fontWeight: FontWeight.w800,
    fontSize: 12,
  );
}

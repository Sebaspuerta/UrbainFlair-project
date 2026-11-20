import 'package:flutter/material.dart';

/// Muestra una pantalla cuyo código se descarga aparte (import diferido),
/// para que el arranque de la app no cargue gráficas, QR, etc.
///
/// Mientras se descarga muestra el fondo de esa pantalla con un indicador
/// discreto. Si ya se había descargado, la muestra de inmediato.
class PantallaDiferida extends StatefulWidget {
  /// Identifica la librería (para saber si ya está cargada).
  final String id;

  /// El `loadLibrary` del import diferido.
  final Future<void> Function() cargar;

  /// Construye la pantalla una vez cargada.
  final Widget Function() construir;

  /// Fondo de la pantalla destino (evita un destello de otro color).
  final Color fondo;

  /// Color del indicador de carga.
  final Color? colorIndicador;

  const PantallaDiferida({
    super.key,
    required this.id,
    required this.cargar,
    required this.construir,
    this.fondo = Colors.white,
    this.colorIndicador,
  });

  static final Set<String> _cargadas = {};

  @override
  State<PantallaDiferida> createState() => _PantallaDiferidaState();
}

class _PantallaDiferidaState extends State<PantallaDiferida> {
  late final bool _yaCargada = PantallaDiferida._cargadas.contains(widget.id);
  late final Future<void>? _carga = _yaCargada
      ? null
      : widget.cargar().then((_) => PantallaDiferida._cargadas.add(widget.id));

  @override
  Widget build(BuildContext context) {
    if (_yaCargada) return widget.construir();
    return FutureBuilder<void>(
      future: _carga,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.done && !snap.hasError) {
          return widget.construir();
        }
        return Scaffold(
          backgroundColor: widget.fondo,
          body: Center(
            child: snap.hasError
                ? const Text(
                    'No se pudo conectar. Revisa tu internet e inténtalo de nuevo.')
                : SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: widget.colorIndicador),
                  ),
          ),
        );
      },
    );
  }
}

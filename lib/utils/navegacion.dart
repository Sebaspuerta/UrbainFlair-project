import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/venta.dart';
import '../routes/app_routes.dart';
import '../screens/comprobante_screen.dart' deferred as comprobante;
import '../theme/app_colors.dart';
import '../widgets/pantalla_diferida.dart';

/// Permite navegar desde fuera de un widget (al tocar una notificación).
final navigatorKey = GlobalKey<NavigatorState>();

/// Regresa al Home desde cualquier vista interna
/// (flecha superior derecha, Cancelar y Guardar).
void volverAlHome(BuildContext context) {
  Navigator.popUntil(context, ModalRoute.withName(AppRoutes.home));
}

/// Cierra la sesión en Supabase y lleva al Login
/// (Home y Mi Perfil usan esta función).
Future<void> cerrarSesion(BuildContext context) async {
  try {
    await AppStore.instance.cerrarSesion();
  } catch (_) {
    // Aunque falle la red, se limpia el estado local y se sale.
    AppStore.instance.usuario = null;
  }
  if (!context.mounted) return;
  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
}

/// Abre el comprobante (con QR) de una venta. Su código (QR, compartir) se
/// descarga la primera vez que se abre.
Future<void> abrirComprobante(BuildContext context, Venta venta,
        {bool recienVendida = false}) =>
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => PantallaDiferida(
        id: 'comprobante',
        cargar: comprobante.loadLibrary,
        construir: () => comprobante.ComprobanteScreen(
            venta: venta, recienVendida: recienVendida),
        fondo: AppColors.azulEncabezado,
        colorIndicador: Colors.white,
      ),
    ));

/// true si la URL trae la respuesta del login con Google (OAuth).
bool esRegresoDeAuth(Uri url) {
  const claves = ['code', 'access_token', 'error', 'error_description'];
  final fragmento = Uri.splitQueryString(
      url.fragment.contains('=') ? url.fragment.split('?').last : '');
  return claves.any(
      (c) => url.queryParameters.containsKey(c) || fragmento.containsKey(c));
}

// ------------------------------------------ Toque en notificación de venta

bool _appLista = false;
String? _comprobantePendiente;

/// Callback de las notificaciones de venta: abre el comprobante de esa venta.
/// Si el toque llega mientras la app aún arranca, se guarda y se abre al
/// terminar la carga (ver [marcarAppLista]).
Future<void> abrirComprobanteDeNotificacion(String codigo) async {
  if (!_appLista) {
    _comprobantePendiente = codigo;
    return;
  }
  final store = AppStore.instance;
  var venta = store.ventaPorCodigo(codigo);
  if (venta == null) {
    try {
      await store.cargarVentas();
      venta = store.ventaPorCodigo(codigo);
    } catch (_) {}
  }
  final ctx = navigatorKey.currentContext;
  if (venta != null && ctx != null && ctx.mounted) {
    abrirComprobante(ctx, venta);
  }
}

/// La pantalla de carga terminó: atiende el toque pendiente, si lo hay.
void marcarAppLista() {
  _appLista = true;
  final pendiente = _comprobantePendiente;
  _comprobantePendiente = null;
  if (pendiente != null) abrirComprobanteDeNotificacion(pendiente);
}

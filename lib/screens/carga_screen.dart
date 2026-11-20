import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/app_store.dart';
import '../routes/app_routes.dart';
import '../services/notificaciones_service.dart';
import '../theme/app_colors.dart';
import '../utils/navegacion.dart';
import '../widgets/urban_flair_logo.dart';

/// Primera pantalla: se muestra al instante mientras se recupera la sesión y
/// se cargan los datos, y luego lleva al Login o al Home (mismo criterio que
/// antes hacía main() antes de runApp).
class CargaScreen extends StatefulWidget {
  /// Ruta pedida en la URL (web), p. ej. '/home' al recargar la página.
  final String rutaSolicitada;

  /// true si la app se abrió al volver del login con Google.
  final bool vieneDeAuth;

  const CargaScreen(
      {super.key, required this.rutaSolicitada, required this.vieneDeAuth});

  @override
  State<CargaScreen> createState() => _CargaScreenState();
}

class _CargaScreenState extends State<CargaScreen> {
  /// Tiempo máximo esperando la sesión del regreso de Google.
  static const _esperaMaximaAuth = Duration(seconds: 8);

  @override
  void initState() {
    super.initState();
    _arrancar();
  }

  Future<void> _arrancar() async {
    // Independiente de los datos: corre en paralelo y no bloquea la navegación.
    unawaited(NotificacionesService.instance.inicializar());

    final ruta = widget.rutaSolicitada;
    final pideAuth = ruta == AppRoutes.login || ruta == AppRoutes.registro;

    var destino = AppRoutes.login;
    if (pideAuth) {
      destino = ruta; // URL explícita de login/registro: se respeta.
    } else if (await _haySesion()) {
      try {
        final store = AppStore.instance;
        await Future.wait([store.cargarUsuario(), store.cargarTodo()]);
        destino = AppRoutes.home;
      } catch (_) {
        // Si falla la carga, se queda en el login (igual que antes).
      }
    }
    if (!mounted) return;

    final navegador = Navigator.of(context);
    navegador.pushReplacementNamed(destino);
    // Recarga en una vista interna (p. ej. /#/mis-ventas): se abre encima
    // del Home para que la flecha de volver siga funcionando.
    if (destino == AppRoutes.home &&
        ruta != AppRoutes.home &&
        AppRoutes.routes.containsKey(ruta)) {
      navegador.pushNamed(ruta);
    }
    marcarAppLista();
  }

  /// Hay sesión si Supabase ya la tiene. Si la app viene del regreso de
  /// Google, además escucha onAuthStateChange un tiempo máximo por si la
  /// sesión llega de forma asíncrona. Si se agota, va al login (como antes).
  Future<bool> _haySesion() async {
    final auth = Supabase.instance.client.auth;
    if (auth.currentSession != null) return true;
    if (!widget.vieneDeAuth) return false;
    try {
      await auth.onAuthStateChange
          .firstWhere((e) => e.session != null)
          .timeout(_esperaMaximaAuth);
    } catch (_) {
      // Tiempo agotado o error de autenticación.
    }
    return auth.currentSession != null;
  }

  @override
  Widget build(BuildContext context) {
    // Mismo fondo y logo que la pantalla de login.
    return const Scaffold(
      backgroundColor: AppColors.fondoAuth,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            UrbanFlairLogo(height: 64),
            SizedBox(height: 24),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

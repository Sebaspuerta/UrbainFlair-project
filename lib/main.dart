import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'routes/app_routes.dart';
import 'screens/carga_screen.dart';
import 'services/notificaciones_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_text_styles.dart';
import 'utils/navegacion.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Las fuentes vienen en assets/fonts: no se descargan de internet.
  GoogleFonts.config.allowRuntimeFetching = false;

  // Se lee antes de initialize(): Supabase limpia el ?code= de la URL al
  // procesar el regreso de Google.
  final vieneDeAuth = esRegresoDeAuth(Uri.base);

  // En web, initialize() también recupera la sesión del regreso de Google.
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

  // Se registra antes de inicializar el plugin (eso ocurre en CargaScreen).
  NotificacionesService.instance.alTocar = abrirComprobanteDeNotificacion;

  runApp(UrbanFlairApp(vieneDeAuth: vieneDeAuth));
}

class UrbanFlairApp extends StatelessWidget {
  /// true si la app se abrió al volver del login con Google (web).
  final bool vieneDeAuth;

  const UrbanFlairApp({super.key, this.vieneDeAuth = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Urban Flair',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.azulBoton),
        textTheme: AppTextStyles.temaTexto(),
      ),
      routes: AppRoutes.routes,
      // Siempre arranca en la pantalla de carga; ella decide login / home.
      // rutaUrl es la ruta de la URL en web (p. ej. al recargar /#/home).
      onGenerateInitialRoutes: (rutaUrl) => [
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: AppRoutes.carga),
          builder: (_) =>
              CargaScreen(rutaSolicitada: rutaUrl, vieneDeAuth: vieneDeAuth),
        ),
      ],
    );
  }
}

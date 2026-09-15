import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app.dart';
import 'src/datos/controlador_admin.dart';
import 'src/datos/repositorio_admin.dart';
import 'src/datos/repositorio_admin_supabase.dart';
import 'src/nucleo/entorno.dart';

/// Panel admin del Reto 50 Onix. Usa el mismo proyecto Supabase que la
/// landing (`landin_onix`), pero solo a traves de las funciones admin_*.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Entorno.cargar();

  var problema = Entorno.problema;
  if (problema == null) {
    try {
      await Supabase.initialize(
        url: Entorno.urlSupabase,
        publishableKey: Entorno.claveAnonima,
        // La sesion es el token propio de administrador, no Supabase Auth.
        authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      );
    } catch (error) {
      problema = 'No se pudo inicializar Supabase: $error';
    }
  }

  final RepositorioAdmin repositorio = problema == null
      ? RepositorioAdminSupabase(Supabase.instance.client)
      : const _RepositorioNoDisponible();

  runApp(
    AplicacionAdmin(
      controlador: ControladorAdmin(
        repositorio,
        intervaloSondeo: Entorno.intervaloSondeo,
      ),
      problemaArranque: problema,
    ),
  );
}

/// Cuando falta la configuracion el panel solo muestra el aviso: cualquier
/// operacion responde con el mismo error.
class _RepositorioNoDisponible implements RepositorioAdmin {
  const _RepositorioNoDisponible();

  @override
  dynamic noSuchMethod(Invocation invocacion) => Future<Never>.error(
        const ErrorAdmin(
          'sinConfiguracion',
          'El panel no está configurado. Revisa el archivo .env.',
        ),
      );
}

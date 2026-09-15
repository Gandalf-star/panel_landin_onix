import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'modelos_admin.dart';
import 'repositorio_admin.dart';

/// [RepositorioAdmin] sobre el proyecto Supabase de la landing.
///
/// Todo pasa por las funciones `admin_*` de `docs/esquema_supabase_admin.sql`
/// (en la carpeta de la landing). Cada una exige el token de sesion de
/// administrador: con la clave publica sola no se lee ni se cambia nada.
class RepositorioAdminSupabase implements RepositorioAdmin {
  RepositorioAdminSupabase(this.cliente);

  final SupabaseClient cliente;

  static const _claveToken = 'onix_admin_token';

  /// Evento que emite la base al abrirse una caja (`fn_avisar_panel_admin`).
  static const eventoPremio = 'premio_reclamado';

  String? _token;

  // -------------------------------------------------------------------------
  // Sesion
  // -------------------------------------------------------------------------

  @override
  Future<SesionAdmin?> sesionGuardada() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_claveToken);
    if (token == null) return null;
    final json = await _rpc('admin_sesion', {'p_token': token});
    if (json == null) {
      await prefs.remove(_claveToken);
      return null;
    }
    _token = token;
    return SesionAdmin.desdeJson(_sinError(json));
  }

  @override
  Future<SesionAdmin> iniciarSesion(String usuario, String contrasena) async {
    final json = _sinError(await _rpc('admin_iniciar_sesion', {
      'p_usuario': usuario.trim(),
      'p_contrasena': contrasena,
    }));
    final sesion = SesionAdmin.desdeJson(json);
    _token = sesion.token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveToken, sesion.token);
    return sesion;
  }

  @override
  Future<void> cerrarSesion() async {
    final token = _token;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_claveToken);
    if (token == null) return;
    try {
      await cliente.rpc<dynamic>('admin_cerrar_sesion', params: {
        'p_token': token,
      });
    } catch (_) {
      // Cerrar la sesion local no puede fallar por culpa del servidor.
    }
  }

  // -------------------------------------------------------------------------
  // Consultas
  // -------------------------------------------------------------------------

  @override
  Future<ResumenAdmin> resumen() async =>
      ResumenAdmin.desdeJson(await _conToken('admin_resumen'));

  @override
  Future<List<NotificacionAdmin>> notificaciones({int limite = 40}) async {
    final json = await _conToken('admin_notificaciones', {'p_limite': limite});
    return [
      for (final item in (json['notificaciones'] as List? ?? const []))
        NotificacionAdmin.desdeJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> marcarNotificaciones([List<int>? ids]) async {
    await _conToken('admin_marcar_notificaciones', {'p_ids': ids});
  }

  @override
  Future<List<ReclamoAdmin>> reclamos({EstadoReclamo? estado}) async {
    final json = await _conToken('admin_reclamos', {'p_estado': estado?.clave});
    return [
      for (final item in (json['reclamos'] as List? ?? const []))
        ReclamoAdmin.desdeJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<DetalleReclamo> detalleReclamo(String idReclamo) async =>
      DetalleReclamo.desdeJson(
        await _conToken('admin_detalle_reclamo', {'p_reclamo': idReclamo}),
      );

  @override
  Future<DetalleReclamo> buscarCodigo(String codigo) async =>
      DetalleReclamo.desdeJson(
        await _conToken('admin_buscar_codigo', {'p_codigo': codigo}),
      );

  @override
  Future<ReclamoAdmin> cambiarEstado(
    String idReclamo,
    EstadoReclamo estado, {
    String? nota,
  }) async {
    final json = await _conToken('admin_cambiar_estado_reclamo', {
      'p_reclamo': idReclamo,
      'p_estado': estado.clave,
      'p_nota': nota,
    });
    return ReclamoAdmin.desdeJson(json['reclamo'] as Map<String, dynamic>);
  }

  @override
  Future<List<FilaParticipante>> participantes({String? busqueda}) async {
    final json = await _conToken('admin_participantes', {
      'p_busqueda': busqueda,
      'p_limite': 120,
    });
    return [
      for (final item in (json['participantes'] as List? ?? const []))
        FilaParticipante.desdeJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<FichaParticipante> fichaParticipante(String idParticipante) async {
    final json = await _conToken('admin_detalle_participante', {
      'p_participante': idParticipante,
    });
    return FichaParticipante.desdeJson(json['ficha'] as Map<String, dynamic>);
  }

  @override
  Future<FichaParticipante> habilitarGanadorPrueba(
    String idParticipante, {
    required bool habilitar,
  }) async {
    final json = await _conToken('admin_habilitar_ganador_prueba', {
      'p_participante': idParticipante,
      'p_habilitar': habilitar,
    });
    return FichaParticipante.desdeJson(json['ficha'] as Map<String, dynamic>);
  }

  @override
  Future<FichaParticipante> reiniciarReclamoPrueba(String idReclamo) async {
    final json = await _conToken('admin_reiniciar_reclamo_prueba', {
      'p_reclamo': idReclamo,
    });
    return FichaParticipante.desdeJson(json['ficha'] as Map<String, dynamic>);
  }

  // -------------------------------------------------------------------------
  // Avisos en tiempo real
  // -------------------------------------------------------------------------

  @override
  Future<void Function()> escucharAvisos(void Function() alAviso) async {
    // El mensaje de la base no trae datos: solo avisa que hay novedades y
    // el panel las pide con su token. Aunque alguien mas escuche el canal,
    // no se entera de nada.
    final canal = cliente
        .channel('onix-panel-admin')
        .onBroadcast(event: eventoPremio, callback: (_) => alAviso())
        .subscribe();
    return () {
      cliente.removeChannel(canal);
    };
  }

  // -------------------------------------------------------------------------
  // Internos
  // -------------------------------------------------------------------------

  Future<Map<String, dynamic>> _conToken(
    String funcion, [
    Map<String, dynamic> parametros = const {},
  ]) async {
    final token = _token;
    if (token == null) {
      throw const ErrorAdmin(
        'sesionAdminExpirada',
        'Tu sesión de administrador expiró. Vuelve a ingresar.',
      );
    }
    return _sinError(await _rpc(funcion, {'p_token': token, ...parametros}));
  }

  Future<Object?> _rpc(String funcion, Map<String, dynamic> parametros) async {
    try {
      return await cliente.rpc<dynamic>(funcion, params: parametros);
    } on PostgrestException catch (error) {
      final texto = error.message.toLowerCase();
      if (texto.contains('could not find') || texto.contains('schema cache')) {
        throw const ErrorAdmin(
          'esquemaIncompleto',
          'A la base le falta la parte del panel admin. Ejecuta '
              'docs/esquema_supabase_completo.sql de la landing en el SQL '
              'Editor de Supabase.',
        );
      }
      throw ErrorAdmin('desconocido', error.message);
    } on ErrorAdmin {
      rethrow;
    } catch (_) {
      throw const ErrorAdmin(
        'sinConexion',
        'No pudimos conectar con Supabase. Revisa tu conexión.',
      );
    }
  }

  /// Las funciones devuelven los errores de negocio dentro del JSON.
  static Map<String, dynamic> _sinError(Object? respuesta) {
    if (respuesta is! Map<String, dynamic>) {
      throw const ErrorAdmin('desconocido', 'Respuesta inesperada del servidor.');
    }
    final error = respuesta['error'];
    if (error is Map) {
      throw ErrorAdmin(
        '${error['motivo'] ?? 'desconocido'}',
        '${error['mensaje'] ?? 'Algo falló en el servidor.'}',
      );
    }
    return respuesta;
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../utiles/aviso_navegador.dart';
import 'modelos_admin.dart';
import 'repositorio_admin.dart';

/// Estado compartido del panel: la sesion, el resumen, las notificaciones y
/// la vigilancia de reclamos nuevos.
///
/// Los reclamos nuevos llegan por dos caminos: el aviso instantaneo de
/// Realtime y una consulta periodica de respaldo. Cualquiera de los dos
/// dispara [refrescarAvisos], que es la unica que decide si hay algo nuevo.
class ControladorAdmin extends ChangeNotifier {
  ControladorAdmin(
    this._repositorio, {
    this.intervaloSondeo = const Duration(seconds: 15),
  });

  final RepositorioAdmin _repositorio;

  /// Cada cuanto se consultan reclamos nuevos. `Duration.zero` desactiva la
  /// consulta periodica y deja solo los avisos de Realtime.
  final Duration intervaloSondeo;

  SesionAdmin? sesion;
  ResumenAdmin resumen = const ResumenAdmin();
  List<NotificacionAdmin> notificaciones = const [];

  bool cargandoInicial = true;
  bool ingresando = false;
  String? mensajeError;

  /// Sube cada vez que cambia algo en el servidor (un reclamo nuevo, un
  /// cambio de estado). Las vistas lo escuchan para volver a cargar.
  int versionDatos = 0;

  final _nuevas = StreamController<NotificacionAdmin>.broadcast();

  /// Notificaciones que llegaron mientras el panel estaba abierto.
  Stream<NotificacionAdmin> get notificacionesNuevas => _nuevas.stream;

  Timer? _sondeo;
  void Function()? _cancelarAvisos;
  int? _ultimaVista;
  bool _refrescando = false;
  bool _desechado = false;

  bool get haySesion => sesion != null;

  RepositorioAdmin get repositorio => _repositorio;

  Future<void> inicializar() async {
    try {
      sesion = await _repositorio.sesionGuardada();
      if (sesion != null) await _arrancarVigilancia();
    } on ErrorAdmin catch (error) {
      mensajeError = error.mensaje;
    } catch (_) {
      mensajeError = 'No pudimos conectar con Supabase.';
    } finally {
      cargandoInicial = false;
      _avisar();
    }
  }

  Future<bool> ingresar(String usuario, String contrasena) async {
    ingresando = true;
    mensajeError = null;
    _avisar();
    try {
      sesion = await _repositorio.iniciarSesion(usuario, contrasena);
      await _arrancarVigilancia();
      return true;
    } on ErrorAdmin catch (error) {
      mensajeError = error.mensaje;
      return false;
    } catch (_) {
      mensajeError = 'No pudimos conectar con Supabase.';
      return false;
    } finally {
      ingresando = false;
      _avisar();
    }
  }

  Future<void> cerrarSesion() async {
    _detenerVigilancia();
    await _repositorio.cerrarSesion();
    sesion = null;
    resumen = const ResumenAdmin();
    notificaciones = const [];
    _ultimaVista = null;
    AvisoNavegador.contadorEnTitulo(0);
    _avisar();
  }

  /// Pide resumen y notificaciones. Si aparecen notificaciones nuevas las
  /// anuncia (dentro del panel, con sonido y en el navegador).
  Future<void> refrescarAvisos() async {
    if (sesion == null || _refrescando) return;
    _refrescando = true;
    try {
      final resultados = await Future.wait<Object>([
        _repositorio.resumen(),
        _repositorio.notificaciones(),
      ]);
      resumen = resultados[0] as ResumenAdmin;
      notificaciones = resultados[1] as List<NotificacionAdmin>;

      final ultima = resumen.ultimaNotificacion ?? 0;
      final anterior = _ultimaVista;
      if (anterior != null && ultima > anterior) {
        final nuevas = notificaciones.where((n) => n.id > anterior).toList();
        for (final nueva in nuevas.reversed) {
          _nuevas.add(nueva);
        }
        if (nuevas.isNotEmpty) {
          AvisoNavegador.sonar();
          AvisoNavegador.notificar(nuevas.first.titulo, nuevas.first.detalle);
        }
        versionDatos++;
      }
      _ultimaVista = ultima;
      AvisoNavegador.contadorEnTitulo(resumen.notificacionesSinLeer);
    } on ErrorAdmin catch (error) {
      if (error.sesionVencida) await _sesionVencida();
    } catch (_) {
      // Sin conexion momentanea: el siguiente sondeo lo vuelve a intentar.
    } finally {
      _refrescando = false;
      _avisar();
    }
  }

  Future<void> marcarLeidas([List<int>? ids]) async {
    await _intentar(() => _repositorio.marcarNotificaciones(ids));
    await refrescarAvisos();
  }

  // -------------------------------------------------------------------------
  // Operaciones que usan las vistas. Todas pasan por [_intentar] para cerrar
  // la sesion local si el servidor dice que vencio.
  // -------------------------------------------------------------------------

  Future<List<ReclamoAdmin>> reclamos({EstadoReclamo? estado}) =>
      _intentar(() => _repositorio.reclamos(estado: estado));

  Future<DetalleReclamo> detalleReclamo(String id) =>
      _intentar(() => _repositorio.detalleReclamo(id));

  Future<DetalleReclamo> buscarCodigo(String codigo) =>
      _intentar(() => _repositorio.buscarCodigo(codigo));

  Future<List<FilaParticipante>> participantes({String? busqueda}) =>
      _intentar(() => _repositorio.participantes(busqueda: busqueda));

  Future<FichaParticipante> fichaParticipante(String id) =>
      _intentar(() => _repositorio.fichaParticipante(id));

  Future<ReclamoAdmin> cambiarEstado(
    String idReclamo,
    EstadoReclamo estado, {
    String? nota,
  }) async {
    final reclamo = await _intentar(
      () => _repositorio.cambiarEstado(idReclamo, estado, nota: nota),
    );
    await _datosCambiaron();
    return reclamo;
  }

  Future<FichaParticipante> habilitarGanadorPrueba(
    String idParticipante, {
    required bool habilitar,
  }) async {
    final ficha = await _intentar(
      () => _repositorio.habilitarGanadorPrueba(
        idParticipante,
        habilitar: habilitar,
      ),
    );
    await _datosCambiaron();
    return ficha;
  }

  Future<FichaParticipante> reiniciarReclamoPrueba(String idReclamo) async {
    final ficha =
        await _intentar(() => _repositorio.reiniciarReclamoPrueba(idReclamo));
    await _datosCambiaron();
    return ficha;
  }

  // -------------------------------------------------------------------------

  Future<void> _arrancarVigilancia() async {
    _detenerVigilancia();
    await refrescarAvisos();
    if (intervaloSondeo > Duration.zero) {
      _sondeo = Timer.periodic(intervaloSondeo, (_) => refrescarAvisos());
    }
    try {
      _cancelarAvisos = await _repositorio.escucharAvisos(refrescarAvisos);
    } catch (_) {
      // Si Realtime no esta disponible queda la consulta periodica.
    }
  }

  void _detenerVigilancia() {
    _sondeo?.cancel();
    _sondeo = null;
    _cancelarAvisos?.call();
    _cancelarAvisos = null;
  }

  Future<void> _datosCambiaron() async {
    versionDatos++;
    await refrescarAvisos();
  }

  Future<T> _intentar<T>(Future<T> Function() operacion) async {
    try {
      return await operacion();
    } on ErrorAdmin catch (error) {
      if (error.sesionVencida) await _sesionVencida();
      rethrow;
    }
  }

  Future<void> _sesionVencida() async {
    if (sesion == null) return;
    await cerrarSesion();
    mensajeError = 'Tu sesión de administrador expiró. Vuelve a ingresar.';
    _avisar();
  }

  void _avisar() {
    if (!_desechado) notifyListeners();
  }

  @override
  void dispose() {
    _desechado = true;
    _detenerVigilancia();
    _nuevas.close();
    super.dispose();
  }
}

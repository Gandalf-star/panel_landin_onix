import 'modelos_admin.dart';

/// Error de negocio del panel, con el motivo que devuelve la base.
class ErrorAdmin implements Exception {
  const ErrorAdmin(this.motivo, this.mensaje);

  final String motivo;
  final String mensaje;

  bool get sesionVencida => motivo == 'sesionAdminExpirada';

  @override
  String toString() => 'ErrorAdmin($motivo): $mensaje';
}

/// Contrato de datos del panel admin. Las pantallas solo conocen esto.
abstract interface class RepositorioAdmin {
  /// Sesion guardada en este navegador si sigue vigente.
  Future<SesionAdmin?> sesionGuardada();

  Future<SesionAdmin> iniciarSesion(String usuario, String contrasena);

  Future<void> cerrarSesion();

  Future<ResumenAdmin> resumen();

  Future<List<NotificacionAdmin>> notificaciones({int limite = 40});

  /// Marca como leidas las notificaciones indicadas, o todas si es `null`.
  Future<void> marcarNotificaciones([List<int>? ids]);

  /// Reclamos, filtrados por estado si se indica (sin los reiniciados).
  Future<List<ReclamoAdmin>> reclamos({EstadoReclamo? estado});

  Future<DetalleReclamo> detalleReclamo(String idReclamo);

  /// Busca el reclamo al que pertenece un codigo de confirmacion.
  Future<DetalleReclamo> buscarCodigo(String codigo);

  Future<ReclamoAdmin> cambiarEstado(
    String idReclamo,
    EstadoReclamo estado, {
    String? nota,
  });

  Future<List<FilaParticipante>> participantes({String? busqueda});

  Future<FichaParticipante> fichaParticipante(String idParticipante);

  Future<FichaParticipante> habilitarGanadorPrueba(
    String idParticipante, {
    required bool habilitar,
  });

  Future<FichaParticipante> reiniciarReclamoPrueba(String idReclamo);

  /// Se suscribe a los avisos instantaneos de reclamos nuevos. Devuelve la
  /// funcion para cancelar la suscripcion.
  Future<void Function()> escucharAvisos(void Function() alAviso);
}

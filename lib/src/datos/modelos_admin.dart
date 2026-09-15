import 'package:flutter/material.dart';

import '../utiles/formato.dart';

// ---------------------------------------------------------------------------
// Lectura segura del JSON que devuelven las funciones admin_* de la base.
// ---------------------------------------------------------------------------

int _entero(Object? valor) =>
    valor is int ? valor : int.tryParse('${valor ?? 0}') ?? 0;

DateTime? _fecha(Object? valor) =>
    valor == null ? null : DateTime.tryParse('$valor')?.toLocal();

String? _texto(Object? valor) => valor is String ? valor : null;

Map<String, dynamic> _mapa(Object? valor) =>
    valor is Map<String, dynamic> ? valor : const {};

List<Map<String, dynamic>> _lista(Object? valor) => valor is List
    ? [for (final item in valor) if (item is Map<String, dynamic>) item]
    : const [];

// ---------------------------------------------------------------------------

/// Los tres premios de las cajas, con la misma clave que usa la base.
enum PremioCaja {
  viaje('1 viaje gratis', Icons.local_taxi_rounded),
  regalo('Un regalo Onix', Icons.redeem_rounded),
  saldo('\$3.000 de saldo Onix', Icons.account_balance_wallet_rounded);

  const PremioCaja(this.titulo, this.icono);

  final String titulo;
  final IconData icono;

  static PremioCaja? desdeClave(Object? clave) {
    for (final premio in values) {
      if (premio.name == clave) return premio;
    }
    return null;
  }
}

enum EstadoReclamo {
  cajasListas('cajas_listas', 'Sin abrir', Icons.inventory_2_rounded),
  pendiente('pendiente', 'Por revisar', Icons.schedule_rounded),
  verificado('verificado', 'Verificado', Icons.verified_rounded),
  entregado('entregado', 'Entregado', Icons.check_circle_rounded),
  rechazado('rechazado', 'Rechazado', Icons.block_rounded),
  reiniciado('reiniciado', 'Reiniciado', Icons.restart_alt_rounded);

  const EstadoReclamo(this.clave, this.etiqueta, this.icono);

  final String clave;
  final String etiqueta;
  final IconData icono;

  static EstadoReclamo desdeClave(Object? clave) => values.firstWhere(
        (estado) => estado.clave == clave,
        orElse: () => EstadoReclamo.pendiente,
      );
}

@immutable
class SesionAdmin {
  const SesionAdmin({
    required this.id,
    required this.usuario,
    required this.nombre,
    required this.token,
    required this.canalAvisos,
    this.expiraEn,
  });

  factory SesionAdmin.desdeJson(Map<String, dynamic> json) => SesionAdmin(
        id: json['id'] as String,
        usuario: json['usuario'] as String,
        nombre: _texto(json['nombre']) ?? json['usuario'] as String,
        token: json['token'] as String,
        canalAvisos: _texto(json['canal_avisos']) ?? 'onix-panel-admin',
        expiraEn: _fecha(json['expira_en']),
      );

  final String id;
  final String usuario;
  final String nombre;
  final String token;
  final String canalAvisos;
  final DateTime? expiraEn;
}

@immutable
class ResumenAdmin {
  const ResumenAdmin({
    this.participantes = 0,
    this.invitadosVerificados = 0,
    this.metasAlcanzadas = 0,
    this.reclamosPorRevisar = 0,
    this.reclamosVerificados = 0,
    this.reclamosEntregados = 0,
    this.notificacionesSinLeer = 0,
    this.ultimaNotificacion,
  });

  factory ResumenAdmin.desdeJson(Map<String, dynamic> json) => ResumenAdmin(
        participantes: _entero(json['participantes']),
        invitadosVerificados: _entero(json['invitados_verificados']),
        metasAlcanzadas: _entero(json['metas_alcanzadas']),
        reclamosPorRevisar: _entero(json['reclamos_por_revisar']),
        reclamosVerificados: _entero(json['reclamos_verificados']),
        reclamosEntregados: _entero(json['reclamos_entregados']),
        notificacionesSinLeer: _entero(json['notificaciones_sin_leer']),
        ultimaNotificacion: json['ultima_notificacion'] == null
            ? null
            : _entero(json['ultima_notificacion']),
      );

  final int participantes;
  final int invitadosVerificados;
  final int metasAlcanzadas;
  final int reclamosPorRevisar;
  final int reclamosVerificados;
  final int reclamosEntregados;
  final int notificacionesSinLeer;
  final int? ultimaNotificacion;
}

@immutable
class NotificacionAdmin {
  const NotificacionAdmin({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.detalle,
    required this.creadoEn,
    required this.leida,
    this.reclamoId,
    this.participanteId,
  });

  factory NotificacionAdmin.desdeJson(Map<String, dynamic> json) =>
      NotificacionAdmin(
        id: _entero(json['id']),
        tipo: _texto(json['tipo']) ?? '',
        titulo: _texto(json['titulo']) ?? '',
        detalle: _texto(json['detalle']) ?? '',
        creadoEn: _fecha(json['creado_en']) ?? DateTime.now(),
        leida: json['leida'] == true,
        reclamoId: _texto(json['reclamo_id']),
        participanteId: _texto(json['participante_id']),
      );

  final int id;
  final String tipo;
  final String titulo;
  final String detalle;
  final DateTime creadoEn;
  final bool leida;
  final String? reclamoId;
  final String? participanteId;
}

/// Datos basicos del ganador que acompañan a cada reclamo.
@immutable
class GanadorResumen {
  const GanadorResumen({
    required this.id,
    required this.nombre,
    required this.telefonoE164,
    required this.tickets,
    this.nombreUsuario,
    this.ganadorPrueba = false,
  });

  factory GanadorResumen.desdeJson(Map<String, dynamic> json) =>
      GanadorResumen(
        id: _texto(json['id']) ?? '',
        nombre: _texto(json['nombre']) ?? 'Participante',
        nombreUsuario: _texto(json['nombre_usuario']),
        telefonoE164: _texto(json['telefono_e164']) ?? '',
        tickets: _entero(json['tickets']),
        ganadorPrueba: json['ganador_prueba'] == true,
      );

  final String id;
  final String nombre;
  final String? nombreUsuario;
  final String telefonoE164;
  final int tickets;
  final bool ganadorPrueba;
}

@immutable
class ReclamoAdmin {
  const ReclamoAdmin({
    required this.id,
    required this.estado,
    required this.esPrueba,
    required this.distribucion,
    required this.creadoEn,
    required this.ganador,
    this.cajaElegida,
    this.premio,
    this.codigoConfirmacion,
    this.ticketsAlReclamar = 0,
    this.abiertoEn,
    this.revisadoEn,
    this.revisadoPor,
    this.notaAdmin,
  });

  factory ReclamoAdmin.desdeJson(Map<String, dynamic> json) => ReclamoAdmin(
        id: json['id'] as String,
        estado: EstadoReclamo.desdeClave(json['estado']),
        esPrueba: json['es_prueba'] == true,
        distribucion: [
          for (final clave in (json['distribucion'] as List?) ?? const [])
            ?PremioCaja.desdeClave(clave),
        ],
        cajaElegida:
            json['caja_elegida'] == null ? null : _entero(json['caja_elegida']),
        premio: PremioCaja.desdeClave(json['premio']),
        codigoConfirmacion: _texto(json['codigo_confirmacion']),
        ticketsAlReclamar: _entero(json['tickets_al_reclamar']),
        creadoEn: _fecha(json['creado_en']) ?? DateTime.now(),
        abiertoEn: _fecha(json['abierto_en']),
        revisadoEn: _fecha(json['revisado_en']),
        revisadoPor: _texto(json['revisado_por']),
        notaAdmin: _texto(json['nota_admin']),
        ganador: GanadorResumen.desdeJson(_mapa(json['participante'])),
      );

  final String id;
  final EstadoReclamo estado;
  final bool esPrueba;

  /// Premio que habia en cada caja (0, 1 y 2).
  final List<PremioCaja> distribucion;
  final int? cajaElegida;
  final PremioCaja? premio;
  final String? codigoConfirmacion;
  final int ticketsAlReclamar;
  final DateTime creadoEn;
  final DateTime? abiertoEn;
  final DateTime? revisadoEn;
  final String? revisadoPor;
  final String? notaAdmin;
  final GanadorResumen ganador;

  String get codigoVisible => Formato.codigoConfirmacion(codigoConfirmacion);

  bool get cajaAbierta => cajaElegida != null;

  DateTime get fechaReferencia => abiertoEn ?? creadoEn;
}

/// Lo que la landing registro del dispositivo (navegador) de una persona.
@immutable
class InfoDispositivo {
  const InfoDispositivo({
    this.descripcion,
    this.agente,
    this.plataforma,
    this.idioma,
    this.pantalla,
    this.zonaHoraria,
    this.nucleos,
    this.tactil,
  });

  factory InfoDispositivo.desdeJson(Object? valor) {
    final json = _mapa(valor);
    return InfoDispositivo(
      descripcion: _texto(json['descripcion']),
      agente: _texto(json['agente']),
      plataforma: _texto(json['plataforma']),
      idioma: _texto(json['idioma']),
      pantalla: _texto(json['pantalla']),
      zonaHoraria: _texto(json['zona_horaria']),
      nucleos: _texto(json['nucleos']),
      tactil: _texto(json['tactil']),
    );
  }

  final String? descripcion;
  final String? agente;
  final String? plataforma;
  final String? idioma;
  final String? pantalla;
  final String? zonaHoraria;
  final String? nucleos;
  final String? tactil;

  bool get vacio => descripcion == null && agente == null;

  /// `Chrome 128 · Android 14 · 412x915@2.6 · America/Santiago`.
  String get resumen => [
        descripcion ?? 'Dispositivo sin datos',
        ?pantalla,
        ?zonaHoraria,
      ].where((parte) => parte.isNotEmpty).join(' · ');
}

@immutable
class InvitadoAdmin {
  const InvitadoAdmin({
    required this.id,
    required this.nombre,
    required this.telefonoE164,
    this.nombreUsuario,
    this.creadoEn,
  });

  factory InvitadoAdmin.desdeJson(Map<String, dynamic> json) => InvitadoAdmin(
        id: _texto(json['id']) ?? '',
        nombre: _texto(json['nombre']) ?? 'Invitado',
        nombreUsuario: _texto(json['nombre_usuario']),
        telefonoE164: _texto(json['telefono_e164']) ?? '',
        creadoEn: _fecha(json['creado_en']),
      );

  final String id;
  final String nombre;
  final String? nombreUsuario;
  final String telefonoE164;
  final DateTime? creadoEn;
}

/// Un codigo compartido por el participante y, si se canjeo, el invitado y
/// el dispositivo que quedo anclado.
@immutable
class InvitacionAdmin {
  const InvitacionAdmin({
    required this.id,
    required this.codigo,
    required this.estado,
    required this.creadoEn,
    this.expiraEn,
    this.usadaEn,
    this.invitado,
    this.estadoReferido,
    this.huella,
    this.firma,
    this.dispositivo = const InfoDispositivo(),
    this.ip,
    this.mismaFirma = 0,
    this.mismaIp = 0,
    this.firmaDelInvitador = false,
  });

  factory InvitacionAdmin.desdeJson(Map<String, dynamic> json) =>
      InvitacionAdmin(
        id: _texto(json['id']) ?? '',
        codigo: _texto(json['codigo']) ?? '',
        estado: _texto(json['estado']) ?? 'pendiente',
        creadoEn: _fecha(json['creado_en']) ?? DateTime.now(),
        expiraEn: _fecha(json['expira_en']),
        usadaEn: _fecha(json['usada_en']),
        invitado: json['invitado'] is Map<String, dynamic>
            ? InvitadoAdmin.desdeJson(json['invitado'] as Map<String, dynamic>)
            : null,
        estadoReferido: _texto(json['estado_referido']),
        huella: _texto(json['huella']),
        firma: _texto(json['firma']),
        dispositivo: InfoDispositivo.desdeJson(json['dispositivo']),
        ip: _texto(json['ip']),
        mismaFirma: _entero(json['misma_firma']),
        mismaIp: _entero(json['misma_ip']),
        firmaDelInvitador: json['firma_del_invitador'] == true,
      );

  final String id;
  final String codigo;

  /// `usada`, `pendiente` o `expirada`.
  final String estado;
  final DateTime creadoEn;
  final DateTime? expiraEn;
  final DateTime? usadaEn;
  final InvitadoAdmin? invitado;
  final String? estadoReferido;
  final String? huella;
  final String? firma;
  final InfoDispositivo dispositivo;
  final String? ip;

  /// Otros invitados de la misma persona con la misma firma de navegador.
  final int mismaFirma;

  /// Otros invitados de la misma persona registrados desde la misma IP.
  final int mismaIp;

  /// El invitado uso un navegador con la misma firma que quien lo invito.
  final bool firmaDelInvitador;

  bool get usada => estado == 'usada';

  String get codigoVisible => Formato.codigoInvitacion(codigo);

  /// Hay algo que el administrador deberia mirar con calma.
  bool get sospechosa => mismaFirma > 0 || firmaDelInvitador || mismaIp > 1;
}

@immutable
class ParticipanteAdmin {
  const ParticipanteAdmin({
    required this.id,
    required this.nombre,
    required this.telefonoE164,
    required this.creadoEn,
    this.nombreUsuario,
    this.estado = 'activo',
    this.ganadorPrueba = false,
    this.huella,
    this.firma,
    this.dispositivo = const InfoDispositivo(),
    this.ipRegistro,
    this.tickets = 0,
    this.referidosPendientes = 0,
    this.codigoConQueEntro,
  });

  factory ParticipanteAdmin.desdeJson(Map<String, dynamic> json) =>
      ParticipanteAdmin(
        id: _texto(json['id']) ?? '',
        nombre: _texto(json['nombre']) ?? 'Participante',
        nombreUsuario: _texto(json['nombre_usuario']),
        telefonoE164: _texto(json['telefono_e164']) ?? '',
        estado: _texto(json['estado']) ?? 'activo',
        ganadorPrueba: json['ganador_prueba'] == true,
        creadoEn: _fecha(json['creado_en']) ?? DateTime.now(),
        huella: _texto(json['huella_dispositivo']),
        firma: _texto(json['firma_dispositivo']),
        dispositivo: InfoDispositivo.desdeJson(json['dispositivo']),
        ipRegistro: _texto(json['ip_registro']),
        tickets: _entero(json['tickets']),
        referidosPendientes: _entero(json['referidos_pendientes']),
        codigoConQueEntro: _texto(json['codigo_con_que_entro']),
      );

  final String id;
  final String nombre;
  final String? nombreUsuario;
  final String telefonoE164;
  final String estado;
  final bool ganadorPrueba;
  final DateTime creadoEn;
  final String? huella;
  final String? firma;
  final InfoDispositivo dispositivo;
  final String? ipRegistro;
  final int tickets;
  final int referidosPendientes;
  final String? codigoConQueEntro;
}

/// Todo lo que el panel sabe de un participante.
@immutable
class FichaParticipante {
  const FichaParticipante({
    required this.participante,
    required this.invitaciones,
    required this.reclamos,
  });

  factory FichaParticipante.desdeJson(Map<String, dynamic> json) =>
      FichaParticipante(
        participante: ParticipanteAdmin.desdeJson(_mapa(json['participante'])),
        invitaciones: [
          for (final item in _lista(json['invitaciones']))
            InvitacionAdmin.desdeJson(item),
        ],
        reclamos: [
          for (final item in _lista(json['reclamos']))
            ReclamoAdmin.desdeJson(item),
        ],
      );

  final ParticipanteAdmin participante;
  final List<InvitacionAdmin> invitaciones;
  final List<ReclamoAdmin> reclamos;

  List<InvitacionAdmin> get canjeadas =>
      invitaciones.where((i) => i.usada).toList();

  List<InvitacionAdmin> get sinCanjear =>
      invitaciones.where((i) => !i.usada).toList();

  int get sospechosas => canjeadas.where((i) => i.sospechosa).length;

  ReclamoAdmin? get reclamoVigente {
    for (final reclamo in reclamos) {
      if (reclamo.estado != EstadoReclamo.reiniciado) return reclamo;
    }
    return null;
  }
}

@immutable
class DetalleReclamo {
  const DetalleReclamo({required this.reclamo, required this.ficha});

  factory DetalleReclamo.desdeJson(Map<String, dynamic> json) => DetalleReclamo(
        reclamo: ReclamoAdmin.desdeJson(_mapa(json['reclamo'])),
        ficha: FichaParticipante.desdeJson(_mapa(json['ficha'])),
      );

  final ReclamoAdmin reclamo;
  final FichaParticipante ficha;
}

/// Fila del buscador de participantes.
@immutable
class FilaParticipante {
  const FilaParticipante({
    required this.id,
    required this.nombre,
    required this.telefonoE164,
    required this.tickets,
    required this.creadoEn,
    this.nombreUsuario,
    this.ganadorPrueba = false,
    this.estadoReclamo,
    this.reclamoId,
    this.reclamoPrueba = false,
  });

  factory FilaParticipante.desdeJson(Map<String, dynamic> json) =>
      FilaParticipante(
        id: _texto(json['id']) ?? '',
        nombre: _texto(json['nombre']) ?? 'Participante',
        nombreUsuario: _texto(json['nombre_usuario']),
        telefonoE164: _texto(json['telefono_e164']) ?? '',
        tickets: _entero(json['tickets']),
        creadoEn: _fecha(json['creado_en']) ?? DateTime.now(),
        ganadorPrueba: json['ganador_prueba'] == true,
        estadoReclamo: json['estado_reclamo'] == null
            ? null
            : EstadoReclamo.desdeClave(json['estado_reclamo']),
        reclamoId: _texto(json['reclamo_id']),
        reclamoPrueba: json['reclamo_prueba'] == true,
      );

  final String id;
  final String nombre;
  final String? nombreUsuario;
  final String telefonoE164;
  final int tickets;
  final DateTime creadoEn;
  final bool ganadorPrueba;
  final EstadoReclamo? estadoReclamo;
  final String? reclamoId;
  final bool reclamoPrueba;
}

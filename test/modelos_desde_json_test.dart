import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:panel_admin_onix/src/datos/modelos_admin.dart';

/// Respuestas copiadas tal cual de las funciones admin_* del proyecto
/// Supabase (generadas en una transaccion de prueba que se deshizo). Si la
/// base cambia la forma de un JSON, estas pruebas lo delatan.
const _buscarCodigo = r'''
{"ficha": {"reclamos": [{"id": "d671580d-b44d-4d50-aff6-69fd935c885c", "estado": "pendiente", "premio": "viaje", "creado_en": "2026-09-15T06:10:17.174293+00:00", "es_prueba": true, "abierto_en": "2026-09-15T06:10:17.174293+00:00", "nota_admin": null, "revisado_en": null, "caja_elegida": 2, "distribucion": ["regalo", "saldo", "viaje"], "participante": {"id": "49981575-64c2-4392-8e75-f05e36e1755a", "nombre": "Camila Torres", "tickets": 1, "telefono_e164": "+56911112222", "ganador_prueba": true, "nombre_usuario": "camila.prueba"}, "revisado_por": null, "codigo_confirmacion": "FFCJHVB2WR", "tickets_al_reclamar": 1}], "invitaciones": [{"id": "d86f6ae4-64ad-4cfa-b486-3c3ca717d37d", "ip": null, "firma": null, "codigo": "MJ2ASAG2", "estado": "pendiente", "huella": null, "invitado": null, "misma_ip": 0, "usada_en": null, "creado_en": "2026-09-15T06:10:17.174293+00:00", "expira_en": "2026-09-22T06:10:17.174293+00:00", "dispositivo": null, "misma_firma": 0, "estado_referido": null, "firma_del_invitador": false}, {"id": "80a321c7-a8f5-4328-b899-b1158e70068b", "ip": "10.0.0.1", "firma": "firma_inv", "codigo": "HM6MR3U8", "estado": "usada", "huella": "h1", "invitado": {"id": "bf84badd-c3e9-451e-bfb9-76c4e88ac682", "estado": "activo", "nombre": "Matías Rivas", "creado_en": "2026-09-15T06:10:17.174293+00:00", "telefono_e164": "+56911113333", "nombre_usuario": "matias.prueba"}, "misma_ip": 0, "usada_en": "2026-09-15T06:10:17.174293+00:00", "creado_en": "2026-09-15T06:10:17.174293+00:00", "expira_en": "2026-09-22T06:10:17.174293+00:00", "dispositivo": {"firma": "firma_inv", "pantalla": "390x844@3", "descripcion": "Safari 17 · iPhone iOS 17", "zona_horaria": "America/Santiago"}, "misma_firma": 0, "estado_referido": "valido", "firma_del_invitador": true}], "participante": {"id": "49981575-64c2-4392-8e75-f05e36e1755a", "estado": "activo", "nombre": "Camila Torres", "tickets": 1, "creado_en": "2026-09-15T06:10:17.174293+00:00", "dispositivo": {"pantalla": "1920x1080@1", "descripcion": "Chrome 128 · Windows 10"}, "ip_registro": null, "telefono_e164": "+56911112222", "ganador_prueba": true, "nombre_usuario": "camila.prueba", "firma_dispositivo": "firma_inv", "huella_dispositivo": "h_inv", "codigo_con_que_entro": null, "referidos_pendientes": 0}}, "reclamo": {"id": "d671580d-b44d-4d50-aff6-69fd935c885c", "estado": "pendiente", "premio": "viaje", "creado_en": "2026-09-15T06:10:17.174293+00:00", "es_prueba": true, "abierto_en": "2026-09-15T06:10:17.174293+00:00", "nota_admin": null, "revisado_en": null, "caja_elegida": 2, "distribucion": ["regalo", "saldo", "viaje"], "participante": {"id": "49981575-64c2-4392-8e75-f05e36e1755a", "nombre": "Camila Torres", "tickets": 1, "telefono_e164": "+56911112222", "ganador_prueba": true, "nombre_usuario": "camila.prueba"}, "revisado_por": null, "codigo_confirmacion": "FFCJHVB2WR", "tickets_al_reclamar": 1}}
''';

const _resumen = r'''
{"participantes": 2, "metas_alcanzadas": 0, "reclamos_entregados": 0, "ultima_notificacion": 2, "reclamos_por_revisar": 0, "reclamos_verificados": 0, "invitados_verificados": 1, "notificaciones_sin_leer": 1}
''';

const _notificaciones = r'''
{"notificaciones": [{"id": 2, "tipo": "premio_reclamado", "leida": false, "titulo": "Prueba · Camila Torres abrió una caja", "detalle": "1 viaje gratis · código PRM-FFCJH-VB2WR", "creado_en": "2026-09-15T06:10:17.174293+00:00", "reclamo_id": "d671580d-b44d-4d50-aff6-69fd935c885c", "participante_id": "49981575-64c2-4392-8e75-f05e36e1755a"}]}
''';

const _participantes = r'''
{"participantes": [{"id": "49981575-64c2-4392-8e75-f05e36e1755a", "estado": "activo", "nombre": "Camila Torres", "tickets": 1, "creado_en": "2026-09-15T06:10:17.174293+00:00", "reclamo_id": "d671580d-b44d-4d50-aff6-69fd935c885c", "telefono_e164": "+56911112222", "estado_reclamo": "pendiente", "ganador_prueba": true, "nombre_usuario": "camila.prueba", "reclamo_prueba": true}]}
''';

Map<String, dynamic> _json(String texto) =>
    jsonDecode(texto) as Map<String, dynamic>;

void main() {
  test('lee el detalle que devuelve admin_buscar_codigo', () {
    final detalle = DetalleReclamo.desdeJson(_json(_buscarCodigo));
    final reclamo = detalle.reclamo;

    expect(reclamo.estado, EstadoReclamo.pendiente);
    expect(reclamo.esPrueba, isTrue);
    expect(reclamo.premio, PremioCaja.viaje);
    expect(reclamo.cajaElegida, 2);
    expect(reclamo.distribucion, [
      PremioCaja.regalo,
      PremioCaja.saldo,
      PremioCaja.viaje,
    ]);
    expect(reclamo.codigoVisible, 'PRM-FFCJH-VB2WR');
    expect(reclamo.ganador.nombreUsuario, 'camila.prueba');

    final ficha = detalle.ficha;
    expect(ficha.participante.ganadorPrueba, isTrue);
    expect(ficha.participante.dispositivo.descripcion, 'Chrome 128 · Windows 10');
    expect(ficha.invitaciones, hasLength(2));
    expect(ficha.canjeadas, hasLength(1));
    expect(ficha.sinCanjear, hasLength(1));

    final canjeada = ficha.canjeadas.single;
    expect(canjeada.codigoVisible, 'ONX-HM6M-R3U8');
    expect(canjeada.invitado?.telefonoE164, '+56911113333');
    expect(canjeada.ip, '10.0.0.1');
    expect(canjeada.dispositivo.zonaHoraria, 'America/Santiago');
    expect(canjeada.firmaDelInvitador, isTrue);
    expect(canjeada.sospechosa, isTrue);
    expect(ficha.sospechosas, 1);

    // Una invitacion sin canjear trae `dispositivo: null`.
    expect(ficha.sinCanjear.single.dispositivo.vacio, isTrue);
  });

  test('lee resumen, notificaciones y participantes', () {
    final resumen = ResumenAdmin.desdeJson(_json(_resumen));
    expect(resumen.ultimaNotificacion, 2);
    expect(resumen.notificacionesSinLeer, 1);
    expect(resumen.invitadosVerificados, 1);

    final notificacion = NotificacionAdmin.desdeJson(
      (_json(_notificaciones)['notificaciones'] as List).first
          as Map<String, dynamic>,
    );
    expect(notificacion.id, 2);
    expect(notificacion.leida, isFalse);
    expect(notificacion.reclamoId, 'd671580d-b44d-4d50-aff6-69fd935c885c');

    final fila = FilaParticipante.desdeJson(
      (_json(_participantes)['participantes'] as List).first
          as Map<String, dynamic>,
    );
    expect(fila.estadoReclamo, EstadoReclamo.pendiente);
    expect(fila.ganadorPrueba, isTrue);
    expect(fila.reclamoPrueba, isTrue);
  });
}

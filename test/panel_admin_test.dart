import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_admin_onix/src/app.dart';
import 'package:panel_admin_onix/src/datos/controlador_admin.dart';
import 'package:panel_admin_onix/src/datos/modelos_admin.dart';
import 'package:panel_admin_onix/src/datos/repositorio_admin.dart';

/// Repositorio falso con un ganador, su reclamo y dos invitados (uno con el
/// mismo navegador que el ganador), para probar el panel sin Supabase.
class RepositorioFalso implements RepositorioAdmin {
  bool conSesion = false;
  bool ganadorPrueba = false;
  EstadoReclamo estado = EstadoReclamo.pendiente;
  int ultimaNotificacion = 1;
  void Function()? avisar;

  static const codigo = 'ABCDE23456';

  final _sesion = const SesionAdmin(
    id: 'a1',
    usuario: 'luis',
    nombre: 'Luis',
    token: 't',
    canalAvisos: 'onix-panel-admin',
  );

  ReclamoAdmin get _reclamo => ReclamoAdmin(
        id: 'r1',
        estado: estado,
        esPrueba: false,
        distribucion: const [PremioCaja.regalo, PremioCaja.saldo, PremioCaja.viaje],
        cajaElegida: 1,
        premio: PremioCaja.saldo,
        codigoConfirmacion: codigo,
        ticketsAlReclamar: 50,
        creadoEn: DateTime(2026, 9, 15, 10),
        abiertoEn: DateTime(2026, 9, 15, 10, 1),
        ganador: const GanadorResumen(
          id: 'p1',
          nombre: 'Camila Torres',
          nombreUsuario: 'camila',
          telefonoE164: '+56964831207',
          tickets: 50,
        ),
      );

  FichaParticipante get _ficha => FichaParticipante(
        participante: ParticipanteAdmin(
          id: 'p1',
          nombre: 'Camila Torres',
          nombreUsuario: 'camila',
          telefonoE164: '+56964831207',
          creadoEn: DateTime(2026, 9, 1),
          tickets: 50,
          ganadorPrueba: ganadorPrueba,
          firma: 'firma_camila',
          dispositivo: const InfoDispositivo(descripcion: 'Chrome 128 · Android 14'),
        ),
        invitaciones: [
          InvitacionAdmin(
            id: 'i1',
            codigo: '7K4Q2P9M',
            estado: 'usada',
            creadoEn: DateTime(2026, 9, 2),
            usadaEn: DateTime(2026, 9, 3),
            invitado: const InvitadoAdmin(
              id: 'p2',
              nombre: 'Matías Rivas',
              telefonoE164: '+56964831208',
            ),
            estadoReferido: 'valido',
            huella: 'nav_1',
            firma: 'firma_matias',
            dispositivo: const InfoDispositivo(descripcion: 'Safari 17 · iPhone iOS 17'),
            ip: '10.0.0.1',
          ),
          InvitacionAdmin(
            id: 'i2',
            codigo: '8M3N4P5Q',
            estado: 'usada',
            creadoEn: DateTime(2026, 9, 2),
            usadaEn: DateTime(2026, 9, 4),
            invitado: const InvitadoAdmin(
              id: 'p3',
              nombre: 'Javiera Soto',
              telefonoE164: '+56964831209',
            ),
            estadoReferido: 'valido',
            huella: 'nav_2',
            firma: 'firma_camila',
            ip: '10.0.0.2',
            firmaDelInvitador: true,
          ),
        ],
        reclamos: [_reclamo],
      );

  @override
  Future<SesionAdmin?> sesionGuardada() async => conSesion ? _sesion : null;

  @override
  Future<SesionAdmin> iniciarSesion(String usuario, String contrasena) async {
    if (contrasena != 'ClaveAdmin123') {
      throw const ErrorAdmin(
        'credencialesIncorrectas',
        'Usuario o contraseña incorrectos.',
      );
    }
    conSesion = true;
    return _sesion;
  }

  @override
  Future<void> cerrarSesion() async => conSesion = false;

  @override
  Future<ResumenAdmin> resumen() async => ResumenAdmin(
        participantes: 3,
        reclamosPorRevisar: estado == EstadoReclamo.pendiente ? 1 : 0,
        notificacionesSinLeer: 1,
        ultimaNotificacion: ultimaNotificacion,
      );

  @override
  Future<List<NotificacionAdmin>> notificaciones({int limite = 40}) async => [
        for (var id = ultimaNotificacion; id >= 1; id--)
          NotificacionAdmin(
            id: id,
            tipo: 'premio_reclamado',
            titulo: 'Camila Torres reclamó su premio',
            detalle: '\$3.000 de saldo Onix · código PRM-ABCDE-23456',
            creadoEn: DateTime.now(),
            leida: false,
            reclamoId: 'r1',
          ),
      ];

  @override
  Future<void> marcarNotificaciones([List<int>? ids]) async {}

  @override
  Future<List<ReclamoAdmin>> reclamos({EstadoReclamo? estado}) async =>
      estado == null || estado == this.estado ? [_reclamo] : const [];

  @override
  Future<DetalleReclamo> detalleReclamo(String idReclamo) async =>
      DetalleReclamo(reclamo: _reclamo, ficha: _ficha);

  @override
  Future<DetalleReclamo> buscarCodigo(String codigo) async {
    final limpio = codigo.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
    if (limpio != 'PRM${RepositorioFalso.codigo}' &&
        limpio != RepositorioFalso.codigo) {
      throw const ErrorAdmin(
        'codigoConfirmacionInexistente',
        'Ese código no corresponde a ningún premio.',
      );
    }
    return DetalleReclamo(reclamo: _reclamo, ficha: _ficha);
  }

  @override
  Future<ReclamoAdmin> cambiarEstado(
    String idReclamo,
    EstadoReclamo estado, {
    String? nota,
  }) async {
    this.estado = estado;
    return _reclamo;
  }

  @override
  Future<List<FilaParticipante>> participantes({String? busqueda}) async => [
        FilaParticipante(
          id: 'p1',
          nombre: 'Camila Torres',
          nombreUsuario: 'camila',
          telefonoE164: '+56964831207',
          tickets: 50,
          creadoEn: DateTime(2026, 9, 1),
          ganadorPrueba: ganadorPrueba,
        ),
      ];

  @override
  Future<FichaParticipante> fichaParticipante(String idParticipante) async =>
      _ficha;

  @override
  Future<FichaParticipante> habilitarGanadorPrueba(
    String idParticipante, {
    required bool habilitar,
  }) async {
    ganadorPrueba = habilitar;
    return _ficha;
  }

  @override
  Future<FichaParticipante> reiniciarReclamoPrueba(String idReclamo) async =>
      _ficha;

  @override
  Future<void Function()> escucharAvisos(void Function() alAviso) async {
    avisar = alAviso;
    return () => avisar = null;
  }
}

void main() {
  late RepositorioFalso repositorio;
  late ControladorAdmin controlador;

  Future<void> montar(WidgetTester tester, {bool conSesion = false}) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    repositorio = RepositorioFalso()..conSesion = conSesion;
    // Sin sondeo periodico: en las pruebas los avisos se disparan a mano.
    controlador = ControladorAdmin(repositorio, intervaloSondeo: Duration.zero);
    addTearDown(controlador.dispose);

    await tester.pumpWidget(AplicacionAdmin(controlador: controlador));
    await tester.pumpAndSettle();
  }

  testWidgets('pide usuario y contraseña y rechaza una clave equivocada',
      (tester) async {
    await montar(tester);

    expect(find.text('Ingresar al panel'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Usuario'), 'luis');
    await tester.enterText(
      find.widgetWithText(TextField, 'Contraseña'),
      'mala',
    );
    await tester.tap(find.text('Ingresar al panel'));
    await tester.pumpAndSettle();

    expect(find.text('Usuario o contraseña incorrectos.'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Contraseña'),
      'ClaveAdmin123',
    );
    await tester.tap(find.text('Ingresar al panel'));
    await tester.pumpAndSettle();

    expect(find.text('Reclamos por revisar'), findsOneWidget);
    expect(find.text('\$3.000 de saldo Onix'), findsWidgets);
  });

  testWidgets('verificar un código muestra el ganador y sus invitados',
      (tester) async {
    await montar(tester, conSesion: true);

    await tester.tap(find.text('Verificar código').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'prm-abcde-23456');
    await tester.tap(find.text('Verificar'));
    await tester.pumpAndSettle();

    expect(find.text('Código válido'), findsOneWidget);
    expect(find.text('PRM-ABCDE-23456'), findsWidgets);
    expect(find.text('+56 9 6483 1208'), findsOneWidget);
    expect(find.text('ONX-7K4Q-2P9M'), findsOneWidget);
    expect(find.text('Mismo navegador que el ganador'), findsOneWidget);

    await tester.ensureVisible(find.text('Confirmar verificación'));
    await tester.tap(find.text('Confirmar verificación'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(repositorio.estado, EstadoReclamo.verificado);
  });

  testWidgets('un código inexistente se marca como no válido', (tester) async {
    await montar(tester, conSesion: true);

    await tester.tap(find.text('Verificar código').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'PRM-ZZZZZ-ZZZZZ');
    await tester.tap(find.text('Verificar'));
    await tester.pumpAndSettle();

    expect(find.text('Código no válido'), findsOneWidget);
  });

  testWidgets('un reclamo nuevo avisa dentro del panel', (tester) async {
    await montar(tester, conSesion: true);

    repositorio.ultimaNotificacion = 2;
    repositorio.avisar!();
    await tester.pumpAndSettle();

    expect(find.textContaining('Camila Torres reclamó su premio'), findsWidgets);
    expect(find.widgetWithText(SnackBarAction, 'Ver'), findsOneWidget);
  });

  testWidgets('habilita una cuenta como ganadora de prueba', (tester) async {
    await montar(tester, conSesion: true);

    await tester.tap(find.text('Participantes').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Camila Torres'));
    await tester.pumpAndSettle();

    expect(find.text('Ganador de prueba'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(repositorio.ganadorPrueba, isTrue);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_admin_onix/src/app.dart';
import 'package:panel_admin_onix/src/datos/controlador_admin.dart';
import 'package:panel_admin_onix/src/utiles/aviso_navegador.dart';

import 'fuentes_prueba.dart';
import 'panel_admin_test.dart' show RepositorioFalso;

/// El panel se usa desde el celular, la tablet y el computador: cada vista
/// tiene que montar sin desbordes en todos esos tamaños.
void main() {
  setUpAll(cargarFuentesReales);

  const tamanos = <String, Size>{
    'celular chico': Size(320, 568),
    'celular': Size(360, 800),
    'celular acostado': Size(844, 390),
    'tablet vertical': Size(768, 1024),
    'computador': Size(1440, 900),
  };

  Future<void> montar(WidgetTester tester, Size tamano) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    // Simula un navegador con notificaciones sin permiso todavia: asi la
    // barra superior muestra tambien el boton «Activar avisos».
    AvisoNavegador.disponiblesEnPruebas = true;
    addTearDown(() => AvisoNavegador.disponiblesEnPruebas = null);

    final controlador = ControladorAdmin(
      RepositorioFalso()..conSesion = true,
      intervaloSondeo: Duration.zero,
    );
    addTearDown(controlador.dispose);
    await tester.pumpWidget(AplicacionAdmin(controlador: controlador));
    await tester.pumpAndSettle();
  }

  /// Alarga la vista para que las listas construyan todo su contenido.
  Future<void> alargar(WidgetTester tester, Size tamano) async {
    tester.view.physicalSize = Size(tamano.width, 3200);
    await tester.pumpAndSettle();
  }

  Future<void> irA(WidgetTester tester, String seccion) async {
    final enMenuInferior = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(seccion),
    );
    await tester.tap(
      enMenuInferior.evaluate().isNotEmpty
          ? enMenuInferior
          : find.text(seccion).first,
    );
    await tester.pumpAndSettle();
  }

  for (final MapEntry(key: nombre, value: tamano) in tamanos.entries) {
    group('$nombre (${tamano.width.toInt()}x${tamano.height.toInt()})', () {
      testWidgets('reclamos', (tester) async {
        await montar(tester, tamano);
        await alargar(tester, tamano);
        expect(find.text('Reclamos por revisar'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('verificar un código con su detalle', (tester) async {
        await montar(tester, tamano);
        await irA(tester, 'Verificar código');
        await tester.enterText(
          find.byType(TextField).first,
          'PRM-ABCDE-23456',
        );
        await tester.tap(find.text('Verificar'));
        await tester.pumpAndSettle();
        await alargar(tester, tamano);

        expect(find.text('Código válido'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('participantes y ficha', (tester) async {
        await montar(tester, tamano);
        await irA(tester, 'Participantes');
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Camila Torres'));
        await tester.pumpAndSettle();
        await alargar(tester, tamano);

        expect(find.text('Ganador de prueba'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('panel de notificaciones', (tester) async {
        await montar(tester, tamano);
        await tester.tap(find.byTooltip('Notificaciones'));
        await tester.pumpAndSettle();

        expect(find.text('Notificaciones'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('ingreso', (tester) async {
        tester.view.physicalSize = tamano;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        final controlador = ControladorAdmin(
          RepositorioFalso(),
          intervaloSondeo: Duration.zero,
        );
        addTearDown(controlador.dispose);
        await tester.pumpWidget(AplicacionAdmin(controlador: controlador));
        await tester.pumpAndSettle();

        expect(find.text('Ingresar al panel'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  }
}

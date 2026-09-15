import 'package:flutter/material.dart';

import 'datos/controlador_admin.dart';
import 'nucleo/tema_admin.dart';
import 'ui/pantalla_ingreso.dart';
import 'ui/pantalla_principal.dart';

/// Deja el [ControladorAdmin] disponible para todo el arbol de widgets.
class ProveedorAdmin extends InheritedNotifier<ControladorAdmin> {
  const ProveedorAdmin({
    super.key,
    required ControladorAdmin controlador,
    required super.child,
  }) : super(notifier: controlador);

  static ControladorAdmin de(BuildContext contexto) {
    final proveedor =
        contexto.dependOnInheritedWidgetOfExactType<ProveedorAdmin>();
    assert(proveedor != null, 'Falta ProveedorAdmin sobre este widget');
    return proveedor!.notifier!;
  }

  /// Acceso sin suscribirse a los cambios (para llamar acciones).
  static ControladorAdmin accion(BuildContext contexto) {
    final proveedor = contexto.getInheritedWidgetOfExactType<ProveedorAdmin>();
    assert(proveedor != null, 'Falta ProveedorAdmin sobre este widget');
    return proveedor!.notifier!;
  }
}

class AplicacionAdmin extends StatefulWidget {
  const AplicacionAdmin({
    super.key,
    required this.controlador,
    this.problemaArranque,
  });

  final ControladorAdmin controlador;

  /// Si el `.env` o Supabase fallaron al arrancar, se muestra en el ingreso.
  final String? problemaArranque;

  @override
  State<AplicacionAdmin> createState() => _AplicacionAdminState();
}

class _AplicacionAdminState extends State<AplicacionAdmin> {
  @override
  void initState() {
    super.initState();
    if (widget.problemaArranque == null) {
      widget.controlador.inicializar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProveedorAdmin(
      controlador: widget.controlador,
      child: MaterialApp(
        title: 'Panel admin · Reto 50 Onix',
        debugShowCheckedModeBanner: false,
        theme: construirTemaAdmin(),
        home: _Raiz(problemaArranque: widget.problemaArranque),
      ),
    );
  }
}

class _Raiz extends StatelessWidget {
  const _Raiz({this.problemaArranque});

  final String? problemaArranque;

  @override
  Widget build(BuildContext context) {
    final controlador = ProveedorAdmin.de(context);

    if (problemaArranque != null) {
      return PantallaIngreso(problemaArranque: problemaArranque);
    }
    if (controlador.cargandoInicial) {
      return const Scaffold(
        backgroundColor: ColoresOnix.azulOnix,
        body: Center(
          child: CircularProgressIndicator(color: ColoresOnix.amarilloOnix),
        ),
      );
    }
    return controlador.haySesion
        ? const PantallaPrincipal()
        : const PantallaIngreso();
  }
}

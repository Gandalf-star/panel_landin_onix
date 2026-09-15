import 'dart:async';

import 'package:flutter/material.dart';

import '../app.dart';
import '../datos/modelos_admin.dart';
import '../nucleo/tema_admin.dart';
import '../utiles/aviso_navegador.dart';
import 'componentes/comunes.dart';
import 'vistas/detalle_reclamo.dart';
import 'vistas/panel_notificaciones.dart';
import 'vistas/vista_participantes.dart';
import 'vistas/vista_reclamos.dart';
import 'vistas/vista_verificar.dart';

/// Estructura del panel: menu lateral (o inferior en celular), barra con la
/// campana de notificaciones y la vista elegida.
class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  static const _secciones = <(IconData, String)>[
    (Icons.redeem_rounded, 'Reclamos'),
    (Icons.fact_check_rounded, 'Verificar código'),
    (Icons.groups_rounded, 'Participantes'),
  ];

  final _clave = GlobalKey<ScaffoldState>();
  int _seccion = 0;
  StreamSubscription<NotificacionAdmin>? _suscripcion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _suscripcion ??= ProveedorAdmin.accion(context)
        .notificacionesNuevas
        .listen(_mostrarNueva);
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    super.dispose();
  }

  void _mostrarNueva(NotificacionAdmin notificacion) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        content: Row(
          children: [
            const Icon(Icons.notifications_active_rounded,
                color: ColoresOnix.amarilloOnix),
            const SizedBox(width: 12),
            Expanded(
              child: Text('${notificacion.titulo}\n${notificacion.detalle}'),
            ),
          ],
        ),
        action: notificacion.reclamoId == null
            ? null
            : SnackBarAction(
                label: 'Ver',
                textColor: ColoresOnix.amarilloOnix,
                onPressed: () => abrirReclamo(context, notificacion.reclamoId!),
              ),
      ),
    );
  }

  Widget _vista() => switch (_seccion) {
        0 => const VistaReclamos(),
        1 => const VistaVerificar(),
        _ => const VistaParticipantes(),
      };

  @override
  Widget build(BuildContext context) {
    final esEscritorio = MedidasAdmin.esEscritorio(context);
    final controlador = ProveedorAdmin.de(context);

    final barra = _BarraSuperior(
      titulo: _secciones[_seccion].$2,
      sinLeer: controlador.resumen.notificacionesSinLeer,
      mostrarLogo: !esEscritorio,
      alAbrirNotificaciones: () => _clave.currentState?.openEndDrawer(),
    );

    // En celular el panel de avisos deja ver un borde de la pantalla detras,
    // para que se note que es un panel y se pueda cerrar tocando afuera.
    final anchoAvisos =
        (MediaQuery.sizeOf(context).width * 0.88).clamp(0.0, 400.0);

    return Scaffold(
      key: _clave,
      endDrawer: Drawer(
        width: anchoAvisos,
        child: const PanelNotificaciones(),
      ),
      bottomNavigationBar: esEscritorio
          ? null
          : NavigationBar(
              selectedIndex: _seccion,
              onDestinationSelected: (i) => setState(() => _seccion = i),
              destinations: [
                for (final (icono, texto) in _secciones)
                  NavigationDestination(icon: Icon(icono), label: texto),
              ],
            ),
      body: esEscritorio
          ? Row(
              children: [
                _MenuLateral(
                  secciones: _secciones,
                  seleccionada: _seccion,
                  alElegir: (i) => setState(() => _seccion = i),
                ),
                Expanded(
                  child: Column(
                    children: [barra, Expanded(child: _vista())],
                  ),
                ),
              ],
            )
          : SafeArea(
              child: Column(children: [barra, Expanded(child: _vista())]),
            ),
    );
  }
}

class _MenuLateral extends StatelessWidget {
  const _MenuLateral({
    required this.secciones,
    required this.seleccionada,
    required this.alElegir,
  });

  final List<(IconData, String)> secciones;
  final int seleccionada;
  final ValueChanged<int> alElegir;

  @override
  Widget build(BuildContext context) {
    final controlador = ProveedorAdmin.de(context);
    final sesion = controlador.sesion;

    return Container(
      width: 250,
      decoration: const BoxDecoration(gradient: GradientesOnix.fondoOscuro),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 26, 22, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: LogoOnix(alto: 34),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 4, 22, 26),
              child: Text(
                'PANEL ADMIN · RETO 50',
                style: TextStyle(
                  color: ColoresOnix.amarilloOnix,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            for (var i = 0; i < secciones.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                child: Material(
                  color: i == seleccionada
                      ? ColoresOnix.blanco.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(MedidasAdmin.radio),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(MedidasAdmin.radio),
                    ),
                    leading: Icon(
                      secciones[i].$1,
                      color: i == seleccionada
                          ? ColoresOnix.amarilloOnix
                          : ColoresOnix.sobreAzulSuave,
                    ),
                    title: Text(
                      secciones[i].$2,
                      style: TextStyle(
                        color: i == seleccionada
                            ? ColoresOnix.blanco
                            : ColoresOnix.sobreAzul,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    trailing: i == 0 && controlador.resumen.reclamosPorRevisar > 0
                        ? _Contador(valor: controlador.resumen.reclamosPorRevisar)
                        : null,
                    onTap: () => alElegir(i),
                  ),
                ),
              ),
            const Spacer(),
            const Divider(color: ColoresOnix.bordeSobreAzul),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: ColoresOnix.amarilloOnix,
                child: Icon(Icons.shield_rounded, color: ColoresOnix.azulOnix),
              ),
              title: Text(
                sesion?.nombre ?? '',
                style: const TextStyle(
                  color: ColoresOnix.blanco,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                '@${sesion?.usuario ?? ''}',
                style: const TextStyle(color: ColoresOnix.sobreAzulSuave),
              ),
              trailing: IconButton(
                tooltip: 'Cerrar sesión',
                icon: const Icon(Icons.logout_rounded),
                color: ColoresOnix.sobreAzulSuave,
                onPressed: controlador.cerrarSesion,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _BarraSuperior extends StatelessWidget {
  const _BarraSuperior({
    required this.titulo,
    required this.sinLeer,
    required this.mostrarLogo,
    required this.alAbrirNotificaciones,
  });

  final String titulo;
  final int sinLeer;
  final bool mostrarLogo;
  final VoidCallback alAbrirNotificaciones;

  @override
  Widget build(BuildContext context) {
    final controlador = ProveedorAdmin.accion(context);
    final esMovil = MedidasAdmin.esMovil(context);

    return Container(
      height: 68,
      padding: EdgeInsets.symmetric(horizontal: esMovil ? 8 : 20),
      decoration: const BoxDecoration(
        color: ColoresOnix.blanco,
        border: Border(bottom: BorderSide(color: ColoresOnix.borde)),
      ),
      child: Row(
        children: [
          if (mostrarLogo) ...[
            if (esMovil) const SizedBox(width: 8),
            const LogoOnix(alto: 26, sobreFondoOscuro: false),
            SizedBox(width: esMovil ? 10 : 14),
          ],
          Expanded(
            child: Text(
              titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontSize: esMovil ? 17 : null),
            ),
          ),
          _BotonActivarAvisos(compacto: !MedidasAdmin.esEscritorio(context)),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: controlador.refrescarAvisos,
            icon: const Icon(Icons.refresh_rounded),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Notificaciones',
                onPressed: alAbrirNotificaciones,
                icon: const Icon(Icons.notifications_rounded),
              ),
              if (sinLeer > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: IgnorePointer(child: _Contador(valor: sinLeer)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pide permiso para las notificaciones del navegador. Desaparece una vez
/// concedido (o si el navegador no las soporta).
class _BotonActivarAvisos extends StatefulWidget {
  const _BotonActivarAvisos({required this.compacto});

  /// En celular y tablet solo el icono: el texto no cabe junto al titulo.
  final bool compacto;

  @override
  State<_BotonActivarAvisos> createState() => _BotonActivarAvisosState();
}

class _BotonActivarAvisosState extends State<_BotonActivarAvisos> {
  @override
  Widget build(BuildContext context) {
    if (!AvisoNavegador.notificacionesDisponibles ||
        AvisoNavegador.notificacionesActivas) {
      return const SizedBox.shrink();
    }
    if (widget.compacto) {
      return IconButton(
        tooltip: 'Activar avisos',
        onPressed: _activar,
        icon: const Icon(Icons.notifications_off_rounded),
      );
    }
    return TextButton.icon(
      onPressed: _activar,
      icon: const Icon(Icons.notifications_off_rounded, size: 18),
      label: const Text('Activar avisos'),
    );
  }

  Future<void> _activar() async {
    final mensajero = ScaffoldMessenger.of(context);
    final activas = await AvisoNavegador.pedirPermiso();
    if (!mounted) return;
    setState(() {});
    mensajero.showSnackBar(
      SnackBar(
        content: Text(
          activas
              ? 'Listo: te avisaremos aunque el panel esté en segundo '
                  'plano.'
              : 'El navegador no dio permiso para notificar.',
        ),
      ),
    );
  }
}

class _Contador extends StatelessWidget {
  const _Contador({required this.valor});

  final int valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: ColoresOnix.rojo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        valor > 99 ? '99+' : '$valor',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: ColoresOnix.blanco,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app.dart';
import '../../datos/modelos_admin.dart';
import '../../datos/repositorio_admin.dart';
import '../../nucleo/tema_admin.dart';
import '../../utiles/formato.dart';
import '../componentes/carga.dart';
import '../componentes/comunes.dart';
import '../componentes/tabla_invitados.dart';
import 'detalle_participante.dart';

/// Abre la pagina de un reclamo.
Future<void> abrirReclamo(BuildContext context, String idReclamo) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PaginaReclamo(idReclamo: idReclamo),
    ),
  );
}

class PaginaReclamo extends StatelessWidget {
  const PaginaReclamo({super.key, required this.idReclamo});

  final String idReclamo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reclamo de premio')),
      body: CargaAdmin<DetalleReclamo>(
        claveCarga: idReclamo,
        cargar: (controlador) => controlador.detalleReclamo(idReclamo),
        construir: (contexto, detalle, recargar) => SingleChildScrollView(
          padding: EdgeInsets.all(MedidasAdmin.margen(contexto)),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: ContenidoReclamo(
                detalle: detalle,
                alActualizar: recargar,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Todo lo necesario para verificar un reclamo: el ticket, las cajas, las
/// acciones, el ganador y sus invitados con los dispositivos anclados.
class ContenidoReclamo extends StatelessWidget {
  const ContenidoReclamo({
    super.key,
    required this.detalle,
    required this.alActualizar,
  });

  final DetalleReclamo detalle;
  final VoidCallback alActualizar;

  @override
  Widget build(BuildContext context) {
    final reclamo = detalle.reclamo;
    final esEscritorio = MedidasAdmin.esEscritorio(context);

    final acciones = _TarjetaVerificacion(
      detalle: detalle,
      alActualizar: alActualizar,
    );
    final cajas = TarjetaSeccion(
      titulo: 'Las tres cajas',
      subtitulo: 'Orden sorteado en el servidor al reclamar.',
      icono: Icons.inventory_2_rounded,
      child: reclamo.distribucion.length == 3
          ? MiniCajas(
              distribucion: reclamo.distribucion,
              elegida: reclamo.cajaElegida,
            )
          : const Text('Sin datos de las cajas.'),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EncabezadoTicket(reclamo: reclamo),
        const SizedBox(height: 16),
        if (esEscritorio)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 5, child: acciones),
                const SizedBox(width: 16),
                Expanded(flex: 4, child: cajas),
              ],
            ),
          )
        else ...[
          acciones,
          const SizedBox(height: 16),
          cajas,
        ],
        const SizedBox(height: 16),
        TarjetaGanador(ficha: detalle.ficha, reclamo: reclamo),
        const SizedBox(height: 16),
        TablaInvitados(ficha: detalle.ficha),
      ],
    );
  }
}

class _EncabezadoTicket extends StatelessWidget {
  const _EncabezadoTicket({required this.reclamo});

  final ReclamoAdmin reclamo;

  @override
  Widget build(BuildContext context) {
    final premio = reclamo.premio;
    final esMovil = MedidasAdmin.esMovil(context);

    final resumen = Row(
      children: [
        Container(
          width: esMovil ? 48 : 58,
          height: esMovil ? 48 : 58,
          decoration: const BoxDecoration(
            gradient: GradientesOnix.dorado,
            shape: BoxShape.circle,
          ),
          child: Icon(
            premio?.icono ?? Icons.inventory_2_rounded,
            color: ColoresOnix.azulOnix,
            size: esMovil ? 24 : 28,
          ),
        ),
        SizedBox(width: esMovil ? 12 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                premio?.titulo ?? 'Cajas sin abrir',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  color: ColoresOnix.blanco,
                  fontSize: esMovil ? 19 : 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Ganador: ${reclamo.ganador.nombre}',
                style: const TextStyle(color: ColoresOnix.sobreAzulSuave),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  EtiquetaEstadoReclamo(estado: reclamo.estado),
                  if (reclamo.esPrueba) const EtiquetaPrueba(),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    final textoCodigo = SelectableText(
      reclamo.codigoVisible,
      style: const TextStyle(
        fontFamily: 'Manrope',
        color: ColoresOnix.amarilloOnix,
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
    );

    final codigo = reclamo.codigoConfirmacion == null
        ? null
        : Column(
            crossAxisAlignment:
                esMovil ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'CÓDIGO DE CONFIRMACIÓN',
                style: TextStyle(
                  color: ColoresOnix.sobreAzulSuave,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              Row(
                mainAxisSize: esMovil ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  // En celular el codigo se achica si no cabe entero.
                  if (esMovil)
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: textoCodigo,
                      ),
                    )
                  else
                    textoCodigo,
                  BotonCopiar(texto: reclamo.codigoVisible, tamano: 18),
                ],
              ),
              Text(
                'Reclamó ${Formato.fechaHora(reclamo.creadoEn)} · abrió '
                '${Formato.fechaHora(reclamo.abiertoEn)}',
                textAlign: esMovil ? TextAlign.start : TextAlign.end,
                style: const TextStyle(
                  color: ColoresOnix.sobreAzulSuave,
                  fontSize: 12.5,
                ),
              ),
            ],
          );

    return Container(
      padding: EdgeInsets.all(esMovil ? 18 : 22),
      decoration: BoxDecoration(
        gradient: GradientesOnix.fondoOscuro,
        borderRadius: BorderRadius.circular(MedidasAdmin.radioGrande),
      ),
      // En celular el premio arriba y el codigo debajo, separados por una
      // linea; desde tablet, premio a la izquierda y codigo a la derecha.
      child: esMovil
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                resumen,
                if (codigo != null) ...[
                  const SizedBox(height: 16),
                  Container(height: 1, color: ColoresOnix.bordeSobreAzul),
                  const SizedBox(height: 14),
                  codigo,
                ],
              ],
            )
          : Row(
              children: [
                Expanded(child: resumen),
                if (codigo != null) ...[
                  const SizedBox(width: 24),
                  codigo,
                ],
              ],
            ),
    );
  }
}

class _TarjetaVerificacion extends StatelessWidget {
  const _TarjetaVerificacion({
    required this.detalle,
    required this.alActualizar,
  });

  final DetalleReclamo detalle;
  final VoidCallback alActualizar;

  @override
  Widget build(BuildContext context) {
    final reclamo = detalle.reclamo;
    final ficha = detalle.ficha;
    const meta = 50;
    final alcanzoMeta = reclamo.ticketsAlReclamar >= meta;

    return TarjetaSeccion(
      titulo: 'Verificación',
      icono: Icons.fact_check_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Chequeo(
            estado: reclamo.esPrueba
                ? _Resultado.info
                : (alcanzoMeta ? _Resultado.bien : _Resultado.mal),
            texto: reclamo.esPrueba
                ? 'Reclamo de prueba (${reclamo.ticketsAlReclamar} tickets): '
                    'no se entrega premio.'
                : '${reclamo.ticketsAlReclamar} tickets al reclamar '
                    '(meta $meta).',
          ),
          _Chequeo(
            estado: ficha.sospechosas == 0 ? _Resultado.bien : _Resultado.alerta,
            texto: ficha.sospechosas == 0
                ? 'Ningún invitado con coincidencias de dispositivo o IP.'
                : '${ficha.sospechosas} invitados con coincidencias: revísalos '
                    'abajo antes de entregar.',
          ),
          _Chequeo(
            estado: reclamo.cajaAbierta ? _Resultado.bien : _Resultado.info,
            texto: reclamo.cajaAbierta
                ? 'Caja ${reclamo.cajaElegida! + 1} abierta el '
                    '${Formato.fechaHora(reclamo.abiertoEn)}.'
                : 'El ganador todavía no elige su caja.',
          ),
          if (reclamo.revisadoPor != null)
            _Chequeo(
              estado: _Resultado.info,
              texto: 'Revisado por @${reclamo.revisadoPor} el '
                  '${Formato.fechaHora(reclamo.revisadoEn)}'
                  '${reclamo.notaAdmin == null ? '' : ' · Nota: ${reclamo.notaAdmin}'}',
            ),
          const SizedBox(height: 14),
          // En celular cada accion ocupa todo el ancho, una bajo otra.
          if (MedidasAdmin.esMovil(context))
            for (final (i, accion) in _acciones(context, reclamo).indexed) ...[
              if (i > 0) const SizedBox(height: 10),
              accion,
            ]
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _acciones(context, reclamo),
            ),
        ],
      ),
    );
  }

  List<Widget> _acciones(BuildContext context, ReclamoAdmin reclamo) {
    Widget boton(
      String texto,
      IconData icono,
      EstadoReclamo destino, {
      bool principal = false,
      bool pedirNota = false,
      Color? color,
    }) {
      void alPresionar() => _cambiar(
            context,
            reclamo,
            destino,
            texto: texto,
            pedirNota: pedirNota,
          );
      return principal
          ? FilledButton.icon(
              onPressed: alPresionar,
              style: color == null
                  ? null
                  : FilledButton.styleFrom(backgroundColor: color),
              icon: Icon(icono, size: 18),
              label: Text(texto),
            )
          : OutlinedButton.icon(
              onPressed: alPresionar,
              style: color == null
                  ? null
                  : OutlinedButton.styleFrom(foregroundColor: color),
              icon: Icon(icono, size: 18),
              label: Text(texto),
            );
    }

    return [
      if (reclamo.estado == EstadoReclamo.pendiente) ...[
        boton('Confirmar verificación', Icons.verified_rounded,
            EstadoReclamo.verificado, principal: true),
        boton('Rechazar', Icons.block_rounded, EstadoReclamo.rechazado,
            pedirNota: true, color: ColoresOnix.rojo),
      ],
      if (reclamo.estado == EstadoReclamo.verificado) ...[
        boton('Marcar entregado', Icons.check_circle_rounded,
            EstadoReclamo.entregado,
            principal: true, color: ColoresOnix.verde),
        boton('Volver a revisión', Icons.undo_rounded, EstadoReclamo.pendiente),
        boton('Rechazar', Icons.block_rounded, EstadoReclamo.rechazado,
            pedirNota: true, color: ColoresOnix.rojo),
      ],
      if (reclamo.estado == EstadoReclamo.rechazado)
        boton('Reabrir revisión', Icons.undo_rounded, EstadoReclamo.pendiente),
      if (reclamo.esPrueba && reclamo.estado != EstadoReclamo.reiniciado)
        OutlinedButton.icon(
          onPressed: () => _reiniciarPrueba(context, reclamo),
          icon: const Icon(Icons.restart_alt_rounded, size: 18),
          label: const Text('Reiniciar prueba'),
        ),
    ];
  }

  Future<void> _cambiar(
    BuildContext context,
    ReclamoAdmin reclamo,
    EstadoReclamo destino, {
    required String texto,
    required bool pedirNota,
  }) async {
    final nota = await _confirmar(
      context,
      titulo: '¿$texto?',
      mensaje: switch (destino) {
        EstadoReclamo.verificado =>
          'Confirmas que el código ${reclamo.codigoVisible} es correcto y que '
              'revisaste a los invitados de ${reclamo.ganador.nombre}.',
        EstadoReclamo.entregado =>
          'El premio «${reclamo.premio?.titulo}» quedará marcado como '
              'entregado.',
        EstadoReclamo.rechazado =>
          'El reclamo quedará anulado. Explica el motivo en la nota.',
        _ => 'El reclamo volverá a quedar pendiente de revisión.',
      },
      pedirNota: pedirNota,
    );
    if (nota == null || !context.mounted) return;

    try {
      await ProveedorAdmin.accion(context).cambiarEstado(
        reclamo.id,
        destino,
        nota: nota.isEmpty ? null : nota,
      );
      if (!context.mounted) return;
      _aviso(context, 'Reclamo actualizado: ${destino.etiqueta}.');
      alActualizar();
    } on ErrorAdmin catch (error) {
      if (context.mounted) _aviso(context, error.mensaje);
    }
  }

  Future<void> _reiniciarPrueba(BuildContext context, ReclamoAdmin reclamo) async {
    final ok = await _confirmar(
      context,
      titulo: '¿Reiniciar la prueba?',
      mensaje: 'La cuenta de ${reclamo.ganador.nombre} podrá volver a reclamar '
          'y elegir una caja. Los premios cambiarán de lugar.',
    );
    if (ok == null || !context.mounted) return;
    try {
      await ProveedorAdmin.accion(context).reiniciarReclamoPrueba(reclamo.id);
      if (!context.mounted) return;
      _aviso(context, 'Prueba reiniciada: ya puede volver a elegir caja.');
      Navigator.of(context).maybePop();
    } on ErrorAdmin catch (error) {
      if (context.mounted) _aviso(context, error.mensaje);
    }
  }
}

enum _Resultado { bien, alerta, mal, info }

class _Chequeo extends StatelessWidget {
  const _Chequeo({required this.estado, required this.texto});

  final _Resultado estado;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final (icono, color) = switch (estado) {
      _Resultado.bien => (Icons.check_circle_rounded, ColoresOnix.verde),
      _Resultado.alerta => (Icons.warning_amber_rounded, ColoresOnix.ambar),
      _Resultado.mal => (Icons.cancel_rounded, ColoresOnix.rojo),
      _Resultado.info => (Icons.info_rounded, ColoresOnix.azulInfo),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 19, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Datos del ganador (o de cualquier participante) y su dispositivo.
class TarjetaGanador extends StatelessWidget {
  const TarjetaGanador({
    super.key,
    required this.ficha,
    this.reclamo,
    this.titulo = 'Ganador',
    this.accion,
  });

  final FichaParticipante ficha;
  final ReclamoAdmin? reclamo;
  final String titulo;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final p = ficha.participante;
    final premio = reclamo?.premio;

    return TarjetaSeccion(
      titulo: titulo,
      icono: Icons.person_rounded,
      accion: accion ??
          TextButton(
            onPressed: () => abrirParticipante(context, p.id),
            child: const Text('Ver ficha'),
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DatoFila(etiqueta: 'Nombre', valor: p.nombre, destacado: true),
          DatoFila(
            etiqueta: 'Usuario',
            valor: p.nombreUsuario == null ? '—' : '@${p.nombreUsuario}',
          ),
          DatoFila(
            etiqueta: 'Teléfono verificado',
            valor: Formato.telefono(p.telefonoE164),
            copiable: true,
          ),
          DatoFila(
            etiqueta: 'Tickets hoy',
            valor: '${p.tickets} · ${p.referidosPendientes} pendientes',
          ),
          DatoFila(
            etiqueta: 'Registrado',
            valor: Formato.fechaHora(p.creadoEn),
          ),
          DatoFila(etiqueta: 'Dispositivo', valor: p.dispositivo.resumen),
          DatoFila(etiqueta: 'IP de registro', valor: p.ipRegistro ?? '—'),
          DatoFila(
            etiqueta: 'Firma del navegador',
            valor: p.firma ?? '—',
          ),
          if (p.codigoConQueEntro != null)
            DatoFila(
              etiqueta: 'Entró invitado con',
              valor: Formato.codigoInvitacion(p.codigoConQueEntro),
            ),
          if (p.ganadorPrueba)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Etiqueta(
                  texto: 'Habilitado como ganador de prueba',
                  color: Color(0xFF8A5CF6),
                  icono: Icons.science_rounded,
                ),
              ),
            ),
          const SizedBox(height: 12),
          // En celular el boton ocupa todo el ancho, como las acciones.
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: MedidasAdmin.esMovil(context) ? double.infinity : null,
              child: OutlinedButton.icon(
                onPressed: () => launchUrl(
                  Formato.whatsapp(
                    p.telefonoE164,
                    premio == null
                        ? 'Hola ${p.nombre.split(' ').first}, te escribimos del '
                            'equipo de Onix Drive por el Reto 50 Onix.'
                        : 'Hola ${p.nombre.split(' ').first}, te escribimos del '
                            'equipo de Onix Drive por tu ticket ganador '
                            '${reclamo!.codigoVisible} del Reto 50 Onix '
                            '(${premio.titulo}).',
                  ),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.chat_rounded, size: 18),
                label: const Text('Escribir por WhatsApp'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialogo de confirmacion. Devuelve la nota escrita (o '' sin nota), o
/// `null` si se cancela.
Future<String?> _confirmar(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  bool pedirNota = false,
}) {
  final nota = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (contexto) => AlertDialog(
      title: Text(titulo),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(mensaje),
            const SizedBox(height: 14),
            TextField(
              controller: nota,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: pedirNota ? 'Motivo' : 'Nota (opcional)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(contexto).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(contexto).pop(nota.text.trim()),
          child: const Text('Confirmar'),
        ),
      ],
    ),
  ).whenComplete(nota.dispose);
}

void _aviso(BuildContext context, String texto) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
}

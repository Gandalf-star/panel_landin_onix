import 'package:flutter/material.dart';

import '../../app.dart';
import '../../datos/modelos_admin.dart';
import '../../datos/repositorio_admin.dart';
import '../../nucleo/tema_admin.dart';
import '../../utiles/formato.dart';
import '../componentes/carga.dart';
import '../componentes/comunes.dart';
import '../componentes/tabla_invitados.dart';
import 'detalle_reclamo.dart';

Future<void> abrirParticipante(BuildContext context, String idParticipante) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PaginaParticipante(idParticipante: idParticipante),
    ),
  );
}

/// Ficha de un participante: sus datos, el modo ganador de prueba, sus
/// reclamos y los invitados que sumo con cada codigo.
class PaginaParticipante extends StatelessWidget {
  const PaginaParticipante({super.key, required this.idParticipante});

  final String idParticipante;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ficha del participante')),
      body: CargaAdmin<FichaParticipante>(
        claveCarga: idParticipante,
        cargar: (controlador) => controlador.fichaParticipante(idParticipante),
        construir: (contexto, ficha, recargar) => SingleChildScrollView(
          padding: EdgeInsets.all(MedidasAdmin.margen(contexto)),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ModoPrueba(ficha: ficha),
                  const SizedBox(height: 16),
                  TarjetaGanador(
                    ficha: ficha,
                    titulo: 'Datos del participante',
                    accion: const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                  _Reclamos(ficha: ficha),
                  const SizedBox(height: 16),
                  TablaInvitados(ficha: ficha),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Interruptor para habilitar la cuenta como ganadora de prueba.
class _ModoPrueba extends StatefulWidget {
  const _ModoPrueba({required this.ficha});

  final FichaParticipante ficha;

  @override
  State<_ModoPrueba> createState() => _ModoPruebaState();
}

class _ModoPruebaState extends State<_ModoPrueba> {
  bool _guardando = false;

  Future<void> _cambiar(bool habilitar) async {
    setState(() => _guardando = true);
    try {
      await ProveedorAdmin.accion(context).habilitarGanadorPrueba(
        widget.ficha.participante.id,
        habilitar: habilitar,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            habilitar
                ? 'Listo: ${widget.ficha.participante.nombre} ya puede '
                    'reclamar el premio desde la landing para probar las cajas.'
                : 'Modo prueba desactivado.',
          ),
        ),
      );
    } on ErrorAdmin catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.mensaje)));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.ficha.participante;
    const violeta = Color(0xFF8A5CF6);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MedidasAdmin.radioGrande),
        side: BorderSide(
          color: p.ganadorPrueba ? violeta : ColoresOnix.borde,
          width: p.ganadorPrueba ? 1.8 : 1,
        ),
      ),
      // Icono, titulo e interruptor en la primera linea y la explicacion a
      // todo el ancho debajo: en celular el texto ya no queda en una columna
      // angosta entre el icono y el interruptor.
      child: Padding(
        padding: EdgeInsets.all(MedidasAdmin.esMovil(context) ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: violeta.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.science_rounded, color: violeta),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Ganador de prueba',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 12),
                if (_guardando)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                else
                  Switch(
                    value: p.ganadorPrueba,
                    activeTrackColor: violeta,
                    onChanged: _cambiar,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Permite que ${p.nombre} reclame el premio y abra una caja '
              'sin tener 50 tickets, para revisar cómo se ve el recorrido. '
              'Sus tickets salen marcados como PRUEBA y no se entregan.',
              style: const TextStyle(
                color: ColoresOnix.textoSuave,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Reclamos extends StatelessWidget {
  const _Reclamos({required this.ficha});

  final FichaParticipante ficha;

  @override
  Widget build(BuildContext context) {
    return TarjetaSeccion(
      titulo: 'Reclamos de premio (${ficha.reclamos.length})',
      icono: Icons.redeem_rounded,
      child: ficha.reclamos.isEmpty
          ? const Text(
              'Todavía no reclamó ningún premio.',
              style: TextStyle(color: ColoresOnix.textoSuave),
            )
          : Column(
              children: [
                for (final reclamo in ficha.reclamos)
                  _FilaReclamo(reclamo: reclamo),
              ],
            ),
    );
  }
}

/// Un reclamo de la ficha. Las etiquetas van bajo el codigo en celular y a
/// la derecha desde tablet, sin apretar el titulo.
class _FilaReclamo extends StatelessWidget {
  const _FilaReclamo({required this.reclamo});

  final ReclamoAdmin reclamo;

  @override
  Widget build(BuildContext context) {
    final esMovil = MedidasAdmin.esMovil(context);
    final etiquetas = Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (reclamo.esPrueba) const EtiquetaPrueba(),
        EtiquetaEstadoReclamo(estado: reclamo.estado),
      ],
    );

    return InkWell(
      onTap: () => abrirReclamo(context, reclamo.id),
      borderRadius: BorderRadius.circular(MedidasAdmin.radio),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              reclamo.premio?.icono ?? Icons.inventory_2_rounded,
              color: ColoresOnix.azulElectrico,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reclamo.premio?.titulo ?? 'Cajas sin abrir',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${reclamo.codigoConfirmacion == null ? 'Sin código' : reclamo.codigoVisible}'
                    ' · ${Formato.fechaHora(reclamo.fechaReferencia)}',
                    style: const TextStyle(
                      color: ColoresOnix.textoSuave,
                      fontSize: 13,
                    ),
                  ),
                  if (esMovil) ...[
                    const SizedBox(height: 8),
                    etiquetas,
                  ],
                ],
              ),
            ),
            if (!esMovil) ...[
              const SizedBox(width: 12),
              etiquetas,
            ],
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: ColoresOnix.textoSuave,
            ),
          ],
        ),
      ),
    );
  }
}

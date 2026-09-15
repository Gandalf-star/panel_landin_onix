import 'dart:async';

import 'package:flutter/material.dart';

import '../../datos/modelos_admin.dart';
import '../../nucleo/tema_admin.dart';
import '../../utiles/formato.dart';
import '../componentes/carga.dart';
import '../componentes/comunes.dart';
import 'detalle_participante.dart';

/// Buscador de participantes por nombre, usuario o telefono.
class VistaParticipantes extends StatefulWidget {
  const VistaParticipantes({super.key});

  @override
  State<VistaParticipantes> createState() => _VistaParticipantesState();
}

class _VistaParticipantesState extends State<VistaParticipantes> {
  final _campo = TextEditingController();
  Timer? _espera;
  String _busqueda = '';

  @override
  void dispose() {
    _espera?.cancel();
    _campo.dispose();
    super.dispose();
  }

  void _alEscribir(String texto) {
    _espera?.cancel();
    _espera = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _busqueda = texto.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(MedidasAdmin.margen(context)),
      children: [
        TextField(
          controller: _campo,
          onChanged: _alEscribir,
          decoration: const InputDecoration(
            hintText: 'Buscar por nombre, @usuario o teléfono',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Para probar las cajas con tu cuenta: búscala, ábrela y activa '
          '«Ganador de prueba».',
          style: TextStyle(color: ColoresOnix.textoSuave, fontSize: 12.5),
        ),
        const SizedBox(height: 16),
        CargaAdmin<List<FilaParticipante>>(
          claveCarga: _busqueda,
          cargar: (controlador) => controlador.participantes(
            busqueda: _busqueda.isEmpty ? null : _busqueda,
          ),
          construir: (contexto, filas, _) {
            if (filas.isEmpty) {
              return EstadoVacio(
                icono: Icons.person_search_rounded,
                mensaje: _busqueda.isEmpty
                    ? 'Todavía no hay participantes registrados.'
                    : 'Nadie coincide con «$_busqueda».',
              );
            }
            return Column(
              children: [
                for (final fila in filas)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _FilaParticipante(fila: fila),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _FilaParticipante extends StatelessWidget {
  const _FilaParticipante({required this.fila});

  final FilaParticipante fila;

  @override
  Widget build(BuildContext context) {
    const meta = 50;
    final avance = (fila.tickets / meta).clamp(0.0, 1.0);
    final esMovil = MedidasAdmin.esMovil(context);
    final etiquetas = [
      if (fila.ganadorPrueba)
        const Etiqueta(
          texto: 'Ganador de prueba',
          color: Color(0xFF8A5CF6),
          icono: Icons.science_rounded,
        ),
      if (fila.estadoReclamo != null)
        EtiquetaEstadoReclamo(estado: fila.estadoReclamo!),
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => abrirParticipante(context, fila.id),
        child: Padding(
          padding: EdgeInsets.all(esMovil ? 14 : 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: esMovil ? 20 : 22,
                backgroundColor: ColoresOnix.azulOnix,
                child: Text(
                  fila.nombre.isEmpty ? '?' : fila.nombre[0].toUpperCase(),
                  style: const TextStyle(
                    color: ColoresOnix.amarilloOnix,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fila.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '${fila.nombreUsuario == null ? '' : '@${fila.nombreUsuario} · '}'
                      '${Formato.telefono(fila.telefonoE164)}',
                      style: const TextStyle(
                        color: ColoresOnix.textoSuave,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // La barra se estira con la tarjeta (hasta 180 px): con
                    // un ancho fijo el contador se salia en celulares.
                    Row(
                      children: [
                        Flexible(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: avance,
                                minHeight: 7,
                                backgroundColor: ColoresOnix.borde,
                                color: ColoresOnix.amarilloOnix,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${fila.tickets}/$meta tickets',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    // En celular las etiquetas bajan bajo la barra.
                    if (esMovil && etiquetas.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(spacing: 6, runSpacing: 6, children: etiquetas),
                    ],
                  ],
                ),
              ),
              if (!esMovil && etiquetas.isNotEmpty) ...[
                const SizedBox(width: 10),
                Wrap(
                  direction: Axis.vertical,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 6,
                  children: etiquetas,
                ),
              ],
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: ColoresOnix.textoSuave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

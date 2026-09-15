import 'package:flutter/material.dart';

import '../../app.dart';
import '../../datos/modelos_admin.dart';
import '../../nucleo/tema_admin.dart';
import '../../utiles/formato.dart';
import '../componentes/carga.dart';
import '../componentes/comunes.dart';
import '../componentes/grilla_uniforme.dart';
import 'detalle_reclamo.dart';

/// Resumen de la campaña y lista de reclamos de premio por estado.
class VistaReclamos extends StatefulWidget {
  const VistaReclamos({super.key});

  @override
  State<VistaReclamos> createState() => _VistaReclamosState();
}

class _VistaReclamosState extends State<VistaReclamos> {
  static const _filtros = <(EstadoReclamo?, String)>[
    (EstadoReclamo.pendiente, 'Por revisar'),
    (EstadoReclamo.cajasListas, 'Sin abrir'),
    (EstadoReclamo.verificado, 'Verificados'),
    (EstadoReclamo.entregado, 'Entregados'),
    (EstadoReclamo.rechazado, 'Rechazados'),
    (null, 'Todos'),
  ];

  EstadoReclamo? _filtro = EstadoReclamo.pendiente;

  @override
  Widget build(BuildContext context) {
    final resumen = ProveedorAdmin.de(context).resumen;
    final ancho = MediaQuery.sizeOf(context).width;
    final esMovil = MedidasAdmin.esMovil(context);
    // Seis cifras que siempre forman filas completas: 2 x 3 en celular,
    // 3 x 2 en tablet y una sola fila de 6 en escritorio amplio.
    final columnas = esMovil ? 2 : (ancho >= 1400 ? 6 : 3);
    final filtros = [
      for (final (estado, texto) in _filtros)
        ChoiceChip(
          label: Text(texto),
          selected: _filtro == estado,
          onSelected: (_) => setState(() => _filtro = estado),
        ),
    ];

    return ListView(
      padding: EdgeInsets.all(MedidasAdmin.margen(context)),
      children: [
        GrillaUniforme(
          columnas: columnas,
          separacion: esMovil ? 10 : 14,
          children: [
            _Cifra(
              valor: resumen.reclamosPorRevisar,
              etiqueta: 'Reclamos por revisar',
              icono: Icons.schedule_rounded,
              color: ColoresOnix.ambar,
            ),
            _Cifra(
              valor: resumen.reclamosVerificados,
              etiqueta: 'Verificados sin entregar',
              icono: Icons.verified_rounded,
              color: ColoresOnix.azulInfo,
            ),
            _Cifra(
              valor: resumen.reclamosEntregados,
              etiqueta: 'Premios entregados',
              icono: Icons.check_circle_rounded,
              color: ColoresOnix.verde,
            ),
            _Cifra(
              valor: resumen.metasAlcanzadas,
              etiqueta: 'Llegaron a 50 tickets',
              icono: Icons.emoji_events_rounded,
              color: ColoresOnix.azulElectrico,
            ),
            _Cifra(
              valor: resumen.participantes,
              etiqueta: 'Participantes',
              icono: Icons.groups_rounded,
              color: ColoresOnix.textoSuave,
            ),
            _Cifra(
              valor: resumen.invitadosVerificados,
              etiqueta: 'Invitados verificados',
              icono: Icons.phonelink_lock_rounded,
              color: ColoresOnix.textoSuave,
            ),
          ],
        ),
        const SizedBox(height: 26),
        // En celular los filtros van en una sola fila deslizable, en vez de
        // tres filas desparejas de pastillas.
        if (esMovil)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < filtros.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  filtros[i],
                ],
              ],
            ),
          )
        else
          Wrap(spacing: 8, runSpacing: 8, children: filtros),
        const SizedBox(height: 16),
        CargaAdmin<List<ReclamoAdmin>>(
          claveCarga: _filtro,
          cargar: (controlador) => controlador.reclamos(estado: _filtro),
          construir: (contexto, reclamos, _) {
            if (reclamos.isEmpty) {
              return const EstadoVacio(
                icono: Icons.inbox_rounded,
                mensaje: 'No hay reclamos en este estado.\nCuando un ganador '
                    'abra su caja aparecerá aquí y sonará un aviso.',
              );
            }
            return Column(
              children: [
                for (final reclamo in reclamos)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TarjetaReclamo(reclamo: reclamo),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Cifra extends StatelessWidget {
  const _Cifra({
    required this.valor,
    required this.etiqueta,
    required this.icono,
    required this.color,
  });

  final int valor;
  final String etiqueta;
  final IconData icono;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final esMovil = MedidasAdmin.esMovil(context);
    final insignia = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icono, color: color, size: 21),
    );
    final textos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$valor',
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        Text(
          etiqueta,
          style: const TextStyle(
            color: ColoresOnix.textoSuave,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    // La grilla le da el ancho y el alto: en celular el icono va arriba del
    // numero para que la etiqueta tenga todo el ancho de la tarjeta.
    return Card(
      child: Padding(
        padding: EdgeInsets.all(esMovil ? 14 : 16),
        child: esMovil
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [insignia, const SizedBox(height: 10), textos],
              )
            : Row(
                children: [
                  insignia,
                  const SizedBox(width: 12),
                  Expanded(child: textos),
                ],
              ),
      ),
    );
  }
}

/// Un reclamo en una lista: premio, ganador, codigo y estado.
class TarjetaReclamo extends StatelessWidget {
  const TarjetaReclamo({super.key, required this.reclamo});

  final ReclamoAdmin reclamo;

  @override
  Widget build(BuildContext context) {
    final premio = reclamo.premio;
    final ganador = reclamo.ganador;
    final esMovil = MedidasAdmin.esMovil(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => abrirReclamo(context, reclamo.id),
        child: Padding(
          padding: EdgeInsets.all(esMovil ? 14 : 16),
          child: Row(
            children: [
              Container(
                width: esMovil ? 42 : 48,
                height: esMovil ? 42 : 48,
                decoration: const BoxDecoration(
                  gradient: GradientesOnix.fondoOscuro,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  premio?.icono ?? Icons.inventory_2_rounded,
                  color: ColoresOnix.amarilloOnix,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      premio?.titulo ?? 'Cajas sin abrir',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${ganador.nombre}'
                      '${ganador.nombreUsuario == null ? '' : ' · @${ganador.nombreUsuario}'}'
                      ' · ${Formato.telefono(ganador.telefonoE164)}',
                      style: const TextStyle(
                        color: ColoresOnix.textoSuave,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        EtiquetaEstadoReclamo(estado: reclamo.estado),
                        if (reclamo.esPrueba) const EtiquetaPrueba(),
                        if (reclamo.codigoConfirmacion != null)
                          Text(
                            reclamo.codigoVisible,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                              color: ColoresOnix.azulElectrico,
                            ),
                          ),
                        if (esMovil)
                          Text(
                            Formato.relativo(reclamo.fechaReferencia),
                            style: const TextStyle(
                              color: ColoresOnix.textoSuave,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (esMovil)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: ColoresOnix.textoSuave,
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formato.relativo(reclamo.fechaReferencia),
                      style: const TextStyle(
                        color: ColoresOnix.textoSuave,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: ColoresOnix.textoSuave,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

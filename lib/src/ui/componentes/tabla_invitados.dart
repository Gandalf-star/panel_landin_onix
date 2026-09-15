import 'package:flutter/material.dart';

import '../../datos/modelos_admin.dart';
import '../../nucleo/tema_admin.dart';
import '../../utiles/formato.dart';
import 'comunes.dart';

/// Invitados de un participante: el codigo que compartio con cada uno, el
/// numero con el que se registro y el dispositivo que quedo anclado, con
/// las coincidencias sospechosas marcadas.
class TablaInvitados extends StatelessWidget {
  const TablaInvitados({super.key, required this.ficha});

  final FichaParticipante ficha;

  @override
  Widget build(BuildContext context) {
    final canjeadas = ficha.canjeadas;
    final sinCanjear = ficha.sinCanjear;

    return TarjetaSeccion(
      titulo: 'Invitados verificados (${canjeadas.length})',
      subtitulo:
          'Cada fila es un código compartido que se canjeó: número del '
          'invitado y dispositivo anclado al código.',
      icono: Icons.groups_rounded,
      accion: ficha.sospechosas > 0
          ? Etiqueta(
              texto: '${ficha.sospechosas} con alertas',
              color: ColoresOnix.rojo,
              icono: Icons.warning_amber_rounded,
            )
          : const Etiqueta(
              texto: 'Sin alertas',
              color: ColoresOnix.verde,
              icono: Icons.verified_user_rounded,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canjeadas.isEmpty)
            const EstadoVacio(
              icono: Icons.person_off_rounded,
              mensaje: 'Todavía no hay invitados verificados.',
            )
          else
            for (var i = 0; i < canjeadas.length; i++)
              _FilaInvitado(
                numero: canjeadas.length - i,
                invitacion: canjeadas[i],
              ),
          if (sinCanjear.isNotEmpty) ...[
            const SizedBox(height: 10),
            Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Códigos compartidos sin canjear (${sinCanjear.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                children: [
                  for (final invitacion in sinCanjear)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.qr_code_2_rounded),
                      title: Text(invitacion.codigoVisible),
                      subtitle: Text(
                        'Generado ${Formato.fechaHora(invitacion.creadoEn)} · '
                        'vence ${Formato.fechaHora(invitacion.expiraEn)}',
                      ),
                      isThreeLine: MedidasAdmin.esMovil(context),
                      trailing: Etiqueta(
                        texto: invitacion.estado == 'expirada'
                            ? 'Expirado'
                            : 'Sin usar',
                        color: invitacion.estado == 'expirada'
                            ? ColoresOnix.rojo
                            : ColoresOnix.textoSuave,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilaInvitado extends StatelessWidget {
  const _FilaInvitado({required this.numero, required this.invitacion});

  final int numero;
  final InvitacionAdmin invitacion;

  @override
  Widget build(BuildContext context) {
    final invitado = invitacion.invitado;
    final dispositivo = invitacion.dispositivo;
    final esMovil = MedidasAdmin.esMovil(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(esMovil ? 12 : 14),
      decoration: BoxDecoration(
        color: invitacion.sospechosa
            ? ColoresOnix.rojo.withValues(alpha: 0.05)
            : ColoresOnix.fondo,
        borderRadius: BorderRadius.circular(MedidasAdmin.radio),
        border: Border.all(
          color: invitacion.sospechosa
              ? ColoresOnix.rojo.withValues(alpha: 0.35)
              : ColoresOnix.borde,
        ),
      ),
      // Material transparente: los ExpansionTile de adentro necesitan uno
      // propio para dibujar su efecto encima del fondo de la fila.
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: ColoresOnix.azulOnix,
                  child: Text(
                    '$numero',
                    style: const TextStyle(
                      color: ColoresOnix.amarilloOnix,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    invitado == null
                        ? 'Invitado'
                        : '${invitado.nombre}'
                              '${invitado.nombreUsuario == null ? '' : '  @${invitado.nombreUsuario}'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (invitacion.estadoReferido != null &&
                    invitacion.estadoReferido != 'valido')
                  Etiqueta(
                    texto: invitacion.estadoReferido!,
                    color: ColoresOnix.ambar,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // En celular los datos van en dos columnas parejas (o en una sola
            // si la tarjeta es muy angosta); desde tablet, en una linea que
            // se parte cuando no cabe.
            LayoutBuilder(
              builder: (contexto, restricciones) {
                const separacion = 12.0;
                final dosColumnas = restricciones.maxWidth >= 320;
                final anchoCampo = !esMovil
                    ? null
                    : dosColumnas
                        ? (restricciones.maxWidth - separacion) / 2
                        : restricciones.maxWidth;
                final campos = [
                  (
                    Icons.phone_iphone_rounded,
                    'Número',
                    Formato.telefono(invitado?.telefonoE164),
                  ),
                  (
                    Icons.qr_code_2_rounded,
                    'Código compartido',
                    invitacion.codigoVisible,
                  ),
                  (
                    Icons.event_available_rounded,
                    'Canjeado',
                    Formato.fechaHora(invitacion.usadaEn),
                  ),
                  (Icons.devices_rounded, 'Dispositivo anclado', dispositivo.resumen),
                  (Icons.public_rounded, 'IP', invitacion.ip ?? '—'),
                ];
                return Wrap(
                  spacing: esMovil ? separacion : 22,
                  runSpacing: 10,
                  children: [
                    for (final (icono, etiqueta, valor) in campos)
                      SizedBox(
                        width: anchoCampo,
                        child: _Campo(
                          icono: icono,
                          etiqueta: etiqueta,
                          valor: valor,
                        ),
                      ),
                  ],
                );
              },
            ),
            if (invitacion.sospechosa) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (invitacion.firmaDelInvitador)
                    const Etiqueta(
                      texto: 'Mismo navegador que el ganador',
                      color: ColoresOnix.rojo,
                      icono: Icons.warning_amber_rounded,
                    ),
                  if (invitacion.mismaFirma > 0)
                    Etiqueta(
                      texto:
                          'Misma firma de navegador que '
                          '${invitacion.mismaFirma} '
                          '${invitacion.mismaFirma == 1 ? 'invitado' : 'invitados'}',
                      color: ColoresOnix.rojo,
                      icono: Icons.fingerprint_rounded,
                    ),
                  if (invitacion.mismaIp > 1)
                    Etiqueta(
                      texto: 'Misma IP que ${invitacion.mismaIp} invitados',
                      color: ColoresOnix.ambar,
                      icono: Icons.router_rounded,
                    ),
                ],
              ),
            ],
            Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                dense: true,
                title: const Text(
                  'Detalle técnico del dispositivo',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: ColoresOnix.textoSuave,
                  ),
                ),
                children: [
                  DatoFila(
                    etiqueta: 'Huella (anclaje)',
                    valor: invitacion.huella ?? '—',
                    copiable: invitacion.huella != null,
                  ),
                  DatoFila(
                    etiqueta: 'Firma del navegador',
                    valor: invitacion.firma ?? '—',
                    copiable: invitacion.firma != null,
                  ),
                  DatoFila(
                    etiqueta: 'Navegador',
                    valor: dispositivo.agente ?? '—',
                  ),
                  DatoFila(
                    etiqueta: 'Plataforma',
                    valor: [
                      ?dispositivo.plataforma,
                      ?dispositivo.idioma,
                      if (dispositivo.nucleos != null)
                        '${dispositivo.nucleos} núcleos',
                      if (dispositivo.tactil != null)
                        'táctil: ${dispositivo.tactil}',
                    ].join(' · '),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  const _Campo({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 16, color: ColoresOnix.azulElectrico),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: const TextStyle(
                    color: ColoresOnix.textoSuave,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SelectableText(
                  valor,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

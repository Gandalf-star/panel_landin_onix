import 'package:flutter/material.dart';

import '../../app.dart';
import '../../nucleo/tema_admin.dart';
import '../../utiles/formato.dart';
import '../componentes/comunes.dart';
import 'detalle_reclamo.dart';

/// Lista de notificaciones (panel lateral de la campana).
class PanelNotificaciones extends StatelessWidget {
  const PanelNotificaciones({super.key});

  @override
  Widget build(BuildContext context) {
    final controlador = ProveedorAdmin.de(context);
    final notificaciones = controlador.notificaciones;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Notificaciones',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (controlador.resumen.notificacionesSinLeer > 0)
                  TextButton(
                    onPressed: () => controlador.marcarLeidas(),
                    child: const Text('Marcar todas leídas'),
                  ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: notificaciones.isEmpty
                ? const EstadoVacio(
                    icono: Icons.notifications_none_rounded,
                    mensaje: 'Sin notificaciones todavía.\nAquí aparece cada '
                        'ganador que abre su caja.',
                  )
                : ListView.separated(
                    itemCount: notificaciones.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (contexto, i) {
                      final n = notificaciones[i];
                      return ListTile(
                        leading: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const CircleAvatar(
                              backgroundColor: ColoresOnix.amarilloClaro,
                              child: Icon(
                                Icons.redeem_rounded,
                                color: ColoresOnix.azulOnix,
                              ),
                            ),
                            if (!n.leida)
                              Positioned(
                                right: -1,
                                top: -1,
                                child: Container(
                                  width: 11,
                                  height: 11,
                                  decoration: BoxDecoration(
                                    color: ColoresOnix.rojo,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: ColoresOnix.blanco,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(
                          n.titulo,
                          style: TextStyle(
                            fontWeight:
                                n.leida ? FontWeight.w600 : FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(
                          '${n.detalle}\n${Formato.relativo(n.creadoEn)}',
                        ),
                        isThreeLine: true,
                        onTap: () {
                          if (!n.leida) controlador.marcarLeidas([n.id]);
                          final idReclamo = n.reclamoId;
                          Navigator.of(context).pop();
                          if (idReclamo != null) {
                            abrirReclamo(context, idReclamo);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

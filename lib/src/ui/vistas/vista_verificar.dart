import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app.dart';
import '../../datos/modelos_admin.dart';
import '../../datos/repositorio_admin.dart';
import '../../nucleo/tema_admin.dart';
import '../../utiles/formato.dart';
import '../componentes/comunes.dart';
import 'detalle_reclamo.dart';

/// Verificacion con el codigo que el ganador ve en su ticket: dice si es
/// real, a quien pertenece y deja confirmar el premio en el mismo lugar.
class VistaVerificar extends StatefulWidget {
  const VistaVerificar({super.key});

  @override
  State<VistaVerificar> createState() => _VistaVerificarState();
}

class _VistaVerificarState extends State<VistaVerificar> {
  final _codigo = TextEditingController();
  DetalleReclamo? _resultado;
  String? _error;
  bool _buscando = false;
  int _versionVista = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Si mientras se revisa llega un cambio (otro admin, una accion), se
    // vuelve a consultar el mismo codigo.
    final version = ProveedorAdmin.de(context).versionDatos;
    if (_versionVista != -1 && version != _versionVista && _resultado != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _buscar();
      });
    }
    _versionVista = version;
  }

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    final codigo = _codigo.text.trim();
    if (codigo.isEmpty) return;
    setState(() {
      _buscando = true;
      _error = null;
    });
    try {
      final detalle = await ProveedorAdmin.accion(context).buscarCodigo(codigo);
      if (!mounted) return;
      setState(() => _resultado = detalle);
    } on ErrorAdmin catch (error) {
      if (!mounted) return;
      setState(() {
        _resultado = null;
        _error = error.mensaje;
      });
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esMovil = MedidasAdmin.esMovil(context);
    final campo = TextField(
      controller: _codigo,
      textCapitalization: TextCapitalization.characters,
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(r'[a-zA-Z0-9\- ]'),
        ),
        _Mayusculas(),
      ],
      style: const TextStyle(
        fontFamily: 'Manrope',
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        fontSize: 18,
      ),
      decoration: const InputDecoration(
        hintText: 'PRM-XXXXX-XXXXX',
        prefixIcon: Icon(Icons.confirmation_number_rounded),
      ),
      onSubmitted: (_) => _buscar(),
    );
    final boton = FilledButton.icon(
      onPressed: _buscando ? null : _buscar,
      icon: _buscando
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ColoresOnix.blanco,
              ),
            )
          : const Icon(Icons.search_rounded),
      label: const Text('Verificar'),
    );

    return ListView(
      padding: EdgeInsets.all(MedidasAdmin.margen(context)),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TarjetaSeccion(
                  titulo: 'Verificar un ticket ganador',
                  subtitulo:
                      'Escribe el código de confirmación que el ganador ve en '
                      'su ticket (PRM-XXXXX-XXXXX).',
                  icono: Icons.qr_code_scanner_rounded,
                  // En celular el campo y el boton ocupan todo el ancho,
                  // uno bajo el otro; desde tablet van en la misma linea.
                  child: esMovil
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [campo, const SizedBox(height: 12), boton],
                        )
                      : Row(
                          children: [
                            Flexible(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 420),
                                child: campo,
                              ),
                            ),
                            const SizedBox(width: 12),
                            boton,
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  _Veredicto(
                    color: ColoresOnix.rojo,
                    icono: Icons.gpp_bad_rounded,
                    titulo: 'Código no válido',
                    detalle: _error!,
                  ),
                if (_resultado != null) ...[
                  _veredictoDe(_resultado!.reclamo),
                  const SizedBox(height: 16),
                  ContenidoReclamo(
                    detalle: _resultado!,
                    alActualizar: _buscar,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _veredictoDe(ReclamoAdmin reclamo) {
    final premio = reclamo.premio?.titulo ?? 'premio';
    final nombre = reclamo.ganador.nombre;

    if (reclamo.esPrueba) {
      return _Veredicto(
        color: const Color(0xFF8A5CF6),
        icono: Icons.science_rounded,
        titulo: 'Código real, pero de un ticket de PRUEBA',
        detalle: 'Pertenece a $nombre ($premio). Fue habilitado desde el '
            'panel para probar: no corresponde entregar premio.',
      );
    }
    return switch (reclamo.estado) {
      EstadoReclamo.entregado => _Veredicto(
          color: ColoresOnix.ambar,
          icono: Icons.history_rounded,
          titulo: 'Código ya usado',
          detalle: 'El premio de $nombre ($premio) se marcó como entregado el '
              '${Formato.fechaHora(reclamo.revisadoEn)} por '
              '@${reclamo.revisadoPor}.',
        ),
      EstadoReclamo.rechazado => _Veredicto(
          color: ColoresOnix.rojo,
          icono: Icons.block_rounded,
          titulo: 'Código de un reclamo anulado',
          detalle: 'Pertenece a $nombre, pero el reclamo fue rechazado'
              '${reclamo.notaAdmin == null ? '' : ': ${reclamo.notaAdmin}'}.',
        ),
      _ => _Veredicto(
          color: ColoresOnix.verde,
          icono: Icons.verified_rounded,
          titulo: 'Código válido',
          detalle: 'Corresponde al ticket de $nombre: $premio. Revisa los '
              'invitados antes de confirmar la entrega.',
        ),
    };
  }
}

class _Veredicto extends StatelessWidget {
  const _Veredicto({
    required this.color,
    required this.icono,
    required this.titulo,
    required this.detalle,
  });

  final Color color;
  final IconData icono;
  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(MedidasAdmin.radioGrande),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.4),
      ),
      child: Row(
        children: [
          Icon(icono, color: color, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(detalle, style: const TextStyle(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Mayusculas extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue anterior,
    TextEditingValue nuevo,
  ) =>
      nuevo.copyWith(text: nuevo.text.toUpperCase());
}

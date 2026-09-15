import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../datos/modelos_admin.dart';
import '../../nucleo/tema_admin.dart';
import 'grilla_uniforme.dart';

class LogoOnix extends StatelessWidget {
  const LogoOnix({super.key, this.alto = 32, this.sobreFondoOscuro = true});

  final double alto;
  final bool sobreFondoOscuro;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      sobreFondoOscuro
          ? 'assets/images/logo_onix_dark.png'
          : 'assets/images/logo_onix_transparent.png',
      height: alto,
      fit: BoxFit.contain,
      semanticLabel: 'Onix Drive',
    );
  }
}

/// Pastilla de color con icono opcional.
class Etiqueta extends StatelessWidget {
  const Etiqueta({
    super.key,
    required this.texto,
    required this.color,
    this.icono,
  });

  final String texto;
  final Color color;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            texto,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

Color colorDeEstado(EstadoReclamo estado) => switch (estado) {
      EstadoReclamo.cajasListas => ColoresOnix.textoSuave,
      EstadoReclamo.pendiente => ColoresOnix.ambar,
      EstadoReclamo.verificado => ColoresOnix.azulInfo,
      EstadoReclamo.entregado => ColoresOnix.verde,
      EstadoReclamo.rechazado => ColoresOnix.rojo,
      EstadoReclamo.reiniciado => ColoresOnix.textoSuave,
    };

class EtiquetaEstadoReclamo extends StatelessWidget {
  const EtiquetaEstadoReclamo({super.key, required this.estado});

  final EstadoReclamo estado;

  @override
  Widget build(BuildContext context) => Etiqueta(
        texto: estado.etiqueta,
        color: colorDeEstado(estado),
        icono: estado.icono,
      );
}

class EtiquetaPrueba extends StatelessWidget {
  const EtiquetaPrueba({super.key});

  @override
  Widget build(BuildContext context) => const Etiqueta(
        texto: 'PRUEBA',
        color: Color(0xFF8A5CF6),
        icono: Icons.science_rounded,
      );
}

/// Tarjeta blanca con titulo, para agrupar informacion.
class TarjetaSeccion extends StatelessWidget {
  const TarjetaSeccion({
    super.key,
    required this.titulo,
    required this.child,
    this.icono,
    this.accion,
    this.subtitulo,
  });

  final String titulo;
  final String? subtitulo;
  final IconData? icono;
  final Widget? accion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final esMovil = MedidasAdmin.esMovil(context);
    // En celular una etiqueta de estado baja bajo el titulo: al lado le
    // quitaba casi todo el ancho y el titulo se partia en tres lineas. Los
    // botones cortos («Ver ficha») siguen a la derecha.
    final accionAbajo = esMovil && accion is Etiqueta;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(esMovil ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: subtitulo == null
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                if (icono != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(
                      icono,
                      size: 20,
                      color: ColoresOnix.azulElectrico,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (subtitulo != null)
                        Text(
                          subtitulo!,
                          style: const TextStyle(
                            color: ColoresOnix.textoSuave,
                            fontSize: 12.5,
                          ),
                        ),
                      if (accionAbajo) ...[
                        const SizedBox(height: 10),
                        accion!,
                      ],
                    ],
                  ),
                ),
                if (!accionAbajo) ?accion,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

/// `Etiqueta: valor`, con boton para copiar si se pide.
class DatoFila extends StatelessWidget {
  const DatoFila({
    super.key,
    required this.etiqueta,
    required this.valor,
    this.copiable = false,
    this.destacado = false,
  });

  final String etiqueta;
  final String valor;
  final bool copiable;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final textoEtiqueta = Text(
      etiqueta,
      style: const TextStyle(
        color: ColoresOnix.textoSuave,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
    // El boton de copiar va pegado al valor y no al borde de la tarjeta.
    final textoValor = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: SelectableText(
            valor,
            style: TextStyle(
              color: ColoresOnix.texto,
              fontSize: destacado ? 15 : 13.5,
              fontWeight: destacado ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
        if (copiable) BotonCopiar(texto: valor),
      ],
    );

    // En celular la etiqueta va sobre el valor: con 150 px fijos a la
    // izquierda el valor quedaba en una columna angosta y partida.
    if (MedidasAdmin.esMovil(context)) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [textoEtiqueta, const SizedBox(height: 2), textoValor],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 150, child: textoEtiqueta),
          Expanded(child: textoValor),
        ],
      ),
    );
  }
}

class BotonCopiar extends StatelessWidget {
  const BotonCopiar({super.key, required this.texto, this.tamano = 16});

  final String texto;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Copiar',
      visualDensity: VisualDensity.compact,
      icon: Icon(Icons.copy_rounded, size: tamano),
      color: ColoresOnix.textoSuave,
      onPressed: () {
        Clipboard.setData(ClipboardData(text: texto));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copiado: $texto'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }
}

/// Cargando, error con reintento o lista vacia.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    super.key,
    required this.icono,
    required this.mensaje,
    this.alReintentar,
  });

  final IconData icono;
  final String mensaje;
  final VoidCallback? alReintentar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Column(
        children: [
          Icon(icono, size: 36, color: ColoresOnix.textoSuave),
          const SizedBox(height: 12),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ColoresOnix.textoSuave,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          if (alReintentar != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: alReintentar,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ],
      ),
    );
  }
}

class Cargando extends StatelessWidget {
  const Cargando({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(48),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              color: ColoresOnix.azulElectrico,
            ),
          ),
        ),
      );
}

/// Las tres cajas del reclamo como las vio el ganador: azul, amarilla y
/// azul, con el premio que tenia cada una y la elegida marcada.
class MiniCajas extends StatelessWidget {
  const MiniCajas({
    super.key,
    required this.distribucion,
    required this.elegida,
  });

  final List<PremioCaja> distribucion;
  final int? elegida;

  @override
  Widget build(BuildContext context) {
    // Tres columnas del mismo ancho y alto, como las vio el ganador. En
    // celulares angostos no caben: van como lista a todo el ancho.
    final enLista = MediaQuery.sizeOf(context).width < 480;
    final cajas = [
      for (var i = 0; i < distribucion.length; i++)
        _MiniCaja(
          indice: i,
          premio: distribucion[i],
          elegida: elegida == i,
          enLista: enLista,
        ),
    ];

    return GrillaUniforme(
      columnas: enLista ? 1 : distribucion.length,
      separacion: enLista ? 8 : 12,
      children: cajas,
    );
  }
}

class _MiniCaja extends StatelessWidget {
  const _MiniCaja({
    required this.indice,
    required this.premio,
    required this.elegida,
    required this.enLista,
  });

  final int indice;
  final PremioCaja premio;
  final bool elegida;
  final bool enLista;

  @override
  Widget build(BuildContext context) {
    final amarilla = indice == 1;
    final caja = Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        gradient: amarilla ? GradientesOnix.dorado : GradientesOnix.fondoOscuro,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Center(
        child: Container(
          width: 4,
          color: amarilla ? ColoresOnix.azulElectrico : ColoresOnix.amarilloOnix,
        ),
      ),
    );
    final estado = Text(
      elegida ? 'Elegida' : 'No elegida',
      style: TextStyle(
        fontSize: 11.5,
        color: elegida ? ColoresOnix.ambar : ColoresOnix.textoSuave,
        fontWeight: FontWeight.w700,
      ),
    );
    final decoracion = BoxDecoration(
      color: elegida ? ColoresOnix.amarilloClaro : ColoresOnix.fondo,
      borderRadius: BorderRadius.circular(MedidasAdmin.radio),
      border: Border.all(
        color: elegida ? ColoresOnix.amarilloOnix : ColoresOnix.borde,
        width: elegida ? 2 : 1.2,
      ),
    );

    if (enLista) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: decoracion,
        child: Row(
          children: [
            caja,
            const SizedBox(width: 10),
            Text(
              'Caja ${indice + 1}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            const SizedBox(width: 12),
            Icon(premio.icono, size: 18, color: ColoresOnix.azulElectrico),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                premio.titulo,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            estado,
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: decoracion,
      child: Column(
        children: [
          Row(
            children: [
              caja,
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Caja ${indice + 1}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              if (elegida)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: ColoresOnix.ambar,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Icon(premio.icono, color: ColoresOnix.azulElectrico),
          const SizedBox(height: 6),
          Text(
            premio.titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          const SizedBox(height: 4),
          estado,
        ],
      ),
    );
  }
}

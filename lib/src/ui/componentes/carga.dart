import 'package:flutter/material.dart';

import '../../app.dart';
import '../../datos/controlador_admin.dart';
import '../../datos/repositorio_admin.dart';
import 'comunes.dart';

/// Carga datos del servidor y los vuelve a pedir cuando cambian: al llegar
/// un reclamo nuevo o tras un cambio de estado ([ControladorAdmin.versionDatos])
/// o cuando cambia [claveCarga] (por ejemplo, un filtro).
///
/// Mientras recarga deja a la vista los datos anteriores, para que la
/// pantalla no parpadee cada vez que llega un aviso.
class CargaAdmin<T> extends StatefulWidget {
  const CargaAdmin({
    super.key,
    required this.cargar,
    required this.construir,
    this.claveCarga,
  });

  final Future<T> Function(ControladorAdmin controlador) cargar;
  final Widget Function(BuildContext contexto, T datos, VoidCallback recargar)
      construir;
  final Object? claveCarga;

  @override
  State<CargaAdmin<T>> createState() => _CargaAdminState<T>();
}

class _CargaAdminState<T> extends State<CargaAdmin<T>> {
  int? _version;
  T? _datos;
  bool _hayDatos = false;
  String? _error;
  bool _cargando = false;
  int _pedido = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final version = ProveedorAdmin.de(context).versionDatos;
    if (version != _version) {
      _version = version;
      _recargar();
    }
  }

  @override
  void didUpdateWidget(CargaAdmin<T> anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.claveCarga != widget.claveCarga) {
      _hayDatos = false;
      _recargar();
    }
  }

  /// Desde el boton de reintentar o desde la vista: hay que redibujar.
  void _recargarYRedibujar() {
    // _recargar cambia los campos antes de su primer await; el setState
    // vacio solo pide dibujar ese estado.
    _recargar();
    setState(() {});
  }

  /// Se llama tambien desde didChangeDependencies y didUpdateWidget, que ya
  /// preceden a un build: por eso aqui no se usa setState antes del await.
  Future<void> _recargar() async {
    final pedido = ++_pedido;
    _cargando = true;
    _error = null;
    try {
      final datos = await widget.cargar(ProveedorAdmin.accion(context));
      if (!mounted || pedido != _pedido) return;
      setState(() {
        _datos = datos;
        _hayDatos = true;
      });
    } on ErrorAdmin catch (error) {
      if (!mounted || pedido != _pedido) return;
      setState(() => _error = error.mensaje);
    } catch (_) {
      if (!mounted || pedido != _pedido) return;
      setState(() => _error = 'No pudimos cargar los datos.');
    } finally {
      if (mounted && pedido == _pedido) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hayDatos) {
      return Stack(
        children: [
          widget.construir(context, _datos as T, _recargarYRedibujar),
          if (_cargando)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      );
    }
    if (_error != null) {
      return EstadoVacio(
        icono: Icons.cloud_off_rounded,
        mensaje: _error!,
        alReintentar: _recargarYRedibujar,
      );
    }
    return const Cargando();
  }
}

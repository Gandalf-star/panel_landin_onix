import 'package:flutter/material.dart';

import '../app.dart';
import '../nucleo/tema_admin.dart';
import 'componentes/comunes.dart';

/// Ingreso del administrador con usuario y contraseña.
class PantallaIngreso extends StatefulWidget {
  const PantallaIngreso({super.key, this.problemaArranque});

  final String? problemaArranque;

  @override
  State<PantallaIngreso> createState() => _PantallaIngresoState();
}

class _PantallaIngresoState extends State<PantallaIngreso> {
  final _usuario = TextEditingController();
  final _contrasena = TextEditingController();
  bool _verContrasena = false;

  @override
  void dispose() {
    _usuario.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    if (_usuario.text.trim().isEmpty || _contrasena.text.isEmpty) return;
    await ProveedorAdmin.accion(context)
        .ingresar(_usuario.text, _contrasena.text);
  }

  @override
  Widget build(BuildContext context) {
    final controlador = ProveedorAdmin.de(context);
    final mensaje = widget.problemaArranque ?? controlador.mensajeError;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: GradientesOnix.fondoOscuro),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(MedidasAdmin.margen(context)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  const LogoOnix(alto: 46),
                  const SizedBox(height: 18),
                  const Text(
                    'Panel admin · Reto 50 Onix',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      color: ColoresOnix.blanco,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Reclamos de premio, verificación de códigos y '
                    'participantes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ColoresOnix.sobreAzulSuave),
                  ),
                  const SizedBox(height: 28),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(
                        MedidasAdmin.esMovil(context) ? 20 : 24,
                      ),
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Ingresar',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 18),
                            TextField(
                              controller: _usuario,
                              autofillHints: const [AutofillHints.username],
                              enabled: widget.problemaArranque == null,
                              decoration: const InputDecoration(
                                labelText: 'Usuario',
                                prefixIcon: Icon(Icons.person_rounded),
                              ),
                              onSubmitted: (_) => _ingresar(),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _contrasena,
                              obscureText: !_verContrasena,
                              autofillHints: const [AutofillHints.password],
                              enabled: widget.problemaArranque == null,
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: const Icon(Icons.lock_rounded),
                                suffixIcon: IconButton(
                                  tooltip: _verContrasena
                                      ? 'Ocultar contraseña'
                                      : 'Mostrar contraseña',
                                  icon: Icon(
                                    _verContrasena
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                  ),
                                  onPressed: () => setState(
                                    () => _verContrasena = !_verContrasena,
                                  ),
                                ),
                              ),
                              onSubmitted: (_) => _ingresar(),
                            ),
                            if (mensaje != null) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: ColoresOnix.rojo.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    MedidasAdmin.radio,
                                  ),
                                ),
                                child: Text(
                                  mensaje,
                                  style: const TextStyle(
                                    color: ColoresOnix.rojo,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            FilledButton.icon(
                              onPressed:
                                  controlador.ingresando ||
                                      widget.problemaArranque != null
                                  ? null
                                  : _ingresar,
                              icon: controlador.ingresando
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: ColoresOnix.blanco,
                                      ),
                                    )
                                  : const Icon(Icons.login_rounded),
                              label: const Text('Ingresar al panel'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

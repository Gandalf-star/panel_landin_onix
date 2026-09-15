import 'package:flutter/foundation.dart';

import 'aviso_navegador_otro.dart'
    if (dart.library.js_interop) 'aviso_navegador_web.dart' as plataforma;

/// Avisos fuera de la pagina: notificacion del sistema, sonido y contador
/// en el titulo de la pestaña. Sirven para enterarse de un reclamo nuevo
/// aunque el panel este en segundo plano.
abstract final class AvisoNavegador {
  /// `true` si el navegador soporta notificaciones y el permiso esta dado.
  static bool get notificacionesActivas => plataforma.notificacionesActivas();

  /// `true` si el navegador soporta notificaciones (con o sin permiso).
  static bool get notificacionesDisponibles =>
      disponiblesEnPruebas ?? plataforma.notificacionesDisponibles();

  /// Las pruebas corren fuera del navegador, donde nunca hay notificaciones:
  /// con esto se simula un navegador que las ofrece, para revisar que el
  /// boton «Activar avisos» quepa en la barra del celular.
  @visibleForTesting
  static bool? disponiblesEnPruebas;

  /// Pide permiso para mostrar notificaciones. Debe llamarse desde un clic.
  static Future<bool> pedirPermiso() => plataforma.pedirPermiso();

  static void notificar(String titulo, String cuerpo) =>
      plataforma.notificar(titulo, cuerpo);

  static void sonar() => plataforma.sonar();

  /// Pone `(3)` delante del titulo de la pestaña, o lo quita con 0.
  static void contadorEnTitulo(int pendientes) =>
      plataforma.contadorEnTitulo(pendientes);
}

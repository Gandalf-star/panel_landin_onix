import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

const _tituloBase = 'Panel admin · Reto 50 Onix';

bool notificacionesDisponibles() {
  try {
    return globalContext.has('Notification');
  } catch (_) {
    return false;
  }
}

bool notificacionesActivas() {
  if (!notificacionesDisponibles()) return false;
  try {
    return web.Notification.permission == 'granted';
  } catch (_) {
    return false;
  }
}

Future<bool> pedirPermiso() async {
  if (!notificacionesDisponibles()) return false;
  try {
    final respuesta = await web.Notification.requestPermission().toDart;
    return respuesta.toDart == 'granted';
  } catch (_) {
    return false;
  }
}

void notificar(String titulo, String cuerpo) {
  if (!notificacionesActivas()) return;
  try {
    web.Notification(
      titulo,
      web.NotificationOptions(
        body: cuerpo,
        icon: 'icons/Icon-192.png',
        tag: 'onix-reclamo',
      ),
    );
  } catch (_) {
    // Sin notificacion del sistema igual queda el aviso dentro del panel.
  }
}

/// Dos tonos cortos con Web Audio: no hace falta ningun archivo de sonido.
void sonar() {
  try {
    final audio = web.AudioContext();
    final ahora = audio.currentTime;
    for (final (retraso, frecuencia) in [(0.0, 880.0), (0.16, 1318.5)]) {
      final oscilador = audio.createOscillator()
        ..type = 'sine'
        ..frequency.value = frecuencia;
      final volumen = audio.createGain();
      volumen.gain
        ..setValueAtTime(0.0001, ahora + retraso)
        ..exponentialRampToValueAtTime(0.18, ahora + retraso + 0.02)
        ..exponentialRampToValueAtTime(0.0001, ahora + retraso + 0.28);
      oscilador.connect(volumen);
      volumen.connect(audio.destination);
      oscilador
        ..start(ahora + retraso)
        ..stop(ahora + retraso + 0.3);
    }
  } catch (_) {
    // El navegador puede bloquear el audio hasta que haya un clic.
  }
}

void contadorEnTitulo(int pendientes) {
  try {
    web.document.title =
        pendientes > 0 ? '($pendientes) $_tituloBase' : _tituloBase;
  } catch (_) {}
}

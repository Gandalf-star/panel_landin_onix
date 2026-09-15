// Fuera del navegador (pruebas en la VM) los avisos no hacen nada.

bool notificacionesActivas() => false;

bool notificacionesDisponibles() => false;

Future<bool> pedirPermiso() async => false;

void notificar(String titulo, String cuerpo) {}

void sonar() {}

void contadorEnTitulo(int pendientes) {}

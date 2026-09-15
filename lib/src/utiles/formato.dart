/// Formatos de texto que se repiten en todo el panel.
abstract final class Formato {
  static String _dos(int n) => n.toString().padLeft(2, '0');

  /// `15/09/2026 14:05`.
  static String fechaHora(DateTime? fecha) {
    if (fecha == null) return '—';
    final f = fecha.toLocal();
    return '${_dos(f.day)}/${_dos(f.month)}/${f.year} '
        '${_dos(f.hour)}:${_dos(f.minute)}';
  }

  /// `hace 5 min`, `hace 3 h`, o la fecha si paso mas de un dia.
  static String relativo(DateTime? fecha, {DateTime? ahora}) {
    if (fecha == null) return '—';
    final diferencia = (ahora ?? DateTime.now()).difference(fecha);
    if (diferencia.inSeconds < 60) return 'recién';
    if (diferencia.inMinutes < 60) return 'hace ${diferencia.inMinutes} min';
    if (diferencia.inHours < 24) return 'hace ${diferencia.inHours} h';
    return fechaHora(fecha);
  }

  /// `+56 9 1234 5678` o `+58 412 123 4567`.
  static String telefono(String? e164) {
    if (e164 == null || e164.isEmpty) return '—';
    if (e164.startsWith('+569') && e164.length == 12) {
      return '+56 9 ${e164.substring(4, 8)} ${e164.substring(8)}';
    }
    if (e164.startsWith('+58') && e164.length == 13) {
      return '+58 ${e164.substring(3, 6)} ${e164.substring(6, 9)} '
          '${e164.substring(9)}';
    }
    return e164;
  }

  /// Codigo de invitacion tal como lo vio la persona: `ONX-7K4Q-2P9M`.
  static String codigoInvitacion(String? codigo) {
    if (codigo == null || codigo.length != 8) return codigo ?? '—';
    return 'ONX-${codigo.substring(0, 4)}-${codigo.substring(4)}';
  }

  /// Codigo de confirmacion del ticket: `PRM-XXXXX-XXXXX`.
  static String codigoConfirmacion(String? codigo) {
    if (codigo == null || codigo.length != 10) return codigo ?? '—';
    return 'PRM-${codigo.substring(0, 5)}-${codigo.substring(5)}';
  }

  /// Link de WhatsApp para escribirle a un numero E.164.
  static Uri whatsapp(String e164, String mensaje) => Uri.parse(
        'https://wa.me/${e164.replaceAll(RegExp(r'\D'), '')}'
        '?text=${Uri.encodeComponent(mensaje)}',
      );
}

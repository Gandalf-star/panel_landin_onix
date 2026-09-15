import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Lectura tipada del `.env` del panel.
abstract final class Entorno {
  static bool _cargado = false;
  static String? _problema;

  /// Motivo por el que no se puede conectar, o `null` si todo esta bien.
  static String? get problema => _problema;

  static Future<void> cargar() async {
    if (_cargado) return;
    try {
      await dotenv.load(fileName: '.env');
    } catch (error) {
      _problema = 'No se encontró el archivo .env del panel. Copia '
          '.env.ejemplo a .env y completa la URL y la clave pública de '
          'Supabase.';
      if (kDebugMode) debugPrint('Entorno: $error');
    }
    _cargado = true;
    if (_problema == null && (urlSupabase.isEmpty || claveAnonima.isEmpty)) {
      _problema = 'Faltan SUPABASE_URL o SUPABASE_ANON_KEY en el .env del '
          'panel.';
    }
  }

  static String _leer(String clave, {String pordefecto = ''}) {
    if (!_cargado) return pordefecto;
    return dotenv.env[clave]?.trim() ?? pordefecto;
  }

  static String get urlSupabase => _leer('SUPABASE_URL');

  static String get claveAnonima => _leer('SUPABASE_ANON_KEY');

  /// Intervalo de la consulta periodica de reclamos nuevos.
  static Duration get intervaloSondeo {
    final segundos = int.tryParse(_leer('SEGUNDOS_SONDEO')) ?? 15;
    return Duration(seconds: segundos.clamp(5, 300));
  }
}

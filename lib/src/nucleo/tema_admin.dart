import 'package:flutter/material.dart';

/// Paleta de Onix Drive, la misma de la landing (`tema_onix.dart`).
abstract final class ColoresOnix {
  static const azulOnix = Color(0xFF030E36);
  static const azulProfundo = Color(0xFF07102C);
  static const azulSuave = Color(0xFF17234B);
  static const azulElectrico = Color(0xFF061E6D);

  static const amarilloOnix = Color(0xFFFFC700);
  static const amarilloIntenso = Color(0xFFFFCC00);
  static const amarilloClaro = Color(0xFFFFF4B8);
  static const ambar = Color(0xFFFFA000);

  static const fondo = Color(0xFFF3F5F9);
  static const blanco = Color(0xFFFFFFFF);
  static const texto = Color(0xFF10182E);
  static const textoSuave = Color(0xFF6E788E);
  static const borde = Color(0xFFE2E5EC);

  static const verde = Color(0xFF16A36A);
  static const rojo = Color(0xFFE5484D);
  static const azulInfo = Color(0xFF2F6BFF);

  static const sobreAzul = Color(0xFFE8ECF5);
  static const sobreAzulSuave = Color(0xFF9FB0CC);
  static const bordeSobreAzul = Color(0x1FFFFFFF);
}

abstract final class GradientesOnix {
  static const fondoOscuro = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      ColoresOnix.azulProfundo,
      ColoresOnix.azulOnix,
      ColoresOnix.azulElectrico,
    ],
    stops: [0.0, 0.55, 1.0],
  );

  static const dorado = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      ColoresOnix.amarilloIntenso,
      ColoresOnix.amarilloOnix,
      ColoresOnix.ambar,
    ],
  );
}

abstract final class MedidasAdmin {
  static const radio = 16.0;
  static const radioGrande = 22.0;
  static const anchoEscritorio = 1000.0;

  /// Por debajo de este ancho la pantalla es de celular: filas apiladas,
  /// botones a todo el ancho y margenes mas justos.
  static const anchoMovil = 600.0;

  static bool esEscritorio(BuildContext contexto) =>
      MediaQuery.sizeOf(contexto).width >= anchoEscritorio;

  static bool esMovil(BuildContext contexto) =>
      MediaQuery.sizeOf(contexto).width < anchoMovil;

  /// Margen de las vistas: 16 px en celular y 24 px desde tablet.
  static double margen(BuildContext contexto) => esMovil(contexto) ? 16 : 24;
}

const _fuenteTitulos = 'Manrope';
const _fuenteTexto = 'Inter';
const _respaldo = <String>['Segoe UI', 'Roboto', 'Helvetica Neue', 'Arial'];

ThemeData construirTemaAdmin() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: ColoresOnix.fondo,
    fontFamily: _fuenteTexto,
    fontFamilyFallback: _respaldo,
    colorScheme: ColorScheme.fromSeed(
      seedColor: ColoresOnix.azulOnix,
      primary: ColoresOnix.azulOnix,
      onPrimary: ColoresOnix.blanco,
      secondary: ColoresOnix.amarilloOnix,
      onSecondary: ColoresOnix.azulOnix,
      surface: ColoresOnix.blanco,
      onSurface: ColoresOnix.texto,
      error: ColoresOnix.rojo,
    ),
  );

  TextStyle titulo(double tamano) => TextStyle(
        fontFamily: _fuenteTitulos,
        fontFamilyFallback: _respaldo,
        fontSize: tamano,
        fontWeight: FontWeight.w800,
        color: ColoresOnix.texto,
        letterSpacing: -0.3,
      );

  final bordeCampo = OutlineInputBorder(
    borderRadius: BorderRadius.circular(MedidasAdmin.radio),
    borderSide: const BorderSide(color: ColoresOnix.borde, width: 1.4),
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      headlineMedium: titulo(26),
      titleLarge: titulo(19),
      titleMedium: titulo(16),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: ColoresOnix.blanco,
      foregroundColor: ColoresOnix.texto,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      titleTextStyle: titulo(18),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ColoresOnix.azulOnix,
        foregroundColor: ColoresOnix.blanco,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MedidasAdmin.radio),
        ),
        textStyle: const TextStyle(
          fontFamily: _fuenteTitulos,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ColoresOnix.azulOnix,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        side: const BorderSide(color: ColoresOnix.borde, width: 1.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MedidasAdmin.radio),
        ),
        textStyle: const TextStyle(
          fontFamily: _fuenteTitulos,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ColoresOnix.blanco,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: bordeCampo,
      enabledBorder: bordeCampo,
      focusedBorder: bordeCampo.copyWith(
        borderSide: const BorderSide(color: ColoresOnix.amarilloOnix, width: 2),
      ),
    ),
    cardTheme: CardThemeData(
      color: ColoresOnix.blanco,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MedidasAdmin.radioGrande),
        side: const BorderSide(color: ColoresOnix.borde),
      ),
    ),
    dividerTheme: const DividerThemeData(color: ColoresOnix.borde, space: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: ColoresOnix.azulOnix,
      behavior: SnackBarBehavior.floating,
      contentTextStyle: const TextStyle(
        color: ColoresOnix.blanco,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MedidasAdmin.radio),
      ),
    ),
  );
}

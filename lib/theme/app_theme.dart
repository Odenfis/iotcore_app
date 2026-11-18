import 'package:flutter/material.dart';

import '../models/sensor_reading.dart';

/// Tokens visuales de la aplicación.
///
/// Centraliza paleta, tipografía y formas para que todas las pantallas
/// compartan el mismo lenguaje visual y se adapten automáticamente al modo
/// claro/oscuro del sistema.
class AppTheme {
  const AppTheme._();

  /// Color semilla del esquema Material 3.
  static const Color seed = Color(0xFF2563EB);

  /// Acento visual de la métrica de temperatura.
  static const Color temperature = Color(0xFFF97316);

  /// Acento visual de la métrica de humedad.
  static const Color humidity = Color(0xFF0EA5E9);

  /// Radio de esquina por defecto de las tarjetas.
  static const double cardRadius = 20;

  /// Color de acento de la temperatura según su clasificación cualitativa.
  static Color temperatureColor(TemperatureState state) {
    return switch (state) {
      TemperatureState.hot => const Color(0xFFEF4444),
      TemperatureState.warm => temperature,
      TemperatureState.cool => const Color(0xFF3B82F6),
      TemperatureState.unknown => temperature,
    };
  }

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      textTheme: base.textTheme.copyWith(
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        titleSmall: base.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        labelSmall: base.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
      ),
    );
  }
}

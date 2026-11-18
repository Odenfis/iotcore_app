/// Clasificación cualitativa de la temperatura reportada por el dispositivo.
///
/// El simulador actual envía etiquetas textuales (`Ambiente Caliente`), pero
/// el modelo también admite valores numéricos, en cuyo caso la clasificación
/// se deduce de los umbrales definidos en [SensorReading].
enum TemperatureState {
  hot,
  warm,
  cool,
  unknown;

  /// Descripción legible del estado (usada cuando no hay texto del dispositivo).
  String get description => switch (this) {
    TemperatureState.hot => 'Caliente',
    TemperatureState.warm => 'Templado',
    TemperatureState.cool => 'Frío',
    TemperatureState.unknown => 'Sin clasificar',
  };
}

/// Lectura de un sensor tal y como la expone la API `/readings`.
///
/// El modelo es deliberadamente tolerante: la API puede devolver números
/// (`humidity: 1.7`), cadenas numéricas, textos cualitativos
/// (`temperature: "Ambiente Caliente"`) o `null`. Cada métrica se normaliza en
/// un valor numérico opcional más una etiqueta lista para mostrar.
class SensorReading {
  const SensorReading({
    required this.deviceId,
    required this.timestamp,
    required this.temperatureValue,
    required this.temperatureLabel,
    required this.temperatureState,
    required this.humidityValue,
    required this.humidityLabel,
  });

  /// Identificador completo del dispositivo (p. ej. `iotconsole-890d8ea6-...`).
  final String deviceId;

  /// Marca de tiempo en segundos epoch.
  final int timestamp;

  /// Valor numérico de la temperatura cuando el dispositivo la envía así.
  final double? temperatureValue;

  /// Texto de la temperatura: el literal del dispositivo o el valor formateado.
  final String temperatureLabel;

  /// Clasificación cualitativa usada para elegir el color de acento.
  final TemperatureState temperatureState;

  /// Valor numérico de la humedad cuando está disponible.
  final double? humidityValue;

  /// Texto de la humedad: el literal del dispositivo o el valor formateado.
  final String humidityLabel;

  /// Umbral (°C) a partir del cual la temperatura se considera calurosa.
  static const double hotThreshold = 28;

  /// Umbral (°C) a partir del cual la temperatura se considera templada.
  static const double warmThreshold = 18;

  /// Fecha y hora de la lectura en la zona horaria local.
  DateTime get dateTime =>
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

  /// Nombre corto y legible del dispositivo para la interfaz.
  String get deviceLabel {
    if (deviceId.trim().isEmpty) return 'Dispositivo';
    final segments = deviceId.split('-');
    if (segments.length > 1 && segments.first.length > 2) {
      return segments.first;
    }
    return deviceId.length <= 14
        ? deviceId
        : '${deviceId.substring(0, 12)}…';
  }

  /// Iniciales del dispositivo para el avatar de la lista.
  String get deviceInitials {
    final label = deviceLabel.trim();
    if (label.isEmpty) return '?';
    final words = label.split(RegExp(r'[\s_-]+')).where((w) => w.isNotEmpty);
    if (words.length >= 2) {
      return '${words.first[0]}${words.elementAt(1)[0]}'.toUpperCase();
    }
    return label.substring(0, label.length >= 2 ? 2 : 1).toUpperCase();
  }

  /// Texto de la temperatura listo para mostrar (valor o etiqueta del sensor).
  String get temperatureDisplay =>
      temperatureValue != null ? _formatNumber(temperatureValue!) : temperatureLabel;

  /// Texto de la humedad listo para mostrar.
  String get humidityDisplay =>
      humidityValue != null ? _formatNumber(humidityValue!) : humidityLabel;

  /// Construye una lectura a partir del JSON devuelto por la API.
  factory SensorReading.fromJson(Map<String, dynamic> json) {
    final temperature = _parseMetric(json['temperature']);
    final humidity = _parseMetric(json['humidity']);

    return SensorReading(
      deviceId: json['device_id']?.toString() ?? 'Desconocido',
      timestamp: _parseTimestamp(json['timestamp']),
      temperatureValue: temperature.value,
      temperatureLabel: temperature.label,
      temperatureState:
          temperature.state ?? _stateFromValue(temperature.value),
      humidityValue: humidity.value,
      humidityLabel: humidity.label,
    );
  }

  /// Normaliza una métrica heterogénea (número, cadena numérica o texto).
  static ({double? value, String label, TemperatureState? state}) _parseMetric(
    dynamic raw,
  ) {
    if (raw == null) {
      return (value: null, label: 'N/D', state: null);
    }
    if (raw is num) {
      final value = raw.toDouble();
      return (value: value, label: _formatNumber(value), state: null);
    }

    final text = raw.toString().trim();
    if (text.isEmpty) {
      return (value: null, label: 'N/D', state: null);
    }

    final numeric = double.tryParse(text.replaceAll(',', '.'));
    if (numeric != null) {
      return (value: numeric, label: _formatNumber(numeric), state: null);
    }

    return (value: null, label: text, state: _stateFromLabel(text));
  }

  /// Acepta `int`, `double` o `String` numérico y normaliza a segundos epoch.
  static int _parseTimestamp(dynamic raw) {
    if (raw == null) return 0;
    final parsed = raw is num ? raw : num.tryParse(raw.toString().trim());
    if (parsed == null) return 0;

    var value = parsed.toDouble();
    if (value > 1e11) {
      // El dispositivo enviaría milisegundos: convertimos a segundos.
      value = value / 1000;
    }
    return value.toInt();
  }

  /// Deduce la clasificación a partir del texto cualitativo del dispositivo.
  static TemperatureState _stateFromLabel(String text) {
    final normalized = text.toLowerCase();
    if (normalized.contains('caliente') ||
        normalized.contains('calor') ||
        normalized.contains('hot')) {
      return TemperatureState.hot;
    }
    if (normalized.contains('templad') ||
        normalized.contains('cálido') ||
        normalized.contains('calido') ||
        normalized.contains('moderad') ||
        normalized.contains('warm')) {
      return TemperatureState.warm;
    }
    if (normalized.contains('frío') ||
        normalized.contains('frio') ||
        normalized.contains('fresc') ||
        normalized.contains('cold') ||
        normalized.contains('cool')) {
      return TemperatureState.cool;
    }
    return TemperatureState.unknown;
  }

  /// Deduce la clasificación a partir del valor numérico y los umbrales.
  static TemperatureState _stateFromValue(double? value) {
    if (value == null) return TemperatureState.unknown;
    if (value >= hotThreshold) return TemperatureState.hot;
    if (value >= warmThreshold) return TemperatureState.warm;
    return TemperatureState.cool;
  }

  /// Formatea un número sin decimales innecesarios (`2` → `2`, `1.7` → `1.7`).
  static String _formatNumber(double value) {
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.toStringAsFixed(0);
    }
    final text = value.toStringAsFixed(2);
    if (!text.contains('.')) return text;
    return text
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

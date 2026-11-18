import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/sensor_reading.dart';

<<<<<<< HEAD
class IoTService {
  // TODO: Reemplazar por endpoint en default
  static const String _baseUrl = 'https://7a5h9psyn1.execute-api.us-east-1.amazonaws.com';
=======
/// Error de negocio de la capa de red, con un mensaje listo para la interfaz.
class ApiException implements Exception {
  const ApiException(this.message);
>>>>>>> dde5c7b (update oit core app version 2)

  final String message;

  @override
  String toString() => message;
}

/// Contrato de acceso a las lecturas.
///
/// Permite inyectar dobles en los tests sin tocar la red.
abstract class ReadingsRepository {
  Future<List<SensorReading>> fetchReadings({String? deviceId});
}

/// Cliente HTTP del API Gateway que expone las lecturas de los sensores.
class IoTService implements ReadingsRepository {
  static const String baseUrl =
      'https://o23be3zsob.execute-api.us-east-1.amazonaws.com';

  /// Tiempo máximo de espera de la respuesta del servidor.
  static const Duration timeout = Duration(seconds: 10);

  @override
  Future<List<SensorReading>> fetchReadings({String? deviceId}) async {
    final uri = Uri.parse('$baseUrl/readings').replace(
      queryParameters:
          deviceId == null || deviceId.isEmpty
              ? null
              : {'device_id': deviceId},
    );

    final http.Response response;
    try {
      response = await http.get(uri).timeout(timeout);
    } on TimeoutException {
      throw const ApiException('El servidor tardó demasiado en responder.');
    } on http.ClientException catch (error) {
      throw ApiException('No se pudo conectar con el servidor: ${error.message}');
    }

    if (response.statusCode != 200) {
      throw ApiException(
        'El servidor respondió con el código ${response.statusCode}.',
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const ApiException(
        'La respuesta del servidor no tiene un formato válido.',
      );
    }

    final List<dynamic> rawReadings;
    if (decoded is List) {
      rawReadings = decoded;
    } else if (decoded is Map<String, dynamic> &&
        decoded['readings'] is List<dynamic>) {
      rawReadings = decoded['readings'] as List<dynamic>;
    } else {
      throw const ApiException(
        'La respuesta del servidor no contiene lecturas.',
      );
    }

    return rawReadings
        .whereType<Map<String, dynamic>>()
        .map(SensorReading.fromJson)
        .toList();
  }
}

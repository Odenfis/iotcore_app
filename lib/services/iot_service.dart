import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_reading.dart';

class IoTService {
  // TODO: Replace with your actual API Gateway Endpoint URL
  static const String _baseUrl = 'https://7a5h9psyn1.execute-api.us-east-1.amazonaws.com';

  Future<List<SensorReading>> fetchReadings({String? deviceId}) async {
    try {
      String url = '$_baseUrl/readings';
      if (deviceId != null) {
        url += '?device_id=$deviceId';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => SensorReading.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load readings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }
}

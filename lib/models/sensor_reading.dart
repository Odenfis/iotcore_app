class SensorReading {
  final String deviceId;
  final int timestamp;
  final String temperature;
  final String humidity;

  SensorReading({
    required this.deviceId,
    required this.timestamp,
    required this.temperature,
    required this.humidity,
  });

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      deviceId: json['device_id'] ?? 'Unknown',
      timestamp: json['timestamp'] is int ? json['timestamp'] : 0,
      temperature: json['temperature']?.toString() ?? 'N/A',
      humidity: json['humidity']?.toString() ?? 'N/A',
    );
  }
}

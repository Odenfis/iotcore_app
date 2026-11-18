import 'package:flutter_test/flutter_test.dart';
import 'package:iotcore_app/models/sensor_reading.dart';

void main() {
  group('SensorReading.fromJson', () {
    test('parsea el payload real de la API', () {
      final reading = SensorReading.fromJson({
        'device_id': 'iotconsole-890d8ea6-d77c-4c72-b755-93d47e1af420',
        'timestamp': 1793890048,
        'temperature': 'Ambiente Caliente',
        'humidity': 1.7,
      });

      expect(reading.deviceId, 'iotconsole-890d8ea6-d77c-4c72-b755-93d47e1af420');
      expect(reading.deviceLabel, 'iotconsole');
      expect(reading.deviceInitials, 'IO');
      expect(reading.timestamp, 1793890048);
      expect(reading.temperatureValue, isNull);
      expect(reading.temperatureLabel, 'Ambiente Caliente');
      expect(reading.temperatureState, TemperatureState.hot);
      expect(reading.humidityValue, 1.7);
      expect(reading.humidityLabel, '1.7');
      expect(reading.humidityDisplay, '1.7');
    });

    test('acepta timestamp numérico, decimal, textual y en milisegundos', () {
      expect(
        SensorReading.fromJson({'timestamp': 1793890048}).timestamp,
        1793890048,
      );
      expect(
        SensorReading.fromJson({'timestamp': 1793890048.0}).timestamp,
        1793890048,
      );
      expect(
        SensorReading.fromJson({'timestamp': '1793890048'}).timestamp,
        1793890048,
      );
      expect(
        SensorReading.fromJson({'timestamp': 1793890048000}).timestamp,
        1793890048,
      );
      expect(SensorReading.fromJson({'timestamp': null}).timestamp, 0);
    });

    test('interpreta temperaturas numéricas según los umbrales', () {
      final hot = SensorReading.fromJson({'temperature': 31.4});
      expect(hot.temperatureValue, 31.4);
      expect(hot.temperatureLabel, '31.4');
      expect(hot.temperatureState, TemperatureState.hot);

      final warm = SensorReading.fromJson({'temperature': '22'});
      expect(warm.temperatureValue, 22);
      expect(warm.temperatureLabel, '22');
      expect(warm.temperatureState, TemperatureState.warm);

      final cool = SensorReading.fromJson({'temperature': 12.5});
      expect(cool.temperatureState, TemperatureState.cool);
    });

    test('clasifica temperaturas cualitativas', () {
      expect(
        SensorReading.fromJson({'temperature': 'Ambiente Templado'})
            .temperatureState,
        TemperatureState.warm,
      );
      expect(
        SensorReading.fromJson({'temperature': 'Ambiente Frío'}).temperatureState,
        TemperatureState.cool,
      );
      expect(
        SensorReading.fromJson({'temperature': 'Sin datos'}).temperatureState,
        TemperatureState.unknown,
      );
    });

    test('gestiona métricas ausentes o vacías', () {
      final reading = SensorReading.fromJson({
        'device_id': 'iotconsole-1',
        'temperature': null,
        'humidity': '',
      });

      expect(reading.temperatureValue, isNull);
      expect(reading.temperatureLabel, 'N/D');
      expect(reading.humidityValue, isNull);
      expect(reading.humidityLabel, 'N/D');
      expect(reading.deviceLabel, 'iotconsole');
    });

    test('expone la fecha y hora de la lectura', () {
      final reading = SensorReading.fromJson({'timestamp': 1793890048});
      expect(reading.dateTime.millisecondsSinceEpoch, 1793890048000);
    });
  });
}

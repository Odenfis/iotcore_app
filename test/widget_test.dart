import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iotcore_app/main.dart';
import 'package:iotcore_app/models/sensor_reading.dart';
import 'package:iotcore_app/services/iot_service.dart';
import 'package:iotcore_app/utils/time_format.dart';

/// Repositorio falso que evita cualquier llamada de red.
class _FakeRepository implements ReadingsRepository {
  _FakeRepository(this.readings, {this.error});

  final List<SensorReading> readings;
  final Object? error;

  @override
  Future<List<SensorReading>> fetchReadings({String? deviceId}) async {
    final failure = error;
    if (failure != null) throw failure;
    return readings;
  }
}

List<SensorReading> _sampleReadings() {
  return [
    SensorReading.fromJson({
      'device_id': 'iotconsole-890d8ea6-d77c-4c72-b755-93d47e1af420',
      'timestamp': 1793890048,
      'temperature': 'Ambiente Caliente',
      'humidity': 1.7,
    }),
    SensorReading.fromJson({
      'device_id': 'iotconsole-890d8ea6-d77c-4c72-b755-93d47e1af420',
      'timestamp': 1793895347,
      'temperature': 'Ambiente Templado',
      'humidity': 1.8,
    }),
    SensorReading.fromJson({
      'device_id': 'iotconsole-890d8ea6-d77c-4c72-b755-93d47e1af420',
      'timestamp': 1793895436,
      'temperature': 'Ambiente Caliente',
      'humidity': 2,
    }),
  ];
}

void main() {
  testWidgets(
    'renderiza las lecturas sin desbordamientos en pantalla estrecha',
    (tester) async {
      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3.0;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });

      await tester.pumpWidget(
        IoTApp(repository: _FakeRepository(_sampleReadings())),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Panel de sensores'), findsOneWidget);
      expect(find.text('Última lectura'.toUpperCase()), findsOneWidget);
      expect(find.text('Ambiente Caliente'), findsWidgets);
      expect(find.text('iotconsole'), findsWidgets);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('muestra la lectura más reciente en la tarjeta principal', (
    tester,
  ) async {
    final readings = _sampleReadings();

    await tester.pumpWidget(
      IoTApp(repository: _FakeRepository(readings)),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);

    final newest = readings.reduce(
      (a, b) => a.timestamp > b.timestamp ? a : b,
    );
    expect(
      find.text('Actualizado ${formatClock(newest.dateTime)}'),
      findsOneWidget,
    );
    expect(find.text('Lecturas recientes'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('muestra el estado de error y ofrece reintentar', (tester) async {
    await tester.pumpWidget(
      IoTApp(
        repository: _FakeRepository(
          const [],
          error: const ApiException('El servidor no responde.'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('No se pudieron obtener los datos'), findsOneWidget);
    expect(find.text('El servidor no responde.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Reintentar'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('muestra el estado vacío cuando no hay lecturas', (tester) async {
    await tester.pumpWidget(
      IoTApp(repository: _FakeRepository(const [])),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('Sin lecturas'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('refresca los datos al pulsar el botón de actualizar', (
    tester,
  ) async {
    var calls = 0;
    final repository = _CountingRepository(() {
      calls++;
      return _sampleReadings();
    });

    await tester.pumpWidget(IoTApp(repository: repository));
    await tester.pump(const Duration(milliseconds: 100));
    expect(calls, 1);

    await tester.tap(find.byTooltip('Actualizar'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(calls, 2);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _CountingRepository implements ReadingsRepository {
  _CountingRepository(this.onFetch);

  final List<SensorReading> Function() onFetch;

  @override
  Future<List<SensorReading>> fetchReadings({String? deviceId}) async {
    return onFetch();
  }
}

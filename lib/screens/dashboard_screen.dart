import 'dart:async';

import 'package:flutter/material.dart';

import '../models/sensor_reading.dart';
import '../services/iot_service.dart';
import '../widgets/app_states.dart';
import '../widgets/latest_reading_card.dart';
import '../widgets/reading_card.dart';

/// Pantalla principal del panel de sensores.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.repository,
    this.pollInterval = const Duration(seconds: 10),
  });

  /// Origen de las lecturas. Si es `null` se usa el cliente HTTP real.
  final ReadingsRepository? repository;

  /// Intervalo de refresco automático. `null` desactiva el polling.
  final Duration? pollInterval;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final ReadingsRepository _repository =
      widget.repository ?? IoTService();

  List<SensorReading> _readings = const [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  Timer? _pollTimer;
  bool _requestInFlight = false;

  @override
  void initState() {
    super.initState();
    _fetchData();

    final interval = widget.pollInterval;
    if (interval != null) {
      _pollTimer = Timer.periodic(interval, (_) => _fetchData(silent: true));
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData({bool silent = false}) async {
    if (_requestInFlight) return;
    _requestInFlight = true;

    if (!silent && mounted) {
      setState(() {
        _isLoading = _readings.isEmpty;
        _isRefreshing = _readings.isNotEmpty;
      });
    }

    try {
      // Copiamos la lista: la del repositorio puede ser inmutable y siempre
      // queremos poder ordenarla por marca de tiempo.
      final data = List<SensorReading>.of(await _repository.fetchReadings());
      data.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (!mounted) return;
      setState(() {
        _readings = data;
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      final message = error is ApiException
          ? error.message
          : 'Ocurrió un error inesperado al consultar el servidor.';

      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = message;
      });

      // Si ya hay datos en pantalla no los sustituimos: solo avisamos.
      if (_readings.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      _requestInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final clampedScaler = media.textScaler.clamp(maxScaleFactor: 1.4);

    return Scaffold(
      body: MediaQuery(
        data: media.copyWith(textScaler: clampedScaler),
        child: RefreshIndicator(
          onRefresh: _fetchData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildAppBar(),
              ..._buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      title: const Text('Panel de sensores'),
      actions: [
        if (_isRefreshing)
          const Padding(
            padding: EdgeInsets.all(14),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _fetchData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  List<Widget> _buildContent() {
    if (_isLoading && _readings.isEmpty) {
      return const [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverToBoxAdapter(child: LoadingSkeleton()),
        ),
      ];
    }

    if (_errorMessage != null && _readings.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorState(
            message: _errorMessage!,
            onRetry: _fetchData,
          ),
        ),
      ];
    }

    if (_readings.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            title: 'Sin lecturas',
            message:
                'El sensor todavía no ha enviado datos. Actualiza la pantalla '
                'en unos segundos.',
          ),
        ),
      ];
    }

    final horizontalPadding = _horizontalPadding();
    final trend = _trend();

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          8,
          horizontalPadding,
          0,
        ),
        sliver: SliverToBoxAdapter(
          child: LatestReadingCard(
            reading: _readings.first,
            trendValues: trend.values,
            trendLabel: trend.label,
          ),
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          24,
          horizontalPadding,
          12,
        ),
        sliver: SliverToBoxAdapter(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  'Lecturas recientes',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_readings.length}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          0,
          horizontalPadding,
          24,
        ),
        sliver: _buildReadingsList(),
      ),
    ];
  }

  Widget _buildReadingsList() {
    final contentWidth =
        MediaQuery.sizeOf(context).width - _horizontalPadding() * 2;

    // En pantallas anchas las tarjetas se reparten en columnas, pero cada una
    // calcula su propia altura: nunca se imponen alturas fijas que puedan
    // provocar desbordamientos.
    if (contentWidth >= 720) {
      final columns = contentWidth >= 1080 ? 3 : 2;
      final cardWidth = (contentWidth - (columns - 1) * 12) / columns;

      return SliverToBoxAdapter(
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final reading in _readings)
              SizedBox(
                width: cardWidth,
                child: ReadingCard(reading: reading),
              ),
          ],
        ),
      );
    }

    return SliverList.separated(
      itemCount: _readings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) => ReadingCard(
        reading: _readings[index],
      ),
    );
  }

  /// Márgenes laterales: en pantallas anchas el contenido se centra.
  double _horizontalPadding() {
    const maxContentWidth = 1120.0;
    final width = MediaQuery.sizeOf(context).width;
    return width > maxContentWidth ? (width - maxContentWidth) / 2 : 16.0;
  }

  /// Serie de tendencia (de más antiguo a más reciente) para el sparkline.
  ({List<double> values, String? label}) _trend() {
    final temperatures = _readings
        .where((reading) => reading.temperatureValue != null)
        .map((reading) => reading.temperatureValue!)
        .toList();
    if (temperatures.length >= 2) {
      return (
        values: temperatures.reversed.toList(),
        label: 'Tendencia de temperatura',
      );
    }

    final humidities = _readings
        .where((reading) => reading.humidityValue != null)
        .map((reading) => reading.humidityValue!)
        .toList();
    if (humidities.length >= 2) {
      return (
        values: humidities.reversed.toList(),
        label: 'Tendencia de humedad',
      );
    }

    return (values: const <double>[], label: null);
  }
}

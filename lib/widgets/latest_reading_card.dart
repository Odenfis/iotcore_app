import 'package:flutter/material.dart';

import '../models/sensor_reading.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import 'metric_tile.dart';
import 'relative_time_text.dart';
import 'trend_sparkline.dart';

/// Tarjeta principal con la última lectura y su tendencia reciente.
class LatestReadingCard extends StatelessWidget {
  const LatestReadingCard({
    super.key,
    required this.reading,
    required this.trendValues,
    this.trendLabel,
  });

  final SensorReading reading;
  final List<double> trendValues;
  final String? trendLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColors = isDark
        ? [scheme.surfaceContainerHigh, scheme.surfaceContainerHighest]
        : [
            scheme.primary,
            Color.lerp(scheme.primary, Colors.black, 0.28)!,
          ];
    final foreground = isDark ? scheme.onSurface : Colors.white;
    final muted = isDark
        ? scheme.onSurfaceVariant
        : Colors.white.withValues(alpha: 0.78);
    final accent = isDark ? scheme.primary : Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: backgroundColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: isDark ? 0.18 : 0.26),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'ÚLTIMA LECTURA',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: muted,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? scheme.surfaceContainerHighest
                        : Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sensors_rounded, size: 14, color: foreground),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          reading.deviceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: MetricTile(
                  label: 'Temperatura',
                  value: reading.temperatureDisplay,
                  unit: reading.temperatureValue != null ? '°C' : null,
                  icon: Icons.thermostat_rounded,
                  accent: AppTheme.temperatureColor(reading.temperatureState),
                  valueColor: foreground,
                  labelColor: muted,
                  iconColor: foreground,
                  iconBackgroundColor: foreground.withValues(alpha: 0.16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricTile(
                  label: 'Humedad',
                  value: reading.humidityDisplay,
                  unit: reading.humidityValue != null ? '%' : null,
                  icon: Icons.water_drop_rounded,
                  accent: AppTheme.humidity,
                  valueColor: foreground,
                  labelColor: muted,
                  iconColor: foreground,
                  iconBackgroundColor: foreground.withValues(alpha: 0.16),
                ),
              ),
            ],
          ),
          if (trendValues.length >= 2) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Flexible(
                  child: Text(
                    trendLabel ?? 'Tendencia',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(color: muted),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'últimas ${trendValues.length}',
                  style: theme.textTheme.labelSmall?.copyWith(color: muted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TrendSparkline(values: trendValues, color: accent),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 14, color: muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Actualizado ${formatClock(reading.dateTime)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ),
              const SizedBox(width: 8),
              RelativeTimeText(
                time: reading.dateTime,
                style: theme.textTheme.labelSmall?.copyWith(color: muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

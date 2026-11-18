import 'package:flutter/material.dart';

import '../models/sensor_reading.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import 'device_avatar.dart';
import 'metric_tile.dart';
import 'relative_time_text.dart';

/// Tarjeta de una lectura del historial.
///
/// Sustituye al `ListTile` anterior: el texto largo de métricas ya no vive
/// en el `trailing`, sino en "pastillas" que se reparten con `Wrap`, de modo
/// que el nombre del dispositivo nunca se estrangula.
class ReadingCard extends StatelessWidget {
  const ReadingCard({super.key, required this.reading, this.onTap});

  final SensorReading reading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final temperatureColor =
        AppTheme.temperatureColor(reading.temperatureState);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DeviceAvatar(initials: reading.deviceInitials),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          reading.deviceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatDateTime(reading.dateTime),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  RelativeTimeText(
                    time: reading.dateTime,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  MetricPill(
                    icon: Icons.thermostat_rounded,
                    value: reading.temperatureDisplay,
                    unit: reading.temperatureValue != null ? '°C' : null,
                    accent: temperatureColor,
                  ),
                  MetricPill(
                    icon: Icons.water_drop_rounded,
                    value: reading.humidityDisplay,
                    unit: reading.humidityValue != null ? '%' : null,
                    accent: AppTheme.humidity,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

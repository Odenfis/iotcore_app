import 'package:flutter/material.dart';

/// Métrica destacada (temperatura / humedad) de la tarjeta principal.
///
/// El valor se dibuja dentro de un [FittedBox] para que un texto largo
/// (`Ambiente Caliente`) se reduzca en lugar de desbordar la tarjeta.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.unit,
    this.valueColor,
    this.labelColor,
    this.iconColor,
    this.iconBackgroundColor,
  });

  final String label;
  final String value;
  final String? unit;
  final IconData icon;
  final Color accent;
  final Color? valueColor;
  final Color? labelColor;
  final Color? iconColor;
  final Color? iconBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final resolvedValueColor = valueColor ?? scheme.onSurface;
    final resolvedLabelColor = labelColor ?? scheme.onSurfaceVariant;
    final resolvedIconColor = iconColor ?? accent;
    final resolvedIconBackground =
        iconBackgroundColor ?? accent.withValues(alpha: 0.14);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: resolvedIconBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: resolvedIconColor, size: 24),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            color: resolvedLabelColor,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                maxLines: 1,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: resolvedValueColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 3),
                Text(
                  unit!,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: resolvedLabelColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Etiqueta compacta de una métrica (formato "pastilla").
class MetricPill extends StatelessWidget {
  const MetricPill({
    super.key,
    required this.icon,
    required this.value,
    required this.accent,
    this.unit,
    this.label,
  });

  final IconData icon;
  final String value;
  final String? unit;
  final String? label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 6),
          if (label != null) ...[
            Text(
              label!,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (unit != null) ...[
            const SizedBox(width: 2),
            Text(
              unit!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

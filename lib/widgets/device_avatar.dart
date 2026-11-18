import 'package:flutter/material.dart';

/// Avatar del dispositivo: cuadro redondeado con sus iniciales.
class DeviceAvatar extends StatelessWidget {
  const DeviceAvatar({
    super.key,
    required this.initials,
    this.size = 42,
  });

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 3),
        gradient: LinearGradient(
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, Colors.black, 0.25)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(
        initials,
        style: theme.textTheme.labelLarge?.copyWith(
          color: scheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

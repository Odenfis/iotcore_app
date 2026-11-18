import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'services/iot_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const IoTApp());
}

class IoTApp extends StatelessWidget {
  const IoTApp({super.key, this.repository});

  /// Permite inyectar un origen de lecturas alternativo (tests).
  final ReadingsRepository? repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Panel de sensores IoT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: DashboardScreen(repository: repository),
    );
  }
}

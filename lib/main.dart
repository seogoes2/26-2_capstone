import 'package:flutter/material.dart';

import 'app_routes.dart';
import 'services/alerts.dart';
import 'services/app_storage.dart';
import 'services/sensor_connection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await AppStorage.load();
  final connection = SensorConnection.fromEnvironment()..start();
  final alerts = AlertCenter(storage);
  if (const String.fromEnvironment('SENSOR_MODE') == 'mock') {
    await alerts.addSamplesIfEmpty(DateTime.now());
  }
  runApp(GupsinApp(storage: storage, connection: connection, alerts: alerts));
}

class GupsinApp extends StatelessWidget {
  const GupsinApp({
    super.key,
    required this.storage,
    required this.connection,
    required this.alerts,
  });

  final AppStorage storage;
  final SensorConnection connection;
  final AlertCenter alerts;

  @override
  Widget build(BuildContext context) {
    final routes = AppRoutes.routes(storage, connection, alerts);
    return MaterialApp(
      title: '굽신굽신',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF375BFF)),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Pretendard',
      ),
      initialRoute: AppRoutes.initialRoute(storage),
      routes: routes,
      onGenerateInitialRoutes: (name) => [
        MaterialPageRoute(
          settings: RouteSettings(name: name),
          builder: routes[name]!,
        ),
      ],
    );
  }
}

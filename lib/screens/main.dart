import 'package:flutter/material.dart';

import '../services/alerts.dart';
import '../services/app_storage.dart';
import '../services/metrics_source.dart';
import '../services/sensor_connection.dart';
import '../theme/app_colors.dart';
import '../widgets/home/bottom_nav.dart';
import 'alerts.dart';
import 'wifi.dart';
import 'home.dart';
import 'report.dart';
import 'settings.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.storage,
    required this.connection,
    required this.alerts,
    required this.onEditProfile,
    this.metrics = const EmptyMetricsSource(),
    this.initialTab = HomeTab.home,
  });

  final AppStorage storage;
  final SensorConnection connection;
  final AlertCenter alerts;
  final VoidCallback onEditProfile;
  final MetricsSource metrics;
  final HomeTab initialTab;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late HomeTab _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _tab.index,
              children: [
                HomeScreen(storage: widget.storage, source: widget.metrics),
                ConnectionScreen(connection: widget.connection),
                ReportScreen(
                  romLimit: widget.storage.settings.romLimit,
                  storage: widget.storage,
                  source: widget.metrics,
                ),
                AlertsScreen(center: widget.alerts),
                SettingsScreen(
                  storage: widget.storage,
                  connection: widget.connection,
                  onEditProfile: widget.onEditProfile,
                ),
              ],
            ),
          ),
          BottomNav(
            current: _tab,
            onTap: (tab) {
              FocusScope.of(context).unfocus();
              setState(() => _tab = tab);
            },
          ),
        ],
      ),
    );
  }
}

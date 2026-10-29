import 'package:flutter/material.dart';

import '../services/alerts.dart';
import '../services/app_storage.dart';
import '../services/sensor_connection.dart';
import '../theme/app_colors.dart';
import '../widgets/home/bottom_nav.dart';
import 'alerts.dart';
import 'wifi.dart';
import 'home.dart';
import 'settings.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.storage,
    required this.connection,
    required this.alerts,
    required this.onEditProfile,
    this.initialTab = HomeTab.home,
  });

  final AppStorage storage;
  final SensorConnection connection;
  final AlertCenter alerts;
  final VoidCallback onEditProfile;
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
                HomeScreen(storage: widget.storage),
                ConnectionScreen(connection: widget.connection),
                const _ComingSoon(title: '리포트'),
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

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 78, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: pretendard(27, FontWeight.w700, AppColors.text)),
          const SizedBox(height: 5),
          Text(
            '준비 중인 화면이에요',
            style: pretendard(13, FontWeight.w400, AppColors.textSub),
          ),
        ],
      ),
    );
  }
}

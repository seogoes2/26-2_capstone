import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/alert.dart';
import '../services/alerts.dart';
import '../theme/app_colors.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({
    super.key,
    required this.center,
    this.now = DateTime.now,
  });

  final AlertCenter center;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListenableBuilder(
        listenable: center,
        builder: (context, _) {
          final alerts = center.alerts;
          final current = now();
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 78, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '알림',
                  style: pretendard(27, FontWeight.w700, AppColors.text),
                ),
                const SizedBox(height: 5),
                Text(
                  '착용 습관과 과사용 신호를 확인해요',
                  style: pretendard(13, FontWeight.w400, AppColors.textSub),
                ),
                const SizedBox(height: 24),
                Text(
                  '알림 설정',
                  style: pretendard(17, FontWeight.w600, AppColors.text),
                ),
                const SizedBox(height: 13),
                _PreferencesCard(center: center),
                const SizedBox(height: 32),
                Text(
                  '최근 알림',
                  style: pretendard(17, FontWeight.w600, AppColors.text),
                ),
                if (alerts.isEmpty) ...[
                  const SizedBox(height: 48),
                  Center(
                    child: Text(
                      '최근 알림 내역이 없어요.',
                      style: pretendard(13, FontWeight.w400, AppColors.textSub),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 14),
                  for (final (i, alert) in alerts.indexed) ...[
                    if (i > 0) const SizedBox(height: 18),
                    _AlertCard(
                      alert: alert,
                      timeLabel: alert.timeLabel(current),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard({required this.center});

  final AlertCenter center;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 201,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          ..._row(
            top: 18,
            title: '착용 권장 알림',
            description: '2시간 동안 착용 기록이 없으면 알려줘요.',
            value: center.wearReminderOn,
            onChanged: center.setWearReminder,
          ),
          const Positioned(
            left: 18,
            right: 18,
            top: 96,
            child: Divider(height: 1, thickness: 1, color: AppColors.divider),
          ),
          ..._row(
            top: 114,
            title: '과사용 알림',
            description: '1시간 내 설정 각도 초과 5회부터 알려줘요.',
            value: center.overuseOn,
            onChanged: center.setOveruse,
          ),
        ],
      ),
    );
  }

  static List<Widget> _row({
    required double top,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => [
    Positioned(
      left: 18,
      top: top,
      child: Text(
        title,
        style: pretendard(14, FontWeight.w600, AppColors.text),
      ),
    ),
    Positioned(
      left: 18,
      right: 84,
      top: top + 29,
      child: Text(
        description,
        style: pretendard(12, FontWeight.w400, AppColors.textSub),
      ),
    ),
    Positioned(
      right: 18,
      top: top + 3,
      child: AppSwitch(value: value, label: title, onChanged: onChanged),
    ),
  ];
}

class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: label,
      button: true,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: 46,
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: value ? AppColors.primary : AppColors.divider,
            borderRadius: BorderRadius.circular(13),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.timeLabel});

  final AppAlert alert;
  final String timeLabel;

  static double _height(AppAlert alert) => switch (alert.kind) {
    _ when alert.message != null => 130,
    AlertKind.goal => 113,
    _ => 120,
  };

  @override
  Widget build(BuildContext context) {
    final message = alert.message;
    final detailTop = message == null ? 48.0 : 73.0;
    final timeTop = message == null ? 82.0 : 103.0;
    return Container(
      height: _height(alert),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 18,
            top: 19,
            child: SvgPicture.asset(
              'assets/icons/${alert.kind.icon}.svg',
              width: 23,
              height: 23,
            ),
          ),
          Positioned(
            left: 52,
            right: 18,
            top: 17,
            child: Text(
              alert.title,
              style: pretendard(14, FontWeight.w600, AppColors.text),
            ),
          ),
          if (message != null)
            Positioned(
              left: 52,
              right: 18,
              top: 47,
              child: Text(
                message,
                style: pretendard(13, FontWeight.w500, AppColors.text),
              ),
            ),
          Positioned(
            left: 52,
            right: 18,
            top: detailTop,
            child: Text(
              alert.detail,
              style: pretendard(12, FontWeight.w400, AppColors.textSub),
            ),
          ),
          Positioned(
            left: 52,
            top: timeTop,
            child: Text(
              timeLabel,
              style: pretendard(11, FontWeight.w400, AppColors.textSub),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/settings.dart';
import '../services/app_storage.dart';
import '../services/sensor_connection.dart';
import '../theme/app_colors.dart';
import '../widgets/app_button.dart';
import '../widgets/steps.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.storage,
    required this.connection,
    required this.onEditProfile,
  });

  final AppStorage storage;
  final SensorConnection connection;
  final VoidCallback onEditProfile;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late DeviceSettings _settings = widget.storage.settings;

  Future<void> _update(DeviceSettings next) async {
    setState(() => _settings = next);
    await widget.storage.saveSettings(next);
    await widget.connection.sendSettings(next.toJson());
  }

  @override
  Widget build(BuildContext context) {
    const romOptions = DeviceSettings.romOptions;
    const vibOptions = DeviceSettings.vibrationOptions;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 78, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '기기 설정',
              style: pretendard(27, FontWeight.w700, AppColors.text),
            ),
            const SizedBox(height: 5),
            Text(
              '나에게 맞는 움직임과 진동을 설정해요',
              style: pretendard(13, FontWeight.w400, AppColors.textSub),
            ),
            const SizedBox(height: 21),
            Text(
              '관절 움직임',
              style: pretendard(17, FontWeight.w600, AppColors.text),
            ),
            const SizedBox(height: 21),
            _Card(
              height: 220,
              children: [
                ..._header(
                  top: 18,
                  title: '허용 ROM',
                  value: '${_settings.romLimit}°',
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  top: 44,
                  child: StepSlider(
                    semanticLabel: '허용 ROM',
                    labels: [for (final v in romOptions) '$v°'],
                    selected: romOptions.indexOf(_settings.romLimit),
                    onChanged: (i) =>
                        _update(_settings.copyWith(romLimit: romOptions[i])),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  top: 106,
                  child: Text(
                    '허용 범위를 넘긴 움직임을 과굴곡으로 기록해요.',
                    style: pretendard(12, FontWeight.w400, AppColors.textSub),
                  ),
                ),
                const Positioned(
                  left: 18,
                  right: 18,
                  top: 142,
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.divider,
                  ),
                ),
                ..._header(
                  top: 162,
                  title: '진동 시작 각도',
                  value: '${_settings.vibrationStartAngle}°',
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  top: 190,
                  child: Text(
                    '허용 ROM에 가까워지면 진동으로 알려줘요.',
                    style: pretendard(12, FontWeight.w400, AppColors.textSub),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 21),
            Text(
              '기기 진동 피드백',
              style: pretendard(17, FontWeight.w600, AppColors.text),
            ),
            const SizedBox(height: 11),
            _Card(
              height: 122,
              children: [
                ..._header(
                  top: 18,
                  title: '진동 지속 시간',
                  value: '${_settings.vibrationSeconds}초',
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  top: 44,
                  child: StepSlider(
                    semanticLabel: '진동 지속 시간',
                    labels: [for (final v in vibOptions) '$v초'],
                    selected: vibOptions.indexOf(_settings.vibrationSeconds),
                    onChanged: (i) => _update(
                      _settings.copyWith(vibrationSeconds: vibOptions[i]),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 45),
            AppButton(
              label: '초기 설정 변경',
              width: double.infinity,
              height: 48,
              radius: 14,
              textStyle: pretendard(20, FontWeight.w600, Colors.white),
              onPressed: widget.onEditProfile,
            ),
          ],
        ),
      ),
    );
  }

  static List<Widget> _header({
    required double top,
    required String title,
    required String value,
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
      right: 18,
      top: top,
      child: Text(
        value,
        style: pretendard(14, FontWeight.w600, AppColors.primary),
      ),
    ),
  ];
}

class _Card extends StatelessWidget {
  const _Card({required this.height, required this.children});

  final double height;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(clipBehavior: Clip.none, children: children),
    );
  }
}

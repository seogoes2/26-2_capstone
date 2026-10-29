import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/sensor_connection.dart';
import '../theme/app_colors.dart';
import '../widgets/app_button.dart';

class ConnectionScreen extends StatelessWidget {
  const ConnectionScreen({super.key, required this.connection});

  final SensorConnection connection;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListenableBuilder(
        listenable: connection,
        builder: (context, _) {
          final state = connection.state;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 78, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '통신',
                  style: pretendard(27, FontWeight.w700, AppColors.text),
                ),
                const SizedBox(height: 5),
                Text(
                  '기기 연결과 데이터 동기화를 관리해요',
                  style: pretendard(13, FontWeight.w400, AppColors.textSub),
                ),
                const SizedBox(height: 25),
                switch (state) {
                  ConnectionChecking() => const _StatusCard.checking(),
                  ConnectionConnected() => _ConnectedBody(
                    state: state,
                    onSync: () => connection.refresh(manual: true),
                  ),
                  ConnectionDisconnected() => _DisconnectedBody(
                    problem: state.problem,
                    onRetry: () => connection.refresh(manual: true),
                  ),
                },
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.icon, required this.title, this.subtitle});

  const _StatusCard.checking()
    : icon = const SizedBox(
        width: 30,
        height: 30,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.primary,
        ),
      ),
      title = '연결 확인 중',
      subtitle = null;

  final Widget icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 212,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 86,
            height: 86,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: icon,
          ),
          const SizedBox(height: 13),
          Text(title, style: pretendard(23, FontWeight.w700, AppColors.text)),
          if (subtitle != null) ...[
            const SizedBox(height: 7),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: pretendard(12, FontWeight.w400, AppColors.primaryDeep),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConnectedBody extends StatelessWidget {
  const _ConnectedBody({required this.state, required this.onSync});

  final ConnectionConnected state;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final status = state.status;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusCard(
          icon: SvgPicture.asset(
            'assets/icons/wifi_large.svg',
            width: 44,
            height: 44,
          ),
          title: 'Wi-Fi 연결됨',
          subtitle: '${status.name} · ${status.signalLabel}',
        ),
        const SizedBox(height: 30),
        Text('연결된 기기', style: pretendard(17, FontWeight.w600, AppColors.text)),
        const SizedBox(height: 13),
        _DeviceCard(status: status),
        const SizedBox(height: 27),
        Text('데이터 동기화', style: pretendard(17, FontWeight.w600, AppColors.text)),
        const SizedBox(height: 13),
        _SyncCard(state: state),
        const SizedBox(height: 24),
        AppButton(
          label: state.syncing ? '동기화 중…' : '지금 동기화',
          width: double.infinity,
          height: 48,
          radius: 14,
          textStyle: pretendard(18, FontWeight.w600, Colors.white),
          onPressed: state.syncing ? null : onSync,
        ),
      ],
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.status});

  final SensorStatus status;

  @override
  Widget build(BuildContext context) {
    final battery = status.batteryPercent;
    return Container(
      height: 101,
      padding: const EdgeInsets.fromLTRB(18, 0, 19, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(15),
            ),
            child: SvgPicture.asset(
              'assets/icons/device.svg',
              width: 30,
              height: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.displayName,
                  style: pretendard(15, FontWeight.w600, AppColors.text),
                ),
                Text(
                  battery == null ? '배터리 정보 없음' : '배터리 $battery%',
                  style: pretendard(12, FontWeight.w400, AppColors.textSub),
                ),
              ],
            ),
          ),
          Container(
            width: 68,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE9F7F1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '연결됨',
              style: pretendard(11, FontWeight.w600, AppColors.positive),
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncCard extends StatelessWidget {
  const _SyncCard({required this.state});

  final ConnectionConnected state;

  @override
  Widget build(BuildContext context) {
    final records = state.status.todayRecords;
    const divider = Divider(height: 1, thickness: 1, color: AppColors.divider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const SizedBox(height: 23),
          _row('마지막 동기화', _relative(state.lastSync), AppColors.text),
          const SizedBox(height: 19),
          divider,
          const SizedBox(height: 14),
          _row('오늘 수신 기록', records == null ? '-' : '$records건', AppColors.text),
          const SizedBox(height: 13),
          divider,
          const SizedBox(height: 20),
          state.syncing
              ? _row('동기화 상태', '동기화 중…', AppColors.textSub)
              : _row('동기화 상태', '최신 상태', AppColors.primary),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static Widget _row(String label, String value, Color valueColor) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: pretendard(13, FontWeight.w400, AppColors.textSub)),
      Text(value, style: pretendard(13, FontWeight.w600, valueColor)),
    ],
  );

  static String _relative(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }
}

class _DisconnectedBody extends StatefulWidget {
  const _DisconnectedBody({required this.problem, required this.onRetry});

  final ConnectionProblem problem;
  final Future<void> Function() onRetry;

  @override
  State<_DisconnectedBody> createState() => _DisconnectedBodyState();
}

class _DisconnectedBodyState extends State<_DisconnectedBody> {
  bool _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    await Future.wait([
      widget.onRetry(),
      Future<void>.delayed(const Duration(milliseconds: 600)),
    ]);
    if (mounted) setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    final wifiOff = widget.problem == ConnectionProblem.wifiOff;
    return Column(
      children: [
        _StatusCard(
          icon: SvgPicture.asset(
            'assets/icons/wifi_off.svg',
            width: 42.13,
            height: 42.13,
          ),
          title: '연결 끊김',
          subtitle: wifiOff
              ? '휴대폰 Wi-Fi가 꺼져 있어요'
              : 'Wi-Fi는 켜져 있지만 센서가 응답하지 않아요',
        ),
        const SizedBox(height: 106),
        SizedBox(
          width: 100,
          height: 100,
          child: Center(
            child: SvgPicture.asset(
              'assets/icons/error.svg',
              width: 83.33,
              height: 83.33,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          wifiOff
              ? 'Wi-Fi 연결을 한 번 더 확인해주세요.'
              : '센서 전원과 Wi-Fi 연결을 한 번 더 확인해주세요.',
          textAlign: TextAlign.center,
          style: pretendard(13, FontWeight.w400, AppColors.textSub),
        ),
        const SizedBox(height: 21),
        AppButton(
          label: _retrying ? '확인 중…' : '새로고침',
          width: 168,
          height: 48,
          radius: 14,
          textStyle: pretendard(18, FontWeight.w600, Colors.white),
          onPressed: _retrying ? null : _retry,
        ),
      ],
    );
  }
}

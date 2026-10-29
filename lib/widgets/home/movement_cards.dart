import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../models/today_metrics.dart';
import '../../theme/app_colors.dart';

class CurrentAngleCard extends StatelessWidget {
  const CurrentAngleCard({super.key, required this.metrics});

  final TodayMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final angle = metrics.jointAngle;
    final within = metrics.isWithinRom;

    return Container(
      height: 198,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 20,
            top: 18,
            child: Text(
              '현재 관절 각도',
              style: pretendard(13, FontWeight.w500, AppColors.primaryDeep),
            ),
          ),
          Positioned(
            left: 18,
            top: 51,
            child: Text(
              angle == null ? '--°' : '$angle°',
              style: pretendard(65, FontWeight.w700, AppColors.text),
            ),
          ),
          if (angle != null)
            Positioned(
              left: 20,
              top: 143,
              child: Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  within ? '✓ 허용 ROM 안' : '! 허용 ROM 밖',
                  style: pretendard(
                    11,
                    FontWeight.w600,
                    within ? AppColors.primary : AppColors.negative,
                  ),
                ),
              ),
            ),
          Positioned(
            right: 26,
            top: 49,
            width: 108,
            height: 108,
            child: CustomPaint(
              painter: _RomRingPainter(
                progress: angle == null || metrics.romMax == 0
                    ? 0
                    : (angle / metrics.romMax).clamp(0.0, 1.0),
              ),
              child: Center(
                child: Text(
                  '${metrics.romMin}–${metrics.romMax}°',
                  style: pretendard(18, FontWeight.w600, AppColors.primaryDeep),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RomRingPainter extends CustomPainter {
  _RomRingPainter({required this.progress});

  final double progress;

  static const _stroke = 6.48;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final ring = rect.deflate(_stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;

    canvas.drawOval(ring, paint..color = AppColors.divider);
    if (progress > 0) {
      canvas.drawArc(
        ring,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        paint..color = AppColors.primary,
      );
    }
  }

  @override
  bool shouldRepaint(_RomRingPainter old) => old.progress != progress;
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    required this.captionColor,
  });

  final String icon;
  final String label;
  final String value;
  final String caption;
  final Color captionColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 122,
      padding: const EdgeInsets.fromLTRB(16, 15, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset('assets/icons/$icon.svg', width: 20, height: 20),
          const SizedBox(height: 5),
          Text(
            label,
            style: pretendard(12, FontWeight.w400, AppColors.textSub),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: pretendard(24, FontWeight.w700, AppColors.text),
            ),
          ),
          Text(caption, style: pretendard(11, FontWeight.w400, captionColor)),
        ],
      ),
    );
  }
}

class WearGoalCard extends StatelessWidget {
  const WearGoalCard({super.key, required this.goal});

  final Duration goal;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      padding: const EdgeInsets.only(left: 22, right: 33),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '하루 착용 목표',
            style: pretendard(20, FontWeight.w600, AppColors.text),
          ),
          Text(
            formatDuration(goal),
            style: pretendard(24, FontWeight.w600, AppColors.primary),
          ),
        ],
      ),
    );
  }
}

String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h == 0) return '$m분';
  if (m == 0) return '$h시간';
  return '$h시간 $m분';
}

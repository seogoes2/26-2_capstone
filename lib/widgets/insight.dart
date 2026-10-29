import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

class InsightCard extends StatelessWidget {
  const InsightCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.height = 75,
    this.iconOffset = const Offset(17, 19),
    this.titleTop = 16,
    this.iconTurns = 0,
  });

  final String icon;
  final String title;
  final String body;
  final double height;
  final Offset iconOffset;
  final double titleTop;
  final double iconTurns;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(
            left: iconOffset.dx,
            top: iconOffset.dy,
            child: RotatedBox(
              quarterTurns: iconTurns.round(),
              child: SvgPicture.asset(
                'assets/icons/$icon.svg',
                width: 21,
                height: 21,
              ),
            ),
          ),
          Positioned(
            left: 51,
            right: 17,
            top: titleTop,
            child: Text(
              title,
              style: pretendard(13, FontWeight.w600, AppColors.text),
            ),
          ),
          Positioned(
            left: 51,
            right: 17,
            top: 42,
            child: Text(
              body,
              style: pretendard(12, FontWeight.w400, AppColors.textSub),
            ),
          ),
        ],
      ),
    );
  }
}

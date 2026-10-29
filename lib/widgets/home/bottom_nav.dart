import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_colors.dart';

enum HomeTab {
  home('홈', 'home'),
  connection('통신', 'wifi'),
  report('리포트', 'chart'),
  alerts('알림', 'bell'),
  settings('설정', 'settings');

  const HomeTab(this.label, this.icon);

  final String label;
  final String icon;
}

class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.current, required this.onTap});

  final HomeTab current;
  final ValueChanged<HomeTab> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final tab in HomeTab.values)
            Expanded(
              child: _NavItem(
                tab: tab,
                active: tab == current,
                onTap: () => onTap(tab),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.active,
    required this.onTap,
  });

  final HomeTab tab;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textSub;
    return Semantics(
      button: true,
      selected: active,
      label: tab.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: 56,
            height: 62,
            decoration: BoxDecoration(
              color: active ? AppColors.primarySoft : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const SizedBox(height: 13),
                SvgPicture.asset(
                  'assets/icons/${tab.icon}.svg',
                  width: 26,
                  height: 26,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                ),
                Text(
                  tab.label,
                  maxLines: 1,
                  style: pretendard(
                    11,
                    active ? FontWeight.w600 : FontWeight.w400,
                    color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

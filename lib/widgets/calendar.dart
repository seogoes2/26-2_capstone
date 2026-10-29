import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.today,
    required this.hasRecord,
    required this.onSelect,
    this.selected,
    this.onPrevious,
    this.onNext,
    this.onPickMonth,
  });

  /// Any date inside the month to show.
  final DateTime month;
  final DateTime today;
  final bool Function(int day) hasRecord;
  final ValueChanged<DateTime> onSelect;
  final DateTime? selected;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onPickMonth;

  static const weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  static const double _sidePadding = 16;
  static const double _rowHeight = 44;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final dayCount = DateUtils.getDaysInMonth(month.year, month.month);
    final lead = first.weekday % 7;
    final weeks = ((lead + dayCount) / 7).ceil();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 64, child: _header()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
            child: Row(
              children: [
                for (final w in weekdays)
                  Expanded(
                    child: Text(
                      w,
                      textAlign: TextAlign.center,
                      style: pretendard(11, FontWeight.w400, AppColors.textSub),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          for (var week = 0; week < weeks; week++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
              child: SizedBox(
                height: _rowHeight,
                child: Row(
                  children: [
                    for (var col = 0; col < 7; col++)
                      Expanded(
                        child: _cell(week * 7 + col - lead + 1, dayCount),
                      ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(19, 7, 18, 21),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _dot(4, AppColors.primary),
                ),
                const SizedBox(width: 8),
                Text(
                  '착용 기록 있음',
                  style: pretendard(11, FontWeight.w400, AppColors.textSub),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    final title = '${month.year}년 ${month.month}월';
    return Stack(
      children: [
        Positioned(
          left: 6,
          top: 6,
          child: _chevron('left', '이전 달', onPrevious),
        ),
        Positioned(right: 6, top: 6, child: _chevron('right', '다음 달', onNext)),
        Positioned(
          left: 50,
          right: 50,
          top: 17,
          child: Center(
            child: Semantics(
              button: onPickMonth != null,
              label: '$title, 월 선택',
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onPickMonth,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Balances the arrow so the title itself stays centered.
                    const SizedBox(width: 18),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          title,
                          style: pretendard(
                            17,
                            FontWeight.w600,
                            AppColors.text,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: Transform.flip(
                        flipY: true,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: SvgPicture.asset('assets/icons/dropdown.svg'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chevron(String side, String label, VoidCallback? onTap) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Opacity(
              opacity: onTap == null ? 0.3 : 1,
              child: SvgPicture.asset(
                'assets/icons/chevron_$side.svg',
                width: 20,
                height: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cell(int day, int dayCount) {
    if (day < 1 || day > dayCount) return const SizedBox.shrink();
    final date = DateTime(month.year, month.month, day);
    final future = date.isAfter(DateUtils.dateOnly(today));
    final isSelected = selected != null && DateUtils.isSameDay(selected, date);
    final record = !future && hasRecord(day);

    return Semantics(
      button: !future,
      selected: isSelected,
      label: '${month.month}월 $day일${record ? ', 착용 기록 있음' : ''}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: future ? null : () => onSelect(date),
        child: Align(
          alignment: Alignment.topCenter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 6,
                  child: Text(
                    '$day',
                    textAlign: TextAlign.center,
                    style: pretendard(
                      13,
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                      isSelected
                          ? Colors.white
                          : future
                          ? AppColors.textSub
                          : AppColors.text,
                    ),
                  ),
                ),
                if (record)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 30,
                    child: Center(
                      child: _dot(
                        3,
                        isSelected ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _dot(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

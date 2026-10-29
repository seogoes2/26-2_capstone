import 'package:flutter/material.dart';

import '../models/today_metrics.dart';
import '../models/weekly.dart';
import '../theme/app_colors.dart';
import '../widgets/chart.dart';
import '../widgets/insight.dart';
import '../widgets/home/movement_cards.dart';

enum ReportPeriod {
  day('하루'),
  week('주간'),
  month('월간');

  const ReportPeriod(this.label);

  final String label;
}

class ReportScreen extends StatefulWidget {
  const ReportScreen({
    super.key,
    this.metrics = TodayMetrics.sample,
    this.weekly = WeeklyMetrics.sample,
    this.romLimit = 45,
    this.now = DateTime.now,
  });

  final TodayMetrics metrics;
  final WeeklyMetrics weekly;
  final int romLimit;
  final DateTime Function() now;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ReportPeriod _period = ReportPeriod.day;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 78, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '사용 리포트',
              style: pretendard(27, FontWeight.w700, AppColors.text),
            ),
            const SizedBox(height: 5),
            Text(
              '움직임과 착용 시간을 한눈에 살펴보세요',
              style: pretendard(13, FontWeight.w400, AppColors.textSub),
            ),
            const SizedBox(height: 19),
            PeriodSelector(
              selected: _period,
              onChanged: (p) => setState(() => _period = p),
            ),
            switch (_period) {
              ReportPeriod.day => _DailyReport(
                metrics: widget.metrics,
                day: widget.now(),
                romLimit: widget.romLimit,
              ),
              ReportPeriod.week => _WeeklyReport(
                metrics: widget.weekly,
                today: widget.now(),
              ),
              _ => Padding(
                padding: const EdgeInsets.only(top: 48),
                child: Center(
                  child: Text(
                    '${_period.label} 리포트는 준비 중이에요.',
                    style: pretendard(13, FontWeight.w400, AppColors.textSub),
                  ),
                ),
              ),
            },
          ],
        ),
      ),
    );
  }
}

class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ReportPeriod selected;
  final ValueChanged<ReportPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    const periods = ReportPeriod.values;
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(13),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slot = constraints.maxWidth / periods.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                left: slot * selected.index,
                width: slot,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final p in periods)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: p == selected,
                        label: p.label,
                        excludeSemantics: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onChanged(p),
                          child: Center(
                            child: Text(
                              p.label,
                              style: pretendard(
                                13,
                                FontWeight.w600,
                                p == selected
                                    ? AppColors.primary
                                    : AppColors.textSub,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DailyReport extends StatelessWidget {
  const _DailyReport({
    required this.metrics,
    required this.day,
    required this.romLimit,
  });

  final TodayMetrics metrics;
  final DateTime day;
  final int romLimit;

  InsightCard? _insight() {
    final maxOver = metrics.maxOverAngle;
    final hourly = metrics.hourlyOverflex;
    if (metrics.overflexCount == 0 || maxOver == null || hourly.isEmpty) {
      return null;
    }
    var peak = 0;
    for (var i = 1; i < hourly.length; i++) {
      if (hourly[i] > hourly[peak]) peak = i;
    }
    final hour = int.parse(TodayMetrics.hourlyLabels[peak]);
    final clock = hour < 12
        ? '오전 $hour시'
        : '오후 ${hour == 12 ? 12 : hour - 12}시';
    return InsightCard(
      icon: 'warning',
      title: '최대 $maxOver°를 초과한 움직임이 있었어요',
      body: '$clock 과굴곡 ${hourly[peak]}회 · 허용 ROM $romLimit° 기준',
      height: 74,
      iconOffset: const Offset(16, 25),
      titleTop: 18,
    );
  }

  static String _dateLabel(DateTime d) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${d.month}월 ${d.day}일 ${weekdays[d.weekday - 1]}요일';
  }

  @override
  Widget build(BuildContext context) {
    final maxOver = metrics.maxOverAngle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 1),
          child: Text(
            _dateLabel(day),
            style: pretendard(13, FontWeight.w500, AppColors.text),
          ),
        ),
        const SizedBox(height: 11),
        HeadlineCard(
          label: '오늘의 착용 시간',
          wear: metrics.wearTime,
          overflex: metrics.overflexCount,
          maxOver: maxOver,
          goalPercent: metrics.wearGoalPercent,
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                '시간대별 과굴곡',
                style: pretendard(17, FontWeight.w600, AppColors.text),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 17, right: 16),
              child: Text(
                '단위: 회',
                style: pretendard(11, FontWeight.w400, AppColors.textSub),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        HourlyBarChart(
          values: metrics.hourlyOverflex.isEmpty
              ? List.filled(TodayMetrics.hourlyLabels.length, 0)
              : metrics.hourlyOverflex,
          labels: TodayMetrics.hourlyLabels,
        ),
        const SizedBox(height: 13),
        Text(
          '사용 기록 분석',
          style: pretendard(17, FontWeight.w600, AppColors.text),
        ),
        const SizedBox(height: 21),
        _insight() ??
            Center(
              child: Text(
                '최근 사용 기록이 없어요.',
                style: pretendard(13, FontWeight.w400, AppColors.textSub),
              ),
            ),
      ],
    );
  }
}

class HeadlineCard extends StatelessWidget {
  const HeadlineCard({
    super.key,
    required this.label,
    required this.wear,
    required this.overflex,
    required this.maxOver,
    required this.goalPercent,
  });

  final String label;
  final Duration wear;
  final int overflex;
  final int? maxOver;
  final int goalPercent;

  @override
  Widget build(BuildContext context) {
    final over = maxOver;
    return Container(
      height: 173,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 20,
            top: 18,
            child: Text(
              label,
              style: pretendard(13, FontWeight.w500, Colors.white),
            ),
          ),
          Positioned(
            left: 20,
            top: 43,
            child: Text(
              formatDuration(wear),
              style: pretendard(37, FontWeight.w700, Colors.white),
            ),
          ),
          Positioned(
            left: 21,
            right: 19,
            top: 111,
            child: Container(height: 1, color: AppColors.primaryDeep),
          ),
          ..._metric(20, '과굴곡', '$overflex회'),
          ..._metric(125, '최대 초과 각도', over == null ? '-' : '+$over°'),
          ..._metric(230, '목표 달성', '$goalPercent%'),
        ],
      ),
    );
  }

  static List<Widget> _metric(double left, String label, String value) => [
    Positioned(
      left: left,
      top: 122,
      child: Text(label, style: pretendard(11, FontWeight.w400, Colors.white)),
    ),
    Positioned(
      left: left,
      top: 138,
      child: Text(value, style: pretendard(17, FontWeight.w600, Colors.white)),
    ),
  ];
}

class _WeeklyReport extends StatelessWidget {
  const _WeeklyReport({required this.metrics, required this.today});

  final WeeklyMetrics metrics;
  final DateTime today;

  static String _rangeLabel(DateTime start, DateTime end) {
    final head = '${start.month}월 ${start.day}일';
    final tail = start.month == end.month
        ? '${end.day}일'
        : '${end.month}월 ${end.day}일';
    return '$head – $tail';
  }

  List<Widget> _insights() {
    final avg = metrics.averageWear;
    final lastAvg = metrics.lastWeekAverageWear;
    String avgBody;
    var avgTurns = 0.0;
    if (lastAvg == null) {
      avgBody = '지난주 기록이 없어요.';
    } else {
      final diff = avg - lastAvg;
      if (diff.inMinutes > 0) {
        avgBody =
            '지난주 평균 ${formatDuration(lastAvg)}보다 ${formatDuration(diff)} 증가했어요.';
      } else if (diff.inMinutes < 0) {
        avgBody =
            '지난주 평균 ${formatDuration(lastAvg)}보다 ${formatDuration(-diff)} 감소했어요.';
        avgTurns = 1;
      } else {
        avgBody = '지난주 평균과 같아요.';
      }
    }

    final now = metrics.overflexCount;
    final last = metrics.lastWeekOverflex;
    String overTitle;
    var overIcon = 'shield';
    if (last == null) {
      overTitle = '이번 주 과굴곡 $now회';
    } else if (now < last) {
      overTitle = '과굴곡 횟수는 ${last - now}회 줄었어요';
    } else if (now > last) {
      overTitle = '과굴곡 횟수는 ${now - last}회 늘었어요';
      overIcon = 'warning';
    } else {
      overTitle = '과굴곡 횟수가 지난주와 같아요';
    }

    return [
      InsightCard(
        icon: 'arrow',
        iconTurns: avgTurns,
        title: '하루 평균 ${formatDuration(avg)} 착용했어요',
        body: avgBody,
      ),
      const SizedBox(height: 15),
      InsightCard(
        icon: overIcon,
        title: overTitle,
        body: last == null ? '지난주 기록이 없어요.' : '지난주 $last회 → 이번 주 $now회',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final day = DateTime(today.year, today.month, today.day);
    final start = day.subtract(Duration(days: day.weekday - 1));
    final end = start.add(const Duration(days: 6));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 1),
          child: Text(
            _rangeLabel(start, end),
            style: pretendard(13, FontWeight.w500, AppColors.text),
          ),
        ),
        const SizedBox(height: 11),
        HeadlineCard(
          label: '이번 주 착용 시간',
          wear: metrics.totalWear,
          overflex: metrics.overflexCount,
          maxOver: metrics.maxOverAngle,
          goalPercent: metrics.goalPercent,
        ),
        const SizedBox(height: 27),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                '착용 시간 변화',
                style: pretendard(17, FontWeight.w600, AppColors.text),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 13, right: 6),
              child: Text(
                '단위: 시간',
                style: pretendard(11, FontWeight.w400, AppColors.textSub),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        WeeklyLineChart(
          values: metrics.dailyWear,
          labels: WeeklyMetrics.dayLabels,
          initialSelected: day.weekday - 1,
        ),
        const SizedBox(height: 27),
        Text('이번 주 변화', style: pretendard(17, FontWeight.w600, AppColors.text)),
        const SizedBox(height: 13),
        ..._insights(),
      ],
    );
  }
}

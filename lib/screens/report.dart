import 'package:flutter/material.dart';

import '../models/journal_entry.dart';
import '../models/monthly.dart';
import '../models/today_metrics.dart';
import '../models/weekly.dart';
import '../services/app_storage.dart';
import '../services/metrics_source.dart';
import '../theme/app_colors.dart';
import '../widgets/app_toast.dart';
import '../widgets/calendar.dart';
import '../widgets/chart.dart';
import '../widgets/insight.dart';
import '../widgets/journal_record.dart';
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
    this.source = const EmptyMetricsSource(),
    this.romLimit = 45,
    this.now = DateTime.now,
    this.storage,
  });

  final MetricsSource source;
  final int romLimit;
  final DateTime Function() now;

  /// Where daily journals are read from and saved to. Kept in memory when null.
  final AppStorage? storage;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ReportPeriod _period = ReportPeriod.day;
  TodayMetrics _today = TodayMetrics.empty;
  WeeklyMetrics _week = WeeklyMetrics.empty;

  /// Bumped on pull-to-refresh so the monthly view reloads too.
  int _generation = 0;

  DateTime get _day => DateUtils.dateOnly(widget.now());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final day = _day;
    try {
      final (today, week) = await (
        widget.source.today(day),
        widget.source.week(day.subtract(Duration(days: day.weekday - 1))),
      ).wait;
      if (!mounted) return;
      setState(() {
        _today = today;
        _week = week;
      });
    } catch (e) {
      debugPrint('리포트 데이터를 불러오지 못했어요: $e');
    }
  }

  Future<void> _refresh() {
    setState(() => _generation++);
    return _load();
  }

  @override
  Widget build(BuildContext context) {
    final day = _day;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                  _period == ReportPeriod.day
                      ? '움직임과 착용 시간을 한눈에 살펴보세요'
                      : '날짜별 기록과 월간 변화를 살펴보세요',
                  style: pretendard(13, FontWeight.w400, AppColors.textSub),
                ),
                const SizedBox(height: 19),
                PeriodSelector(
                  selected: _period,
                  onChanged: (p) => setState(() => _period = p),
                ),
                switch (_period) {
                  ReportPeriod.day => _DailyReport(
                    metrics: _today,
                    day: day,
                    romLimit: widget.romLimit,
                  ),
                  ReportPeriod.week => _WeeklyReport(
                    metrics: _week,
                    today: day,
                  ),
                  ReportPeriod.month => _MonthlyReport(
                    source: widget.source,
                    today: day,
                    todayMetrics: _today,
                    storage: widget.storage,
                    generation: _generation,
                  ),
                },
              ],
            ),
          ),
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
    if (!metrics.hasRecords) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(
              '최근 사용 기록이 없어요.',
              style: pretendard(13, FontWeight.w400, AppColors.textSub),
            ),
          ),
        ),
      ];
    }

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
        height: 80,
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
        const SizedBox(height: 16),
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
          values: metrics.hasRecords ? metrics.dailyWear : const [],
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

class _MonthlyReport extends StatefulWidget {
  const _MonthlyReport({
    required this.source,
    required this.today,
    required this.todayMetrics,
    required this.storage,
    required this.generation,
  });

  final MetricsSource source;
  final DateTime today;
  final TodayMetrics todayMetrics;
  final AppStorage? storage;
  final int generation;

  @override
  State<_MonthlyReport> createState() => _MonthlyReportState();
}

class _MonthlyReportState extends State<_MonthlyReport> {
  static const _monthsBack = 23;

  late final DateTime _today = DateUtils.dateOnly(widget.today);
  late final DateTime _thisMonth = DateTime(_today.year, _today.month);
  late DateTime _month = _thisMonth;
  late MonthlyMetrics _metrics = _emptyFor(_month);
  late MonthlyMetrics _previous = _emptyFor(_shift(_month, -1));
  late DateTime? _selected = _today;
  bool _editing = false;
  final _formKey = GlobalKey();
  final _recordKey = GlobalKey();
  final _toastKey = GlobalKey<AppToastState>();

  // Fallback when there is no storage (tests, previews).
  final Map<DateTime, JournalEntry> _journals = {};

  @override
  void initState() {
    super.initState();
    _load(_month);
  }

  @override
  void didUpdateWidget(covariant _MonthlyReport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.generation != widget.generation) _load(_month);
  }

  static MonthlyMetrics _emptyFor(DateTime m) =>
      MonthlyMetrics.empty(m.year, m.month);

  static DateTime _shift(DateTime m, int months) =>
      DateTime(m.year, m.month + months);

  Future<void> _load(DateTime month) async {
    final prev = _shift(month, -1);
    try {
      final (current, previous) = await (
        widget.source.month(month.year, month.month),
        widget.source.month(prev.year, prev.month),
      ).wait;
      // Ignore a late answer for a month the user already left.
      if (!mounted || month != _month) return;
      setState(() {
        _metrics = current;
        _previous = previous;
      });
    } catch (e) {
      debugPrint('월간 데이터를 불러오지 못했어요: $e');
    }
  }

  /// This month with today's live numbers, so it matches the daily report.
  MonthlyMetrics get _shown {
    final t = widget.todayMetrics;
    final today = DayRecord(
      wear: t.wearTime,
      overflexCount: t.overflexCount,
      maxOverAngle: t.maxOverAngle,
    );
    if (!_isThisMonth || !today.hasRecord) return _metrics;
    return MonthlyMetrics(
      year: _metrics.year,
      month: _metrics.month,
      wearGoalPerDay: _metrics.wearGoalPerDay,
      days: {..._metrics.days, _today.day: today},
    );
  }

  DateTime get _earliest => _shift(_thisMonth, -_monthsBack);

  bool get _isThisMonth => _month == _thisMonth;

  JournalEntry _journalFor(DateTime day) =>
      widget.storage?.journalFor(day) ?? _journals[day] ?? JournalEntry.empty;

  void _goTo(DateTime month) {
    if (month == _month) return;
    setState(() {
      _month = month;
      _metrics = _emptyFor(month);
      _previous = _emptyFor(_shift(month, -1));
      _selected = month == _thisMonth ? _today : null;
      _editing = false;
    });
    _load(month);
  }

  void _select(DateTime day) {
    if (_selected == day) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _selected = day;
      _editing = false;
    });
  }

  void _scrollTo(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (ctx == null || !ctx.mounted) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0.05,
        alignmentPolicy: key == _recordKey
            ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
            : ScrollPositionAlignmentPolicy.explicit,
      );
    });
  }

  void _startEditing() {
    setState(() => _editing = true);
    _scrollTo(_formKey);
  }

  Future<void> _save(DateTime day, JournalEntry entry) async {
    final storage = widget.storage;
    if (storage == null) {
      _journals[day] = entry;
    } else {
      await storage.saveJournal(day, entry);
    }
    if (!mounted) return;
    setState(() => _editing = false);
    _scrollTo(_recordKey);
    _toastKey.currentState?.show('저장되었어요.');
  }

  Future<void> _pickMonth() async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => _MonthPickerSheet(
        months: [for (var i = 0; i <= _monthsBack; i++) _shift(_thisMonth, -i)],
        selected: _month,
      ),
    );
    if (picked != null) _goTo(picked);
  }

  Widget _insight(MonthlyMetrics metrics) {
    if (!metrics.hasRecords) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            '이번 달 사용 기록이 없어요.',
            style: pretendard(13, FontWeight.w400, AppColors.textSub),
          ),
        ),
      );
    }

    final avg = metrics.averageWear;
    var turns = 0.0;
    String compare;
    if (!_previous.hasRecords) {
      compare = '이전 달 기록이 없어요';
    } else {
      final diff = avg - _previous.averageWear;
      if (diff.inMinutes > 0) {
        compare = '이전 달보다 ${formatDuration(diff)} 증가';
      } else if (diff.inMinutes < 0) {
        compare = '이전 달보다 ${formatDuration(-diff)} 감소';
        turns = 1;
      } else {
        compare = '이전 달과 같아요';
      }
    }

    return InsightCard(
      icon: 'arrow',
      iconTurns: turns,
      iconOffset: const Offset(16, 17),
      titleTop: 17,
      title: '${_monthName()} 평균 착용 ${formatDuration(avg)}',
      body: '기록된 ${metrics.recordedDays}일 기준 · $compare',
    );
  }

  String _monthName() => _isThisMonth ? '이번 달' : '${_month.month}월';

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final metrics = _shown;
    final elapsed = _isThisMonth ? _today.day : metrics.daysInMonth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 43),
        HeadlineCard(
          label: '${_monthName()} 착용 시간',
          wear: metrics.totalWear,
          overflex: metrics.overflexCount,
          maxOver: metrics.maxOverAngle,
          goalPercent: metrics.goalPercent(elapsed),
        ),
        const SizedBox(height: 43),
        MonthCalendar(
          month: _month,
          today: _today,
          selected: selected,
          hasRecord: (day) => metrics.recordOn(day) != null,
          onSelect: _select,
          onPrevious: _month.isAfter(_earliest)
              ? () => _goTo(_shift(_month, -1))
              : null,
          onNext: _isThisMonth ? null : () => _goTo(_shift(_month, 1)),
          onPickMonth: _pickMonth,
        ),
        if (selected != null) ...[
          const SizedBox(height: 22),
          DaySummaryCard(
            date: selected,
            wear: metrics.recordOn(selected.day)?.wear ?? Duration.zero,
            overflex: metrics.recordOn(selected.day)?.overflexCount ?? 0,
          ),
          const SizedBox(height: 21),
          Stack(
            key: _recordKey,
            children: [
              JournalRecordCard(
                date: selected,
                entry: _journalFor(selected),
                onEdit: _startEditing,
              ),
              // Same toast as the home screen's journal save.
              Positioned(
                left: 9,
                right: 9,
                bottom: 0,
                child: Center(
                  child: AppToast(
                    key: _toastKey,
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ),
            ],
          ),
          if (_editing) ...[
            const SizedBox(height: 27),
            KeyedSubtree(
              key: _formKey,
              child: JournalEditForm(
                key: ValueKey(selected),
                date: selected,
                initial: _journalFor(selected),
                onCancel: () => setState(() => _editing = false),
                onSave: (entry) => _save(selected, entry),
              ),
            ),
          ],
        ],
        SizedBox(height: selected == null ? 22 : 18),
        _insight(metrics),
      ],
    );
  }
}

class _MonthPickerSheet extends StatelessWidget {
  const _MonthPickerSheet({required this.months, required this.selected});

  final List<DateTime> months;
  final DateTime selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
              child: Text(
                '월 선택',
                style: pretendard(17, FontWeight.w600, AppColors.text),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                children: [
                  for (final m in months) _option(context, m, m == selected),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _option(BuildContext context, DateTime month, bool isSelected) {
    final label = '${month.year}년 ${month.month}월';
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(month),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primarySoft : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: pretendard(
              15,
              isSelected ? FontWeight.w600 : FontWeight.w400,
              isSelected ? AppColors.primary : AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:gupsin/models/monthly.dart';
import 'package:gupsin/models/today_metrics.dart';
import 'package:gupsin/models/weekly.dart';
import 'package:gupsin/services/metrics_source.dart';

/// Test-only data. The app itself ships with no sample numbers.
const sampleToday = TodayMetrics(
  jointAngle: 60,
  wearTime: Duration(hours: 2, minutes: 36),
  wearGoal: Duration(hours: 4),
  overflexCount: 7,
  overflexChangeFromYesterday: -2,
  maxOverAngle: 8,
  hourlyOverflex: [0, 1, 0, 4, 1, 1],
);

const sampleWeek = WeeklyMetrics(
  dailyWear: [
    Duration(hours: 2, minutes: 36),
    Duration(hours: 3, minutes: 12),
    Duration(hours: 3, minutes: 9),
    Duration(hours: 3, minutes: 36),
    Duration(hours: 2, minutes: 52),
    Duration(hours: 3, minutes: 50),
    Duration(hours: 3, minutes: 9),
  ],
  overflexCount: 31,
  wearGoalPerDay: Duration(hours: 4),
  maxOverAngle: 16,
  lastWeekAverageWear: Duration(hours: 2, minutes: 48),
  lastWeekOverflex: 39,
);

const _sampleDays = {
  2: DayRecord(
    wear: Duration(minutes: 200),
    overflexCount: 6,
    maxOverAngle: 12,
  ),
  4: DayRecord(wear: Duration(minutes: 175), overflexCount: 4, maxOverAngle: 9),
  7: DayRecord(
    wear: Duration(minutes: 190),
    overflexCount: 5,
    maxOverAngle: 14,
  ),
  9: DayRecord(
    wear: Duration(minutes: 210),
    overflexCount: 7,
    maxOverAngle: 17,
  ),
  11: DayRecord(
    wear: Duration(minutes: 165),
    overflexCount: 3,
    maxOverAngle: 6,
  ),
  14: DayRecord(
    wear: Duration(minutes: 185),
    overflexCount: 6,
    maxOverAngle: 11,
  ),
  15: DayRecord(
    wear: Duration(minutes: 205),
    overflexCount: 5,
    maxOverAngle: 10,
  ),
  17: DayRecord(
    wear: Duration(minutes: 156),
    overflexCount: 7,
    maxOverAngle: 8,
  ),
  18: DayRecord(
    wear: Duration(minutes: 220),
    overflexCount: 8,
    maxOverAngle: 28,
  ),
  21: DayRecord(
    wear: Duration(minutes: 180),
    overflexCount: 4,
    maxOverAngle: 9,
  ),
  22: DayRecord(
    wear: Duration(minutes: 195),
    overflexCount: 5,
    maxOverAngle: 13,
  ),
  24: DayRecord(
    wear: Duration(minutes: 170),
    overflexCount: 3,
    maxOverAngle: 7,
  ),
  27: DayRecord(
    wear: Duration(minutes: 193),
    overflexCount: 5,
    maxOverAngle: 15,
  ),
};

/// The same 13 days in every month, up to [until]. Wear shifts by month so
/// month-over-month comparisons differ (August is 21 minutes lower per day
/// than September 2026).
MonthlyMetrics sampleMonth(int year, int month, {DateTime? until}) {
  final shift = Duration(minutes: ((year * 12 + month) % 4 - 1) * 21);
  final last = DateTime(year, month + 1, 0).day;
  return MonthlyMetrics(
    year: year,
    month: month,
    wearGoalPerDay: const Duration(hours: 4),
    days: {
      for (final MapEntry(key: day, value: r) in _sampleDays.entries)
        if (day <= last &&
            (until == null || !DateTime(year, month, day).isAfter(until)))
          day: DayRecord(
            wear: r.wear + shift,
            overflexCount: r.overflexCount,
            maxOverAngle: r.maxOverAngle,
          ),
    },
  );
}

/// Answers synchronously so a single pump shows the data.
class FixtureMetricsSource implements MetricsSource {
  const FixtureMetricsSource({
    this.todayMetrics = sampleToday,
    this.weekMetrics = sampleWeek,
    this.monthMetrics,
  });

  final TodayMetrics todayMetrics;
  final WeeklyMetrics weekMetrics;
  final MonthlyMetrics Function(int year, int month)? monthMetrics;

  @override
  Future<TodayMetrics> today(DateTime day) => SynchronousFuture(todayMetrics);

  @override
  Future<WeeklyMetrics> week(DateTime monday) => SynchronousFuture(weekMetrics);

  @override
  Future<MonthlyMetrics> month(int year, int month) => SynchronousFuture(
    monthMetrics?.call(year, month) ?? MonthlyMetrics.empty(year, month),
  );
}

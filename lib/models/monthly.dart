import 'today_metrics.dart';

class DayRecord {
  const DayRecord({
    required this.wear,
    this.overflexCount = 0,
    this.maxOverAngle,
  });

  final Duration wear;
  final int overflexCount;
  final int? maxOverAngle;

  bool get hasRecord => wear > Duration.zero || overflexCount > 0;
}

class MonthlyMetrics {
  const MonthlyMetrics({
    required this.year,
    required this.month,
    required this.days,
    required this.wearGoalPerDay,
  });

  /// Nothing recorded yet. Shown until real data arrives.
  const MonthlyMetrics.empty(this.year, this.month)
    : days = const {},
      wearGoalPerDay = defaultWearGoal;

  final int year;
  final int month;

  /// Day of month (1-based) → that day's record.
  final Map<int, DayRecord> days;
  final Duration wearGoalPerDay;

  int get daysInMonth => DateTime(year, month + 1, 0).day;

  DayRecord? recordOn(int day) {
    final r = days[day];
    return r != null && r.hasRecord ? r : null;
  }

  Iterable<DayRecord> get _recorded => days.values.where((r) => r.hasRecord);

  int get recordedDays => _recorded.length;

  bool get hasRecords => recordedDays > 0;

  Duration get totalWear =>
      _recorded.fold(Duration.zero, (sum, r) => sum + r.wear);

  int get overflexCount => _recorded.fold(0, (sum, r) => sum + r.overflexCount);

  int? get maxOverAngle {
    int? max;
    for (final r in _recorded) {
      final a = r.maxOverAngle;
      if (a != null && (max == null || a > max)) max = a;
    }
    return max;
  }

  /// Average over the days that have a record.
  Duration get averageWear => recordedDays == 0
      ? Duration.zero
      : Duration(minutes: (totalWear.inMinutes / recordedDays).round());

  /// Progress toward the daily goal summed over [dayCount] days.
  int goalPercent(int dayCount) {
    final goal = wearGoalPerDay.inMinutes * dayCount;
    return goal == 0 ? 0 : (totalWear.inMinutes * 100 / goal).round();
  }
}

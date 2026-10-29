import 'today_metrics.dart';

class WeeklyMetrics {
  const WeeklyMetrics({
    required this.dailyWear,
    required this.overflexCount,
    required this.wearGoalPerDay,
    this.maxOverAngle,
    this.lastWeekAverageWear,
    this.lastWeekOverflex,
  });

  static const dayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  final List<Duration> dailyWear;
  final int overflexCount;
  final Duration wearGoalPerDay;
  final int? maxOverAngle;
  final Duration? lastWeekAverageWear;
  final int? lastWeekOverflex;

  bool get hasRecords =>
      dailyWear.any((duration) => duration > Duration.zero) ||
      overflexCount > 0;

  Duration get totalWear => dailyWear.fold(Duration.zero, (sum, d) => sum + d);

  Duration get averageWear => dailyWear.isEmpty
      ? Duration.zero
      : Duration(minutes: (totalWear.inMinutes / dailyWear.length).round());

  int get goalPercent {
    final goal = wearGoalPerDay.inMinutes * 7;
    return goal == 0 ? 0 : (totalWear.inMinutes * 100 / goal).round();
  }

  /// Nothing recorded yet. Shown until real data arrives.
  static const empty = WeeklyMetrics(
    dailyWear: [],
    overflexCount: 0,
    wearGoalPerDay: defaultWearGoal,
  );
}

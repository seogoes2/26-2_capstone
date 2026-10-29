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

  Duration get totalWear => dailyWear.fold(Duration.zero, (sum, d) => sum + d);

  Duration get averageWear => dailyWear.isEmpty
      ? Duration.zero
      : Duration(minutes: (totalWear.inMinutes / dailyWear.length).round());

  int get goalPercent {
    final goal = wearGoalPerDay.inMinutes * 7;
    return goal == 0 ? 0 : (totalWear.inMinutes * 100 / goal).round();
  }

  static const sample = WeeklyMetrics(
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
}

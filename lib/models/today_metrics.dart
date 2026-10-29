class TodayMetrics {
  const TodayMetrics({
    required this.jointAngle,
    this.romMin = 0,
    this.romMax = 90,
    required this.wearTime,
    required this.wearGoal,
    required this.overflexCount,
    this.overflexChangeFromYesterday,
  });

  final int? jointAngle;

  final int romMin;
  final int romMax;

  final Duration wearTime;
  final Duration wearGoal;

  final int overflexCount;

  final int? overflexChangeFromYesterday;

  bool get isWithinRom =>
      jointAngle != null && jointAngle! >= romMin && jointAngle! <= romMax;

  int get wearGoalPercent => wearGoal.inMinutes == 0
      ? 0
      : (wearTime.inMinutes * 100 / wearGoal.inMinutes).round();

  static const sample = TodayMetrics(
    jointAngle: 60,
    wearTime: Duration(hours: 2, minutes: 36),
    wearGoal: Duration(hours: 4),
    overflexCount: 7,
    overflexChangeFromYesterday: -2,
  );
}

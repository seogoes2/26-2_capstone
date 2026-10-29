class TodayMetrics {
  const TodayMetrics({
    required this.jointAngle,
    this.romMin = 0,
    this.romMax = 90,
    required this.wearTime,
    required this.wearGoal,
    required this.overflexCount,
    this.overflexChangeFromYesterday,
    this.maxOverAngle,
    this.hourlyOverflex = const [],
  });

  final int? jointAngle;

  final int romMin;
  final int romMax;

  final Duration wearTime;
  final Duration wearGoal;

  final int overflexCount;

  final int? overflexChangeFromYesterday;

  final int? maxOverAngle;

  final List<int> hourlyOverflex;

  static const hourlyLabels = ['06', '09', '12', '15', '18', '21'];

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
    maxOverAngle: 8,
    hourlyOverflex: [0, 1, 0, 4, 1, 1],
  );
}

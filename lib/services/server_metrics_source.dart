import '../models/monthly.dart';
import '../models/today_metrics.dart';
import '../models/weekly.dart';
import 'api_client.dart';
import 'metrics_source.dart';
import 'server_api.dart';

/// Reads usage numbers from the backend.
///
/// Weekly and monthly views are built from the per-day range endpoint, and
/// comparisons (yesterday, last week) are computed here, so the server only
/// has to store per-day summaries.
class ServerMetricsSource implements MetricsSource {
  ServerMetricsSource(this._api, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final ApiClient _api;
  final DateTime Function() _now;

  @override
  Future<TodayMetrics> today(DateTime day) async {
    final t = ServerApi.today(await _summary(day));
    final yesterday = await _summary(_addDays(day, -1));
    final change = yesterday == null
        ? null
        : t.overflexCount - ServerApi.today(yesterday).overflexCount;
    return TodayMetrics(
      jointAngle: t.jointAngle,
      romMin: t.romMin,
      romMax: t.romMax,
      wearTime: t.wearTime,
      wearGoal: t.wearGoal,
      overflexCount: t.overflexCount,
      overflexChangeFromYesterday: change,
      maxOverAngle: t.maxOverAngle,
      hourlyOverflex: t.hourlyOverflex,
    );
  }

  @override
  Future<WeeklyMetrics> week(DateTime monday) async {
    final lastMonday = _addDays(monday, -7);
    final records = await _range(lastMonday, _addDays(monday, 6));

    // Stop at today so the chart doesn't drop to zero for days to come.
    final today = _dateOnly(_now());
    final thisWeek = [
      for (var i = 0; i < 7; i++)
        if (!_addDays(monday, i).isAfter(today)) records[_addDays(monday, i)],
    ];
    final lastWeek = [
      for (var i = 0; i < 7; i++) records[_addDays(lastMonday, i)],
    ].nonNulls.where((r) => r.hasRecord).toList();

    int? maxOver;
    for (final a in thisWeek.map((r) => r?.maxOverAngle).nonNulls) {
      if (maxOver == null || a > maxOver) maxOver = a;
    }

    return WeeklyMetrics(
      dailyWear: [for (final r in thisWeek) r?.wear ?? Duration.zero],
      overflexCount: thisWeek.fold(0, (s, r) => s + (r?.overflexCount ?? 0)),
      wearGoalPerDay: defaultWearGoal,
      maxOverAngle: maxOver,
      lastWeekAverageWear: lastWeek.isEmpty
          ? null
          : Duration(
              minutes: (lastWeek.fold(0, (s, r) => s + r.wear.inMinutes) / 7)
                  .round(),
            ),
      lastWeekOverflex: lastWeek.isEmpty
          ? null
          : lastWeek.fold<int>(0, (s, r) => s + r.overflexCount),
    );
  }

  @override
  Future<MonthlyMetrics> month(int year, int month) async {
    final records = await _range(
      DateTime(year, month),
      DateTime(year, month + 1, 0),
    );
    return MonthlyMetrics(
      year: year,
      month: month,
      wearGoalPerDay: defaultWearGoal,
      days: {
        for (final MapEntry(key: date, value: r) in records.entries)
          if (date.year == year && date.month == month) date.day: r,
      },
    );
  }

  /// One day's summary, or null when the server has nothing for that day.
  Future<Object?> _summary(DateTime day) async {
    try {
      return await _api.get(
        ServerApi.dailySummary,
        query: ServerApi.dayQuery(day),
      );
    } on ApiException catch (e) {
      if (e.notFound) return null;
      rethrow;
    }
  }

  Future<Map<DateTime, DayRecord>> _range(DateTime start, DateTime end) async =>
      ServerApi.days(
        await _api.get(
          ServerApi.dailyRange,
          query: ServerApi.rangeQuery(start, end),
        ),
      );

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _addDays(DateTime d, int days) =>
      DateTime(d.year, d.month, d.day + days);
}

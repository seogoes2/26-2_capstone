import '../models/monthly.dart';
import '../models/today_metrics.dart';
import '../models/weekly.dart';
import 'backend_session.dart';
import 'metrics_source.dart';
import 'server_api.dart';

/// Reads usage numbers from the backend's `/dashboard/*` endpoints.
///
/// The server aggregates on every call, so new sensor readings show up the
/// next time a screen loads or is pulled to refresh.
class ServerMetricsSource implements MetricsSource {
  ServerMetricsSource(this._session, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final BackendSession _session;
  final DateTime Function() _now;

  DateTime get _today => _dateOnly(_now());

  @override
  Future<TodayMetrics> today(DateTime day) async {
    final api = _session.api;
    final id = await _session.deviceId();
    final isToday = _dateOnly(day) == _today;
    final (daily, hourly, yesterday, overview) = await (
      api.get(ServerApi.daily, query: ServerApi.dayQuery(id, day)),
      api.get(ServerApi.hourly, query: ServerApi.dayQuery(id, day)),
      api.get(
        ServerApi.daily,
        query: ServerApi.dayQuery(id, _addDays(day, -1)),
      ),
      // Live angle and wear goal only exist for today.
      isToday
          ? api.get(ServerApi.overview, query: {'device_id': id})
          : Future<Object?>.value(),
    ).wait;
    return ServerApi.today(
      daily,
      hourly: hourly,
      overview: overview,
      yesterdayOverflex: ServerApi.overflexOn(yesterday),
    );
  }

  @override
  Future<WeeklyMetrics> week(DateTime monday) async {
    final start = _dateOnly(monday);
    final today = _today;
    if (start.isAfter(today)) return WeeklyMetrics.empty;

    // The server returns the 7 days ending at end_date and refuses future
    // dates, so this week stops at today.
    final sunday = _addDays(start, 6);
    final end = sunday.isAfter(today) ? today : sunday;

    final api = _session.api;
    final id = await _session.deviceId();
    final (thisJson, lastJson) = await (
      api.get(ServerApi.weekly, query: ServerApi.weekQuery(id, end)),
      api.get(
        ServerApi.weekly,
        query: ServerApi.weekQuery(id, _addDays(start, -1)),
      ),
    ).wait;

    final thisDays = ServerApi.days(thisJson);
    final thisWeek = [
      for (var d = start; !d.isAfter(end); d = _addDays(d, 1)) thisDays[d],
    ];
    final lastWeek = ServerApi.days(lastJson).values
        .where((r) => r.hasRecord)
        .toList();

    int? maxOver;
    for (final a in thisWeek.map((r) => r?.maxOverAngle).nonNulls) {
      if (maxOver == null || a > maxOver) maxOver = a;
    }

    return WeeklyMetrics(
      dailyWear: [for (final r in thisWeek) r?.wear ?? Duration.zero],
      overflexCount: thisWeek.fold(0, (s, r) => s + (r?.overflexCount ?? 0)),
      wearGoalPerDay: ServerApi.wearGoal(thisJson),
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
    final today = _today;
    if (DateTime(year, month).isAfter(today)) {
      return MonthlyMetrics.empty(year, month);
    }
    final id = await _session.deviceId();
    final json = await _session.api.get(
      ServerApi.monthly,
      query: ServerApi.monthQuery(id, year, month),
    );
    return MonthlyMetrics(
      year: year,
      month: month,
      wearGoalPerDay: ServerApi.wearGoal(json),
      days: {
        for (final MapEntry(key: date, value: r) in ServerApi.days(
          json,
        ).entries)
          if (date.year == year && date.month == month) date.day: r,
      },
    );
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _addDays(DateTime d, int days) =>
      DateTime(d.year, d.month, d.day + days);
}

import '../models/monthly.dart';
import '../models/today_metrics.dart';
import 'sensor_connection.dart';

/// Everything that depends on the backend's API shape, in one place.
///
/// Matches gubsin_back (FastAPI). See its UI_API.md and
/// http://127.0.0.1:8000/docs. The parsers tolerate missing fields, so a
/// change on the server shows up as an empty value instead of a crash.
abstract final class ServerApi {
  // ── Endpoints ────────────────────────────────────────────────────────────

  static const login = '/auth/login';

  /// The account's devices: `{"devices": [{"device_id": ...}, ...]}`.
  static const devices = '/devices';

  /// Today only: live angle, wear goal, change in overflexion from yesterday.
  /// Query: device_id
  static const overview = '/dashboard/overview';

  /// One day's totals. Query: device_id, target_date=YYYY-MM-DD
  static const daily = '/dashboard/daily';

  /// 24 hourly buckets for one day. Query: device_id, target_date
  static const hourly = '/dashboard/overflexion/hourly';

  /// The 7 days ending at end_date (not in the future).
  /// Query: device_id, end_date
  static const weekly = '/dashboard/weekly';

  /// One calendar month, up to today. Query: device_id, year, month
  static const monthly = '/dashboard/monthly';

  /// The sensor's last contact with the server.
  static String deviceStatus(String deviceId) =>
      '/devices/${Uri.encodeComponent(deviceId)}/status';

  /// ROM and vibration settings. PATCH with query device_id.
  static const romSettings = '/settings/rom';

  static String date(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

  static Map<String, String> dayQuery(String deviceId, DateTime day) => {
    'device_id': deviceId,
    'target_date': date(day),
  };

  static Map<String, String> weekQuery(String deviceId, DateTime end) => {
    'device_id': deviceId,
    'end_date': date(end),
  };

  static Map<String, String> monthQuery(String deviceId, int year, int month) =>
      {'device_id': deviceId, 'year': '$year', 'month': '$month'};

  // ── Responses ────────────────────────────────────────────────────────────

  /// `GET /devices` → the first device's id, or null.
  static String? firstDeviceId(Object? json) {
    final list = _list(json is Map ? json['devices'] : json);
    for (final item in list.map(_map)) {
      final id = item['device_id'];
      if (id is String && id.isNotEmpty) return id;
    }
    return null;
  }

  /// `/dashboard/daily` (+ hourly, + overview for today) → [TodayMetrics].
  static TodayMetrics today(
    Object? daily, {
    Object? hourly,
    Object? overview,
    int? yesterdayOverflex,
  }) {
    final d = _map(daily);
    final o = _map(overview);
    final realtime = _map(o['realtime']);
    final today = _map(o['today']);
    final overflex = _int(d['overflexion_count']) ?? 0;
    final goal = _int(today['target_wear_minutes']);
    return TodayMetrics(
      jointAngle: _int(realtime['angle']),
      wearTime: _minutes(d['wear_minutes']),
      wearGoal: goal == null || goal <= 0
          ? defaultWearGoal
          : Duration(minutes: goal),
      overflexCount: overflex,
      overflexChangeFromYesterday: yesterdayOverflex == null
          ? null
          : overflex - yesterdayOverflex,
      maxOverAngle: _excess(d['max_excess_angle']),
      hourlyOverflex: _hourly(hourlyCounts(hourly)),
    );
  }

  /// `/dashboard/daily` → that day's overflexion count, or null when the
  /// sensor recorded nothing that day.
  static int? overflexOn(Object? daily) {
    final d = _map(daily);
    final readings = _int(d['total_readings']) ?? 0;
    final wear = _num(d['wear_minutes']) ?? 0;
    final overflex = _int(d['overflexion_count']) ?? 0;
    if (readings == 0 && wear == 0 && overflex == 0) return null;
    return overflex;
  }

  /// `/dashboard/overflexion/hourly` → 24 overflexion counts by hour.
  static List<int> hourlyCounts(Object? json) {
    final counts = List.filled(24, 0);
    final items = _list(json is Map ? json['hourly'] : json);
    var seen = false;
    for (final item in items.map(_map)) {
      final hour = _int(item['hour']);
      if (hour == null || hour < 0 || hour > 23) continue;
      counts[hour] = _int(item['overflexion_count']) ?? 0;
      seen = true;
    }
    return seen ? counts : const [];
  }

  /// `/dashboard/weekly` or `/dashboard/monthly` → day records by date.
  static Map<DateTime, DayRecord> days(Object? json) => {
    for (final item in _list(_map(json)['daily']).map(_map))
      // Entries without a readable date are skipped.
      ?_date(item['date']): DayRecord(
        wear: _minutes(item['wear_minutes']),
        overflexCount: _int(item['overflexion_count']) ?? 0,
        maxOverAngle: _excess(item['max_excess_angle']),
      ),
  };

  /// Daily wear goal from a weekly/monthly response.
  static Duration wearGoal(Object? json) {
    final m = _int(_map(json)['target_wear_minutes_per_day']);
    return m == null || m <= 0 ? defaultWearGoal : Duration(minutes: m);
  }

  /// Device status → [SensorStatus], or null when the sensor hasn't talked to
  /// the server lately (the server decides: `is_connected`).
  static SensorStatus? sensorStatus(
    Object? json, {
    required Duration responseTime,
  }) {
    final m = _map(json);
    if (m['is_connected'] != true) return null;
    final id = m['device_id'];
    return SensorStatus(
      name: id is String && id.isNotEmpty ? id : 'GUPSIN_SENSOR',
      batteryPercent: _int(m['battery']),
      responseTime: responseTime,
    );
  }

  // ── Requests ─────────────────────────────────────────────────────────────

  /// App settings ([DeviceSettings.toJson]) → `PATCH /settings/rom` body.
  /// The server derives the vibration start angle (ROM − 5°) itself.
  static Map<String, Object?> settings(Map<String, Object?> app) => {
    if (app['romLimit'] is int) 'limit_angle': app['romLimit'],
    if (app['vibrationSeconds'] is int)
      'vibration_duration_ms': (app['vibrationSeconds'] as int) * 1000,
  };

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String _two(int n) => n.toString().padLeft(2, '0');

  static Map<Object?, Object?> _map(Object? v) => v is Map ? v : const {};

  static List<Object?> _list(Object? v) => v is List ? v : const [];

  static num? _num(Object? v) => v is num ? v : null;

  static int? _int(Object? v) => v is num ? v.round() : null;

  /// The server reports 0 when nothing went over the limit; show that as
  /// "no value" rather than 0°.
  static int? _excess(Object? v) {
    final n = _int(v);
    return n == null || n <= 0 ? null : n;
  }

  static Duration _minutes(Object? v) =>
      v is num ? Duration(minutes: v.round()) : Duration.zero;

  static DateTime? _date(Object? v) {
    final parsed = v is String ? DateTime.tryParse(v) : null;
    return parsed == null
        ? null
        : DateTime(parsed.year, parsed.month, parsed.day);
  }

  /// Six 3-hour buckets starting at 06 (see [TodayMetrics.hourlyLabels]).
  /// Accepts those six counts directly, or 24 hourly counts to bucket here.
  static List<int> _hourly(List<int> counts) {
    final buckets = TodayMetrics.hourlyLabels.length;
    if (counts.length == buckets) return counts;
    if (counts.length != 24) return const [];
    return [
      for (var b = 0; b < buckets; b++)
        counts.skip(6 + b * 3).take(3).fold(0, (sum, c) => sum + c),
    ];
  }
}

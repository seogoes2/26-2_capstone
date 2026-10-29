import '../models/monthly.dart';
import '../models/today_metrics.dart';
import 'sensor_connection.dart';

/// Everything that depends on the backend's API shape, in one place.
///
/// The paths and JSON field names below are placeholders until they are
/// checked against Swagger (http://127.0.0.1:8000/docs). Each spot to confirm
/// is marked `TODO(/docs)`. The parsers tolerate missing or differently named
/// fields, so a wrong guess shows up as an empty value instead of a crash.
abstract final class ServerApi {
  // ── Endpoints ────────────────────────────────────────────────────────────

  // TODO(/docs): one day's summary. Query: date=YYYY-MM-DD
  static const dailySummary = '/metrics/daily';

  // TODO(/docs): per-day summaries for a date range (inclusive).
  // Query: start=YYYY-MM-DD&end=YYYY-MM-DD
  static const dailyRange = '/metrics/days';

  // TODO(/docs): the sensor's latest status as last reported to the server.
  static const deviceStatus = '/device/status';

  // TODO(/docs): settings the sensor picks up from the server.
  static const deviceSettings = '/device/settings';

  static String date(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

  static Map<String, String> dayQuery(DateTime day) => {'date': date(day)};

  static Map<String, String> rangeQuery(DateTime start, DateTime end) => {
    'start': date(start),
    'end': date(end),
  };

  // ── Responses ────────────────────────────────────────────────────────────

  /// One day's summary → [TodayMetrics]. The day-over-day change is filled in
  /// by the caller.
  static TodayMetrics today(Object? json) {
    final m = _map(json);
    return TodayMetrics(
      // TODO(/docs): field names
      jointAngle: _int(m['joint_angle'] ?? m['current_angle']),
      wearTime: _minutes(m['wear_minutes']),
      wearGoal: defaultWearGoal,
      overflexCount: _int(m['overflex_count']) ?? 0,
      maxOverAngle: _int(m['max_over_angle']),
      hourlyOverflex: _hourly(m['hourly_overflex']),
    );
  }

  /// A range of per-day summaries → day records keyed by local date.
  /// Accepts either a bare list or `{"days": [...]}`.
  static Map<DateTime, DayRecord> days(Object? json) {
    final items = json is Map ? _list(json['days'] ?? json['items']) : json;
    return {
      for (final item in _list(items).map(_map))
        // Entries without a readable date are skipped.
        ?_date(item['date']): DayRecord(
          // TODO(/docs): field names
          wear: _minutes(item['wear_minutes']),
          overflexCount: _int(item['overflex_count']) ?? 0,
          maxOverAngle: _int(item['max_over_angle']),
        ),
    };
  }

  /// The sensor counts as disconnected once the server hasn't heard from it
  /// for this long.
  static const offlineAfter = Duration(minutes: 1);

  /// Device status → [SensorStatus], or null when the sensor is offline.
  static SensorStatus? sensorStatus(
    Object? json, {
    required Duration responseTime,
    required DateTime now,
  }) {
    final m = _map(json);
    // TODO(/docs): field names
    final lastSeen = DateTime.tryParse('${m['last_seen'] ?? ''}')?.toLocal();
    if (m['online'] == false ||
        (lastSeen != null && now.difference(lastSeen) > offlineAfter)) {
      return null;
    }
    final name = m['name'] ?? m['device_name'];
    return SensorStatus(
      name: name is String && name.isNotEmpty ? name : 'GUPSIN_SENSOR',
      batteryPercent: _int(m['battery']),
      rssi: _int(m['rssi']),
      todayRecords: _int(m['today_records']),
      responseTime: responseTime,
    );
  }

  // ── Requests ─────────────────────────────────────────────────────────────

  /// App settings ([DeviceSettings.toJson]) → request body.
  static Map<String, Object?> settings(Map<String, Object?> app) => {
    // TODO(/docs): field names
    'rom_limit': app['romLimit'],
    'vibration_start_angle': app['vibrationStartAngle'],
    'vibration_seconds': app['vibrationSeconds'],
  };

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String _two(int n) => n.toString().padLeft(2, '0');

  static Map<Object?, Object?> _map(Object? v) => v is Map ? v : const {};

  static List<Object?> _list(Object? v) => v is List ? v : const [];

  static int? _int(Object? v) => v is num ? v.round() : null;

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
  static List<int> _hourly(Object? v) {
    final counts = [for (final c in _list(v)) _int(c) ?? 0];
    final buckets = TodayMetrics.hourlyLabels.length;
    if (counts.length == buckets) return counts;
    if (counts.length != 24) return const [];
    return [
      for (var b = 0; b < buckets; b++)
        counts.skip(6 + b * 3).take(3).fold(0, (sum, c) => sum + c),
    ];
  }
}

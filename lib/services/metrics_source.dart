import '../models/monthly.dart';
import '../models/today_metrics.dart';
import '../models/weekly.dart';

/// Supplies the usage numbers shown on the home and report screens.
///
/// Screens depend only on this interface, so a server- or sensor-backed
/// implementation can be plugged in from `main.dart` without touching the UI.
/// Dates are local calendar dates (time of day is zero).
abstract interface class MetricsSource {
  /// Today's numbers, including the latest joint angle.
  Future<TodayMetrics> today(DateTime day);

  /// The Monday–Sunday week starting at [monday], with last week's figures
  /// filled in for comparison.
  Future<WeeklyMetrics> week(DateTime monday);

  /// Per-day records for one calendar month.
  Future<MonthlyMetrics> month(int year, int month);
}

/// Used until a real source is connected: every screen shows its empty state.
class EmptyMetricsSource implements MetricsSource {
  const EmptyMetricsSource();

  @override
  Future<TodayMetrics> today(DateTime day) async => TodayMetrics.empty;

  @override
  Future<WeeklyMetrics> week(DateTime monday) async => WeeklyMetrics.empty;

  @override
  Future<MonthlyMetrics> month(int year, int month) async =>
      MonthlyMetrics.empty(year, month);
}

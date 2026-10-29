import 'package:flutter/foundation.dart';

import '../models/alert.dart';
import 'app_storage.dart';

class AlertCenter extends ChangeNotifier {
  AlertCenter(this._storage) : _alerts = _storage.alerts;

  static const maxCount = 50;

  final AppStorage _storage;
  final List<AppAlert> _alerts;

  List<AppAlert> get alerts => List.unmodifiable(_alerts);

  bool get wearReminderOn => _storage.wearReminderOn;

  bool get overuseOn => _storage.overuseAlertOn;

  bool isEnabled(AlertKind kind) => switch (kind) {
    AlertKind.wear => wearReminderOn,
    AlertKind.overuse => overuseOn,
    AlertKind.goal => true,
  };

  Future<void> setWearReminder(bool on) async {
    await _storage.setWearReminder(on);
    notifyListeners();
  }

  Future<void> setOveruse(bool on) async {
    await _storage.setOveruseAlert(on);
    notifyListeners();
  }

  Future<bool> add(AppAlert alert) async {
    if (!isEnabled(alert.kind)) return false;
    _alerts
      ..add(alert)
      ..sort((a, b) => b.time.compareTo(a.time));
    if (_alerts.length > maxCount) {
      _alerts.removeRange(maxCount, _alerts.length);
    }
    await _storage.saveAlerts(_alerts);
    notifyListeners();
    return true;
  }

  Future<void> addSamplesIfEmpty(DateTime now) async {
    if (_alerts.isNotEmpty) return;
    final today = DateTime(now.year, now.month, now.day);
    await add(
      AppAlert.overuse(
        count: 7,
        limitAngle: 45,
        maxOver: 8,
        time: now.subtract(const Duration(minutes: 20)),
      ),
    );
    await add(
      AppAlert.wear(
        hours: 2,
        time: today
            .subtract(const Duration(days: 1))
            .add(const Duration(hours: 18)),
      ),
    );
    await add(
      AppAlert.goal(
        left: const Duration(hours: 1, minutes: 24),
        time: today
            .subtract(const Duration(days: 15))
            .add(const Duration(hours: 11, minutes: 32)),
      ),
    );
  }
}

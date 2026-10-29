import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/alert.dart';
import '../models/hand.dart';
import '../models/journal_entry.dart';
import '../models/settings.dart';

class AppStorage {
  AppStorage._(this._prefs);

  final SharedPreferences _prefs;

  static Future<AppStorage> load() async =>
      AppStorage._(await SharedPreferences.getInstance());

  static const _kOnboardingDone = 'onboarding_done';
  static const _kHand = 'profile_hand';
  static const _kFinger = 'profile_finger';
  static const _kWearReminder = 'alert_wear';
  static const _kOveruse = 'alert_overuse';
  static const _kAlerts = 'alerts';
  static const _kRomLimit = 'rom_limit';
  static const _kVibration = 'vibration_seconds';

  bool get onboardingDone => _prefs.getBool(_kOnboardingDone) ?? false;

  Future<void> markOnboardingDone() => _prefs.setBool(_kOnboardingDone, true);

  Hand? get hand {
    final name = _prefs.getString(_kHand);
    for (final h in Hand.values) {
      if (h.name == name) return h;
    }
    return null;
  }

  int? get finger => _prefs.getInt(_kFinger);

  Future<void> saveProfile({required Hand hand, required int finger}) async {
    await _prefs.setString(_kHand, hand.name);
    await _prefs.setInt(_kFinger, finger);
  }

  JournalEntry journalFor(DateTime day) {
    final raw = _prefs.getString(_journalKey(day));
    if (raw == null) return JournalEntry.empty;
    try {
      return JournalEntry.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on FormatException {
      return JournalEntry.empty;
    }
  }

  Future<void> saveJournal(DateTime day, JournalEntry entry) =>
      _prefs.setString(_journalKey(day), jsonEncode(entry.toJson()));

  bool get wearReminderOn => _prefs.getBool(_kWearReminder) ?? true;

  Future<void> setWearReminder(bool on) => _prefs.setBool(_kWearReminder, on);

  bool get overuseAlertOn => _prefs.getBool(_kOveruse) ?? true;

  Future<void> setOveruseAlert(bool on) => _prefs.setBool(_kOveruse, on);

  List<AppAlert> get alerts {
    final raw = _prefs.getString(_kAlerts);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return [];
      return [for (final item in list) ?AppAlert.fromJson(item)];
    } on FormatException {
      return [];
    }
  }

  Future<void> saveAlerts(List<AppAlert> alerts) => _prefs.setString(
    _kAlerts,
    jsonEncode([for (final a in alerts) a.toJson()]),
  );

  DeviceSettings get settings {
    const fallback = DeviceSettings();
    final rom = _prefs.getInt(_kRomLimit);
    final vib = _prefs.getInt(_kVibration);
    return DeviceSettings(
      romLimit: DeviceSettings.romOptions.contains(rom)
          ? rom!
          : fallback.romLimit,
      vibrationSeconds: DeviceSettings.vibrationOptions.contains(vib)
          ? vib!
          : fallback.vibrationSeconds,
    );
  }

  Future<void> saveSettings(DeviceSettings settings) async {
    await _prefs.setInt(_kRomLimit, settings.romLimit);
    await _prefs.setInt(_kVibration, settings.vibrationSeconds);
  }

  static String _journalKey(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'journal_${d.year}-${two(d.month)}-${two(d.day)}';
  }
}

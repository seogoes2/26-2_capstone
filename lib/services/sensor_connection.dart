import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

@immutable
class SensorStatus {
  const SensorStatus({
    required this.name,
    this.batteryPercent,
    this.rssi,
    this.todayRecords,
    this.responseTime = Duration.zero,
  });

  final String name;
  final int? batteryPercent;

  final int? rssi;

  final int? todayRecords;

  final Duration responseTime;

  factory SensorStatus.fromJson(
    Map<String, Object?> json,
    Duration responseTime,
  ) {
    int? asInt(Object? v) => v is num ? v.round() : null;
    final name = json['name'];
    return SensorStatus(
      name: name is String && name.isNotEmpty ? name : 'GUPSIN_SENSOR',
      batteryPercent: asInt(json['battery']),
      rssi: asInt(json['rssi']),
      todayRecords: asInt(json['todayRecords']),
      responseTime: responseTime,
    );
  }

  String get signalLabel {
    final r = rssi;
    if (r != null) {
      if (r >= -67) return '신호 원활';
      if (r >= -80) return '신호 보통';
      return '신호 약함';
    }
    return responseTime < const Duration(milliseconds: 500) ? '신호 원활' : '신호 보통';
  }

  String get displayName {
    final match = RegExp(r'(\d+)$').firstMatch(name);
    return match == null ? '굽신굽신 센서' : '굽신굽신 · 센서 ${match.group(1)}';
  }
}

enum ConnectionProblem { wifiOff, sensorUnreachable }

abstract class SensorLink {
  Future<bool> isOnWifi();

  Stream<void> get networkChanges;

  Future<SensorStatus?> fetchStatus();

  Future<bool> sendSettings(Map<String, Object?> settings);
}

class HttpSensorLink implements SensorLink {
  HttpSensorLink({
    this.baseUrl = defaultBaseUrl,
    this.timeout = const Duration(seconds: 3),
    Connectivity? connectivity,
    http.Client? client,
  }) : _connectivity = connectivity ?? Connectivity(),
       _client = client ?? http.Client();

  static const defaultBaseUrl = String.fromEnvironment(
    'DEVICE_BASE_URL',
    defaultValue: 'http://192.168.4.1',
  );

  final String baseUrl;
  final Duration timeout;
  final Connectivity _connectivity;
  final http.Client _client;

  static bool _hasWifi(List<ConnectivityResult> results) =>
      results.contains(ConnectivityResult.wifi) ||
      results.contains(ConnectivityResult.ethernet);

  @override
  Future<bool> isOnWifi() async =>
      _hasWifi(await _connectivity.checkConnectivity());

  @override
  Stream<void> get networkChanges => _connectivity.onConnectivityChanged;

  @override
  Future<SensorStatus?> fetchStatus() async {
    final watch = Stopwatch()..start();
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/status'))
          .timeout(timeout);
      if (res.statusCode != 200) return null;
      return SensorStatus.fromJson(_decodeMap(res.bodyBytes), watch.elapsed);
    } on Exception {
      return null;
    }
  }

  @override
  Future<bool> sendSettings(Map<String, Object?> settings) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$baseUrl/settings'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(settings),
          )
          .timeout(timeout);
      return res.statusCode == 200;
    } on Exception {
      return false;
    }
  }

  static Map<String, Object?> _decodeMap(List<int> bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      return decoded is Map<String, Object?> ? decoded : const {};
    } on FormatException {
      return const {};
    }
  }
}

class MockSensorLink implements SensorLink {
  const MockSensorLink();

  static const sample = SensorStatus(
    name: 'GUPSIN_SENSOR_01',
    batteryPercent: 82,
    rssi: -55,
    todayRecords: 156,
  );

  @override
  Future<bool> isOnWifi() async => true;

  @override
  Stream<void> get networkChanges => const Stream.empty();

  @override
  Future<SensorStatus?> fetchStatus() async => sample;

  @override
  Future<bool> sendSettings(Map<String, Object?> settings) async => true;
}

@immutable
sealed class SensorConnectionState {
  const SensorConnectionState();
}

class ConnectionChecking extends SensorConnectionState {
  const ConnectionChecking();
}

class ConnectionConnected extends SensorConnectionState {
  const ConnectionConnected({
    required this.status,
    required this.lastSync,
    this.syncing = false,
  });

  final SensorStatus status;
  final DateTime lastSync;

  final bool syncing;
}

class ConnectionDisconnected extends SensorConnectionState {
  const ConnectionDisconnected(this.problem);

  final ConnectionProblem problem;
}

class SensorConnection extends ChangeNotifier {
  SensorConnection(
    this._link, {
    this.pollInterval = const Duration(seconds: 5),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  factory SensorConnection.fromEnvironment() {
    const mode = String.fromEnvironment('SENSOR_MODE');
    return SensorConnection(
      mode == 'mock' ? const MockSensorLink() : HttpSensorLink(),
    );
  }

  final SensorLink _link;
  final Duration? pollInterval;
  final DateTime Function() _now;

  SensorConnectionState _state = const ConnectionChecking();
  SensorConnectionState get state => _state;

  StreamSubscription<void>? _networkSub;
  Timer? _poll;
  bool _checking = false;

  void start() {
    _networkSub ??= _link.networkChanges.listen((_) => refresh());
    final interval = pollInterval;
    if (interval != null) {
      _poll ??= Timer.periodic(interval, (_) => refresh());
    }
    refresh();
  }

  Future<void> refresh({bool manual = false}) async {
    if (_checking) return;
    _checking = true;
    final current = _state;
    if (manual && current is ConnectionConnected) {
      _set(
        ConnectionConnected(
          status: current.status,
          lastSync: current.lastSync,
          syncing: true,
        ),
      );
    }
    try {
      if (!await _link.isOnWifi()) {
        _set(const ConnectionDisconnected(ConnectionProblem.wifiOff));
        return;
      }
      final status = await _link.fetchStatus();
      _set(
        status == null
            ? const ConnectionDisconnected(ConnectionProblem.sensorUnreachable)
            : ConnectionConnected(status: status, lastSync: _now()),
      );
    } finally {
      _checking = false;
    }
  }

  Future<bool> sendSettings(Map<String, Object?> settings) async {
    if (_state is! ConnectionConnected) return false;
    return _link.sendSettings(settings);
  }

  void _set(SensorConnectionState next) {
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _networkSub?.cancel();
    _poll?.cancel();
    super.dispose();
  }
}

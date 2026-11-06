import 'dart:async';

import 'package:http/http.dart' as http;

import 'api_client.dart';
import 'app_storage.dart';
import 'server_api.dart';

/// Logs in to the backend and knows which sensor (device) the app reads.
///
/// There is no login screen yet, so the account comes from build flags:
/// ```
/// --dart-define=API_EMAIL=demo@gubsin.example
/// --dart-define=API_PASSWORD=<setup_demo.py가 출력한 비밀번호>
/// --dart-define=API_DEVICE_ID=GUBSIN-DEMO-001   (생략하면 계정의 첫 기기)
/// ```
/// The token is kept in [AppStorage] and renewed automatically on a 401.
class BackendSession {
  BackendSession(
    this._storage, {
    String baseUrl = ApiClient.defaultBaseUrl,
    this.email = _envEmail,
    this.password = _envPassword,
    String deviceId = _envDeviceId,
    http.Client? client,
  }) : _deviceId = deviceId.isEmpty ? null : deviceId {
    api = ApiClient(
      baseUrl: baseUrl,
      token: () => _storage.apiToken,
      onUnauthorized: login,
      client: client,
    );
  }

  static const _envEmail = String.fromEnvironment('API_EMAIL');
  static const _envPassword = String.fromEnvironment('API_PASSWORD');
  static const _envDeviceId = String.fromEnvironment('API_DEVICE_ID');

  final AppStorage _storage;
  final String email;
  final String password;

  late final ApiClient api;

  String? _deviceId;
  Future<bool>? _loggingIn;
  Future<String>? _findingDevice;

  bool get canLogin => email.isNotEmpty && password.isNotEmpty;

  /// Gets a fresh token. Concurrent callers share one login request.
  Future<bool> login() =>
      _loggingIn ??= _login().whenComplete(() => _loggingIn = null);

  Future<bool> _login() async {
    if (!canLogin) return false;
    try {
      final json = await api.post(ServerApi.login, {
        'email': email,
        'password': password,
      }, reauth: false);
      final token = json is Map ? json['access_token'] : null;
      if (token is! String || token.isEmpty) return false;
      await _storage.saveApiToken(token);
      return true;
    } on ApiException {
      return false;
    }
  }

  /// The sensor to read: the build flag, or else the account's first device.
  /// Throws [ApiException] (404) when the account has no device yet.
  Future<String> deviceId() {
    final known = _deviceId;
    if (known != null) return Future.value(known);
    return _findingDevice ??= _firstDevice().whenComplete(
      () => _findingDevice = null,
    );
  }

  Future<String> _firstDevice() async {
    final id = ServerApi.firstDeviceId(await api.get(ServerApi.devices));
    if (id == null) {
      throw const ApiException(404, '계정에 연결된 기기가 없어요.');
    }
    return _deviceId = id;
  }
}

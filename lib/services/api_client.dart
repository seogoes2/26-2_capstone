import 'dart:convert';

import 'package:http/http.dart' as http;

/// A request to the backend failed: no response, a non-2xx status, or a body
/// that isn't JSON.
class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  /// Null when the server never answered (offline, timeout).
  final int? statusCode;
  final String message;

  bool get notFound => statusCode == 404;
  bool get unauthorized => statusCode == 401;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Talks JSON to the FastAPI backend and attaches the Bearer token.
class ApiClient {
  ApiClient({
    this.baseUrl = defaultBaseUrl,
    this.timeout = const Duration(seconds: 5),
    String? Function()? token,
    http.Client? client,
  }) : _token = token ?? _noToken,
       _client = client ?? http.Client();

  /// The simulator reaches the Mac's server at 127.0.0.1 as-is. On a real
  /// iPhone pass the Mac's Wi-Fi IP, and start uvicorn with --host 0.0.0.0:
  /// `--dart-define=API_BASE_URL=http://192.168.0.10:8000`
  static const defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  /// Lets a demo run without a login screen:
  /// `--dart-define=API_TOKEN=<access_token>`
  static const _envToken = String.fromEnvironment('API_TOKEN');

  static String? _noToken() => null;

  final String baseUrl;
  final Duration timeout;
  final String? Function() _token;
  final http.Client _client;

  Future<Object?> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<Object?> post(String path, Object? body) =>
      _send('POST', path, body: body);

  Future<Object?> put(String path, Object? body) =>
      _send('PUT', path, body: body);

  Future<Object?> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path')
        .replace(queryParameters: query?.isEmpty ?? true ? null : query);
    final request = http.Request(method, uri)
      ..headers['Accept'] = 'application/json';

    final token = _token() ?? (_envToken.isEmpty ? null : _envToken);
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final http.Response res;
    try {
      res = await http.Response.fromStream(
        await _client.send(request).timeout(timeout),
      );
    } on Exception catch (e) {
      throw ApiException(null, '$e');
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        res.statusCode,
        utf8.decode(res.bodyBytes, allowMalformed: true),
      );
    }
    if (res.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(res.bodyBytes));
    } on FormatException catch (e) {
      throw ApiException(res.statusCode, 'JSON이 아닌 응답: $e');
    }
  }
}

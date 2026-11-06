import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gupsin/services/api_client.dart';
import 'package:gupsin/services/app_storage.dart';
import 'package:gupsin/services/backend_session.dart';
import 'package:gupsin/services/sensor_connection.dart';
import 'package:gupsin/services/server_api.dart';
import 'package:gupsin/services/server_metrics_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// A fake backend. [handler] returns the JSON body, or an int to answer
  /// with that bare status code.
  ApiClient fakeServer(
    Object? Function(http.Request request) handler, {
    List<http.Request>? log,
    String? token = 'test-token',
  }) => ApiClient(
    baseUrl: 'http://server.test',
    token: () => token,
    client: MockClient((request) async {
      log?.add(request);
      final body = handler(request);
      if (body is int) return http.Response('', body);
      return http.Response.bytes(
        utf8.encode(jsonEncode(body)),
        200,
        headers: {'content-type': 'application/json'},
      );
    }),
  );

  group('ApiClient', () {
    test('Bearer 토큰과 쿼리를 붙여 JSON을 받는다', () async {
      final log = <http.Request>[];
      final api = fakeServer((_) => {'ok': true}, log: log);
      final json = await api.get('/ping', query: {'date': '2026-10-29'});

      expect(json, {'ok': true});
      expect(
        log.single.url.toString(),
        'http://server.test/ping?date=2026-10-29',
      );
      expect(log.single.headers['Authorization'], 'Bearer test-token');
    });

    test('토큰이 없으면 Authorization 헤더를 보내지 않는다', () async {
      final log = <http.Request>[];
      await fakeServer((_) => {}, log: log, token: null).get('/ping');
      expect(log.single.headers.containsKey('Authorization'), isFalse);
    });

    test('실패 응답은 상태 코드와 함께 ApiException으로 바뀐다', () async {
      final api = fakeServer((_) => 401);
      await expectLater(
        api.get('/ping'),
        throwsA(isA<ApiException>().having((e) => e.unauthorized, '401', true)),
      );
    });

    test('서버가 응답하지 않으면 상태 코드 없는 ApiException', () async {
      final api = ApiClient(
        baseUrl: 'http://server.test',
        client: MockClient((_) async => throw http.ClientException('down')),
      );
      await expectLater(
        api.get('/ping'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'code', null)),
      );
    });
  });

  /// A logged-in session on a fake backend, reading device GUBSIN-DEMO-001.
  Future<BackendSession> session(
    Object? Function(http.Request request) handler, {
    List<http.Request>? log,
    String deviceId = 'GUBSIN-DEMO-001',
    Map<String, Object> prefs = const {'api_access_token': 'test-token'},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    return BackendSession(
      await AppStorage.load(),
      baseUrl: 'http://server.test',
      email: 'demo@gubsin.example',
      password: 'pw',
      deviceId: deviceId,
      client: MockClient((request) async {
        log?.add(request);
        final body = handler(request);
        if (body is int) return http.Response('', body);
        return http.Response.bytes(
          utf8.encode(jsonEncode(body)),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  }

  group('로그인·기기', () {
    test('401이면 로그인해서 새 토큰으로 한 번 다시 요청한다', () async {
      final log = <http.Request>[];
      final s = await session((r) {
        if (r.url.path == ServerApi.login) return {'access_token': 'fresh'};
        return r.headers['Authorization'] == 'Bearer fresh' ? {'ok': 1} : 401;
      }, log: log);

      expect(await s.api.get('/ping'), {'ok': 1});
      expect(log.map((r) => r.url.path), ['/ping', ServerApi.login, '/ping']);
      expect(jsonDecode(log[1].body), {
        'email': 'demo@gubsin.example',
        'password': 'pw',
      });
    });

    test('로그인도 실패하면 401을 그대로 던진다', () async {
      final s = await session((_) => 401);
      await expectLater(
        s.api.get('/ping'),
        throwsA(isA<ApiException>().having((e) => e.unauthorized, '401', true)),
      );
    });

    test('기기 ID를 안 주면 계정의 첫 기기를 쓴다', () async {
      final s = await session(
        (_) => {
          'devices': [
            {'device_id': 'GUBSIN-007'},
            {'device_id': 'GUBSIN-008'},
          ],
        },
        deviceId: '',
      );
      expect(await s.deviceId(), 'GUBSIN-007');
    });
  });

  group('센서 상태', () {
    test('서버가 연결됐다고 하면 기기 ID·배터리를 읽는다', () {
      final s = ServerApi.sensorStatus({
        'device_id': 'GUBSIN-DEMO-001',
        'is_connected': true,
        'battery': 40,
      }, responseTime: Duration.zero)!;
      expect(s.displayName, '굽신굽신 · 센서 001');
      expect(s.batteryPercent, 40);
    });

    test('is_connected가 false면 끊긴 것으로 본다', () {
      expect(
        ServerApi.sensorStatus({
          'is_connected': false,
          'battery': 65,
        }, responseTime: Duration.zero),
        isNull,
      );
    });

    test('상태는 기기별 경로, 설정은 PATCH /settings/rom 형식으로 보낸다', () async {
      final down = ServerSensorLink(await session((_) => 500));
      expect(await down.fetchStatus(), isNull);
      expect(await down.sendSettings({'romLimit': 45}), isFalse);

      final log = <http.Request>[];
      final link = ServerSensorLink(
        await session((_) => {'is_connected': true}, log: log),
      );
      expect(await link.fetchStatus(), isNotNull);
      expect(log.last.url.path, '/devices/GUBSIN-DEMO-001/status');

      expect(
        await link.sendSettings({
          'romLimit': 60,
          'vibrationStartAngle': 55,
          'vibrationSeconds': 5,
        }),
        isTrue,
      );
      expect(log.last.method, 'PATCH');
      expect(log.last.url.path, ServerApi.romSettings);
      expect(log.last.url.queryParameters, {'device_id': 'GUBSIN-DEMO-001'});
      expect(jsonDecode(log.last.body), {
        'limit_angle': 60,
        'vibration_duration_ms': 5000,
      });
    });
  });

  group('ServerMetricsSource', () {
    Map<String, Object?> day(
      String date,
      num wear,
      int overflex, [
      num excess = 0,
    ]) => {
      'date': date,
      'wear_minutes': wear,
      'overflexion_count': overflex,
      'max_excess_angle': excess,
      'total_readings': wear > 0 ? 4 : 0,
    };

    test('오늘: 일간·시간대·홈 요약을 합치고 어제와 비교한다', () async {
      final log = <http.Request>[];
      final source = ServerMetricsSource(
        await session((r) {
          final date = r.url.queryParameters['target_date'];
          return switch (r.url.path) {
            ServerApi.daily when date == '2026-11-06' => day(
              '2026-11-06',
              163.0,
              3,
              6.7,
            ),
            ServerApi.daily => day('2026-11-05', 150, 5),
            ServerApi.hourly => {
              'hourly': [
                for (var h = 0; h < 24; h++)
                  {'hour': h, 'overflexion_count': h == 9 || h == 10 ? 1 : 0},
              ],
            },
            ServerApi.overview => {
              'realtime': {'angle': 49.1},
              'today': {'target_wear_minutes': 120},
            },
            _ => 404,
          };
        }, log: log),
        now: () => DateTime(2026, 11, 6, 15),
      );
      final t = await source.today(DateTime(2026, 11, 6));

      expect(t.jointAngle, 49);
      expect(t.wearTime, const Duration(hours: 2, minutes: 43));
      expect(t.wearGoal, const Duration(hours: 2));
      expect(t.overflexCount, 3);
      expect(t.overflexChangeFromYesterday, -2);
      expect(t.maxOverAngle, 7);
      expect(t.hourlyOverflex, [0, 2, 0, 0, 0, 0]);
      expect(
        log.every(
          (r) => r.url.queryParameters['device_id'] == 'GUBSIN-DEMO-001',
        ),
        isTrue,
      );
    });

    test('어제 측정이 하나도 없으면 변화는 비워 두고, 초과 0°는 값 없음', () async {
      final source = ServerMetricsSource(
        await session(
          (r) => r.url.queryParameters['target_date'] == '2026-11-06'
              ? day('2026-11-06', 30, 0)
              : day('2026-11-05', 0, 0),
        ),
        now: () => DateTime(2026, 11, 6, 15),
      );
      final t = await source.today(DateTime(2026, 11, 6));
      expect(t.overflexChangeFromYesterday, isNull);
      expect(t.maxOverAngle, isNull);
      expect(t.hourlyOverflex, isEmpty);
    });

    test('24시간 값은 06시부터 3시간씩 묶는다', () {
      final hourly = {
        'hourly': [
          for (var h = 0; h < 24; h++) {'hour': h, 'overflexion_count': h},
        ],
      };
      // 6+7+8, 9+10+11, ...
      expect(ServerApi.today({}, hourly: hourly).hourlyOverflex, [
        21,
        30,
        39,
        48,
        57,
        66,
      ]);
    });

    test('주간: 이번 주는 오늘까지, 지난주는 지난 일요일 기준으로 받는다', () async {
      final log = <http.Request>[];
      final source = ServerMetricsSource(
        await session((r) {
          final end = r.url.queryParameters['end_date'];
          return switch (end) {
            // The 7 days ending today (Fri) start on last Saturday.
            '2026-11-06' => {
              'target_wear_minutes_per_day': 120,
              'daily': [
                day('2026-10-31', 85, 9),
                day('2026-11-01', 98, 9),
                day('2026-11-02', 120, 2, 9.4),
                day('2026-11-03', 0, 0),
                day('2026-11-04', 200, 4, 14),
                day('2026-11-05', 60, 1, 3),
                day('2026-11-06', 30, 0),
              ],
            },
            '2026-11-01' => {
              'daily': [day('2026-10-26', 180, 10), day('2026-10-28', 240, 5)],
            },
            _ => 404,
          };
        }, log: log),
        now: () => DateTime(2026, 11, 6, 15),
      );
      final w = await source.week(DateTime(2026, 11, 2));

      expect(log.map((r) => r.url.queryParameters['end_date']), [
        '2026-11-06',
        '2026-11-01',
      ]);
      expect(w.dailyWear, const [
        Duration(minutes: 120),
        Duration.zero,
        Duration(minutes: 200),
        Duration(minutes: 60),
        Duration(minutes: 30),
      ]);
      expect(w.overflexCount, 7);
      expect(w.maxOverAngle, 14);
      expect(w.wearGoalPerDay, const Duration(hours: 2));
      expect(w.lastWeekAverageWear, const Duration(minutes: 60));
      expect(w.lastWeekOverflex, 15);
    });

    test('주간·월간: 미래 기간은 서버에 묻지 않고 비운다', () async {
      final log = <http.Request>[];
      final source = ServerMetricsSource(
        await session((_) => 422, log: log),
        now: () => DateTime(2026, 11, 6, 15),
      );
      expect((await source.week(DateTime(2026, 11, 9))).hasRecords, isFalse);
      expect((await source.month(2026, 12)).hasRecords, isFalse);
      expect(log, isEmpty);
    });

    test('월간: 그 달 날짜만 일자별로 담는다', () async {
      final log = <http.Request>[];
      final source = ServerMetricsSource(
        await session(
          (_) => {
            'target_wear_minutes_per_day': 120,
            'daily': [
              day('2026-09-30', 100, 1),
              day('2026-10-02', 150, 3, 12),
              day('2026-10-17', 0, 0),
              'not a day',
            ],
          },
          log: log,
        ),
        now: () => DateTime(2026, 11, 6, 15),
      );
      final m = await source.month(2026, 10);

      expect(log.single.url.path, ServerApi.monthly);
      expect(log.single.url.queryParameters, {
        'device_id': 'GUBSIN-DEMO-001',
        'year': '2026',
        'month': '10',
      });
      expect(m.days.keys, [2, 17]);
      expect(m.recordedDays, 1);
      expect(m.totalWear, const Duration(minutes: 150));
      expect(m.maxOverAngle, 12);
      expect(m.wearGoalPerDay, const Duration(hours: 2));
    });
  });
}

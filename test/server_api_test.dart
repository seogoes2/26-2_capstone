import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gupsin/services/api_client.dart';
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

  group('센서 상태 읽기', () {
    final now = DateTime(2026, 10, 29, 12);

    test('이름·배터리·신호·기록 수를 읽는다', () {
      final s = ServerApi.sensorStatus(
        {
          'name': 'GUPSIN_SENSOR_03',
          'battery': 40,
          'rssi': -85,
          'today_records': 12,
        },
        responseTime: Duration.zero,
        now: now,
      )!;
      expect(s.displayName, '굽신굽신 · 센서 03');
      expect(s.batteryPercent, 40);
      expect(s.signalLabel, '신호 약함');
      expect(s.todayRecords, 12);
    });

    test('값이 없어도 연결된 것으로 본다', () {
      final s = ServerApi.sensorStatus(
        {},
        responseTime: const Duration(milliseconds: 100),
        now: now,
      )!;
      expect(s.displayName, '굽신굽신 센서');
      expect(s.batteryPercent, isNull);
      expect(s.signalLabel, '신호 원활');
    });

    test('서버가 센서 소식을 1분 넘게 못 받았으면 끊긴 것으로 본다', () {
      Object status(Duration ago) => {
        'last_seen': now.subtract(ago).toUtc().toIso8601String(),
      };
      expect(
        ServerApi.sensorStatus(
          status(const Duration(seconds: 30)),
          responseTime: Duration.zero,
          now: now,
        ),
        isNotNull,
      );
      expect(
        ServerApi.sensorStatus(
          status(const Duration(minutes: 2)),
          responseTime: Duration.zero,
          now: now,
        ),
        isNull,
      );
    });

    test('서버에 닿지 않으면 연결 끊김, 설정은 서버 형식으로 보낸다', () async {
      final down = ServerSensorLink(fakeServer((_) => 500));
      expect(await down.fetchStatus(), isNull);
      expect(await down.sendSettings({'romLimit': 45}), isFalse);

      final log = <http.Request>[];
      final link = ServerSensorLink(fakeServer((_) => {}, log: log));
      expect(
        await link.sendSettings({
          'romLimit': 60,
          'vibrationStartAngle': 55,
          'vibrationSeconds': 5,
        }),
        isTrue,
      );
      expect(log.single.method, 'PUT');
      expect(log.single.url.path, ServerApi.deviceSettings);
      expect(jsonDecode(log.single.body), {
        'rom_limit': 60,
        'vibration_start_angle': 55,
        'vibration_seconds': 5,
      });
    });
  });

  group('ServerMetricsSource', () {
    Map<String, Object?> day(String date, int wear, int overflex, [int? max]) =>
        {
          'date': date,
          'wear_minutes': wear,
          'overflex_count': overflex,
          'max_over_angle': max,
        };

    test('오늘 요약과 어제 대비 과굴곡 변화를 만든다', () async {
      final source = ServerMetricsSource(
        fakeServer((r) {
          if (r.url.path != ServerApi.dailySummary) return 404;
          return switch (r.url.queryParameters['date']) {
            '2026-10-29' => {
              'joint_angle': 52,
              'wear_minutes': 156,
              'overflex_count': 7,
              'max_over_angle': 8,
              'hourly_overflex': [0, 1, 0, 4, 1, 1],
            },
            '2026-10-28' => {'overflex_count': 9},
            _ => 404,
          };
        }),
      );
      final t = await source.today(DateTime(2026, 10, 29));
      expect(t.jointAngle, 52);
      expect(t.wearTime, const Duration(hours: 2, minutes: 36));
      expect(t.overflexCount, 7);
      expect(t.overflexChangeFromYesterday, -2);
      expect(t.hourlyOverflex, [0, 1, 0, 4, 1, 1]);
    });

    test('어제 기록이 없으면(404) 변화는 비워 둔다', () async {
      final source = ServerMetricsSource(
        fakeServer(
          (r) => r.url.queryParameters['date'] == '2026-10-29'
              ? {'overflex_count': 3}
              : 404,
        ),
      );
      final t = await source.today(DateTime(2026, 10, 29));
      expect(t.overflexCount, 3);
      expect(t.overflexChangeFromYesterday, isNull);
    });

    test('24시간 값은 06시부터 3시간씩 묶는다', () {
      final hours = List.generate(24, (h) => h);
      // 6+7+8, 9+10+11, ...
      expect(ServerApi.today({'hourly_overflex': hours}).hourlyOverflex, [
        21,
        30,
        39,
        48,
        57,
        66,
      ]);
    });

    test('주간: 오늘까지만 담고 지난주 평균과 비교한다', () async {
      final log = <http.Request>[];
      final source = ServerMetricsSource(
        fakeServer(
          (_) => {
            'days': [
              // Last week: 7 h in total over two days.
              day('2026-10-20', 180, 10),
              day('2026-10-22', 240, 5),
              // This week (Mon 10-26 … today Thu 10-29).
              day('2026-10-26', 120, 2, 9),
              day('2026-10-28', 200, 4, 14),
              day('2026-10-29', 60, 1, 3),
            ],
          },
          log: log,
        ),
        now: () => DateTime(2026, 10, 29, 15),
      );
      final w = await source.week(DateTime(2026, 10, 26));

      expect(log.single.url.queryParameters, {
        'start': '2026-10-19',
        'end': '2026-11-01',
      });
      expect(w.dailyWear, const [
        Duration(minutes: 120),
        Duration.zero,
        Duration(minutes: 200),
        Duration(minutes: 60),
      ]);
      expect(w.overflexCount, 7);
      expect(w.maxOverAngle, 14);
      expect(w.lastWeekAverageWear, const Duration(minutes: 60));
      expect(w.lastWeekOverflex, 15);
    });

    test('월간: 그 달 날짜만 일자별로 담는다', () async {
      final log = <http.Request>[];
      final source = ServerMetricsSource(
        fakeServer(
          (_) => [
            day('2026-09-30', 100, 1),
            day('2026-10-02', 150, 3, 12),
            day('2026-10-17', 0, 0),
            'not a day',
          ],
          log: log,
        ),
      );
      final m = await source.month(2026, 10);

      expect(log.single.url.queryParameters, {
        'start': '2026-10-01',
        'end': '2026-10-31',
      });
      expect(m.days.keys, [2, 17]);
      expect(m.recordedDays, 1);
      expect(m.totalWear, const Duration(minutes: 150));
      expect(m.maxOverAngle, 12);
    });
  });
}

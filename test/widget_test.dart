import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gupsin/main.dart';
import 'package:gupsin/models/alert.dart';
import 'package:gupsin/models/hand.dart';
import 'package:gupsin/models/journal_entry.dart';
import 'package:gupsin/models/today_metrics.dart';
import 'package:gupsin/screens/finger.dart';
import 'package:gupsin/screens/hands.dart';
import 'package:gupsin/screens/home.dart';
import 'package:gupsin/screens/main.dart';
import 'package:gupsin/screens/report.dart';
import 'package:gupsin/screens/settings.dart';
import 'package:gupsin/screens/alerts.dart';
import 'package:gupsin/screens/start.dart';
import 'package:gupsin/services/alerts.dart';
import 'package:gupsin/services/app_storage.dart';
import 'package:gupsin/services/metrics_source.dart';
import 'package:gupsin/services/sensor_connection.dart';
import 'package:gupsin/widgets/app_button.dart';
import 'package:gupsin/widgets/app_toast.dart';
import 'package:gupsin/widgets/calendar.dart';
import 'package:gupsin/widgets/chart.dart';
import 'package:gupsin/widgets/finger_number_button.dart';
import 'package:gupsin/widgets/home/journal_cards.dart';

import 'fixtures.dart';

class FakeSensorLink implements SensorLink {
  bool wifiOn = true;
  SensorStatus? status = MockSensorLink.sample;
  final _changes = StreamController<void>.broadcast();

  void networkChanged() => _changes.add(null);

  @override
  Future<bool> isOnWifi() async => wifiOn;

  @override
  Stream<void> get networkChanges => _changes.stream;

  @override
  Future<SensorStatus?> fetchStatus() async => status;

  final sentSettings = <Map<String, Object?>>[];

  @override
  Future<bool> sendSettings(Map<String, Object?> settings) async {
    sentSettings.add(settings);
    return true;
  }
}

void main() {
  late AppStorage storage;
  late FakeSensorLink link;
  late SensorConnection connection;
  late AlertCenter alerts;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await AppStorage.load();
    alerts = AlertCenter(storage);
    link = FakeSensorLink();
    connection = SensorConnection(link, pollInterval: null);
    addTearDown(connection.dispose);
  });

  void usePhoneSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(402, 874) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Future<void> openApp(
    WidgetTester tester, {
    MetricsSource metrics = const FixtureMetricsSource(),
  }) async {
    usePhoneSize(tester);
    connection.start();
    await tester.pumpWidget(
      GupsinApp(
        storage: storage,
        connection: connection,
        alerts: alerts,
        metrics: metrics,
      ),
    );
  }

  Future<void> openHandSelect(WidgetTester tester) async {
    await openApp(tester);
    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();
  }

  Future<void> openFingerSelect(WidgetTester tester, Hand hand) async {
    await openHandSelect(tester);
    await tester.tap(find.text(hand.label));
    await tester.pump();
    await tester.tap(find.text('다음으로'));
    await tester.pumpAndSettle();
  }

  Future<void> openHome(WidgetTester tester) async {
    await openFingerSelect(tester, Hand.right);
    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.tap(find.text('다음으로'));
    await tester.pumpAndSettle();
  }

  AppButton buttonOf(WidgetTester tester, String label) =>
      tester.widget<AppButton>(find.widgetWithText(AppButton, label));

  FingerNumberButton numberOf(WidgetTester tester, int n) =>
      tester.widget<FingerNumberButton>(
        find.widgetWithText(FingerNumberButton, '$n'),
      );

  bool chipSelected(WidgetTester tester, String label) => tester
      .widget<SelectChip>(find.widgetWithText(SelectChip, label))
      .selected;

  bool toastVisible(WidgetTester tester, String message) {
    final opacity = tester.widget<AnimatedOpacity>(
      find.ancestor(
        of: find.text(message),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    return opacity.opacity == 1;
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).first,
      );

  group('온보딩', () {
    testWidgets('처음 켜면 시작화면이 나온다', (tester) async {
      await openApp(tester);
      expect(find.byType(StartScreen), findsOneWidget);
    });

    testWidgets('손을 고르면 그 버튼만 선택된다', (tester) async {
      await openHandSelect(tester);

      await tester.tap(find.text('왼손'));
      await tester.pump();
      expect(buttonOf(tester, '왼손').selected, isTrue);
      expect(buttonOf(tester, '오른손').selected, isFalse);
    });

    testWidgets('손을 안 고르고 다음으로를 누르면 안내창이 떴다 사라진다', (tester) async {
      await openHandSelect(tester);

      await tester.tap(find.text('다음으로'));
      await tester.pump();
      expect(find.byType(HandSelectScreen), findsOneWidget);
      expect(toastVisible(tester, '손을 선택해 주세요.'), isTrue);

      await tester.pump(AppToast.visibleFor);
      await tester.pumpAndSettle();
      expect(toastVisible(tester, '손을 선택해 주세요.'), isFalse);
    });

    for (final hand in Hand.values) {
      testWidgets('${hand.label} → 손가락 선택(${hand.label})', (tester) async {
        await openFingerSelect(tester, hand);
        final screen = tester.widget<FingerSelectScreen>(
          find.byType(FingerSelectScreen),
        );
        expect(screen.hand, hand);
      });
    }

    testWidgets('손가락은 하나만 고를 수 있고, 다시 누르면 해제된다', (tester) async {
      await openFingerSelect(tester, Hand.left);

      await tester.tap(find.text('2'));
      await tester.pump();
      expect(numberOf(tester, 2).selected, isTrue);

      await tester.tap(find.text('5'));
      await tester.pump();
      expect(numberOf(tester, 5).selected, isTrue);
      expect(numberOf(tester, 2).selected, isFalse);

      await tester.tap(find.text('5'));
      await tester.pump();
      expect(numberOf(tester, 5).selected, isFalse);
    });

    testWidgets('손가락을 안 고르고 다음으로를 누르면 안내창이 떴다 사라진다', (tester) async {
      await openFingerSelect(tester, Hand.left);

      await tester.tap(find.text('다음으로'));
      await tester.pump();
      expect(find.byType(FingerSelectScreen), findsOneWidget);
      expect(toastVisible(tester, '손가락을 선택해 주세요.'), isTrue);

      await tester.pump(AppToast.visibleFor);
      await tester.pumpAndSettle();
      expect(toastVisible(tester, '손가락을 선택해 주세요.'), isFalse);
    });

    testWidgets('이전으로를 누르면 손 방향 선택으로 돌아가고 고른 손이 유지된다', (tester) async {
      await openFingerSelect(tester, Hand.left);

      await tester.tap(find.text('이전으로'));
      await tester.pumpAndSettle();

      expect(find.byType(HandSelectScreen), findsOneWidget);
      expect(buttonOf(tester, '왼손').selected, isTrue);
    });

    testWidgets('손가락까지 고르면 홈으로 가고, 고른 값과 완료 여부가 저장된다', (tester) async {
      await openHome(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(storage.hand, Hand.right);
      expect(storage.finger, 2);
      expect(storage.onboardingDone, isTrue);
    });
  });

  group('다시 켰을 때', () {
    testWidgets('홈에 한 번 들어왔으면 다음엔 바로 홈으로 시작한다', (tester) async {
      await storage.markOnboardingDone();
      await openApp(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(StartScreen), findsNothing);
    });
  });

  group('홈', () {
    testWidgets('데이터 소스가 연결되기 전에는 빈 값만 보인다', (tester) async {
      await storage.markOnboardingDone();
      await openApp(tester, metrics: const EmptyMetricsSource());
      await tester.pumpAndSettle();

      expect(find.text('60°'), findsNothing);
      expect(find.text('0분'), findsOneWidget);
      expect(find.text('0회'), findsOneWidget);
    });

    testWidgets('오늘의 움직임 값이 보인다', (tester) async {
      await openHome(tester);

      expect(find.text('60°'), findsOneWidget);
      expect(find.text('✓ 허용 ROM 안'), findsOneWidget);
      expect(find.text('2시간 36분'), findsOneWidget);
      expect(find.text('목표 4시간의 65%'), findsOneWidget);
      expect(find.text('7회'), findsOneWidget);
      expect(find.text('어제보다 2회 감소'), findsOneWidget);
    });

    testWidgets('손가락 상태는 하나만, 같은 걸 다시 누르면 취소', (tester) async {
      await openHome(tester);
      await scrollTo(tester, find.text('매우 심함'));

      MoodSelector selector() => tester.widget(find.byType(MoodSelector));

      await tester.tap(find.text('보통'));
      await tester.pump();
      expect(selector().selected, Mood.okay);

      await tester.tap(find.text('심함'));
      await tester.pump();
      expect(selector().selected, Mood.bad);

      await tester.tap(find.text('심함'));
      await tester.pump();
      expect(selector().selected, isNull);
    });

    testWidgets('증상·활동은 여러 개 고를 수 있고, 증상 없음은 따로', (tester) async {
      await openHome(tester);
      await scrollTo(
        tester,
        find.text('휴식').evaluate().isEmpty ? find.text('운동') : find.text('휴식'),
      );

      await tester.tap(find.text('통증'));
      await tester.tap(find.text('붓기'));
      await tester.pump();
      expect(chipSelected(tester, '통증'), isTrue);
      expect(chipSelected(tester, '붓기'), isTrue);

      await tester.tap(find.text('없음'));
      await tester.pump();
      expect(chipSelected(tester, '없음'), isTrue);
      expect(chipSelected(tester, '통증'), isFalse);

      await tester.tap(find.text('타이핑'));
      await tester.tap(find.text('운동'));
      await tester.pump();
      expect(chipSelected(tester, '타이핑'), isTrue);
      expect(chipSelected(tester, '운동'), isTrue);
    });

    testWidgets('오늘 기록 저장: 안내창이 떴다 사라지고, 다시 켜도 기록과 메모가 남는다', (tester) async {
      await openHome(tester);
      await scrollTo(tester, find.text('오늘 기록 저장'));

      await tester.tap(find.text('뻣뻣함'));
      await tester.tap(find.text('타이핑'));
      await tester.enterText(find.byType(TextField), '아침에 뻣뻣했음');
      await tester.pump();
      expect(find.text('8 / 1000'), findsOneWidget);

      await tester.tap(find.text('오늘 기록 저장'));
      await tester.pump();
      expect(toastVisible(tester, '저장되었어요.'), isTrue);
      expect(find.text('오늘 기록 저장'), findsOneWidget);

      await tester.pump(AppToast.visibleFor);
      await tester.pumpAndSettle();
      expect(toastVisible(tester, '저장되었어요.'), isFalse);

      final saved = storage.journalFor(DateTime.now());
      expect(saved.symptoms, {Symptom.stiffness});
      expect(saved.activities, {Activity.typing});
      expect(saved.memo, '아침에 뻣뻣했음');

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        GupsinApp(storage: storage, connection: connection, alerts: alerts),
      );
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('오늘 기록 저장'));

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('아침에 뻣뻣했음'), findsOneWidget);
      expect(chipSelected(tester, '뻣뻣함'), isTrue);
      expect(chipSelected(tester, '타이핑'), isTrue);
    });
  });

  group('통신', () {
    Future<void> openConnectionTab(WidgetTester tester) async {
      await storage.markOnboardingDone();
      await openApp(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('통신'));
      await tester.pumpAndSettle();
    }

    testWidgets('센서와 연결되면 연결됨 화면', (tester) async {
      await openConnectionTab(tester);

      expect(find.text('Wi-Fi 연결됨'), findsOneWidget);
      expect(find.text('GUPSIN_SENSOR_01 · 신호 원활'), findsOneWidget);
      expect(find.text('굽신굽신 · 센서 01'), findsOneWidget);
      expect(find.text('배터리 82%'), findsOneWidget);
      expect(find.text('방금 전'), findsOneWidget);
      expect(find.text('156건'), findsOneWidget);
      expect(find.text('최신 상태'), findsOneWidget);
      expect(find.text('지금 동기화'), findsOneWidget);
    });

    testWidgets('휴대폰 Wi-Fi가 꺼지면 바로 연결 끊김 화면', (tester) async {
      await openConnectionTab(tester);

      link.wifiOn = false;
      link.networkChanged();
      await tester.pumpAndSettle();

      expect(find.text('연결 끊김'), findsOneWidget);
      expect(find.text('휴대폰 Wi-Fi가 꺼져 있어요'), findsOneWidget);
      expect(find.text('Wi-Fi 연결을 한 번 더 확인해주세요.'), findsOneWidget);
      expect(find.text('새로고침'), findsOneWidget);
    });

    testWidgets('센서가 응답하지 않으면 연결 끊김, 새로고침으로 다시 연결', (tester) async {
      link.status = null;
      await openConnectionTab(tester);

      expect(find.text('연결 끊김'), findsOneWidget);
      expect(find.text('센서 전원과 Wi-Fi 연결을 한 번 더 확인해주세요.'), findsOneWidget);

      await tester.tap(find.text('새로고침'));
      await tester.pump();
      expect(find.text('확인 중…'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('연결 끊김'), findsOneWidget);
      expect(find.text('새로고침'), findsOneWidget);

      link.status = MockSensorLink.sample;
      await tester.tap(find.text('새로고침'));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.text('Wi-Fi 연결됨'), findsOneWidget);
    });

    testWidgets('탭을 오가도 홈에 쓰던 메모가 남아 있다', (tester) async {
      await storage.markOnboardingDone();
      await openApp(tester);
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('오늘 기록 저장'));
      await tester.enterText(find.byType(TextField), '쓰는 중');

      await tester.tap(find.text('통신'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('홈'));
      await tester.pumpAndSettle();

      expect(find.text('쓰는 중'), findsOneWidget);
    });
  });

  group('센서 응답 읽기', () {
    test('이름·배터리·신호·기록 수를 읽는다', () {
      final s = SensorStatus.fromJson({
        'name': 'GUPSIN_SENSOR_03',
        'battery': 40,
        'rssi': -85,
        'todayRecords': 12,
      }, Duration.zero);
      expect(s.displayName, '굽신굽신 · 센서 03');
      expect(s.batteryPercent, 40);
      expect(s.signalLabel, '신호 약함');
      expect(s.todayRecords, 12);
    });

    test('값이 없어도 연결된 것으로 본다', () {
      final s = SensorStatus.fromJson({}, const Duration(milliseconds: 100));
      expect(s.displayName, '굽신굽신 센서');
      expect(s.batteryPercent, isNull);
      expect(s.signalLabel, '신호 원활');
    });
  });

  group('알림', () {
    Future<void> openAlertsTab(WidgetTester tester) async {
      await storage.markOnboardingDone();
      await openApp(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('알림').last);
      await tester.pumpAndSettle();
    }

    AppSwitch switchOf(WidgetTester tester, String label) =>
        tester.widget<AppSwitch>(
          find.byWidgetPredicate((w) => w is AppSwitch && w.label == label),
        );

    testWidgets('알림이 없으면 빈 화면 문구, 설정은 기본으로 켜져 있다', (tester) async {
      await openAlertsTab(tester);

      expect(find.text('최근 알림 내역이 없어요.'), findsOneWidget);
      expect(switchOf(tester, '착용 권장 알림').value, isTrue);
      expect(switchOf(tester, '과사용 알림').value, isTrue);
    });

    testWidgets('스위치를 끄면 저장되고, 꺼진 종류의 알림은 쌓이지 않는다', (tester) async {
      await openAlertsTab(tester);

      await tester.tap(
        find.byWidgetPredicate((w) => w is AppSwitch && w.label == '과사용 알림'),
      );
      await tester.pumpAndSettle();
      expect(switchOf(tester, '과사용 알림').value, isFalse);
      expect(storage.overuseAlertOn, isFalse);

      final now = DateTime.now();
      await tester.runAsync(() async {
        expect(
          await alerts.add(
            AppAlert.overuse(count: 6, limitAngle: 45, maxOver: 3, time: now),
          ),
          isFalse,
        );
        expect(await alerts.add(AppAlert.wear(hours: 2, time: now)), isTrue);
      });
      await tester.pumpAndSettle();

      expect(find.text('손 사용을 잠시 쉬어주세요'), findsNothing);
      expect(find.text('보조기 착용을 잊지 마세요'), findsOneWidget);
      expect(storage.alerts, hasLength(1));
    });

    testWidgets('최근 알림이 있으면 최신순으로 보인다', (tester) async {
      await tester.runAsync(() => alerts.addSamplesIfEmpty(DateTime.now()));
      await openAlertsTab(tester);

      expect(find.text('손 사용을 잠시 쉬어주세요'), findsOneWidget);
      expect(find.text('최근 1시간 동안 과굴곡 7회'), findsOneWidget);
      expect(find.text('설정 각도 45°보다 최대 8° 초과'), findsOneWidget);
      expect(find.text('보조기 착용을 잊지 마세요'), findsOneWidget);
      expect(find.text('오늘 목표까지 1시간 24분'), findsOneWidget);
      expect(find.text('어제 오후 6:00'), findsOneWidget);

      final first = tester.getTopLeft(find.text('손 사용을 잠시 쉬어주세요')).dy;
      final second = tester.getTopLeft(find.text('보조기 착용을 잊지 마세요')).dy;
      expect(first, lessThan(second));
    });
  });

  group('알림 시간 표시', () {
    final now = DateTime(2026, 10, 29, 17, 0);
    String label(DateTime t) => AppAlert.wear(hours: 2, time: t).timeLabel(now);

    test('오늘 / 어제 / 그 전', () {
      expect(label(DateTime(2026, 10, 29, 15, 40)), '오후 3:40');
      expect(label(DateTime(2026, 10, 29, 0, 5)), '오전 12:05');
      expect(label(DateTime(2026, 10, 28, 18, 0)), '어제 오후 6:00');
      expect(label(DateTime(2026, 9, 14, 11, 32)), '9월 14일 오전 11:32');
    });
  });

  group('설정', () {
    Future<void> openSettingsTab(WidgetTester tester) async {
      await storage.markOnboardingDone();
      await storage.saveProfile(hand: Hand.left, finger: 3);
      await openApp(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('설정').last);
      await tester.pumpAndSettle();
    }

    Finder inSettings(String text) => find.descendant(
      of: find.byType(SettingsScreen),
      matching: find.text(text),
    );

    testWidgets('처음엔 허용 ROM 45°, 진동 시작 40°, 진동 5초', (tester) async {
      await openSettingsTab(tester);

      expect(inSettings('기기 설정'), findsOneWidget);
      expect(inSettings('45°'), findsNWidgets(2));
      expect(inSettings('40°'), findsOneWidget);
      expect(inSettings('5초'), findsNWidgets(2));
    });

    testWidgets('단계를 누르면 값이 바뀌고 저장되며 센서로도 보낸다', (tester) async {
      await openSettingsTab(tester);

      await tester.tap(find.bySemanticsLabel('허용 ROM 60°'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('진동 지속 시간 7초'));
      await tester.pumpAndSettle();

      expect(inSettings('55°'), findsOneWidget);
      expect(storage.settings.romLimit, 60);
      expect(storage.settings.vibrationSeconds, 7);
      expect(link.sentSettings.last, {
        'romLimit': 60,
        'vibrationStartAngle': 55,
        'vibrationSeconds': 7,
      });
    });

    testWidgets('초기 설정 변경: 저장된 손·손가락이 눌린 상태로 다시 고를 수 있다', (tester) async {
      await openSettingsTab(tester);

      await tester.tap(find.text('초기 설정 변경'));
      await tester.pumpAndSettle();
      expect(find.byType(HandSelectScreen), findsOneWidget);
      expect(buttonOf(tester, '왼손').selected, isTrue);

      await tester.tap(find.text('다음으로'));
      await tester.pumpAndSettle();
      expect(numberOf(tester, 3).selected, isTrue);

      await tester.tap(find.text('5'));
      await tester.pump();
      await tester.tap(find.text('다음으로'));
      await tester.pumpAndSettle();

      expect(find.byType(MainShell), findsOneWidget);
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(storage.hand, Hand.left);
      expect(storage.finger, 5);
    });

    testWidgets('초기 설정 변경에서 다른 손을 고르면 손가락은 새로 고른다', (tester) async {
      await openSettingsTab(tester);

      await tester.tap(find.text('초기 설정 변경'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('오른손'));
      await tester.pump();
      await tester.tap(find.text('다음으로'));
      await tester.pumpAndSettle();

      for (var n = 1; n <= 5; n++) {
        expect(numberOf(tester, n).selected, isFalse);
      }
    });

    testWidgets('바로 홈으로 시작해도 뒤에 시작화면이 깔려 있지 않다', (tester) async {
      await storage.markOnboardingDone();
      await openApp(tester);
      await tester.pumpAndSettle();

      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      expect(navigator.canPop(), isFalse);
    });
  });

  group('리포트', () {
    Future<void> openReportTab(WidgetTester tester) async {
      await storage.markOnboardingDone();
      await openApp(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('리포트').last);
      await tester.pumpAndSettle();
    }

    Finder inReport(String text) => find.descendant(
      of: find.byType(ReportScreen),
      matching: find.text(text),
    );

    testWidgets('하루 리포트: 오늘 착용·과굴곡·최대 초과·목표 달성과 시간대별 그래프', (tester) async {
      await openReportTab(tester);

      expect(inReport('사용 리포트'), findsOneWidget);
      expect(inReport('2시간 36분'), findsOneWidget);
      expect(inReport('7회'), findsOneWidget);
      expect(inReport('+8°'), findsOneWidget);
      expect(inReport('65%'), findsOneWidget);
      expect(find.byType(HourlyBarChart), findsOneWidget);
      for (final label in ['06', '09', '12', '15', '18', '21']) {
        expect(inReport(label), findsOneWidget);
      }
      expect(inReport('최대 8°를 초과한 움직임이 있었어요'), findsOneWidget);
      expect(inReport('오후 3시 과굴곡 4회 · 허용 ROM 45° 기준'), findsOneWidget);
    });

    testWidgets('주간 리포트: 이번 주 합계·그래프·변화 분석', (tester) async {
      await openReportTab(tester);

      await tester.tap(inReport('주간'));
      await tester.pumpAndSettle();

      expect(inReport('이번 주 착용 시간'), findsOneWidget);
      expect(inReport('22시간 24분'), findsOneWidget);
      expect(inReport('31회'), findsOneWidget);
      expect(inReport('+16°'), findsOneWidget);
      expect(inReport('80%'), findsOneWidget);
      expect(find.byType(WeeklyLineChart), findsOneWidget);
      for (final d in ['월', '화', '수', '목', '금', '토', '일']) {
        expect(inReport(d), findsOneWidget);
      }
      expect(inReport('하루 평균 3시간 12분 착용했어요'), findsOneWidget);
      expect(inReport('지난주 평균 2시간 48분보다 24분 증가했어요.'), findsOneWidget);
      expect(inReport('과굴곡 횟수는 8회 줄었어요'), findsOneWidget);
      expect(inReport('지난주 39회 → 이번 주 31회'), findsOneWidget);
    });

    testWidgets('주간 그래프의 요일을 누르면 그날 착용 시간이 말풍선으로 보인다', (tester) async {
      await openReportTab(tester);
      await tester.tap(inReport('주간'));
      await tester.pumpAndSettle();

      final chart = find.byType(WeeklyLineChart);
      final box = tester.getRect(chart);
      await tester.tapAt(Offset(box.left + 186, box.top + 100));
      await tester.pump();
      expect(
        find.descendant(of: chart, matching: find.text('3시간 36분')),
        findsOneWidget,
      );
    });

    testWidgets('월간 탭은 달력과 이번 달 합계를 보여준다', (tester) async {
      await openReportTab(tester);
      await tester.tap(inReport('월간'));
      await tester.pumpAndSettle();
      expect(inReport('이번 달 착용 시간'), findsOneWidget);
      expect(find.byType(MonthCalendar), findsOneWidget);
    });

    testWidgets('과굴곡이 없는 날은 분석 대신 빈 문구', (tester) async {
      usePhoneSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: ReportScreen(
            source: FixtureMetricsSource(
              todayMetrics: TodayMetrics(
                jointAngle: 30,
                wearTime: Duration(hours: 1),
                wearGoal: Duration(hours: 4),
                overflexCount: 0,
                hourlyOverflex: [0, 0, 0, 0, 0, 0],
              ),
            ),
          ),
        ),
      );
      expect(find.text('최근 사용 기록이 없어요.'), findsOneWidget);
    });

    test('주간 날짜 범위', () {
      expect(sampleWeek.totalWear, const Duration(hours: 22, minutes: 24));
      expect(sampleWeek.averageWear, const Duration(hours: 3, minutes: 12));
      expect(sampleWeek.goalPercent, 80);
    });
  });
}

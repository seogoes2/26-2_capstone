import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gupsin/models/weekly.dart';
import 'package:gupsin/screens/report.dart';
import 'package:gupsin/widgets/chart.dart';
import 'package:gupsin/widgets/insight.dart';

import 'fixtures.dart';

void main() {
  Future<void> openWeek(
    WidgetTester tester, {
    WeeklyMetrics metrics = sampleWeek,
    DateTime? date,
    double width = 402,
  }) async {
    tester.view.physicalSize = Size(width, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          source: FixtureMetricsSource(weekMetrics: metrics),
          now: () => date ?? DateTime(2026, 9, 17),
        ),
      ),
    );
    await tester.tap(find.text('주간'));
    await tester.pumpAndSettle();
  }

  testWidgets('월을 걸치는 주도 월요일부터 일요일까지 표시한다', (tester) async {
    await openWeek(tester, date: DateTime(2026, 10, 29));
    expect(find.text('10월 26일 – 11월 1일'), findsOneWidget);
    expect(find.text('22시간 24분'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);
  });

  testWidgets('기록이 없는 주는 분석과 선택 말풍선 대신 빈 상태를 보여준다', (tester) async {
    await openWeek(
      tester,
      metrics: const WeeklyMetrics(
        dailyWear: [],
        overflexCount: 0,
        wearGoalPerDay: Duration(hours: 4),
      ),
    );
    expect(find.text('착용 기록이 없어요'), findsOneWidget);
    expect(find.text('최근 사용 기록이 없어요.'), findsOneWidget);
    expect(find.byType(InsightCard), findsNothing);
    await tester.tap(find.byType(WeeklyLineChart));
    await tester.pump();
    expect(tester.takeException(), isNull);
    for (final day in WeeklyMetrics.dayLabels) {
      expect(find.text(day), findsOneWidget);
    }
  });

  testWidgets('하루만 있는 주도 탭할 수 있고 지난주 기록은 따로 안내한다', (tester) async {
    await openWeek(
      tester,
      metrics: const WeeklyMetrics(
        dailyWear: [Duration(hours: 2)],
        overflexCount: 1,
        wearGoalPerDay: Duration(hours: 4),
      ),
    );
    await tester.tap(find.byType(WeeklyLineChart));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('지난주 기록이 없어요.'), findsNWidgets(2));
    expect(
      find.descendant(
        of: find.byType(WeeklyLineChart),
        matching: find.text('2시간'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('그래프를 가로로 움직이면 선택한 날짜의 시간이 바뀐다', (tester) async {
    await openWeek(tester);
    final box = tester.getRect(find.byType(WeeklyLineChart));
    await tester.dragFrom(
      Offset(box.left + 48, box.top + 110),
      const Offset(276, 0),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(WeeklyLineChart),
        matching: find.text('3시간 9분'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('작은 화면에서 변화 설명이 카드 안에서 줄바꿈된다', (tester) async {
    await openWeek(tester, width: 320);
    final body = find.text('지난주 평균 2시간 48분보다 24분 증가했어요.');
    final card = find.ancestor(of: body, matching: find.byType(InsightCard));
    final title = find.text('하루 평균 3시간 12분 착용했어요');
    expect(
      tester.getBottomLeft(title).dy,
      lessThan(tester.getTopLeft(body).dy),
    );
    expect(
      tester.getBottomLeft(body).dy,
      lessThan(tester.getBottomLeft(card).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('기록이 갱신되어 줄어들어도 선택값이 범위를 벗어나지 않는다', (tester) async {
    Future<void> show(List<Duration> values) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeeklyLineChart(
            values: values,
            labels: WeeklyMetrics.dayLabels,
            initialSelected: 6,
          ),
        ),
      ),
    );
    await show(sampleWeek.dailyWear);
    await show(const [Duration(minutes: 30)]);
    expect(find.text('30분'), findsOneWidget);
    await show(const []);
    expect(find.text('착용 기록이 없어요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

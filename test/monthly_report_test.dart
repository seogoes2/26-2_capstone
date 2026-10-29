import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gupsin/models/journal_entry.dart';
import 'package:gupsin/models/monthly.dart';
import 'package:gupsin/models/today_metrics.dart';
import 'package:gupsin/screens/report.dart';
import 'package:gupsin/widgets/calendar.dart';
import 'package:gupsin/widgets/journal_record.dart';

import 'fixtures.dart';

void main() {
  Future<void> openMonth(
    WidgetTester tester, {
    DateTime? date,
    MonthlyMetrics Function(int, int)? monthly,
    TodayMetrics today = sampleToday,
    double width = 402,
  }) async {
    tester.view.physicalSize = Size(width, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final now = date ?? DateTime(2026, 9, 30);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          now: () => now,
          source: FixtureMetricsSource(
            todayMetrics: today,
            monthMetrics: monthly ?? (y, m) => sampleMonth(y, m, until: now),
          ),
        ),
      ),
    );
    await tester.tap(find.text('월간'));
    await tester.pumpAndSettle();
  }

  Finder inCalendar(String text) => find.descendant(
    of: find.byType(MonthCalendar),
    matching: find.text(text),
  );

  testWidgets('이번 달 합계와 오늘 요약을 보여준다', (tester) async {
    await openMonth(tester);
    expect(find.text('9월 30일 요약'), findsOneWidget);
    await tester.tap(inCalendar('17'));
    await tester.pumpAndSettle();
    expect(find.text('날짜별 기록과 월간 변화를 살펴보세요'), findsOneWidget);
    expect(find.text('이번 달 착용 시간'), findsOneWidget);
    expect(find.text('2026년 9월'), findsOneWidget);
    // 13 sample days plus today's live metrics (2시간 36분, 7회).
    expect(find.text('43시간 20분'), findsOneWidget);
    expect(find.text('75회'), findsOneWidget);
    expect(find.text('+28°'), findsOneWidget);
    expect(find.text('9월 17일 요약'), findsOneWidget);
    expect(find.text('2시간 36분'), findsOneWidget);
    expect(find.text('7회'), findsOneWidget);
    expect(find.text('이번 달 평균 착용 3시간 6분'), findsOneWidget);
    expect(find.text('기록된 14일 기준 · 이전 달보다 19분 증가'), findsOneWidget);
  });

  testWidgets('날짜를 누르면 그 날의 요약으로 바뀌고 미래 날짜는 누를 수 없다', (tester) async {
    await openMonth(tester, date: DateTime(2026, 9, 20));
    await tester.tap(inCalendar('18'));
    await tester.pumpAndSettle();
    expect(find.text('9월 18일 요약'), findsOneWidget);
    expect(find.text('3시간 40분'), findsOneWidget);

    await tester.tap(inCalendar('25'));
    await tester.pumpAndSettle();
    expect(find.text('9월 18일 요약'), findsOneWidget);
  });

  testWidgets('이전 달로 이동하면 선택이 풀리고 다음 달은 이번 달까지만 간다', (tester) async {
    await openMonth(tester);
    expect(
      tester.widget<MonthCalendar>(find.byType(MonthCalendar)).onNext,
      isNull,
    );
    await tester.tap(find.bySemanticsLabel('이전 달'));
    await tester.pumpAndSettle();
    expect(find.text('2026년 8월'), findsOneWidget);
    expect(find.text('8월 착용 시간'), findsOneWidget);
    expect(find.byType(DaySummaryCard), findsNothing);

    await tester.tap(find.bySemanticsLabel('다음 달'));
    await tester.pumpAndSettle();
    expect(find.text('2026년 9월'), findsOneWidget);
    expect(find.text('9월 30일 요약'), findsOneWidget);
  });

  testWidgets('월 제목을 눌러 다른 달을 고를 수 있다', (tester) async {
    await openMonth(tester);
    await tester.tap(find.bySemanticsLabel('2026년 9월, 월 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('2026년 6월'));
    await tester.pumpAndSettle();
    expect(find.text('2026년 6월'), findsOneWidget);
  });

  testWidgets('기록을 수정해 저장하면 조회 카드에 반영된다', (tester) async {
    await openMonth(tester);
    expect(find.text('기록 없음'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('기록 추가'));
    await tester.pumpAndSettle();
    expect(find.text('9월 30일 기록 수정'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(Mood.okay.label));
    await tester.tap(find.bySemanticsLabel(Symptom.stiffness.label));
    await tester.tap(find.bySemanticsLabel(Activity.typing.label));
    await tester.enterText(find.byType(TextField), '타이핑 후 뻣뻣함');
    await tester.tap(find.bySemanticsLabel('수정 내용 저장'));
    await tester.pumpAndSettle();

    expect(find.byType(JournalEditForm), findsNothing);
    expect(find.text('저장되었어요.'), findsOneWidget);
    expect(find.text('기록 있음'), findsOneWidget);
    expect(find.text('보통'), findsOneWidget);
    expect(find.text('뻣뻣함'), findsOneWidget);
    expect(find.text('타이핑'), findsOneWidget);
    expect(find.text('타이핑 후 뻣뻣함'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('기록 수정'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('취소'));
    await tester.pumpAndSettle();
    expect(find.byType(JournalEditForm), findsNothing);
    expect(find.text('보통'), findsOneWidget);
  });

  testWidgets('기록이 없는 달은 빈 상태를 보여준다', (tester) async {
    await openMonth(
      tester,
      today: const TodayMetrics(
        jointAngle: null,
        wearTime: Duration.zero,
        wearGoal: Duration(hours: 4),
        overflexCount: 0,
      ),
      monthly: (y, m) => MonthlyMetrics(
        year: y,
        month: m,
        days: const {},
        wearGoalPerDay: const Duration(hours: 4),
      ),
    );
    expect(find.text('0분'), findsNWidgets(2));
    expect(find.text('이번 달 사용 기록이 없어요.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('6주에 걸친 달과 작은 화면에서도 넘치지 않는다', (tester) async {
    await openMonth(tester, date: DateTime(2026, 8, 31), width: 320);
    expect(inCalendar('31'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('기록 추가'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

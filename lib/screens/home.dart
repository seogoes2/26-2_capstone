import 'package:flutter/material.dart';

import '../models/journal_entry.dart';
import '../models/today_metrics.dart';
import '../services/app_storage.dart';
import '../theme/app_colors.dart';
import '../widgets/app_button.dart';
import '../widgets/app_toast.dart';
import '../widgets/home/journal_cards.dart';
import '../widgets/home/movement_cards.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.storage,
    this.metrics = TodayMetrics.sample,
    this.now = DateTime.now,
  });

  final AppStorage storage;
  final TodayMetrics metrics;

  final DateTime Function() now;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final DateTime _today;
  Mood? _mood;
  final Set<Symptom> _symptoms = {};
  final Set<Activity> _activities = {};
  final _memo = TextEditingController();
  final _toastKey = GlobalKey<AppToastState>();

  static const _symptomOrder = [
    Symptom.pain,
    Symptom.stiffness,
    Symptom.swelling,
    Symptom.numbness,
    Symptom.other,
    Symptom.none,
  ];

  static const _activityWidths = {
    Activity.typing: 78.0,
    Activity.chores: 78.0,
    Activity.exercise: 66.0,
    Activity.other: 75.0,
  };

  @override
  void initState() {
    super.initState();
    widget.storage.markOnboardingDone();

    _today = DateUtils.dateOnly(widget.now());
    final saved = widget.storage.journalFor(_today);
    _mood = saved.mood;
    _symptoms.addAll(saved.symptoms);
    _activities.addAll(saved.activities);
    _memo.text = saved.memo;
  }

  @override
  void dispose() {
    _memo.dispose();
    super.dispose();
  }

  void _toggleSymptom(Symptom s) {
    setState(() {
      if (_symptoms.remove(s)) return;
      if (s == Symptom.none) {
        _symptoms.clear();
      } else {
        _symptoms.remove(Symptom.none);
      }
      _symptoms.add(s);
    });
  }

  void _toggleActivity(Activity a) {
    setState(() {
      if (!_activities.remove(a)) _activities.add(a);
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    await widget.storage.saveJournal(
      _today,
      JournalEntry(
        mood: _mood,
        symptoms: {..._symptoms},
        activities: {..._activities},
        memo: _memo.text,
      ),
    );
    _toastKey.currentState?.show('저장되었어요.');
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.metrics;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 78, 24, 31),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '오늘의 움직임',
                style: pretendard(27, FontWeight.w700, AppColors.text),
              ),
              const SizedBox(height: 5),
              Text(
                '${_dateLabel(_today)} · 내 손가락 사용 습관을 점검해요',
                style: pretendard(13, FontWeight.w400, AppColors.textSub),
              ),
              const SizedBox(height: 25),
              CurrentAngleCard(metrics: m),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      icon: 'clock',
                      label: '오늘 착용',
                      value: formatDuration(m.wearTime),
                      caption:
                          '목표 ${formatDuration(m.wearGoal)}의 ${m.wearGoalPercent}%',
                      captionColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricCard(
                      icon: 'hand_small',
                      label: '오늘 과굴곡',
                      value: '${m.overflexCount}회',
                      caption: _overflexCaption(m.overflexChangeFromYesterday),
                      captionColor: _overflexColor(
                        m.overflexChangeFromYesterday,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                '착용 목표',
                style: pretendard(17, FontWeight.w600, AppColors.text),
              ),
              const SizedBox(height: 16),
              WearGoalCard(goal: m.wearGoal),
              const SizedBox(height: 51),
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '오늘의 상태',
                      style: pretendard(27, FontWeight.w700, AppColors.text),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '몸의 느낌과 활동을 함께 남겨보세요',
                      style: pretendard(13, FontWeight.w400, AppColors.textSub),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              JournalCard(
                title: '오늘 손가락 상태는 어떤가요?',
                titleGap: 13,
                childPadding: const EdgeInsets.fromLTRB(18, 0, 18, 11),
                child: MoodSelector(
                  selected: _mood,
                  onChanged: (mood) => setState(() => _mood = mood),
                ),
              ),
              const SizedBox(height: 20),
              JournalCard(
                title: '느낀 증상',
                childPadding: const EdgeInsets.fromLTRB(25, 0, 18, 9),
                child: ChipGroup<Symptom>(
                  options: _symptomOrder,
                  labelOf: (s) => s.label,
                  chipWidthOf: (_) => 67,
                  selected: _symptoms,
                  onToggle: _toggleSymptom,
                ),
              ),
              const SizedBox(height: 20),
              JournalCard(
                title: '주로 한 활동',
                childPadding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                child: ChipGroup<Activity>(
                  options: Activity.values,
                  labelOf: (a) => a.label,
                  chipWidthOf: (a) => _activityWidths[a]!,
                  spacing: 7,
                  selected: _activities,
                  onToggle: _toggleActivity,
                ),
              ),
              const SizedBox(height: 20),
              Stack(
                children: [
                  JournalCard(
                    title: '한 줄 메모',
                    titleGap: 16,
                    childPadding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                    child: NoteField(controller: _memo),
                  ),
                  Positioned(
                    left: 9,
                    right: 9,
                    bottom: 0,
                    child: Center(
                      child: AppToast(
                        key: _toastKey,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 21),
              AppButton(
                label: '오늘 기록 저장',
                width: double.infinity,
                height: 48,
                radius: 14,
                textStyle: pretendard(18, FontWeight.w600, Colors.white),
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _dateLabel(DateTime d) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${d.month}월 ${d.day}일 ${weekdays[d.weekday - 1]}요일';
  }

  static String _overflexCaption(int? change) {
    if (change == null) return '어제 기록 없음';
    if (change < 0) return '어제보다 ${-change}회 감소';
    if (change > 0) return '어제보다 $change회 증가';
    return '어제와 같아요';
  }

  static Color _overflexColor(int? change) {
    if (change == null || change == 0) return AppColors.textSub;
    return change < 0 ? AppColors.positive : AppColors.negative;
  }
}

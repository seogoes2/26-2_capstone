import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/journal_entry.dart';
import '../theme/app_colors.dart';
import 'app_button.dart';
import 'home/journal_cards.dart';
import 'home/movement_cards.dart';

String monthDayLabel(DateTime d) => '${d.month}월 ${d.day}일';

class DaySummaryCard extends StatelessWidget {
  const DaySummaryCard({
    super.key,
    required this.date,
    required this.wear,
    required this.overflex,
  });

  final DateTime date;
  final Duration wear;
  final int overflex;

  @override
  Widget build(BuildContext context) {
    Widget stat(String label, String value) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: pretendard(12, FontWeight.w400, AppColors.textSub)),
        const SizedBox(height: 7),
        Text(value, style: pretendard(23, FontWeight.w700, AppColors.text)),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${monthDayLabel(date)} 요약',
            style: pretendard(15, FontWeight.w600, AppColors.text),
          ),
          const SizedBox(height: 13),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 187, child: stat('착용 시간', formatDuration(wear))),
              Expanded(child: stat('과굴곡', '$overflex회')),
            ],
          ),
        ],
      ),
    );
  }
}

class JournalRecordCard extends StatelessWidget {
  const JournalRecordCard({
    super.key,
    required this.date,
    required this.entry,
    required this.onEdit,
  });

  final DateTime date;
  final JournalEntry entry;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final has = !entry.isEmpty;
    final labelStyle = pretendard(11, FontWeight.w400, AppColors.textSub);

    String joined(Iterable<String> labels) =>
        labels.isEmpty ? '-' : labels.join(', ');

    Widget field(String label, String value) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 5),
        Text(value, style: pretendard(14, FontWeight.w500, AppColors.text)),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    '${monthDayLabel(date)} 상태 기록',
                    style: pretendard(15, FontWeight.w600, AppColors.text),
                  ),
                ),
              ),
              Container(
                width: 71,
                height: 25,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: has ? AppColors.primarySoft : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  has ? '기록 있음' : '기록 없음',
                  style: pretendard(
                    10,
                    FontWeight.w500,
                    has ? AppColors.primary : AppColors.textSub,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 170,
                child: field('손가락 상태', entry.mood?.label ?? '-'),
              ),
              Expanded(
                child: field(
                  '느낀 증상',
                  joined([
                    for (final s in Symptom.values)
                      if (entry.symptoms.contains(s)) s.label,
                  ]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('주요 활동', style: labelStyle),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  joined([
                    for (final a in Activity.values)
                      if (entry.activities.contains(a)) a.label,
                  ]),
                  style: pretendard(
                    12,
                    FontWeight.w500,
                    entry.activities.isEmpty
                        ? AppColors.textSub
                        : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 53),
            padding: const EdgeInsets.fromLTRB(11, 7, 11, 7),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              entry.memo.isEmpty ? '남긴 메모가 없어요.' : entry.memo,
              style: pretendard(
                12,
                FontWeight.w400,
                entry.memo.isEmpty ? AppColors.textSub : AppColors.text,
              ),
            ),
          ),
          const SizedBox(height: 13),
          Semantics(
            button: true,
            label: has ? '기록 수정' : '기록 추가',
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onEdit,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/pen.svg',
                      width: 17,
                      height: 17,
                    ),
                    const SizedBox(width: 17),
                    Text(
                      has ? '기록 수정' : '기록 추가',
                      style: pretendard(13, FontWeight.w600, AppColors.primary),
                    ),
                    // Mirrors the icon so the label stays centered.
                    const SizedBox(width: 34),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class JournalEditForm extends StatefulWidget {
  const JournalEditForm({
    super.key,
    required this.date,
    required this.initial,
    required this.onCancel,
    required this.onSave,
  });

  final DateTime date;
  final JournalEntry initial;
  final VoidCallback onCancel;
  final ValueChanged<JournalEntry> onSave;

  @override
  State<JournalEditForm> createState() => _JournalEditFormState();
}

class _JournalEditFormState extends State<JournalEditForm> {
  late Mood? _mood = widget.initial.mood;
  late final Set<Symptom> _symptoms = {...widget.initial.symptoms};
  late final Set<Activity> _activities = {...widget.initial.activities};
  late final _memo = TextEditingController(text: widget.initial.memo);

  static const _activityWidths = {
    Activity.typing: 78.0,
    Activity.chores: 78.0,
    Activity.exercise: 66.0,
    Activity.other: 66.0,
  };

  // Inner cards sit on a white form, so they get a hairline instead of a fill.
  static const _cardBorder = AppColors.background;

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

  void _save() {
    FocusScope.of(context).unfocus();
    widget.onSave(
      JournalEntry(
        mood: _mood,
        symptoms: {..._symptoms},
        activities: {..._activities},
        memo: _memo.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Text(
              '${monthDayLabel(widget.date)} 기록 수정',
              style: pretendard(16, FontWeight.w600, AppColors.text),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                JournalCard(
                  title: '손가락 상태',
                  borderColor: _cardBorder,
                  titlePadding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
                  childPadding: const EdgeInsets.fromLTRB(9, 0, 11, 18),
                  child: MoodSelector(
                    selected: _mood,
                    onChanged: (mood) => setState(() => _mood = mood),
                  ),
                ),
                const SizedBox(height: 15),
                JournalCard(
                  title: '느낀 증상',
                  borderColor: _cardBorder,
                  titlePadding: const EdgeInsets.fromLTRB(16, 15, 16, 12),
                  childPadding: const EdgeInsets.fromLTRB(16, 0, 16, 9),
                  child: ChipGroup<Symptom>(
                    options: Symptom.values,
                    labelOf: (s) => s.label,
                    chipWidthOf: (_) => 67,
                    selected: _symptoms,
                    onToggle: _toggleSymptom,
                  ),
                ),
                const SizedBox(height: 15),
                JournalCard(
                  title: '주로 한 활동',
                  borderColor: _cardBorder,
                  titlePadding: const EdgeInsets.fromLTRB(16, 15, 16, 12),
                  childPadding: const EdgeInsets.fromLTRB(16, 0, 11, 20),
                  child: ChipGroup<Activity>(
                    options: Activity.values,
                    labelOf: (a) => a.label,
                    chipWidthOf: (a) => _activityWidths[a]!,
                    spacing: 7,
                    selected: _activities,
                    onToggle: _toggleActivity,
                  ),
                ),
                const SizedBox(height: 15),
                JournalCard(
                  title: '한 줄 메모',
                  borderColor: _cardBorder,
                  titlePadding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
                  childPadding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: NoteField(controller: _memo),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
            child: Row(
              children: [
                AppButton(
                  label: '취소',
                  width: 100,
                  height: 44,
                  radius: 12,
                  colors: const AppButtonColors(
                    base: AppColors.background,
                    hover: AppColors.divider,
                    pressed: AppColors.divider,
                  ),
                  textStyle: pretendard(13, FontWeight.w600, AppColors.textSub),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    widget.onCancel();
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: '수정 내용 저장',
                    width: double.infinity,
                    height: 44,
                    radius: 12,
                    textStyle: pretendard(13, FontWeight.w600, Colors.white),
                    onPressed: _save,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

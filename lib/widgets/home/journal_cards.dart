import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../models/journal_entry.dart';
import '../../theme/app_colors.dart';

class JournalCard extends StatelessWidget {
  const JournalCard({
    super.key,
    required this.title,
    required this.child,
    this.titleGap = 12,
    this.childPadding = const EdgeInsets.fromLTRB(18, 0, 18, 18),
  });

  final String title;
  final Widget child;

  final double titleGap;
  final EdgeInsets childPadding;

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
            padding: EdgeInsets.fromLTRB(18, 17, 18, titleGap),
            child: Text(
              title,
              style: pretendard(15, FontWeight.w600, AppColors.text),
            ),
          ),
          Padding(padding: childPadding, child: child),
        ],
      ),
    );
  }
}

class MoodSelector extends StatelessWidget {
  const MoodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Mood? selected;
  final ValueChanged<Mood?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final mood in Mood.values)
          _MoodItem(
            mood: mood,
            selected: mood == selected,
            onTap: () => onChanged(mood == selected ? null : mood),
          ),
      ],
    );
  }
}

class _MoodItem extends StatelessWidget {
  const _MoodItem({
    required this.mood,
    required this.selected,
    required this.onTap,
  });

  final Mood mood;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSub;
    return Semantics(
      button: true,
      selected: selected,
      label: mood.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 60,
          height: 67,
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              const SizedBox(height: 9),
              SvgPicture.asset(
                'assets/icons/${mood.icon}.svg',
                width: 28,
                height: 28,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
              const SizedBox(height: 9),
              Text(mood.label, style: pretendard(10, FontWeight.w500, color)),
            ],
          ),
        ),
      ),
    );
  }
}

class ChipGroup<T> extends StatelessWidget {
  const ChipGroup({
    super.key,
    required this.options,
    required this.labelOf,
    required this.selected,
    required this.onToggle,
    this.chipWidthOf,
    this.spacing = 12,
  });

  final List<T> options;
  final String Function(T) labelOf;
  final Set<T> selected;
  final ValueChanged<T> onToggle;

  final double Function(T)? chipWidthOf;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: 8,
      children: [
        for (final option in options)
          SelectChip(
            label: labelOf(option),
            width: chipWidthOf?.call(option),
            selected: selected.contains(option),
            onTap: () => onToggle(option),
          ),
      ],
    );
  }
}

class SelectChip extends StatelessWidget {
  const SelectChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.width,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: width,
          height: 34,
          padding: width == null
              ? const EdgeInsets.symmetric(horizontal: 18)
              : EdgeInsets.zero,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: pretendard(
              12,
              FontWeight.w500,
              selected ? Colors.white : AppColors.textSub,
            ),
          ),
        ),
      ),
    );
  }
}

class NoteField extends StatelessWidget {
  const NoteField({super.key, required this.controller});

  final TextEditingController controller;

  static const maxLength = 1000;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          height: 88,
          child: TextField(
            controller: controller,
            maxLength: maxLength,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: pretendard(13, FontWeight.w400, AppColors.text),
            buildCounter: (
              _, {
              required currentLength,
              required isFocused,
              maxLength,
            }) => null,
            decoration: InputDecoration(
              hintText: '오늘 느낀 점을 남겨보세요(선택)',
              hintStyle: pretendard(13, FontWeight.w400, AppColors.textSub),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        ValueListenableBuilder(
          valueListenable: controller,
          builder: (context, value, _) => Text(
            '${value.text.characters.length} / $maxLength',
            style: pretendard(11, FontWeight.w400, AppColors.textSub),
          ),
        ),
      ],
    );
  }
}

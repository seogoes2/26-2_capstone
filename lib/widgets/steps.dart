import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class StepSlider extends StatelessWidget {
  const StepSlider({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.semanticLabel,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  final String? semanticLabel;

  static const double height = 62;
  static const double _inset = 12;
  static const _duration = Duration(milliseconds: 160);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final gap = (width - _inset * 2) / (labels.length - 1);
          double x(int i) => _inset + gap * i;

          int nearest(double dx) =>
              ((dx - _inset) / gap).round().clamp(0, labels.length - 1);

          void pick(double dx) {
            final i = nearest(dx);
            if (i != selected) onChanged(i);
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (d) => pick(d.localPosition.dx),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < labels.length - 1; i++)
                  Positioned(
                    left: x(i),
                    top: 19,
                    width: gap,
                    height: 4,
                    child: AnimatedContainer(
                      duration: _duration,
                      decoration: BoxDecoration(
                        color: i < selected
                            ? AppColors.primary
                            : AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                for (var i = 0; i < labels.length; i++) ...[
                  Positioned(
                    left: x(i) - 11,
                    top: 10,
                    width: 22,
                    height: 22,
                    child: Center(child: _Dot(state: _dotState(i))),
                  ),
                  Positioned(
                    left: x(i) - 24,
                    top: 39,
                    width: 48,
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: pretendard(
                        11,
                        FontWeight.w500,
                        i == selected ? AppColors.primary : AppColors.textSub,
                      ),
                    ),
                  ),
                ],
                for (var i = 0; i < labels.length; i++)
                  Positioned(
                    left: x(i) - 22,
                    top: 0,
                    width: 44,
                    height: 61,
                    child: Semantics(
                      button: true,
                      selected: i == selected,
                      label: '${semanticLabel ?? ''} ${labels[i]}'.trim(),
                      excludeSemantics: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (i != selected) onChanged(i);
                        },
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  _DotState _dotState(int i) {
    if (i == selected) return _DotState.selected;
    return i < selected ? _DotState.passed : _DotState.ahead;
  }
}

enum _DotState { passed, selected, ahead }

class _Dot extends StatelessWidget {
  const _Dot({required this.state});

  final _DotState state;

  @override
  Widget build(BuildContext context) {
    if (state == _DotState.selected) {
      return Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Container(
          width: 14,
          height: 14,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      );
    }
    final passed = state == _DotState.passed;
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: passed ? AppColors.primary : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: passed ? AppColors.primary : AppColors.divider,
          width: 2,
        ),
      ),
    );
  }
}

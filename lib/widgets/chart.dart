import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'home/movement_cards.dart';

class HourlyBarChart extends StatelessWidget {
  const HourlyBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.unit = '회',
  });

  final List<int> values;
  final List<String> labels;
  final String unit;

  static const double height = 203;
  static const double _plotLeft = 40;
  static const double _plotRightGap = 21;
  static const double _baseline = 144;
  static const double _top = 53;
  static const double _barWidth = 32.5;
  static const double _firstBarGap = 9;
  static const double _lastBarGap = 14;

  int get _axisMax {
    final max = values.fold<int>(0, (a, b) => a > b ? a : b);
    if (max <= 2) return 2;
    return max.isEven ? max : max + 1;
  }

  @override
  Widget build(BuildContext context) {
    final axisMax = _axisMax;
    final peak = values.fold<int>(0, (a, b) => a > b ? a : b);
    const plotHeight = _baseline - _top;
    final axisStyle = pretendard(10, FontWeight.w400, AppColors.textSub);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final plotRight = width - _plotRightGap;
          final firstX = _plotLeft + _firstBarGap;
          final lastX = plotRight - _lastBarGap - _barWidth;
          final step = values.length > 1
              ? (lastX - firstX) / (values.length - 1)
              : 0.0;

          Widget gridLine(double y) => Positioned(
            left: _plotLeft,
            right: _plotRightGap,
            top: y,
            child: Container(height: 1, color: AppColors.divider),
          );

          Widget axisLabel(String text, double top) => Positioned(
            left: 13,
            width: 20,
            top: top,
            child: Text(text, textAlign: TextAlign.center, style: axisStyle),
          );

          return Stack(
            children: [
              Positioned(
                left: 18,
                top: 23,
                child: Text(
                  unit,
                  style: pretendard(11, FontWeight.w400, AppColors.textSub),
                ),
              ),
              gridLine(_top),
              gridLine((_top + _baseline) / 2),
              gridLine(_baseline),
              axisLabel('$axisMax', 45),
              axisLabel('${axisMax ~/ 2}', 91),
              axisLabel('0', 134),
              for (var i = 0; i < values.length; i++) ...[
                _bar(
                  left: firstX + step * i,
                  value: values[i],
                  height: values[i] == 0
                      ? 4
                      : (plotHeight * values[i] / axisMax).clamp(4, plotHeight),
                  highlight: values[i] > 0 && values[i] == peak,
                ),
                Positioned(
                  left: firstX + step * i - 6,
                  width: _barWidth + 12,
                  top: 156,
                  child: Text(
                    i < labels.length ? labels[i] : '',
                    textAlign: TextAlign.center,
                    style: axisStyle,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _bar({
    required double left,
    required int value,
    required double height,
    required bool highlight,
  }) {
    final top = _baseline - height;
    return Positioned(
      left: left - 4,
      width: _barWidth + 8,
      top: top - 21,
      height: height + 21,
      child: Column(
        children: [
          SizedBox(
            height: 16,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: pretendard(11, FontWeight.w600, AppColors.text),
            ),
          ),
          const SizedBox(height: 5),
          Container(
            width: _barWidth,
            height: height,
            decoration: BoxDecoration(
              color: highlight ? AppColors.primary : AppColors.primarySoft,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ],
      ),
    );
  }
}

class WeeklyLineChart extends StatefulWidget {
  const WeeklyLineChart({
    super.key,
    required this.values,
    required this.labels,
    this.initialSelected,
  });

  final List<Duration> values;
  final List<String> labels;
  final int? initialSelected;

  static const double height = 212;

  @override
  State<WeeklyLineChart> createState() => _WeeklyLineChartState();
}

class _WeeklyLineChartState extends State<WeeklyLineChart> {
  late int? _selected = _validSelection(widget.initialSelected);

  int? _validSelection(int? index) {
    if (index == null || widget.values.isEmpty) return null;
    return index.clamp(0, widget.values.length - 1);
  }

  @override
  void didUpdateWidget(covariant WeeklyLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selected = _validSelection(
      oldWidget.initialSelected != widget.initialSelected
          ? widget.initialSelected
          : _selected,
    );
  }

  static const double _base = 153;
  static const double _top = 51;
  static const double _firstX = 48;
  static const double _rightGap = 30;
  static const double _gridLeft = 44;
  static const double _gridRightGap = 24;

  int get _axisHours {
    final maxMinutes = widget.values.fold<int>(
      0,
      (m, d) => d.inMinutes > m ? d.inMinutes : m,
    );
    final hours = (maxMinutes / 60).ceil();
    if (hours <= 4) return 4;
    return hours.isEven ? hours : hours + 1;
  }

  @override
  Widget build(BuildContext context) {
    final axis = _axisHours;
    final axisStyle = pretendard(11, FontWeight.w400, AppColors.textSub);

    return Container(
      height: WeeklyLineChart.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final n = widget.values.length;
          // Keep Monday–Sunday in the same slots, including a partial week.
          final slots = n > widget.labels.length ? n : widget.labels.length;
          final step = slots > 1
              ? (width - _rightGap - _firstX) / (slots - 1)
              : 0.0;
          final points = [
            for (var i = 0; i < n; i++)
              Offset(
                _firstX + step * i,
                _base -
                    (_base - _top) * widget.values[i].inMinutes / (axis * 60),
              ),
          ];

          void selectAt(double dx) {
            if (n == 0) return;
            final index = n == 1 || step <= 0
                ? 0
                : ((dx - _firstX) / step).round().clamp(0, n - 1);
            if (_selected != index) setState(() => _selected = index);
          }

          Widget grid(double y, String label) => Positioned(
            left: 0,
            right: 0,
            top: y - 8,
            height: 16,
            child: Stack(
              children: [
                Positioned(
                  left: 15,
                  top: 0,
                  child: Text(label, style: axisStyle),
                ),
                Positioned(
                  left: _gridLeft,
                  right: _gridRightGap,
                  top: 8,
                  child: Container(height: 1, color: AppColors.divider),
                ),
              ],
            ),
          );

          final selected = _selected;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: n == 0 ? null : (d) => selectAt(d.localPosition.dx),
            onHorizontalDragUpdate: n == 0
                ? null
                : (d) => selectAt(d.localPosition.dx),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                grid(_top, '${axis}h'),
                grid((_top + _base) / 2, '${axis ~/ 2}h'),
                grid(_base, '0h'),
                Positioned.fill(
                  child: CustomPaint(painter: _LinePainter(points)),
                ),
                for (var i = 0; i < slots; i++)
                  Positioned(
                    left: _firstX + step * i - 20,
                    width: 40,
                    top: 157,
                    height: 44,
                    child: Semantics(
                      button: i < n,
                      selected: i == selected,
                      label: i < widget.labels.length ? widget.labels[i] : '',
                      value: i < n ? formatDuration(widget.values[i]) : '기록 없음',
                      excludeSemantics: true,
                      onTap: i < n ? () => setState(() => _selected = i) : null,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text(
                          i < widget.labels.length ? widget.labels[i] : '',
                          textAlign: TextAlign.center,
                          style: axisStyle,
                        ),
                      ),
                    ),
                  ),
                if (n == 0)
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          '착용 기록이 없어요',
                          style: pretendard(
                            12,
                            FontWeight.w400,
                            AppColors.textSub,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (selected != null && selected < n)
                  Positioned(
                    left: points[selected].dx - 25.5,
                    top: points[selected].dy - 4 - 25,
                    child: _Tooltip(
                      text: formatDuration(widget.values[selected]),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.points);

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final line = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, line);
    final dot = Paint()..color = AppColors.primary;
    for (final p in points) {
      canvas.drawCircle(p, 4, dot);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.points != points;
}

class _Tooltip extends StatelessWidget {
  const _Tooltip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 51,
      height: 25,
      child: CustomPaint(
        painter: _BubblePainter(),
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: 18.75,
            child: Center(
              child: Text(
                text,
                style: pretendard(8, FontWeight.w500, Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.primary;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 51, 18.75),
        const Radius.circular(3),
      ),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(20.59, 18.75)
        ..lineTo(30.41, 18.75)
        ..lineTo(25.5, 25)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(_BubblePainter old) => false;
}

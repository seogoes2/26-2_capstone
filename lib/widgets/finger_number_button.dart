import 'package:flutter/material.dart';

import 'app_button.dart';

class FingerNumberButton extends StatefulWidget {
  const FingerNumberButton({
    super.key,
    required this.number,
    required this.selected,
    required this.onPressed,
  });

  final int number;
  final bool selected;
  final VoidCallback onPressed;

  static const double size = 50;

  @override
  State<FingerNumberButton> createState() => _FingerNumberButtonState();
}

class _FingerNumberButtonState extends State<FingerNumberButton> {
  bool _hovered = false;
  bool _pressed = false;

  static const _colors = AppButtonColors.primary;

  Color get _color {
    if (_pressed || widget.selected) return _colors.pressed;
    if (_hovered) return _colors.hover;
    return _colors.base;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: widget.selected,
      label: '${widget.number}번 손가락',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: _pressed ? 0.92 : (_hovered ? 1.08 : 1.0),
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              width: FingerNumberButton.size,
              height: FingerNumberButton.size,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
              child: Text(
                '${widget.number}',
                style: const TextStyle(
                  fontFamily: 'Helvetica Neue',
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

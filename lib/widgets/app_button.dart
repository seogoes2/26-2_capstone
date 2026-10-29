import 'package:flutter/material.dart';

class AppButtonColors {
  const AppButtonColors({
    required this.base,
    required this.hover,
    required this.pressed,
  });

  final Color base;
  final Color hover;
  final Color pressed;

  static const primary = AppButtonColors(
    base: Color(0xFF375BFF),
    hover: Color(0xFF2347E6),
    pressed: Color(0xFF1A3AC7),
  );

  static const secondary = AppButtonColors(
    base: Color(0xFF7B8495),
    hover: Color(0xFF687183),
    pressed: Color(0xFF565E6E),
  );
}

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.width,
    required this.textStyle,
    this.height = 69,
    this.radius = 22,
    this.selected = false,
    this.colors = AppButtonColors.primary,
    this.onPressed,
  });

  final String label;
  final double width;
  final double height;
  final double radius;
  final TextStyle textStyle;
  final bool selected;
  final AppButtonColors colors;
  final VoidCallback? onPressed;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _hovered = false;
  bool _pressed = false;

  Color get _color {
    if (_pressed || widget.selected) return widget.colors.pressed;
    if (_hovered) return widget.colors.hover;
    return widget.colors.base;
  }

  double get _scale {
    if (_pressed) return 0.97;
    if (_hovered && !widget.selected) return 1.03;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
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
            scale: _scale,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              width: widget.width,
              height: widget.height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(widget.radius),
                boxShadow: _hovered && !widget.selected
                    ? [
                        BoxShadow(
                          color: widget.colors.base.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : const [],
              ),
              child: Text(widget.label, style: widget.textStyle),
            ),
          ),
        ),
      ),
    );
  }
}

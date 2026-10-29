import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppToast extends StatefulWidget {
  const AppToast({super.key, this.alignment = Alignment.center});

  final AlignmentGeometry alignment;

  static const visibleFor = Duration(milliseconds: 1500);
  static const fadeIn = Duration(milliseconds: 200);
  static const fadeOut = Duration(milliseconds: 600);

  @override
  State<AppToast> createState() => AppToastState();
}

class AppToastState extends State<AppToast> {
  String _message = '';
  bool _visible = false;
  Timer? _timer;

  void show(String message) {
    _timer?.cancel();
    setState(() {
      _message = message;
      _visible = true;
    });
    _timer = Timer(AppToast.visibleFor, () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: _visible ? AppToast.fadeIn : AppToast.fadeOut,
        curve: Curves.easeOut,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 335),
          child: Container(
            width: double.infinity,
            height: 27,
            alignment: widget.alignment,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: AppColors.toast,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 20 / 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

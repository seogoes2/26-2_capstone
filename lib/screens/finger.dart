import 'package:flutter/material.dart';

import '../models/hand.dart';
import '../widgets/app_button.dart';
import '../widgets/app_toast.dart';
import '../widgets/finger_number_button.dart';

class FingerSelectScreen extends StatefulWidget {
  const FingerSelectScreen({
    super.key,
    required this.hand,
    required this.onNext,
    required this.onBack,
    this.initialFinger,
  });

  final Hand hand;

  final ValueChanged<int> onNext;

  final VoidCallback onBack;

  final int? initialFinger;

  @override
  State<FingerSelectScreen> createState() => _FingerSelectScreenState();
}

class _FingerSelectScreenState extends State<FingerSelectScreen> {
  late int? _selected = widget.initialFinger;
  final _toastKey = GlobalKey<AppToastState>();

  static const double _areaTop = 205;
  static const Size _areaSize = Size(402, 462);

  static const double _fixedHeight = 35 + 69 + 32.65 + 54.35;
  static const double _topFlex = 170, _areaFlex = 462, _bottomFlex = 51;

  static const Map<Hand, Map<int, Offset>> _numberPositions = {
    Hand.left: {
      1: Offset(53, 364),
      2: Offset(103, 297),
      3: Offset(170, 268),
      4: Offset(237, 315),
      5: Offset(299, 434),
    },
    Hand.right: {
      1: Offset(40, 440),
      2: Offset(100, 326),
      3: Offset(169, 282),
      4: Offset(238, 304),
      5: Offset(288, 362),
    },
  };

  static const _titleStyle = TextStyle(
    fontFamily: 'Koverwatch',
    fontSize: 35,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: Colors.black,
  );

  static const _nextTextStyle = TextStyle(
    fontFamily: 'Koverwatch',
    fontSize: 40,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: Colors.white,
  );

  static const _backTextStyle = TextStyle(
    fontFamily: 'Koverwatch',
    fontSize: 33,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: Colors.white,
  );

  void _toggle(int number) {
    setState(() => _selected = _selected == number ? null : number);
  }

  void _next() {
    final finger = _selected;
    if (finger == null) {
      _toastKey.currentState?.show('손가락을 선택해 주세요.');
      return;
    }
    widget.onNext(finger);
  }

  @override
  Widget build(BuildContext context) {
    final positions = _numberPositions[widget.hand]!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final free = (constraints.maxHeight - _fixedHeight).clamp(
            0,
            double.infinity,
          );
          final titleTop =
              free * _topFlex / (_topFlex + _areaFlex + _bottomFlex);
          final toastTop = titleTop + 35 + 19;

          return Stack(
            children: [
              SizedBox.expand(
                child: Column(
                  children: [
                    const Spacer(flex: 170),
                    const Text('어느 손가락이 불편하신가요?', style: _titleStyle),
                    Expanded(
                      flex: 462,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox.fromSize(
                          size: _areaSize,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 77,
                                top: 351 - _areaTop,
                                child: Transform.flip(
                                  flipX: widget.hand == Hand.left,
                                  child: Image.asset(
                                    'assets/images/hand.png',
                                    width: 236,
                                    height: 254,
                                    semanticLabel: widget.hand.label,
                                  ),
                                ),
                              ),
                              for (final MapEntry(key: number, value: pos)
                                  in positions.entries)
                                Positioned(
                                  left: pos.dx,
                                  top: pos.dy - _areaTop,
                                  child: FingerNumberButton(
                                    number: number,
                                    selected: _selected == number,
                                    onPressed: () => _toggle(number),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    AppButton(
                      label: '다음으로',
                      width: 261,
                      textStyle: _nextTextStyle,
                      onPressed: _next,
                    ),
                    const SizedBox(height: 32.65),
                    AppButton(
                      label: '이전으로',
                      width: 261,
                      height: 54.35,
                      textStyle: _backTextStyle,
                      colors: AppButtonColors.secondary,
                      onPressed: widget.onBack,
                    ),
                    const Spacer(flex: 51),
                  ],
                ),
              ),
              Positioned(
                top: toastTop,
                left: 20,
                right: 20,
                child: Center(child: AppToast(key: _toastKey)),
              ),
            ],
          );
        },
      ),
    );
  }
}

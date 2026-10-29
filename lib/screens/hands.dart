import 'package:flutter/material.dart';

import '../models/hand.dart';
import '../widgets/app_button.dart';
import '../widgets/app_toast.dart';

class HandSelectScreen extends StatefulWidget {
  const HandSelectScreen({super.key, required this.onNext, this.initialHand});

  final ValueChanged<Hand> onNext;

  final Hand? initialHand;

  @override
  State<HandSelectScreen> createState() => _HandSelectScreenState();
}

class _HandSelectScreenState extends State<HandSelectScreen> {
  late Hand? _selected = widget.initialHand;
  final _toastKey = GlobalKey<AppToastState>();

  static const double _fixedHeight = 35 + 82 + 192 + 42 + 69 + 61 + 69;

  static const _titleStyle = TextStyle(
    fontFamily: 'Koverwatch',
    fontSize: 35,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: Colors.black,
  );

  static const _buttonTextStyle = TextStyle(
    fontFamily: 'Koverwatch',
    fontSize: 40,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: Colors.white,
  );

  void _select(Hand hand) => setState(() => _selected = hand);

  void _next() {
    final hand = _selected;
    if (hand == null) {
      _toastKey.currentState?.show('손을 선택해 주세요.');
      return;
    }
    widget.onNext(hand);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final free = (constraints.maxHeight - _fixedHeight).clamp(
            0,
            double.infinity,
          );
          final toastTop = free * 224 / (224 + 100) + 35 + 19;
          return Stack(
            children: [
              SizedBox.expand(
                child: Column(
                  children: [
                    const Spacer(flex: 224),
                    const Text('어느쪽 손이 불편하신가요?', style: _titleStyle),
                    const SizedBox(height: 82),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _HandImage(
                          hand: Hand.left,
                          onTap: () => _select(Hand.left),
                        ),
                        _HandImage(
                          hand: Hand.right,
                          onTap: () => _select(Hand.right),
                        ),
                      ],
                    ),
                    const SizedBox(height: 42),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppButton(
                          label: Hand.left.label,
                          width: 145,
                          textStyle: _buttonTextStyle,
                          selected: _selected == Hand.left,
                          onPressed: () => _select(Hand.left),
                        ),
                        const SizedBox(width: 34),
                        AppButton(
                          label: Hand.right.label,
                          width: 153,
                          textStyle: _buttonTextStyle,
                          selected: _selected == Hand.right,
                          onPressed: () => _select(Hand.right),
                        ),
                      ],
                    ),
                    const SizedBox(height: 61),
                    AppButton(
                      label: '다음으로',
                      width: 261,
                      textStyle: _buttonTextStyle,
                      onPressed: _next,
                    ),
                    const Spacer(flex: 100),
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

class _HandImage extends StatelessWidget {
  const _HandImage({required this.hand, required this.onTap});

  final Hand hand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Transform.flip(
        flipX: hand == Hand.left,
        child: Image.asset(
          'assets/images/hand.png',
          width: 178,
          height: 192,
          semanticLabel: hand.label,
        ),
      ),
    );
  }
}

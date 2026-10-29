import 'package:flutter/material.dart';

import '../widgets/app_button.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key, this.onStart});

  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: Column(
          children: [
            const Spacer(flex: 283),
            Image.asset(
              'assets/images/gupsin_logo.png',
              width: 235,
              height: 251,
              semanticLabel: '굽신굽신 로고',
            ),
            const SizedBox(height: 144),
            AppButton(
              label: '시작하기',
              width: 261,
              onPressed: onStart,
              textStyle: const TextStyle(
                fontFamily: 'PearToucan',
                fontSize: 35,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
                color: Colors.white,
              ),
            ),
            const Spacer(flex: 127),
          ],
        ),
      ),
    );
  }
}

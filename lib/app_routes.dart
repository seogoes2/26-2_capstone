import 'package:flutter/material.dart';

import 'models/hand.dart';
import 'screens/finger.dart';
import 'screens/hands.dart';
import 'screens/main.dart';
import 'screens/start.dart';
import 'services/alerts.dart';
import 'services/app_storage.dart';
import 'services/sensor_connection.dart';

abstract final class AppRoutes {
  static const start = '/';
  static const handSelect = '/hand-select';
  static const fingerSelectLeft = '/finger-select/left';
  static const fingerSelectRight = '/finger-select/right';
  static const home = '/home';
  static const editHands = '/edit/hands';
  static const editFingerLeft = '/edit/finger/left';
  static const editFingerRight = '/edit/finger/right';

  static String initialRoute(AppStorage storage) =>
      storage.onboardingDone ? home : start;

  static String fingerSelectFor(Hand hand) =>
      hand == Hand.left ? fingerSelectLeft : fingerSelectRight;

  static Map<String, WidgetBuilder> routes(
    AppStorage storage,
    SensorConnection connection,
    AlertCenter alerts,
  ) => {
    start: (context) =>
        StartScreen(onStart: () => Navigator.pushNamed(context, handSelect)),
    handSelect: (context) => HandSelectScreen(
      onNext: (hand) => Navigator.pushNamed(context, fingerSelectFor(hand)),
    ),
    fingerSelectLeft: (context) => _fingerSelect(context, storage, Hand.left),
    fingerSelectRight: (context) => _fingerSelect(context, storage, Hand.right),
    home: (context) => MainShell(
      storage: storage,
      connection: connection,
      alerts: alerts,
      onEditProfile: () => Navigator.pushNamed(context, editHands),
    ),
    ..._editRoutes(storage),
  };

  static Map<String, WidgetBuilder> _editRoutes(AppStorage storage) => {
    editHands: (context) => HandSelectScreen(
      initialHand: storage.hand,
      onNext: (hand) => Navigator.pushNamed(
        context,
        hand == Hand.left ? editFingerLeft : editFingerRight,
      ),
    ),
    editFingerLeft: (context) => _editFinger(context, storage, Hand.left),
    editFingerRight: (context) => _editFinger(context, storage, Hand.right),
  };

  static Widget _editFinger(
    BuildContext context,
    AppStorage storage,
    Hand hand,
  ) => FingerSelectScreen(
    hand: hand,
    initialFinger: storage.hand == hand ? storage.finger : null,
    onBack: () => Navigator.pop(context),
    onNext: (finger) async {
      await storage.saveProfile(hand: hand, finger: finger);
      if (!context.mounted) return;
      Navigator.popUntil(context, ModalRoute.withName(home));
    },
  );

  static Widget _fingerSelect(
    BuildContext context,
    AppStorage storage,
    Hand hand,
  ) => FingerSelectScreen(
    hand: hand,
    onBack: () => Navigator.pop(context),
    onNext: (finger) async {
      await storage.saveProfile(hand: hand, finger: finger);
      if (!context.mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, home, (_) => false);
    },
  );
}

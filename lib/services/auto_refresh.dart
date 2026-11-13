import 'dart:async';

import 'package:flutter/widgets.dart';

/// How often screens showing live sensor numbers ask the server again.
const autoRefreshInterval = Duration(seconds: 3);

/// Calls [onAutoRefresh] every [autoRefreshInterval] while [autoRefreshActive]
/// is true and the app is in the foreground.
///
/// Every tab of the main shell stays alive in an IndexedStack, so screens turn
/// this on only while their tab is showing. When a screen becomes active again
/// (tab switch, app back from the background) it refreshes right away.
mixin AutoRefresh<T extends StatefulWidget> on State<T> {
  /// Whether this screen should keep its numbers live right now.
  bool get autoRefreshActive;

  /// Reloads the screen's data. Errors should be handled inside.
  Future<void> onAutoRefresh();

  Timer? _autoRefreshTimer;
  AppLifecycleListener? _lifecycle;
  bool _foreground = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        _foreground = state == AppLifecycleState.resumed;
        _syncAutoRefresh();
      },
    );
    // The screen loads once in its own initState, so no immediate refresh.
    _syncAutoRefresh(refreshNow: false);
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _lifecycle?.dispose();
    super.dispose();
  }

  void _syncAutoRefresh({bool refreshNow = true}) {
    final shouldRun = mounted && _foreground && autoRefreshActive;
    final running = _autoRefreshTimer != null;
    if (shouldRun && !running) {
      _autoRefreshTimer = Timer.periodic(autoRefreshInterval, (_) => _tick());
      if (refreshNow) _tick();
    } else if (!shouldRun && running) {
      _autoRefreshTimer!.cancel();
      _autoRefreshTimer = null;
    }
  }

  /// Skips a tick while the previous request is still out, so a slow network
  /// doesn't pile up requests.
  Future<void> _tick() async {
    if (_refreshing || !mounted) return;
    _refreshing = true;
    try {
      await onAutoRefresh();
    } finally {
      _refreshing = false;
    }
  }
}

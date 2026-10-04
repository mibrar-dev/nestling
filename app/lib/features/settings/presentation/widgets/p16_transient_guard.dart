import 'package:clock/clock.dart';

/// Session-local fencing of taps during/just after a modal or sheet's
/// closing animation.
///
/// Shared modal helpers remove their route from the hit-test tree before
/// the exit animation ends. An impatient second tap at the same spot
/// then lands on a settings row underneath (P16-B08). Ignoring taps for
/// a short window after the modal's future completes stops that fall
/// through without routing behaviour changes.
class P16TransientGuard {
  P16TransientGuard._();

  static DateTime? _lastModalClosedAt;

  /// Window of ignored taps following a close.
  static const Duration window = Duration(milliseconds: 300);

  /// Call when a modal/sheet route closes.
  static void suppressShortly() {
    _lastModalClosedAt = clock.now();
  }

  /// Test reset: clear the modal-close tap guard so it never leaks
  /// a 300 ms suppression into the next test in the same process.
  static void reset() {
    _lastModalClosedAt = null;
  }

  /// True while taps should be ignored.
  static bool get suppressing {
    final closedAt = _lastModalClosedAt;
    return closedAt != null && clock.now().difference(closedAt) <= window;
  }

  /// Runs [action] only outside the guard window.
  static void run(void Function() action) {
    if (suppressing) return;
    action();
  }
}

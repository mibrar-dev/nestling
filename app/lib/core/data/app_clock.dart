// Nestling — single app-wide "now".
//
// App code never calls `DateTime.now()`; it uses `clock.now()`
// (package:clock) via [appNowUtc] below. Tests are pinned to
// Sat 3 Oct 2026 09:41 Europe/London (= 08:41Z) by
// `app/test/flutter_test_config.dart` (`Seed.anchorOverride` + `withClock`).
//
// Why the anchor fallback: `withClock` in `flutter_test_config.dart` wraps
// `testMain()` (registration), but `test`/`testWidgets` bodies run later in
// fresh zones (verified by probe: `clock.now()` inside a body reads the real
// wall clock, not the outer pin; `FakeAsync` is constructed at `runTest`
// time from that real clock). `Seed.anchorOverride` IS visible to bodies
// (global static), so [appNowUtc] returns the pinned instant whenever the
// anchor is set and the zone clock otherwise. Production (no anchor) is
// exactly `clock.now().toUtc()` — no behaviour change.

import 'package:clock/clock.dart';
import 'package:nestling/core/data/seed.dart';

/// Pinned "now" for the demo story: 08:41 UTC on the anchor day (09:41 in
/// Europe/London during BST, after the seeded 8:12/8:05/7:58 morning events
/// and matching the designs' status bar).
DateTime appNowUtc() {
  final anchor = Seed.anchorOverride?.toUtc();
  if (anchor != null) {
    return DateTime.utc(anchor.year, anchor.month, anchor.day, 8, 41);
  }
  return clock.now().toUtc();
}

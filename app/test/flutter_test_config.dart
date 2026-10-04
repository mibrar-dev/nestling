// Runs before every test file: pins the demo seed's story day AND the app
// clock so "today" in the app equals the seed's pinned story day.
//
// The seed lives on Sat 3 Oct 2026 (Seed.anchorOverride). The app clock is
// pinned to 09:41 Europe/London on that day (= 08:41 UTC, after the seeded
// morning events at 8:12/8:05/7:58 and matching the designs' status bar).
// App code reads time via `clock.now()` (package:clock), so every
// `DateTime.now()` in app/lib was replaced — tests see the pinned instant
// (plus FakeAsync elapsed time inside testWidgets).

import 'dart:async';

import 'package:clock/clock.dart';
import 'package:nestling/core/data/seed.dart';

/// Pinned "now" for every test: Sat 3 Oct 2026 09:41 Europe/London = 08:41Z.
/// October is BST (UTC+1), so 09:41 London is 08:41 UTC.
final DateTime pinnedTestNowUtc = DateTime.utc(2026, 10, 3, 8, 41);

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Seed.anchorOverride = DateTime.utc(2026, 10, 3);
  final pinned = Clock.fixed(pinnedTestNowUtc);
  await withClock(pinned, () async {
    await testMain();
  });
}

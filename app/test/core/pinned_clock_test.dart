// Pinned-clock contract: "today" in the app equals the seed's story day.
//
// `flutter_test_config.dart` pins `Seed.anchorOverride = 2026-10-03` and runs
// `testMain` inside `withClock(Clock.fixed(2026-10-03T08:41Z))` (09:41 London,
// after the 8:12/8:05/7:58 seeded events). App code never calls
// `DateTime.now()`; it uses `clock.now()` via [appNowUtc].
//
// Zone note (verified by probe 2026-10-04): `withClock` around `testMain`
// covers registration only — `test`/`testWidgets` bodies run later in fresh
// zones, so bare `clock.now()` inside a body reads the real wall clock.
// Real determinism comes from [appNowUtc], which returns the pinned instant
// whenever `Seed.anchorOverride` is set (global, visible to bodies) and the
// zone clock otherwise. Explicit `withClock` *inside* a body (or a plain
// `FakeAsync` created inside one) DOES pin `clock.now()` — proved below —
// so per-test clocks (`AppSession(clock: …)`, `withClock` in DST tests) win.

import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_clock.dart';
import 'package:nestling/core/data/seed.dart';

/// Pinned "now": Sat 3 Oct 2026 09:41 Europe/London = 08:41Z (BST = UTC+1).
final DateTime kPinnedUtc = DateTime.utc(2026, 10, 3, 8, 41);

void main() {
  test('seed anchor is pinned to Sat 3 Oct 2026', () {
    expect(Seed.anchorOverride, DateTime.utc(2026, 10, 3));
  });

  test('appNowUtc is the pinned instant while the anchor is set', () {
    expect(appNowUtc(), kPinnedUtc);
  });

  test('explicit withClock pins clock.now in a plain test', () {
    withClock(Clock.fixed(kPinnedUtc), () {
      expect(clock.now().toUtc(), kPinnedUtc);
    });
  });

  test('FakeAsync reads the zone clock (package:fake_async uses clock)', () {
    withClock(Clock.fixed(kPinnedUtc), () {
      fakeAsync((async) {
        // Starts at the zone clock, advances with elapsed fake time.
        expect(clock.now().toUtc(), kPinnedUtc);
        async.elapse(const Duration(minutes: 5));
        expect(clock.now().toUtc(), kPinnedUtc.add(const Duration(minutes: 5)));
      });
    });
  });

  testWidgets('app time is pinned inside testWidgets (seed story day)', (
    tester,
  ) async {
    // App-facing time — what views/blocs/repositories use — is pinned even
    // though the bare zone clock is real (see header note).
    expect(Seed.anchorOverride, DateTime.utc(2026, 10, 3));
    expect(appNowUtc(), kPinnedUtc);

    // Explicit zone pinning inside the body works. NOTE: `Clock.fixed` does
    // not advance with `pump` (fixed stays fixed); advancing FakeAsync time
    // is proved in the plain `fakeAsync` test above, where the FakeAsync
    // clock starts at the zone clock and moves with `elapse`.
    final pinned = Clock.fixed(kPinnedUtc);
    await withClock(pinned, () async {
      expect(clock.now().toUtc(), kPinnedUtc);
      await tester.pump(const Duration(minutes: 2));
      expect(clock.now().toUtc(), kPinnedUtc);
      expect(appNowUtc(), kPinnedUtc);
    });
  });
}

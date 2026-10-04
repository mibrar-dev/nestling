# 3 TEST (iteration 2) — K02 Kid PIN (`kid_home`, `/kid-pin`)

Scope: `app/test/features/kid_home/**` + this file (RULES §1). **No product
code was touched by this stage** — the one file outside my own suite that I
edited, `k02_bugs_test.dart`, is a *test* file and the edit is the mandatory
hang fix below. **No simulator was booted, installed on, screenshot or driven.**

Two things this stage had to do:

1. **Mandatory `ORCHESTRATOR_NOTES.md` (10:32) — the hang in
   `k02_bugs_test.dart`.** `flutter test` on that file never finished (the
   orchestrator measured one run alive 1 h 08; my own attempt was still going
   at 19 min before it was killed) and full-suite runs hung on it too. **Fixed
   — the file now finishes in 3 s.**
2. **Extend the K02 suite for the iteration-2 build** (the FIXES_1 view fixes
   + the shared keypad grid) and hunt for regressions behind them.

## 1. The hang: root cause and fix

**Symptom.** `flutter test test/features/kid_home/k02_bugs_test.dart` stalls
at `K02 data edges (probes) non-BMP and composed initials render whole and
crash-free` (a 10-minute `TimeoutException`), and everything after it is
collateral damage — the isolate stays wedged, so the next test also times out
and the file dies at the end ("`loading …/k02_bugs_test.dart [E]`"). In a
full-suite run the same file hangs the whole `flutter test` (which is how two
of my runs were killed with SIGTERM).

**Root cause — a test that reuses its GetIt scope across pumps.** Four tests
in that file pump the app **twice or more inside one `testWidgets`** and only
`disposeApp()` in between:

| test | cycles |
|---|---|
| `a 20-char UK name fits at 390/1.0, 390/1.3 and 320/1.0` (`k02_bugs_test.dart:540`) | 3 pumps, 1 `runAsync` |
| `a 24-char UK name (P05 max) fits at 320/1.3 and 390/1.3` (`:564`) | 2 pumps, 1 `runAsync` |
| `restart after a wrong attempt resets dots but keeps the PIN` (`:771`) | 2 app instances |
| `screen text is identical across a BST -> GMT clock change` (`:930`) | 2 pumps |

`disposeApp` tears the widget tree down but leaves `AppSession`'s live Drift
watch (and its deferred stream-close work) alive in the **fake-async** queue.
The next test's `await tester.runAsync(…)` — which is the only thing in the
harness that crosses into the real zone — then waits for that queue to drain
and never returns. Single-cycle tests are immune, which is exactly why the
three `_assertInitial` tests pass in isolation and only hang when they run
after a multi-cycle test. (`--timeout 60s` did not bound it: the run reported
"timed out after 10 minutes", i.e. the per-test budget is the harness default,
so the only cure is to stop leaking the pending work.)

**Fix** (test-side only, `k02_bugs_test.dart`): make every cycle **complete** —
`await setUpTestScope()` (fresh GetIt scope, re-seeded DB) before each pump,
with any DB state that cycle needs re-applied inside `runAsync`. Applied to
the four tests above; each carries a comment pointing at
`ORCHESTRATOR_NOTES.md` (10:32). No assertion was changed, added or removed;
the only other edit in that file is the shared explanation above the
`_assertInitial` helper, which already stated the rule this bug violated.

**Proof.**

```
flutter test test/features/kid_home/k02_bugs_test.dart
  before: >19 min, SIGTERM (orchestrator: 1 h 08) — 3 timeouts, file-level [E]
  after:  00:03 +30 ~1: All tests passed!      (exit 0)

flutter test test/features/kid_home            00:13 +435 ~2: All tests passed!
flutter test                                   01:12 +2990 ~3: All tests passed!
```

The same trap bit me inside my own file first (a `setUpTestScope()` immediately
before a `runAsync` never completes), so `_insetProbes` and the nickname matrix
are documented against it too — see §4.

## 2. Tests added (iteration 2)

### `app/test/features/kid_home/kid_pin_view_test.dart` (47 → **54**)

Group `K02 iteration 2 fixes` — each test pins what a fix *promises*, so a
regression lands here instead of at the UI gate:

| Test | Fix it pins |
|---|---|
| `the greeting keeps the design single line at 390/1.0` | K02-BUG-2's `maxLines: 3` must not reflow the design: the seeded nickname still renders **one 26 px line** at 390/1.0 with `didExceedMaxLines == false`, and the cap stays at 3 so a long name still cannot be cut |
| `the longest legal nickname is never clipped` | K02-BUG-2's user-visible guarantee across the **whole matrix** (320/390/430 × scale 1.0/1.3) with a 24-character name (P05's maximum) — `didExceedMaxLines == false` and no exception in all six passes |
| `only .mark carries tracking, and both type styles match CSS` | the orchestrator's LETTER SPACING known case, swept over **every** `Text` on the screen: the only non-zero tracking is `1.28`, and only on `NESTLING`. Also pins both local styles to the CSS metrics (`Nunito` 900/16/22-per-16 + 1.28 for `.mark`, 800/20/26-per-20 + 0 for `.say`) so that when SHARED_REQUEST #1 lands, `NestType.kidSay`/`kidMark` cannot silently move a number |
| `the loading state reserves the real bottom inset` | review #4's `_BottomInset`: with a bottom inset of 20 / 34 / 60 logical px the centred spinner **does not move below the 34 px design floor** and moves up exactly half the extra reserve above it — and the shared meadow still reaches y 844 at every inset (BOTTOM EDGE) |
| `the failure card reserves the real bottom inset` | same, for the failure card's centred block |
| `the chooser reserves the real bottom inset` | same, for `_NoActiveChild` |
| `a wrong-code nudge cannot outlive the successful retry` | K02-BUG-4 as a navigation outcome: wrong code → toast, right code → `/kid-home` **with no "That didn't work. Try again." left on the destination** |

Shared helpers added for those: `_registerRepo` (register a `_PinStub`-wrapped
repository), `_insetProbes` (prepare once, then measure the probe's centre at
three insets) and `_expectInsetFloor` (the floor + follow-the-inset pair of
assertions), so the three fallback-state tests are one behaviour, three
entry points.

Carried from iteration 1 and re-verified unchanged: the design-anchor test
(key columns 77/159/241, rows 393/475/557/639, caption 731, say 285, dots 331,
back/lock 47 ±2) still passes **with** the shared keypad grid in place, so the
`5_ui` deviation is genuinely closed and not just re-measured once.

## 3. Gates

```
dart format --set-exit-if-changed --output=none test/features/kid_home lib/features/kid_home
Formatted 36 files (0 changed) in 0.21 seconds.

flutter analyze
Analyzing app...
No issues found! (ran in 4.0s)

flutter test test/features/kid_home/kid_pin_view_test.dart
00:18 +54: All tests passed!

flutter test test/features/kid_home/k02_bugs_test.dart
00:03 +30 ~1: All tests passed!          (was: hang)

flutter test test/features/kid_home
00:13 +435 ~2: All tests passed!

flutter test                                   (whole app)
01:12 +2990 ~3: All tests passed!
```

The `~3` skips are the parked bug proofs (`K02-BUG-5` in this feature,
`K01-BUG-7` in the sibling K01 loop) plus the sibling P12 park — no skip was
added by this stage. Whole-suite wall clock is now 1 min 12 s, of which the
previously hanging file was an unbounded slice.

## 4. Bugs

### Found by this stage — 1 (not on K02's screen, but in its feature)

**K02-TEST-BUG-A — major — the K02-BUG-1 crash class is still live on K01
and K03.**

* `app/lib/features/kid_home/presentation/widgets/profile_tile.dart:96` —
  `child.nickname[0].toUpperCase()` in the K01 profile tile.
* `app/lib/features/kid_home/presentation/views/kid_home_view.dart:364` —
  `nickname[0].toUpperCase()` in the K03 kid home.
* Mechanism: `[0]` slices UTF-16 code units, so a nickname whose first
  character is non-BMP (emoji, CJK extension, regional-indicator flag) yields
  an unpaired surrogate and the frame fails to build with
  `ArgumentError: Invalid argument(s): string is not well-formed UTF-16` while
  laying out the avatar initial. K02's own site is fixed
  (`kid_pin_view.dart:158`, `String.fromCharCode(nickname.runes.first)`).
* Repro (verified this stage, then the probe was deleted — rerun it as a
  one-off, it needs no fixture beyond the demo seed):

  ```dart
  // app/test/features/kid_home/<probe>.dart
  await tester.runAsync(() async {
    final db = GetIt.instance<AppDatabase>();
    await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
      ChildrenCompanion(nickname: const Value('\u{1F41D} Bee')),
    );
    await GetIt.instance<AppSession>().refresh();
  });
  await tester.pumpWidget(const NestlingApp(initialRoute: '/who-is-playing'));
  await tester.pump(); await tester.pump(const Duration(milliseconds: 200));
  debugPrint('${tester.takeException()}');   // => Invalid argument(s): string is not well-formed UTF-16
  ```

  Measured: `/who-is-playing` renders 2 tiles and throws; `/kid-home` renders
  1 avatar and throws the same. P05 accepts any non-empty nickname ≤ 24 chars
  with no character filter, so this is reachable by a parent, not a synthetic
  state.
* **Why it is not patched here:** both files belong to sibling screen loops in
  the *same* feature (K01 and K03), and RULES §3 forbids two agents editing one
  feature in parallel; my brief also says to record, not patch. It is already
  filed as `docs/screens/K02/SHARED_REQUEST.md` **#3** (seven sites, four
  features) — what this stage adds is the *proof* that two of those sites are
  live today, which the request had only inferred. The shared fix
  (`String nestAvatarInitial(String)` in `core/design_system/` + a design-system
  test) is `core/**`, i.e. orchestrator-owned.

### Verified fixed this iteration (regression proofs run un-skipped)

K02-BUG-1 (rune-safe initial — plus the flag / astral-math / composed probes),
K02-BUG-2 (`maxLines: 3`), K02-BUG-3 (post-frame re-check), K02-BUG-4
(`hideCurrentSnackBar`), review #2 (4th digit reverted when the child is null),
review #4 (`_BottomInset`) and the ORCHESTRATOR_NOTES 07:13 keypad pitch — all
green, the last one now also pinned at unit level by my design-anchor test.

### Still open, tracked elsewhere (no action for this stage)

`K02-BUG-5` (no-PIN latch never released when its navigation is declined) stays
parked in `k02_bugs_test.dart`; `SHARED_REQUEST` #1 (`NestType.kidSay` /
`kidMark`) and #3 (the grapheme-safe initial helper) stay open with the
orchestrator.

## 5. Notes for the next iteration

1. **The harness rule that caused the hang, written down:** in a
   `testWidgets`, a cycle that only calls `disposeApp()` leaves
   `AppSession`'s Drift watch pending in the fake-async queue, and the *next*
   `await tester.runAsync(…)` blocks on it forever. Always finish a cycle with
   `await setUpTestScope()` (re-seed the DB, re-apply the state you need inside
   `runAsync`) before pumping again. Two shapes are known-good and used here:
   one pump per test, or a loop of *complete* cycles
   (`_insetProbes`, `useLongName`).
2. **`find.bySemanticsLabel` needs a `RegExp` for the dots and the toast** —
   those nodes merge into the screen's text node, so an exact-string lookup
   reports `findsNothing` even though the label is present.
3. **Keypad pitch is now pinned at unit level** (design-anchor test) *and*
   pixel-verified by 5_ui; if the shared grid is ever touched again, that test
   is the canary.
4. **Every K02 test file finishes in seconds.** If any run exceeds ~60 s, treat
   it as the same class of bug the orchestrator flagged, not as slowness.

VERDICT: FAIL
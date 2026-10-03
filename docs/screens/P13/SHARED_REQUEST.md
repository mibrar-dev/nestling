# Shared request — P13 `pumpAppRoute` surface size is hard-coded

> **Three requests on this page.** #1 is from iteration 1, still open and
> non-blocking. #2 was filed in iteration 2 about a single test.
> **#3 (iteration 4) supersedes #2: the same clock-vs-calendar defect now
> fails 35 tests across 5 features, and it will fail again every midnight.**
> Fix #3 and #2 resolves itself.

## #1 — `pumpAppRoute` surface size is hard-coded

Need: `test/test_scope.dart::pumpAppRoute` (line 34) sets
`tester.view.physicalSize = const Size(390 * 3, 844 * 3)` unconditionally, so any
size a test sets *before* calling it is silently overwritten and the first frame
is always 390×844. Every screen's "320 px" / "430 px" / "short screen" case that
goes through this helper therefore passes while running at 390 — responsive
coverage that cannot fail. Give the helper an optional `size` (and optionally
`textScale`) parameter defaulting to the current behaviour:

```dart
Future<void> pumpAppRoute(
  WidgetTester tester,
  String route, {
  ThemeMode theme = ThemeMode.light,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async { ... }
```

Files: `app/test/test_scope.dart` (one helper signature, no behaviour change for
existing callers).

Blocks: **no** — P13 already works around it. `payout_responsive_test.dart` and
`p13_bugs_test.dart` pump `NestlingApp` directly with their own
`tester.view.physicalSize`, so their 320/390/430 and 320×568 probes are real.
Only the two `payout_view_test.dart` cases named below still silently run at
390; each now carries a `HARNESS TRAP` comment above it saying so.

Confirmed affected P13 cases (both currently execute at 390×844, not what their
names claim):

- `payout_view_test.dart` — `320 px at text scale 1.3 overflows nothing`
- `payout_view_test.dart` — `a short screen scrolls the sheet instead of
  overflowing`

Same trap exists for P12's `money_ledger_responsive_test.dart` and other
features; a shared fix repairs all of them at once.

---

## #2 — `family_time_test.dart` fails after 20:00 UTC (wall-clock fragile)

**Found by:** P13 stage 3, iteration 2. This is what turned the whole-repo
`flutter test` red; the P13 feature suite is green.

**Symptom.** `test/core/family_time_test.dart:319`
`Bad state: Too many elements` (`List.single`):

```
seed + repository zone plumbing kid_home completions are stamped with the
family zone
00:00 +18 -1
```

**Repro.** Run after 20:00 UTC on any day:

```bash
cd app && flutter test test/core/family_time_test.dart
```

It passed earlier the same evening and fails now — the trigger is the clock,
not a code change.

**Root cause (verified against source).**

1. `lib/core/data/seed.dart:392` seeds a `to_do` completion for
   `['q-plants', 'leo', '10']` stamped `utc(10, 3, 6)` — 2026-10-03T06:00Z,
   intended as "today".
2. `family_time_test.dart:314-319` calls `Seed.movedToDubai(db)` and then
   `completeQuest('leo', 'q-plants')`, then expects
   `leoRows.single`.
3. `KidHomeRepositoryImpl.completeQuest`
   (`lib/features/kid_home/data/kid_home_repository_impl.dart:145-182`) only
   **updates** the seeded row when
   `countsForCurrentPeriod(quest.repeatRule, c.createdAt, now, zone)` is true;
   otherwise it **inserts a second row**.
4. `now` there is the real wall clock (`DateTime.now().toUtc()`), *not* the
   `Seed.anchorOverride` that `test/flutter_test_config.dart` pins. Once real
   UTC passes 20:00, the Dubai day has already rolled to the next date, the
   seeded 06:00Z row is "yesterday" under the new zone, a second row is
   inserted, and `.single` throws.

Measured on the machine at the time of this run: `UTC 2026-10-03 21:10`,
`Dubai 2026-10-04 01:10`.

**Files.** `app/test/core/family_time_test.dart` (and/or
`app/lib/core/data/seed.dart`). Both are shared and outside RULES §1, so P13
may not edit them.

**Suggested fix (either is fine).**
- Assert with `first`/`last` or filter to the row the call created instead of
  `.single`, e.g.
  `expect(leoRows.where((r) => r.status == 'done_pending'), hasLength(1))`; or
- pick a quest the seed leaves with **no** completion row (the test only needs
  a quest to complete, not a pre-seeded `to_do` one); or
- make `completeQuest`'s period test use the same pinned clock the seed uses,
  which is the real fix — a repository whose period logic reads the wall clock
  cannot be tested deterministically after 20:00 UTC.

Blocks: **yes for the repo-wide gate** — `flutter test` is red for every screen
loop until this is fixed, even though no screen is at fault. P13's own suite
(`flutter test test/features/pocket_money`) is green.

---

## #3 — the pinned seed date now drifts from the wall clock: 35 tests fail (SUPERSEDES #2)

**Found by:** P13 stage 3, iteration 4. **This is #2's root cause, but the
blast radius is 35 tests across 5 features instead of 1.** Fixing the one test
named in #2 will not make the gate green.

## Current state (iteration 4, 4 Oct 2026)

`test/flutter_test_config.dart:9` pins the whole suite to a fixed calendar day:

```dart
Seed.anchorOverride = DateTime.utc(2026, 10, 3);
```

Every seeded completion is therefore stamped **3 Oct 2026**, while the period
rule (`countsForCurrentPeriod`) — the orchestrator's own mandatory PERIODS
ruling — evaluates against the **real** `DateTime.now()`. The moment the real
clock passes midnight in the family's zone the two disagree, and every
period-sensitive test in the repo reclassifies its seeded rows as out-of-period.

Measured during this stage: `UTC 2026-10-03 23:22`, `London 2026-10-04 00:22`.

## Failures (stable across 4 consecutive full runs; zero in `pocket_money`)

| File | Failures |
|---|---|
| `features/kid_home/kid_home_view_test.dart` | 20 — `Expected "4 of 6 done", Found 0 widgets` |
| `features/kid_home/k03_bugs_test.dart` | 8 — a completion finds `0` in-period rows |
| `features/approvals/approvals_view_states_test.dart` | 3 |
| `features/today/p08_bugs_test.dart` | 2 — `P08-B11` gets `approved`, expected `to_do` |
| `features/approvals/approvals_view_test.dart` | 1 |
| `core/family_time_test.dart` | 1 — #2 above |

`p08_bugs_test.dart:414` states its own cause in the assertion message:
*"yesterday's daily completion is outside **today's** London day"*. The fixture
is relative to the real clock; the seed anchor is a fixed date. They cannot both
hold.

## Why this is not a one-day blip

This recurs **every midnight** and in **every timezone** whose day differs from
UTC at the moment of the run. #2 (Dubai, 20:00 UTC) was the first visible
symptom of the same defect. Nothing about it is specific to P13.

## Suggested fix

The durable fix is to stop mixing a fixed calendar date with a live clock:

1. **Inject the clock.** Make `countsForCurrentPeriod` / the repository layer
   take a `now` parameter (defaulting to `DateTime.now()`), and have
   `test/flutter_test_config.dart` pass `Seed.anchorDay`. Then tests are
   deterministic forever and the pin stops being a calendar date that expires.
2. **Or** derive the pin from the anchor instead of hard-coding it —
   `Seed.anchorOverride = Seed.anchorDay` — so the fixture and the rule always
   agree, whatever day it runs.
3. **Or** as a stop-gap: bump the pinned date whenever the real day rolls over.
   This is the option that keeps breaking, and it needs a human every midnight.

Option 1 or 2 repairs #2 and #3 together.

Files: `app/test/flutter_test_config.dart`, `app/lib/core/data/london_time.dart`,
`app/lib/core/data/seed.dart`, and the date fixtures in the five feature test
files above.

Blocks: **yes for the repo-wide gate** — 35 failures, every screen loop, and it
recurs daily. P13's own suite (`flutter test test/features/pocket_money`) is
green at +461.

## Note on the 23:55 exemption

`ORCHESTRATOR_NOTES.md` (23:55) exempts the `family_time_test` failure **"if it
is the ONLY failing test in the full suite"**. It is not — there are 35, and they
appeared after that note was written. The condition is not met, so I have not
treated the gate as green.

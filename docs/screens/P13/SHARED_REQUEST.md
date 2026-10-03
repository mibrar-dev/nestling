# Shared request — P13 `pumpAppRoute` surface size is hard-coded

> **Two requests on this page.** #1 is from iteration 1 and is still open.
> #2 was filed in iteration 2 and is **breaking `flutter test` for every
> screen loop** — see the bottom of the file.

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

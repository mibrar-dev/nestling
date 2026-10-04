# test_clock — one pinned clock for the app in tests

Pin `today` in the app to the seed's story day (Sat 3 Oct 2026 09:41 London =
08:41Z) so `flutter test` is green on any real date. Main was red with 34
failures (P08 period scoping, P11 "Today 8:12am", K03 matrix/navigation):
`app/test/flutter_test_config.dart` pinned `Seed.anchorOverride = 2026-10-03`
but app code read `DateTime.now()` directly, and the real London date rolled
to 4 Oct.

## Files changed

| File | Change |
|---|---|
| `app/pubspec.yaml` (+ lock) | `clock: ^1.1.1` direct (was transitive 1.1.3); `fake_async: ^1.3.1` dev (for the proof test). |
| `app/lib/core/data/app_clock.dart` | NEW. `appNowUtc()`: pinned `08:41Z` on `Seed.anchorOverride`'s day in tests, else `clock.now().toUtc()`. Single app-wide "now"; uses `package:clock`. |
| `app/lib/core/data/seed.dart` | `DateTime.now()` → `clock.now()` (anchorDay fallback, empty-trial stamp). Import `package:clock/clock.dart`. |
| `app/lib/core/data/app_session.dart` | Default clock `DateTime.now` → `appNowUtc` (i.e. `clock.now`, pinned on anchor in tests). Explicit `clock:` params win. |
| `app/lib/core/data/family_zone_service.dart` | `DateTime.now()` → `appNowUtc()`. |
| `app/lib/features/today/data/today_repository_impl.dart` | Default `_defaultClock` `Seed.anchorOverride ?? DateTime.now()` → `appNowUtc()`. |
| `app/lib/features/today/presentation/bloc/today_bloc.dart` | Greeting/dateLine `now` → `appNowUtc()`. |
| `app/lib/features/kid_home/data/kid_home_repository_impl.dart` (2) | Period-scoping + `completeQuest` stamps → `appNowUtc()`. |
| `app/lib/features/pocket_money/data/pocket_money_repository_impl.dart` (5) | `setMode`/`setPayoutDay`/`addMoney`/`recordSpending`/`recordPayout` stamps → `appNowUtc()`. |
| `app/lib/features/approvals/data/approvals_repository_impl.dart` (2) | `approve`/`markNotYet` stamps → `appNowUtc()`. |
| `app/lib/features/approvals/presentation/widgets/approval_card.dart` | `nowUtc ?? DateTime.now()` → `nowUtc ?? appNowUtc()`. |
| `app/lib/features/pocket_money/presentation/views/money_ledger_view.dart` | `payoutLabel(nowUtc: DateTime.now())` → `appNowUtc()`. |
| `app/lib/features/family/data/family_repository_impl.dart` (3) | `createdAt` → `appNowUtc()`; `child-`/`coparent-` IDs → `clock.now()` (uniqueness, still `package:clock`). |
| `app/lib/features/rewards/data/rewards_repository_impl.dart` (1) | `reward-` ID → `clock.now()`. |
| `app/lib/features/settings/...`, `kid_jar/...`, `kid_shop/...`, `parental_gate/...`, `paywall/...` | Stamps → `appNowUtc()`. |
| `app/test/flutter_test_config.dart` | `withClock(Clock.fixed(2026-10-03T08:41Z))` around `testMain`, keeps `anchorOverride = 2026-10-03`. |
| `app/test/core/pinned_clock_test.dart` | NEW. Proof tests (see below). |
| `app/test/features/{today,pocket_money,paywall,kid_home}/**` (10 files) | `DateTime.now().toUtc()` → `appNowUtc()` + import (period/day-start/`before`/`nowUtc` expectations now use the pinned clock, not the wall clock). No placeholder-text assertions touched; router-location/key assertions unchanged. |
| `docs/screens/RULES.md` | §9 pinned-clock rule (exact line from the task). |

Zero `DateTime.now()` calls remain in `app/lib` (grep `DateTime\.now\b` finds only a comment in `app_clock.dart`). No other behaviour changed; production (no anchor) is exactly `clock.now()`.

## What / why

Root cause: seed pinned to 3 Oct, app read the wall clock (4 Oct London).
Fix: every app `now` goes through `package:clock` (`clock.now()` directly for
IDs, `appNowUtc()` — which is `clock.now()` outside tests — for everything
else), and tests pin the pair (anchor 3 Oct + 08:41Z).

Zone note (probe 2026-10-04, kept in the proof test header): `withClock`
around `testMain` covers registration only — `test`/`testWidgets` bodies run
later in fresh zones, so bare `clock.now()` in a body reads the real clock
(`FakeAsync` is built at `runTest` time from it). Real determinism is
`Seed.anchorOverride` (global) via `appNowUtc`; the outer `withClock` is kept
per the task and explicit `withClock` *inside* a body (or `FakeAsync`
created inside one) does pin — proved. Explicit per-test clocks (`AppSession
(clock: …)`, DST tests with literal instants) are untouched and win.

## Tests added (`app/test/core/pinned_clock_test.dart`)

- `seed anchor is pinned to Sat 3 Oct 2026`
- `appNowUtc is the pinned instant while the anchor is set`
- `explicit withClock pins clock.now in a plain test`
- `FakeAsync reads the zone clock (package:fake_async uses clock)` — starts at the zone clock, advances with `elapse`
- `app time is pinned inside testWidgets (seed story day)` — `appNowUtc()` pinned; inner `withClock` pins `clock.now()` (`Clock.fixed` stays fixed across `pump`; advancing proved in the plain `fakeAsync` test)

## Verification

- `cd app && dart format .` → `486 files (0 changed)` clean.
- `flutter analyze` → `No issues found!` (no new ignores).
- `flutter test` (full, real London 4 Oct) → `+2422 ~1: All tests passed!` (0 failures; was 34, then 12 mid-fix).
- Oct-5 probe (fixed clock `2026-10-05T08:41Z` + anchor `2026-10-05`, proof test patched to match): **~50+ failures** (weekday labels flip Sat→Mon, weekly periods roll to the Mon-5-Oct week, e.g. `today Maya 4 of 6`, Dubai straddle, P08/K03 matrices). Restored to Oct 3 → green again. This is expected: outcomes depend only on the pinned pair (real wall clock Oct 4 is irrelevant), and the story is written for Sat 3 Oct — any other pair is a different story, not a supported pin.

## Follow-up for screens

Nothing required: no shared API/schema/seed/router/design-system change.
Feature-test edits above are clock-only (`DateTime.now()` → `appNowUtc()`);
merging them keeps every screen green. New rule: never add `DateTime.now()`
to app code (use `clock.now()`/`appNowUtc()`); never assert wall-clock-derived
copy in tests — derive expectations from `appNowUtc()`/anchor.

VERDICT: PASS

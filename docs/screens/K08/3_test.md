# K08 · Reward shop — stage 3 test (iteration 1)

Scope: tests only. `app/test/features/kid_shop/**` — no `lib/` file was read
into a change, no screen code was patched (three bugs are recorded below and
proved, not fixed). No simulator was booted, installed on, driven or
screenshotted; no `flutter clean`; `analysis_options` untouched.

Starting point: stage 2 left 53 tests (15 bloc + 7 repository + 20 view +
11 geometry), all green. This stage ends with **141** tests: **135 green, 6
failing** — every failure is an intentional, un-skipped bug proof for one of
the three open defects in `6_bugs.md`.

| file | before | after | added |
|---|---|---|---|
| `kid_shop_bloc_test.dart` | 15 | 34 | 19 |
| `kid_shop_repository_test.dart` | 7 | 16 | 9 |
| `reward_shop_view_test.dart` | 20 | 66 | 46 |
| `reward_shop_widget_geometry_test.dart` | 11 | 18 | 7 |
| `k08_bugs_test.dart` (bug proofs) | — | 7 | 7 |

## Tests added

### `kid_shop_bloc_test.dart` — every event and state path

New plumbing: `_FakeKidShopRepository` gained a controllable broadcast
stream (`controlled`, `push`, `finishLive`, `liveCancels`) and a `writeDelay`,
plus a `_Harness` that records **every** state from the first emission
(recording, not `expectLater(bloc.stream, …)`, because the bloc stream is a
broadcast stream: a subscriber that attaches after an event has fired silently
misses it — three of my first drafts were wrong for exactly that reason).

- **load**: a live emission replaces child, coins and every affordability
  (Maya 120 → Leo 45, creation order preserved); a stream error *after* a
  healthy load keeps `errorMessage` and the last known coins; `close()`
  releases the shop subscription exactly once and drops late emissions (no
  leaked watcher, no state after close).
- **requests**: five guard paths (unaffordable, unknown id, before load,
  duplicate, after failure) now assert the **repository is never written**,
  not just that no state was emitted — a guard that dropped the state but still
  spent coins would be worse than no guard; two different ids both write while
  one is in flight (the guard is per id, never global); two identical
  requests produce two distinct notices (`noticeSeq` 1 then 2).
- **pending-notice lifetime**: an unshown toast survives a coin emission
  mid-toast; a stream switch between two requests keeps the first toast and
  blocks the second (Leo's 45 coins cannot buy the 90-coin dinner);
  `KidShopNoticeShown` with nothing pending emits nothing.
- **double tap** (the one that needed real async): with a fake whose
  `requestReward` takes 20 ms, two same-batch `KidShopRewardRequested` events
  produce **one** write and one toast; the per-id independence is proved
  alongside so a `droppable()`-style fix cannot regress it.
- **state value semantics**: fresh-state defaults, `isLoaded`, `copyWith`
  field preservation, `==` between equal states, and `requestingIds` being an
  independent copy per state.

### `kid_shop_repository_test.dart` — the stream contract against Drift

New `_ShopEmissions` queue (a local stand-in for `package:async`'s
`StreamQueue`, which is not a declared dependency) whose `next()` fails fast
instead of hanging. New: a local `keepOnlyRewards`/`addReward`/`setCoins`/
`setActiveChild` toolbox.

- **live re-emission** — the `_switchMap` behaviour `1_plan.md` §(b) exists
  for, all six mutations landing *after* the subscription is live: an
  active-child switch, a balance change (every card flips to unaffordable), a
  reward added later (lands at the END of the list, not by price), an instant
  reward streaming the new balance straight back, a needs-OK request leaving
  the displayed shop untouched, and a write to the switched-away child
  producing no stale emission.
- **legacy `watchShop`** (the shared `repositories_test.dart` entry point)
  returns the same creation-ordered items.
- **`Seed.empty`** at the repository level: no rewards, no active child, coins
  0.
- `requestReward`: two calls write two rows (the write-per-request behaviour
  underneath the bloc guard), unknown id is a no-op.

### `reward_shop_view_test.dart` — the screen

- **full width × scale × theme matrix**: 320 / 390 / 430 × 1.0 / 1.3 × light /
  dark (12 pumps) — no overflow, columns follow `(W − 40 − 16) / 2`, gutters
  stay 20 / 16, and the reward names stay clamped to two lines. The empty and
  failure surfaces get the same treatment at 320 / 1.3 and 430 / 1.3.
- **data-driven states**, all through the real Drift database and never a
  hard-coded design number: an instant purchase moves the pill, the footer and
  all six affordabilities; a needs-OK purchase changes none of them but writes
  a `requested` row; the toast copy for both cases; the toast is announced
  through the notice **sequence** (a second identical purchase replaces the
  toast, it never stacks); Leo's shop (45 coins) shows six `Save up!` cards,
  `5 more to go` on the cheapest, and Leo's footer — switched live, which is
  the flow the repository test mirrors; a family with no rewards gets the
  empty state with no stale pill or footer.
- **states**: `Try again` really reloads and brings the six cards back (a
  fail-once fake, previously only the copy was asserted); a stalled reload
  keeps the chrome usable and still reaches the parental gate.
- **navigation**: back from `/reward-shop` → `/kid-home`; **back POPS** when
  the shop was pushed from the K03 dock (the `canPop()` branch, reached the way
  a child reaches it); the lock opens `/parental-gate`; a same-frame double
  tap on the lock opens exactly one gate (one back press comes home);
  a same-frame double tap on Back leaves once; the list scrolls far enough to
  reach the footer and the last row.
- **accessibility**: every card button reads as a button; the coin pill is a
  reading with no tap action; a VoiceOver tap on the disabled card changes
  nothing in the database; a same-frame double tap on one card writes **one**
  redemption; two different cards both write, once each.
- **tap targets**: back and lock are exactly 56 × 56 and every card action is
  ≥ 56 × 56 at 390/1.0 and 320/1.3; the card action's hit area is the painted
  56, never larger (a tap 5 px under it, in the card's bottom padding, hits
  nothing).
- **data edges** (previously separate probes): 0 coins → six `Save up!`,
  pill 0, `150 more to go`; one child → six cards, pill 120; 9999 coins at
  320/1.3 → no overflow; a very long reward title → two-line ellipsis with the
  card still on its 132 px column; a 2.0 system text scale renders **identically
  to 1.3** (proving `app.dart`'s clamp rather than asserting the copy of it);
  leaving mid-request → no throw and the write still lands.

### `reward_shop_widget_geometry_test.dart` — design arithmetic, real fonts

Kept in its own file because it loads the bundled Nunito/Inter faces. Added:
the ALIGNMENT owner rule as a reusable check (back left, card left, intro
edges at the 20 px gutter; lock, pill and last card at `width − 20`) run at
320 / 390 / 430; the column arithmetic at all three widths; the card-internal
offsets measured **relative to the card top** (name box at +95, 56 px art disc
at +41) so they hold on a device where the balanced heading wraps and the whole
rhythm moves down; and the 56 × 56 chrome targets at 320 px.

## Results

```
dart format .        Formatted 556 files (0 changed)
flutter analyze      No issues found! (ran in 3.0s)
```

Feature suite:

```
flutter test --timeout 120s test/features/kid_shop/kid_shop_bloc_test.dart                 +34: All tests passed
flutter test --timeout 120s test/features/kid_shop/kid_shop_repository_test.dart           +16: All tests passed
flutter test --timeout 120s test/features/kid_shop/reward_shop_view_test.dart              +66: All tests passed
flutter test --timeout 120s test/features/kid_shop/reward_shop_widget_geometry_test.dart   +18: All tests passed
flutter test --timeout 120s test/features/kid_shop/k08_bugs_test.dart            +1 -6: Some tests failed (the proofs)
```

Whole app (clean unbuffered run):

```
01:21 +3526 ~4 -8: Some tests failed.
```

- **6** are this stage's bug proofs (below).
- **2** are the pre-existing `kid_home_view_test.dart` failures already filed in
  `SHARED_REQUEST.md` (`K03 navigation dock Shop opens /reward-shop`,
  `K03 accessibility actions … every dock button exposes a tap action and
  routes` — both assert the foundation placeholder's copy `K08 Reward shop`,
  which the real build replaced with the design's `Reward shop`). Untouched
  here: `test/features/kid_home/**` belongs to another feature (RULES §1).
- `~4` skips are the expected shared-code skips.

Rule audit on the result: no `google_fonts` / `GoogleFonts` anywhere in the
feature's tests; no `DateTime.now()` (the clock is pinned by
`test/flutter_test_config.dart`, and the only clock the screen touches is
`requestReward`'s `createdAt`); every pumped app ends with `disposeApp`; no
simulator touched; no file outside RULES §1 modified except the new
`k08_bugs_test.dart` and `docs/screens/K08/**`.

## Bugs found (recorded, not patched)

### K08-BUG-1 — major, money integrity: an `approved` redemption can be written without payment

`app/lib/features/kid_shop/data/kid_shop_repository_impl.dart:79-106`
(`requestReward` / `_spendCoins`, guard at line 102). Independently reproduced
by this stage (it is also `6_bugs.md` K08-BUG-1; the proofs there were left
`skip:`-ped, mine are not).

Repro A — repository, deterministic:
1. `Seed.demo`; set `r-screen.needs_ok = false` so two rewards are instant.
2. `requestReward('maya', 'r-baking')` → coins 120 → 20.
3. `requestReward('maya', 'r-screen')` → the 50-coin price is **not** covered,
   yet the row still lands `approved`.
4. Observed: `approved` reward value **150**, coins actually spent **100**
   (`Expected: a value less than or equal to <100>`, `Actual: <150>`).

Repro B — end-to-end through the screen:
1. Same DB tweak; open `/reward-shop`; tap `Get it` on "30 min extra screen
   time" (50) and on "Baking together" (100) in one frame. Both cards are
   individually affordable at 120, and both taps land before the stream has
   rebuilt the grid.
2. Observed: both rows `approved`, coins 120 → 70, approved value 150
   (`Expected: <= 50`, `Actual: 150`). Which card ends up free depends on the
   transaction order; the invariant breaks either way.

Why it matters: the child receives rewards the balance never paid for. The
write happens **before** the balance check, and `_spendCoins` silently returns
when the balance is short, so the `approved` row survives an un-paid write.

Suggested fix (feature-owned, no shared change needed): mirror P14's
`RewardsRepositoryImpl.approveRedemption` (`app/lib/features/rewards/data/
rewards_repository_impl.dart:113-131`), which reads the child row, refuses
when `kid == null || kid.coins < reward.coinPrice`, and only then writes
`approved` **and** deducts inside one transaction. For K08, do the read inside
the same transaction and either write `requested` instead (a grown-up decides)
or throw, so the bloc's existing failure toast fires and no unpaid `approved`
row is left behind. A per-child serialization of `KidShopRewardRequested` in
the bloc would improve the feedback, but the data layer is where the invariant
has to be restored.

### K08-BUG-2 — major, the screen breaks: any odd reward count crashes the grid

`app/lib/features/kid_shop/presentation/views/reward_shop_view.dart:354`
(`_ShopGrid`'s odd-trailing-cell filler), with the `Expanded` at line 356.

```dart
final right = i + 1 < items.length
    ? _cardFor(items[i + 1], bloc)
    : const Spacer();          // Spacer IS an Expanded
Expanded(child: right),        // Expanded(child: Expanded(…)) → competing ParentDataWidgets
```

Repro: `Seed.demo`, delete one reward (5 cards) — or keep only `r-screen`
(1 card) — and open `/reward-shop`. Observed:
`FlutterError: Incorrect use of ParentDataWidget. Competing ParentDataWidgets
… SizedBox.shrink ← Expanded ← Spacer ← Expanded ← Row ← IntrinsicHeight ←
Column ← _ShopGrid`. The grid does not lay out at all.

Why the demo hides it: the seed has exactly six rewards, so every design
screenshot, the whole-app UI check and all six non-bug geometry tests pin an
even count. Any family that deletes one reward loses the shop.

Fix: the trailing slot is already inside an `Expanded`, so the placeholder has
to be inert — `const SizedBox.shrink()`, which is exactly what `1_plan.md` §(a)
specified ("second `Expanded` with `SizedBox.shrink`").

### K08-BUG-3 — minor, accessibility: the card price is announced with no unit

`app/lib/features/kid_shop/presentation/widgets/shop_reward_card.dart:189-217`
(`_ShopPrice`). The coin `SvgPicture` is `ExcludeSemantics`d and the number
`Text('$price')` carries no label, so VoiceOver/TalkBack reads "50" with no
unit, while `NestCoinPill` (the same price elsewhere in the app) announces
"120 coins".

Repro: `tester.ensureSemantics()`, open `/reward-shop` with the demo seed, move
to "30 min extra screen time": announced "30 min extra screen time, **50**, Get
30 min extra screen time"; expected "…, **50 coins**, …"
(`find.bySemanticsLabel('50 coins')` finds 0 candidates).

Fix: wrap the row in `Semantics(label: '$price coins')` with the children
excluded, mirroring `nest_coin_pill.dart:64`. The "N more to go" note already
reads as a sentence and needs no change.

### Cleared, not a bug: the `requestingIds` double-tap guard

Worth recording because it looked like a bug and was not. A first proof
(`two requests queued in one batch reach the repository twice`) failed with
`Actual: ['r-screen', 'r-screen']`, which reads exactly like K08-BUG-1's
family. It is an artefact of the fake: `_onRewardRequested` reads the guard
from the *emitted* state, so it holds only while the write is genuinely in
flight, and a fake whose `requestReward` completes in one microtask finishes
before the second event is handled. Measured, with the same two events queued
in one block:

| `requestReward` | repository writes |
|---|---|
| completes in one microtask (the old fake) | 2 |
| takes 30 ms (a Drift transaction does) | **1** |

End to end through the real database, a same-frame double tap on one card
writes exactly one `reward_redemptions` row — pinned as a passing regression
test in `reward_shop_view_test.dart` ("a fast double tap on one card writes one
redemption") and at bloc level in `kid_shop_bloc_test.dart` ("a double tap is
swallowed while the write is still in flight"). Both kinds of fake are now
available (`writeDelay`), so the next iteration cannot accidentally re-open
this question.

## Harness notes (not screen defects)

1. **`Seed.empty` cannot be pumped through the full app.** `Seed.empty` calls
   `db.clearAll()` while `AppSession` holds live watch streams on that same
   database, and the reseed never completes in a widget-test isolate (the test
   hangs until its own timeout — I hit this twice before diagnosing it). It is
   not a K08 problem: `watchActiveShop` on a reseeded database emits
   `maya:0:0` in milliseconds (proved without the app in
   `kid_shop_repository_test.dart`, "on an empty family"). The empty-state
   surface is therefore driven through a fake repository, and the `Seed.empty`
   coverage lives at the repository level.
2. **Drift writes need `tester.runAsync`.** A `db.update(...)` awaited inside
   `testWidgets` runs in the fake-async zone, where Drift's deferred stream
   notifications never fire and the shop sits on its spinner forever. Every
   DB-driven widget test here writes through `tester.runAsync` (plus one
   real-zone turn) and then pumps. Live-switch assertions run after the pump,
   which is also the real user flow (the K01 picker).
3. **`pumpAndSettle` never meets a K08 loading state.** `_ShopLoading` is a
   `CircularProgressIndicator`, which animates forever, so `pumpAndSettle`
   spins until its own timeout. The stalled-stream tests use explicit pumps.
4. **`k08_bugs_test.dart` was rewritten.** The bug-hunt stage (6) had written
   the same path with five `skip:` markers so its suite stayed green, and the
   loop forbids skipping tests. This stage replaced it with an un-skipped
   proof for all three documented bugs, and re-proved the "verified clean"
   probes as ordinary green tests in `reward_shop_view_test.dart` (double tap,
   one child, no rewards, 0 coins, 9999 coins at 320/1.3, long title, 2.0 scale
   clamp, leave mid-request, back double tap) so that coverage survives the
   rewrite. No `skip:` marker exists anywhere in `test/features/kid_shop/`.
5. **ORCHESTRATOR_NOTES (15:08)** — reward icons move to a shared
   `rewardIconFor(audience: kid)` map. No test action this stage: the icon map
   is `lib/` code with no behaviour to assert beyond "each seeded icon renders
   a glyph", and the build stage owns the swap. When it lands, add one assertion
   that the six seeded icon keys still resolve (the fallback must stay
   `gift`).

## Left for the next iteration

1. **Blocker**: K08-BUG-1 (money integrity) — fix in
   `kid_shop_repository_impl.dart` per the P14 pattern, then the two proofs go
   green. Until then `flutter test` is red.
2. **Blocker**: K08-BUG-2 — `const Spacer()` → `const SizedBox.shrink()` in
   `_ShopGrid`; the three proofs go green and the odd-count geometry can then
   be pinned (left column, full 167/132/187 width, row height 216).
3. K08-BUG-3 — one `Semantics(label: '$price coins')` in `_ShopPrice`.
4. The `SHARED_REQUEST.md` blocker from stage 2 (two `kid_home_view_test.dart`
   lines asserting the placeholder's copy) is still the only thing keeping the
   suite red outside this feature.

VERDICT: FAIL
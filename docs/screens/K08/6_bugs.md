# K08 Reward shop — bug hunt (Stage 6, iteration 1)

Adversarial pass over `kid_shop` / `/reward-shop` after the iteration-1 build:
data edges (0/1/6 children, long UK names, 0 and 9999 coins, empty lists),
rapid double taps, back navigation and deep links, restart persistence,
parent/kid mode guards, dark mode, 320 px + 1.3 text scale, async gaps,
Europe/London/BST, integer coins, owner rules (PIP / bottom edge / alignment /
child order / copy / fonts / letter spacing / balanced headings), accessibility
actions and the ±2 px UI rule. No screen code was changed in this stage. No
simulator was booted, installed on or driven (only `5_ui` may use
E7D5555E-378A-49DF-AAEE-16677AF4B9DB).

- Suite: `app/test/features/kid_shop/k08_bugs_test.dart` — 18 tests:
  13 run green, 5 skipped (three open bugs: two major, one minor; five proofs).
- Run the green suite:
  `cd app && flutter test --timeout 120s test/features/kid_shop/k08_bugs_test.dart`
- Run the proofs (they fail on the current code, on purpose):
  `cd app && flutter test --run-skipped --timeout 120s --plain-name K08-BUG-1 test/features/kid_shop/k08_bugs_test.dart`
  `cd app && flutter test --run-skipped --timeout 120s --plain-name K08-BUG-2 test/features/kid_shop/k08_bugs_test.dart`
  `cd app && flutter test --run-skipped --timeout 120s --plain-name K08-BUG-3 test/features/kid_shop/k08_bugs_test.dart`

## Open bugs

### K08-BUG-1 — An `approved` redemption can be written without payment (Major, money integrity)

**Severity: Major.** The child can receive a reward the coin balance never paid
for; the invariant “coins spent == value of approved redemptions” is violated.
`KidShopBloc` guards only the *same* card while its own write is in flight
(`requestingIds`, `kid_shop_bloc.dart:84`); it does not guard a second card
tapped inside the same in-flight window, and the repository never re-validates
the balance before writing `approved`.

Root cause — `app/lib/features/kid_shop/data/kid_shop_repository_impl.dart:79-106`:

```dart
await _db.transaction(() async {
  await _db.into(_db.rewardRedemptions).insert(      // approved row FIRST
    RewardRedemptionsCompanion.insert(status: Value(status), ...));
  if (!reward.needsOk) {
    await _spendCoins(childId, reward.coinPrice, now); // silently no-ops
  }
});
...
Future<void> _spendCoins(...) async {
  ...
  if (kid == null || kid.coins < coins) return;      // line 102: no deduction,
  ...                                                // row stays approved
}
```

Repro A (deterministic, repository):
1. `Seed.demo`, set `r-screen.needsOk = false` (so both rewards are instant).
2. `requestReward('maya', 'r-baking')` → 120 − 100 = 20 coins.
3. `requestReward('maya', 'r-screen')` → 50 is not covered, but the row lands
   `approved` anyway.
4. Observed: spent 100, approved value 150 (baking + screen time). The
   “Baking together” / “30 min extra screen time” pair costs 150 of 120.

Repro B (end-to-end, kid):
1. Same DB tweak; open `/reward-shop`.
2. Tap “Get 30 min extra screen time” and “Get Baking together” in one frame —
   both taps land before the stream has rebuilt the grid, exactly like a kid
   mashing two buttons.
3. Observed: only the first-paid reward is deducted (spent 50 in the captured
   run), both rows are `approved`; the second reward is free. (Which reward is
   free depends on the transaction order; the invariant fails either way.)

Failing tests (skipped so the suite stays green):
- `K08-BUG-1 money integrity two instant rewards cannot both be approved beyond the balance`
  (plain test; `Expected: <150>, Actual: <100>`).
- `K08-BUG-1 money integrity tapping two instant cards in one frame cannot overspend`
  (`Expected: <150>, Actual: <50>` plus the same invariant reason).

Suggested fix (data layer first, then UX):
1. Make payment a precondition of the `approved` row, inside the single
   transaction: read the child row, and if `kid == null || kid.coins < price`
   either (a) throw a typed `InsufficientCoins` so the bloc's existing failure
   toast (“Hmm, that did not work. Try again.”) fires and no row is written, or
   (b) write the row as `requested` for a grown-up decision. Only deduct + write
   `approved` when the balance covers the price. `RewardsRepositoryImpl
   .approveRedemption` already does the check-before-write (`_
   rewards_repository_impl.dart:124`) and is the model to mirror.
2. Optionally serialize `KidShopRewardRequested` in the bloc per child, or
   subtract the in-flight rewards' prices from affordability, so the second tap
   is refused before the repo is called. The data-layer fix alone restores the
   invariant; the bloc change only improves the feedback.

### K08-BUG-2 — Any odd reward count crashes the grid (Major, screen breaks)

**Severity: Major.** With 1, 3, 5, … rewards the whole two-column grid throws at
layout; a family with one reward, or five after one deletion, cannot use the
shop (debug builds show the error box; the tests record the FlutterError).

Root cause — `app/lib/features/kid_shop/presentation/views/reward_shop_view.dart:352-362`:

```dart
final right = i + 1 < items.length
    ? _cardFor(items[i + 1], bloc)
    : const Spacer();          // Spacer IS an Expanded
...
Expanded(child: right),        // Expanded(child: Expanded(...)) → competing
                               // ParentDataWidgets on the same render object
```

Repro:
1. `Seed.demo`, delete one reward (`r-dinner` → five items) — or keep only
   `r-screen` (one item).
2. Open `/reward-shop`.
3. Observed: `FlutterError: Incorrect use of ParentDataWidget. Competing
   ParentDataWidgets are providing parent data to the same RenderObject …
   SizedBox.shrink ← Expanded ← Spacer ← Expanded ← Row ← IntrinsicHeight ←
   Column ← _ShopGrid`. The grid does not lay out.

Failing tests (skipped so the suite stays green):
- `K08-BUG-2 odd reward counts a single reward renders one full card, no phantom column`
- `K08-BUG-2 odd reward counts an odd reward count renders the trailing card at column 1`

Suggested fix: the odd trailing slot is already wrapped in `Expanded`, so the
placeholder must be inert — `: const SizedBox.shrink()`. This is exactly what
`1_plan.md` §(a) specified (“second Expanded with SizedBox.shrink”); the build
used `Spacer` instead. The demo seed's six rewards hide the bug: every
non-skipped geometry test pins an even count.

### K08-BUG-3 — The card price is announced as a bare number (Minor, a11y)

**Severity: Minor.** The price row excludes the coin icon from semantics and
leaves `Text('$price')` unlabelled, so VoiceOver/TalkBack reads “50” — no unit
— while every coin pill on the app announces “N coins”
(`nest_coin_pill.dart:64`). Also recorded by the stage-4 review (finding 1).

Root cause — `app/lib/features/kid_shop/presentation/widgets/shop_reward_card.dart:189-217`:
the `SvgPicture(coin)` is `ExcludeSemantics`d and the number `Text` has no
wrapping `Semantics(label: '$price coins')`.

Repro:
1. Enable a screen reader (or `tester.ensureSemantics()`); open `/reward-shop`
   with the demo seed.
2. Move to the “30 min extra screen time” card.
3. Observed: “30 min extra screen time, 50, Get 30 min extra screen time”.
   Expected: “30 min extra screen time, 50 coins, Get 30 min extra screen time”.

Failing test (skipped so the suite stays green):
- `K08-BUG-3 price accessibility the card price is announced with its unit`
  (`find.bySemanticsLabel('50 coins')` finds nothing; the node label is `50`).

Suggested fix: wrap the price row in
`Semantics(label: '$price coins')` and keep the row’s children excluded (or
pass `excludeSemantics: true`), mirroring `NestCoinPill`. The “N more to go”
note already reads as a sentence and needs no change.

## Verified clean this iteration (new probes, all green)

| Category | Probe | Result |
|---|---|---|
| rapid double tap, same card | two taps in one frame → exactly one redemption, one deduction (120 → 20) | pass |
| data edge: 1 child | delete Leo → 6 cards, pill 120 intact | pass |
| data edge: 6 children + long UK name | 5 extra rows incl. “Maximilian-Alexander” → roster size never changes whose shop is open | pass |
| data edge: 0 coins | all six cards “Save up!”, no tap action, pill 0 | pass |
| data edge: 0 children | children deleted, rewards left → chrome intact, no crash (see observation 1) | pass |
| data edge: no rewards | kid-voice empty state + back/lock present, no actions invented | pass |
| data edge: 9999 coins @ 320 px / 1.3 | pill fits, no overflow/exception | pass |
| text overflow: long reward title @ 320 px / 1.3 | two-line ellipsis, no overflow | pass |
| text scale 2.0 | shell clamps to 1.3, no overflow | pass |
| dark mode | whole shop renders, no exception | pass |
| async gap: leave mid-request | bloc disposes while the write is in flight → no throw, write recorded | pass |
| restart (Drift persistence) | buy “Baking together”, re-open the app → 20 coins + “130 more to go” | pass |
| back navigation | double-tap Back in one frame → one `/kid-home`, no throw | pass |
| copy / fonts / letter spacing | no GoogleFonts, no tracking added, copy matches the HTML (é in café) | pass (existing tests) |
| accessibility actions | every control exposes tap; Save up! stays `enabled:false`; taps drive the DB | pass (existing tests) |

## Observations (verified, not defects)

1. **0 children / deleted active child**: `watchActiveShop` falls back to the
   literal `'maya'` (`kid_shop_repository_impl.dart:26`), so a family with no
   children still gets a shop for a child who no longer exists (coins 0, all
   “Save up!”). This is the repo-wide convention (`kid_jar`, `pip`,
   `pocket_money`, `badges` all do `activeChildId ?? 'maya'`), the chrome stays
   intact and no write is reachable (P14 enforces min price 5, so no 0-price
   reward can exist). Product-level question, not a K08 defect.
2. **Parent-mode deep link `/reward-shop`** renders the kid screen (only
   parent-only routes are guarded from kid mode, not the reverse). Same
   product-level question as K03's note 3.
3. **Pluralisation**: at 1 coin the footer and pill announce “1 coins”
   (app-wide “N coins” convention, e.g. P08's summary line). Cosmetic; not
   filed.
4. **£0.00 / £999.99 / rounding**: N/A — K08 is a coins-only screen and never
   formats £ or does pence math (integer coins throughout).
5. **Europe/London / BST**: K08 shows no dates or times; the only clock use is
   `requestReward`'s `createdAt = appNowUtc()` + `createdAtTz = familyZoneId()`
   (UTC instant + zone id, no wall-clock copy). Nothing to break at a DST
   boundary.
6. **`.k8-get.off`**: the unaffordable “Save up!” button still renders through
   the `NestKidButtonColor.white` + `Opacity(0.45)` fallback, not the design's
   flat `surface-2`/`ink-2`. This is the already-filed, non-blocking
   `SHARED_REQUEST.md` item — not a new finding.
7. **Stale “success” toast for a reward deleted between emission and tap** is
   unreachable on a single-device app (parent and kid modes are exclusive);
   defensive robustness only.

## Summary

| ID | Severity | Status |
|---|---|---|
| K08-BUG-1 | **Major (money integrity)** | **open — approved redemption unpaid; 2 skipped proofs** |
| K08-BUG-2 | **Major (screen breaks on odd counts)** | **open — `Expanded(child: Spacer())`; 2 skipped proofs** |
| K08-BUG-3 | Minor (a11y) | open — price announced without its unit; 1 skipped proof |

Two major defects in the data and layout layers; the screen cannot pass this
stage until they are fixed. The minor a11y item is recorded with a proof for
the next iteration. Everything else the hunt touched is clean.

VERDICT: FAIL

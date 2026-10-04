# K08 · Reward shop — stage 3 test (iteration 2)

Scope: tests only. `app/test/features/kid_shop/**` — no `lib/` file was
modified, no screen code was patched (two open defects are recorded below and
proved). No simulator was booted, installed on, driven or screenshotted; no
`flutter clean`; `analysis_options` untouched; no `skip:` marker anywhere in the
feature.

Iteration 1 ended at 141 K08 tests with 6 failing proofs for K08-BUG-1 … -3.
The iteration-2 builders fixed all three and landed the shared audience glyph
maps, so this stage starts from **143 green**, and ends at **164 tests: 160
green, 4 failing** — every failure an intentional, un-skipped proof of one of
the two OPEN defects.

| file | iter 1 | iter 2 | added this iteration |
|---|---|---|---|
| `kid_shop_bloc_test.dart` | 34 | 34 | — (all paths already covered) |
| `kid_shop_repository_test.dart` | 16 | 18 | +2 |
| `reward_shop_view_test.dart` | 66 | 67 | +1 (by the 2b builder) |
| `reward_shop_widget_geometry_test.dart` | 18 | 24 | +6 |
| `shop_reward_icons_test.dart` | — | 7 | +7 (new file) |
| `shop_reward_a11y_test.dart` | — | 7 | +7 (new file, 4 green / 3 proofs) |
| `k08_bugs_test.dart` | 7 | 7 | re-scoped (1 → 6 green) |

## What changed on `main` since iteration 1, and what it made testable

- **K08-BUG-1 fixed** — `requestReward` now makes payment a precondition of the
  `approved` row inside the single transaction (`kid_shop_repository_impl.dart:
  78-118`), mirroring P14's `approveRedemption`. An uncovered instant reward
  (or a missing child row) lands `requested`.
- **K08-BUG-2 fixed** — the odd grid filler is `const SizedBox.shrink()`.
- **K08-BUG-3 fixed** — the card price is `Semantics(label: '$price coins',
  container: true, excludeSemantics: true)`.
- **`ORCHESTRATOR_NOTES.md` 14:31 + 15:08 discharged** — the shared
  `rewardIconFor(key, audience:)` maps are on `main` and K08 forwards to the
  **kid** branch. The new ICONS rule ("kid screens use
  `rewardIconFor(audience: NestAudience.kid)`; each screen matches its own
  design's glyphs exactly") is now mandatory, and `shop_reward_icons_test.dart`
  makes it mechanical instead of an eyeball check.
- **`NestKidButton` gained a `trailing` slot** (K06's use). Null here, so the
  `.k8-get` box is byte-identical; the existing 62-tall widget box assertions
  (56 painted + 6 shadow room) still hold, which is the regression proof.

## Tests added

### `shop_reward_icons_test.dart` (new, 7 green) — the audience glyph rule

Pins ART fidelity exactly, because the stage-4 UI check had to catch the
baking chef's hat and the café sit-down mug **by eye**:

- every seeded `rewards.icon` key resolves to its exact `.k8-art` asset
  (`ic_reward_tv` / `_film` / `_moon` / `_cake` / `_coffee` / `_plate`);
- `shopRewardIcon(key) == rewardIconFor(key, audience: NestAudience.kid)` for
  all six, so the screen cannot fork the map — only the audience may differ;
- **no** seeded key resolves to the PARENT glyph (`screenTime`, `film`,
  `clock`, `chefHat`, `rewardCoffeeParent`), which is the assertion that would
  have caught the iteration-1 mix-ups without a screenshot. `plate` is the one
  key both designs share, and that is stated;
- an unknown key (a reward created on another device) falls back to
  `NestIcons.gift` at the map level, on a rendered card, and end-to-end
  (a seventh row is inserted into the database and its disc still paints);
- the rendered cards: six `NestIcon`s in creation order, each 32 px and tinted
  (`.k8-art` is a 32 px glyph in a 56 disc), proved through the real app with
  the real repository.

### `shop_reward_a11y_test.dart` (new, 4 green + 3 proofs) — per-card semantics

Green (the shape the fixes produced): each price is **its own node** ("50
coins") with no tap action; each card button is its own node labelled after
the reward, with `isButton` and a tap action — except the out-of-reach café,
which correctly reports no action; no single announcement mixes a price and a
button (the reason `container: true` is load-bearing); the heading and the
balance are announced together in the head row and the pill is not a control.

Failing (K08-BUG-5, below): the reward **names** are not individually
announced.

### `reward_shop_widget_geometry_test.dart` (+6) — the promise iteration 1 made

Iteration 1 said the odd-count geometry could be pinned "once the filler is
legal". It is, so it is now pinned at **390 and 320** for 5, 3 and 1 cards:
the lone card keeps the left 20 px gutter, its full column width
(`(W − 40 − 16) / 2` → 167 / 132) and its own height (216, or 240 when the
café's "N more to go" note is on it); the row pitch is measured from two real
rows rather than assumed, because a narrow device moves the whole rhythm down
when the balanced heading wraps; and the cards above still share their rows.

### `kid_shop_repository_test.dart` (+1) — the branch the fix added

`an instant reward for a child with no row is left requested`: with the
`watchActiveShop` `'maya'` fallback, a deleted child still reaches the new
`kid == null` branch, and nothing may be granted or deducted. (The
balance-short branch already had 2a's regression test.)

### `k08_bugs_test.dart` — re-scoped, and the `skip:` removed

K08-BUG-1 … -3 are fixed, so their iteration-1 proofs now run GREEN and stay
as the regressions that keep them fixed. The iteration-2 bug stage had marked
its new K08-BUG-4 proof `skip: true` "so the suite stays green"; **the loop
forbids skipped tests**, so the marker is gone and the proof runs — it fails,
which is the point.

## Results

```
dart format .        Formatted 582 files (0 changed)
flutter analyze      No issues found! (ran in 3.4s)
```

Feature suite (per file):

```
kid_shop_bloc_test.dart                       +34: All tests passed
kid_shop_repository_test.dart                 +18: All tests passed
reward_shop_view_test.dart                    +67: All tests passed
reward_shop_widget_geometry_test.dart         +24: All tests passed
shop_reward_icons_test.dart                    +7: All tests passed
shop_reward_a11y_test.dart                     +4 -3: Some tests failed (proofs)
k08_bugs_test.dart                             +6 -1: Some tests failed (proof)
                                              ─────────
                                              160 green, 4 failing
```

Whole app (clean unbuffered run):

```
01:34 +3782 ~4 -6: Some tests failed.
```

- **4** are this stage's proofs for the two open defects below.
- **2** are the `kid_home_view_test.dart` placeholder-copy assertions still
  filed in `SHARED_REQUEST.md` (third iteration of the same blocker; that file
  belongs to another feature per RULES §1).

Rule audit: no `google_fonts` / `GoogleFonts`; no `DateTime.now()`; every
pumped app ends with `disposeApp`; no ids minted; clock pinned by
`test/flutter_test_config.dart`; no simulator touched; no `skip:` in
`test/features/kid_shop/**`; no file outside RULES §1 modified (only the
feature's test directory and `docs/screens/K08/**`).

## Bugs found (recorded, not patched)

### K08-BUG-4 — minor, honesty: "It’s yours — enjoy!" for a reward that was not granted

**Found independently by this stage, by the iteration-2 review (finding 1) and
by the iteration-2 bug hunt — same defect, three times.** Root cause:
`app/lib/features/kid_shop/presentation/bloc/kid_shop_bloc.dart:89-105` — the
notice is chosen from `item.needsOk`, captured **before**
`await _repository.requestReward(...)`, while `requestReward` may now write
`requested` instead of `approved`.

Repro (deterministic, two instant cards, one frame):
1. `Seed.demo`; set `r_screen.needs_ok = false` so two rewards are instant.
2. Open `/reward-shop`; tap `Get it` on "30 min extra screen time" (50) and on
   "Baking together" (100) in one frame. Both are individually affordable at
   120.
3. Observed: `r-screen:approved`, `r-baking:requested`, coins 120 → 70 — and the
   toast still reads **"It’s yours — enjoy!"** for the baking card that is
   waiting for a grown-up and was never paid for.

Why it matters: the toast is the child's only feedback for that tap. The design
has no "waiting for approval" copy for an instant card, so the app promises a
reward it has not given and a deduction it has not made.

Suggested fix (both inside RULES §1, feature-owned): have `requestReward`
return the status it actually wrote (`'approved' | 'requested'`) and map that in
`_onRewardRequested` — `approved` → enjoy copy, `requested` → thumbs-up copy.
The review adds a nicer variant for a balance refusal ("Not quite enough coins
yet — keep saving!"), which would need one more status or an exception. A
thinner alternative: re-read the item's affordability from the state after the
write instead of trusting the captured `needsOk`.

### K08-BUG-5 — minor, accessibility (NEW this iteration): every reward name merges into one announcement

Root cause: `app/lib/features/kid_shop/presentation/widgets/shop_reward_card.dart`
— the name `Text(item.title)` (around line 113) has no semantics container, and
`ShopRewardCard`'s `Column` provides no boundary, so the grid's `Column` in
`reward_shop_view.dart` absorbs all six names into a single node.

Observed tree (`/reward-shop`, demo seed, `ensureSemantics`):

```
label="Reward shop\n120 coins"
label="Spend your coins on things you actually want."
label="30 min extra screen time\nPick Friday film\nStay up 15 min later\n"
      "Baking together\nTrip to the park café\n30 more to go\nChoose dinner"
  label="50 coins"                        <- its own node (K08-BUG-3's fix)
  label="Get 30 min extra screen time"
  label="80 coins"
  label="Get Pick Friday film"
  …
```

Repro: enable a screen reader (or `tester.ensureSemantics()`), open
`/reward-shop`, swipe once. VoiceOver/TalkBack reads all six rewards — plus the
café's note — as one item, then the six prices and six buttons separately, so
the name can no longer be tied to its own price or action.

Why it matters: the card's own doc-comment says the name and price "carry the
meaning", and DESIGN_SPEC §5 K08 pairs each name with its price. After the
iteration-2 fix made the price its own node, the name is the only part of a
card left without one.

Suggested fix: give the name its own node the same way the price now has one —
`Semantics(container: true, child: Text(...))` on the `.k8-n` row (or
`MergeSemantics` per card, which would read name + price + action as one run
per card). Either satisfies the three proofs, which only require that no
announcement names two different rewards.

Not filed as a duplicate: K08-BUG-3 (iteration 1) was the price's missing
unit, and `6_bugs.md` iteration 2 lists exactly that; this is the name's missing
node, a different defect in the same card.

## Cleared again this iteration

- **The `requestingIds` double-tap guard** still holds end to end: the same-frame
  double tap on one card writes exactly one redemption, and two *different*
  needs-OK cards both write (so a `droppable()`-style fix for K08-BUG-4 cannot
  swallow the second card). Both stay pinned in `reward_shop_view_test.dart`.
- **`Seed.empty`** is still only reachable at the repository level: `Seed.empty`
  calls `db.clearAll()` while `AppSession` holds live watch streams, and the
  reseed never completes in a widget-test isolate. Not a screen defect; the
  empty-state surface is driven through a fake and the `Seed.empty` contract is
  covered at the repository level.
- **Drift writes need `tester.runAsync`** (fake-async swallows Drift's deferred
  notifications) and **`pumpAndSettle` never meets the kid loading spinner**.
  Both traps are commented at the tests that hit them.

## Process note

The iteration-2 bug stage and the UI stage were running **concurrently** with
this stage in this worktree: `k08_bugs_test.dart` and `6_bugs.md` changed under
me mid-stage, and I independently wrote a K08-BUG-4 proof at the same time.
Resolved without clobbering their work: my duplicate group was removed, their
proof kept as the single authoritative one, and their `skip: true` removed so
the loop's no-skipped-tests rule holds. The K08-BUG-5 proofs live in
`shop_reward_a11y_test.dart` rather than in `k08_bugs_test.dart` precisely so a
concurrent editor of that file cannot lose them; they are cross-referenced
here and in this file's header. Nothing else of theirs was touched.

## Left for the next iteration

1. **K08-BUG-4** — return the written status from `requestReward` and map it to
   the toast in `_onRewardRequested`; the proof in `k08_bugs_test.dart` goes
   green.
2. **K08-BUG-5** — give `.k8-n` its own semantics node (or `MergeSemantics` per
   card); the three proofs in `shop_reward_a11y_test.dart` go green.
3. `SHARED_REQUEST.md` §1 (`.k8-get.off` muted colourway) is still open and
   still non-blocking; the "Save up!" card keeps the documented
   `NestKidButtonColor.white` + `Opacity(0.45)` deviation until the design
   system adds the variant.
4. `SHARED_REQUEST.md` §2 (the two `kid_home_view_test.dart` lines) is the only
   thing keeping the whole-app suite red outside this feature.

VERDICT: FAIL
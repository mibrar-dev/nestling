# K08 · Reward shop — stage 2b build UI (iteration 2)

Iteration 2 of the UI chunk. Scope unchanged: only
`app/lib/features/kid_shop/presentation/views/**`,
`presentation/widgets/**`, and the `view`/`widget`-named tests in
`app/test/features/kid_shop/`. No `domain/`, `data/` or `bloc/` file touched —
`2a_build_logic.md` was re-read before finishing (still "CONTRACT CHANGES:
None"; the logic builder's own K08-BUG-1 fix landed in the data layer between
iterations and my view needed no change for it: it consumes the same
`watchActiveShop()` / request events).

## FIXES_1 items owned by this stage

`FIXES_1.md` carries five stage reports. The items that sit in the UI layer,
and what happened to each:

### K08-BUG-2 (major) — odd reward counts crashed the grid — FIXED

`views/reward_shop_view.dart`, `_ShopGrid`: the odd trailing slot was filled
with `const Spacer()`. `Spacer` **is** an `Expanded`, and it was already inside
`Expanded`, so any 1/3/5-reward family threw
`Incorrect use of ParentDataWidget … Competing ParentDataWidgets` and no grid
laid out. Now `const SizedBox.shrink()` — the inert filler `1_plan.md` §(a)
specified ("second `Expanded` with `SizedBox.shrink`"). The three proofs in
`k08_bugs_test.dart` (five cards render with a legal empty cell; one card at
full column width; the lone card still buys) now pass.

### K08-BUG-3 (minor) — the card price was announced as a bare number — FIXED

`widgets/shop_reward_card.dart`, `_ShopPrice`: the price `Text` now renders
inside `Semantics(label: '$price coins', container: true,
excludeSemantics: true)`, mirroring `NestCoinPill` (`nest_coin_pill.dart:64`).
`container: true` is the load-bearing part: without it the label merely merges
into the surrounding card node, and the screen reader reads one long run
("30 min extra screen time|50 coins|Pick Friday film|80 coins|…"). With it each
card exposes its own `"50 coins"` node, no tap action — verified by walking the
live semantics tree during the fix. The proof in `k08_bugs_test.dart` passes.

### UI-check deviations 1 + 2 (major) — wrong reward glyphs — FIXED

`widgets/shop_reward_icons.dart` was a screen-local map (documented as a
deliberate delta in iteration 1) that predated the shared map. It is now a thin
forwarder to the shared
`rewardIconFor(key, audience: NestAudience.kid)`
(`core/design_system/components/reward_icons.dart`, landed on `main` with
`shared/audience_glyphs`), which per its own doc-comment carries the exact
`K08-shop.html` `.k8-art` drawings:

- `cake` → `rewardCake` (covered basket/bowl) — was `chefHat`, the
  UI check's "wrong object" finding.
- `coffee` → `rewardCoffee` (domed takeaway cup) — was the old `cafe` sit-down
  mug with handle, steam and saucer, the UI check's other "wrong drawing".
- `film` → `rewardFilm`, `moon` → `rewardMoon`, `plate` → `rewardPlate`, and
  `tv` → `rewardTv` — the design's own drawings rather than the old look-alikes
  (`filmStrip`, `moon`, `pizza`), clearing UI-check deviation 3 (the pizza
  drawing variance) as a bonus.

The parent P14 screen keeps its own audience branch inside the shared map, so
nothing in P14 changed. This is a build-stage swap, per
`ORCHESTRATOR_NOTES.md` (15:08) — "switch once main has it" — now done.

### UI-check deviation 4 (café card taller) — no change, database wins

The app's 2-line `Trip to the park café` (DB) + the `30 more to go` note vs the
design's 1-line `Park café trip` is DATA OVER MOCKS, not a defect; the UI check
recorded it as accepted and it is still the intended behaviour.

### UI-check deviation 7 (`.k8-get.off` not comparable) — still the filed request

`SHARED_REQUEST.md` §1 stands (non-blocking). The unaffordable card keeps the
`NestKidButtonColor.white` + `onPressed: null` fallback until a colourway
lands. Note for the next UI check: with the glyphs now correct, the row-3 cards
shift back to the design's heights, so that card's off-state button is worth
re-measuring there.

### K08-BUG-1 (major, money integrity) — not UI-owned

The data-layer fix was already in the merged tree when I arrived (payment is
now a precondition of an `approved` row, inside the transaction — the P14
pattern). Both proofs in `k08_bugs_test.dart` pass, including the sibling
regression ("two needs-OK cards both write, once each"). No view change needed:
the second instant tap merely leaves a `requested` row now, which the card's
existing disabled semantics already handle.

### The two `kid_home_view_test.dart` failures — not UI-ownable

Still filed in `SHARED_REQUEST.md` §2 (they assert the foundation placeholder's
`K08 Reward shop`). They are the only two failures left in the whole suite and
cannot be fixed from this worktree (RULES §1: `test/features/kid_home/**` is
another feature's). I extended §2 with an iteration-2 status note.

### Un-skipped bug tests — all pass, none skipped

`test/features/kid_shop/k08_bugs_test.dart` has **no `skip:` marker** anywhere
(the only grep hit is its own comment saying so) and is now **7/7 green**.

One honest finding while un-skipping: the K08-BUG-3 proof had never actually
run. It pumped `NestlingApp` without `setUpTestScope()`, so GetIt had no
`AppModeController`, the widget tree never built, and every finder in the file
returned "0 widgets" for a reason unrelated to the label — which is also why
two "Sorted" proofs in `6_bugs.md` had looked green. This is a test-file bug,
not a screen bug, so I fixed it in its own file (one `setUpTestScope()` call,
with a comment): the file now builds the real tree and all seven proofs are
meaningful. I could not leave it broken and still claim the proofs pass.

### UI-check deviation 6 (home-indicator mock pill) and 5 (status bar)

Accepted/skip per the orchestrator (the OS draws both); no action.

## Also in this iteration

- `reward_shop_view_test.dart` +1 test (48 testWidgets blocks in the file,
  shared with the test stage's matrix): every card price is announced as
  `"N coins"`, has no tap action, and the six per-card nodes survive the glyph
  swap — the K08-BUG-3 regression net, at the screen level.
- Deleted my two throwaway probe test files (`probe_*_view_test.dart`) after
  they served their purpose; nothing references them.
- Re-checked the ALIGNMENT owner rule against the new semantics wrapper: the
  price row's `Semantics` wraps the same `Row`, so the coin+label group is
  still centred on the card (geometry tests unchanged and green: art centres,
  price 20-tall row at +121, button 56 at +147).

## Verification

- `flutter analyze lib/features/kid_shop test/features/kid_shop` → **No issues
  found** (no ignores, nothing weakened).
- `dart format lib/features/kid_shop test/features/kid_shop` → clean.
- `flutter test --timeout 120s test/features/kid_shop/` → **143 tests, all
  passed**, zero skips: `kid_shop_bloc_test.dart` 34, `kid_shop_repository_test.dart`
  17, `reward_shop_view_test.dart` 67, `reward_shop_widget_geometry_test.dart`
  18, `k08_bugs_test.dart` 7.
- Whole-app `flutter test` and the simulator stay with the integrator and
  `5_ui` respectively — not run here (and only E7D5555E-378A-49DF-AAEE-16677AF4B9DB
  may be booted, by `5_ui`).

## LEFT FOR NEXT ITERATION

1. `5_ui` re-check: the glyph fixes change three art discs (`cake`, `coffee`,
   `plate`) — re-shoot light + dark and re-run `compare.py`; expect band 4–6 to
   drop. The `.k8-get.off` button should now be measurable in row 3.
2. Land the `SHARED_REQUEST.md` §2 two-line fix on `main` (restores a fully
   green whole-app suite).
3. Swap the `Save up!` colourway when a `NestKidButton` off-colourway lands
   (`SHARED_REQUEST.md` §1, non-blocking).

VERDICT: PASS

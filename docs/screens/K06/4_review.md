# K06 · Pip's nest — QA code review (stage 4, iteration 4)

Scope: `git diff main...HEAD` on `screen/K06` (HEAD = `006f3ed` "K06:
checkpoint after build (iteration 4)") — 8 product files in
`app/lib/features/pip/**` (repository rewrite + `PipBuyResult`, the nest
view, five feature widgets, two deleted forks) + 14 test files in
`app/test/features/pip/**` + this directory's notes, plus one test file in
`app/test/features/kid_home/` (finding 1).

Reviewed against `docs/ARCHITECTURE.md`, `docs/screens/RULES.md`,
`docs/DESIGN_SPEC.md` §5 K06, `design/html-source/screens/K06-pip.html`,
both design PNGs, `docs/design/SPACING_SPEC.md`, `1_plan.md`, the mandatory
`ORCHESTRATOR_NOTES.md` (both rounds), and the design system in
`app/lib/core/design_system/`.

Checks run by this stage — no simulator was booted, installed on, driven or
screenshot on (only stage 5 may); no `flutter clean`, no `analysis_options`
change, no code edited, no image attached (PNGs read with the file reader):

```
flutter analyze lib test                          → No issues found!   (5.2s)
flutter test --timeout 120s test/features/pip/    → +222: All tests passed!   (0 skips)
flutter test --timeout 120s test/features/kid_home/ → +462 ~3: All tests passed!
flutter test --timeout 120s (whole app)           → +3846 ~4: All tests passed!
dart format --set-exit-if-changed lib/features/pip test/features/pip
                                                 → clean at HEAD
git diff main...HEAD -- app/lib/core app/lib/app  → empty (no shared code touched)
```

The 4 skips in the whole-app run are all outside `test/features/pip` (3 in
`kid_home`). **No blocker, no major. Carried minors + one filed
documentation item. Verdict: PASS.**

---

## Findings

### 1. minor (RULES §1 path discipline — sanctioned, needs ratification)
`app/test/features/kid_home/kid_home_view_test.dart:1990-1993` and
`:2057-2084`

The branch edits another feature's test directory, which RULES §1 puts under
"another feature's directory — NEVER edit". It replaces the placeholder-title
assertions `find.text('K06 Pip nest')` with the router location
`expect(pushedPath(tester), '/pip')` (and makes the dock loop's third tuple
field `String?` so it asserts the path only for the built destination).

This is the one deviation the branch knowingly carries, and it is filed:
`SHARED_REQUEST.md` §4 cites both shared rulings (`_shared/HEADER.md` line 6 —
"NEVER assert placeholder view texts … assert the router location
(`currentPath`) or keys instead"; `_shared/router_push_test_fix_REPORT.md`
§5) plus the `P09/SHARED_REQUEST.md` §3 precedent. No K03 behaviour is
touched and no assertion is weakened — the swap makes the K03 contract
strictly stronger (it can no longer pass against a stub that renders the old
title), which is why I keep it at minor rather than major.

**Fix (no code change needed in K06):** the orchestrator should ratify the
exception, or land the same two-hunk swap as a shared-test change on `main`
so the K03 loop and this branch never meet on those lines. Note the file is
the one merge hotspot between the K03 and K06 branches.

### 2. minor (test discipline — DATA OVER MOCKS)
`app/test/features/pip/k06_bugs_test.dart:727`

```dart
expect(await _coins(db), 85, reason: '120 - 5 feed - 30 wellies');
```

The DB-reopen proof types the wardrobe price (`30`) and the opening balance
(`120`) instead of reading them, while every other price premise in the
feature reads the seeded row — `pip_atomic_writes_test.dart:191-196` and
`pip_orchestrator_notes_test.dart:369-379` both do it explicitly, and item 3
of the orchestrator notes exists to keep prices as data. The value is correct
today (batch 7 moved the seed to the design's 30/60), so this is
brittleness, not a wrong result: the next seed decision reddens a
persistence proof that has nothing to do with prices.

**Fix:** read the row before the buy and derive the expectation, e.g.

```dart
final price = (await repo.watchNest().first)!.items
    .firstWhere((i) => i.id == 'wellies').priceCoins;
… await repo.feed('maya'); await repo.buyItem('maya', 'wellies'); …
expect(await _coins(db), 120 - PipRepository.feedCostCoins - price);
```

(Or seed the balance the same way if `120` is the half of the problem.)

### 3. minor (comment rot — stale premises that will mislead the next reader)
Three headers still narrate iteration-2/3 facts that the code has since
outlived. No functional impact; the live proofs below them are correct.

- `app/test/features/pip/pip_copy_parity_test.dart:25-27` — "the coin prices.
  `.k6-item-p` says 30/60, **the seed says 40/120**". The seed moved to 30/60
  in `shared_batch7`; the DATA OVER MOCKS paragraph is now moot.
- `app/test/features/pip/pip_orchestrator_notes_test.dart:10-11` ("the missing
  dashed stroke is stage 6's K06-BUG-6 (parked there)"), `:17-18` ("the parity
  proof below is parked … it must fail until the shared asset is fixed"),
  `:22` ("prices 30/60 in the design vs 40/120 in the app"), `:188-189` ("the
  dashed stroke is painted by a **screen-local painter** … its visibility is
  stage 6's K06-BUG-6"). All superseded: the stroke is live through the
  shared `NestDashedBorder`, the glyph proofs are green, and the seed matches
  the design. The ITERATION 3 block at `:25-37` and the sun-hat block at
  `:336-343` already say so, which makes the stale text above it actively
  confusing.
- (Harmless, kept deliberately: `k06_bugs_test.dart:319` and
  `pip_iter2_fixes_test.dart:112` name `_DashedBorderPainter` / `PipCareButton`
  while describing the *bug's* mechanism and the switch — correct as history.)

**Fix:** one-paragraph refresh of those three headers.

### 4. minor (shared doc — already filed, no runtime effect)
`docs/DESIGN_SPEC.md` §5 K06: "big Pip stage 3 (**280px**)" and "Wardrobe
strip: 4 items … as **72px** tiles". The HTML/PNG oracle is
`.k6-pet { width: 230px; height: 206px }` and four `flex: 1` tiles of
(350 − 36) / 4 = **78.5** px, which is what the screen builds and what
`5_ui.md` measured at Δ 0. Filed as `SHARED_REQUEST.md` §8; the runtime needs
no change, the prose does.

**Fix:** amend §5 K06 to 230 × 206 and 78.5 (owner: shared-spec agent).

### 5. minor (open ratification — copy the design does not define)
`app/lib/features/pip/presentation/bloc/pip_bloc.dart:11`
(`kPipNotEnoughCoins` = "Not enough coins yet — keep going!") and
`app/lib/features/pip/presentation/views/pip_nest_view.dart:425`
(`kPipNotWearable` = "That one is not something Pip can wear.")

Two user-visible strings with no counterpart in `K06-pip.html`. Both are
kind, factual, shame-free and British-spelled, and both are documented in
code comments and the stage notes; they have been awaiting orchestrator
ratification since iteration 1. The third invented string,
`'Hmm, that did not work. Try again.'`
(`pip_nest_view.dart:70`), is the repo-wide failure toast already used by
K01/K03/P14 (`rewards/presentation/widgets/p14_reward_meta.dart:143`) and
needs no ratification.

**Fix:** orchestrator ratifies both, or supplies replacement copy.

### 6. informational — measured, within tolerance: the wardrobe art circles
`app/lib/features/pip/presentation/widgets/pip_wardrobe_tile.dart:73, 89-99`

By construction the four tiles' *content* insets differ by the price row's
height: `.k6-item-p.on` ("Owned") is a 14 px line box (`height: 1` at 14 px)
while `.k6-item-p` with the 16 px coin art is 16 px, so the owned column
stacks 92 px of content into the 100 px its padding leaves and
`mainAxisAlignment: center` splits the 8 px of slack 4/4 — art-circle top
≈ 12 px below the tile edge for the owned tiles against 11 px for the locked
tiles (which reserve the 3 px dashed band in padding). The design's inset is
11 px for all four. Δ ≈ 1 px, inside the ±2 px UI verdict tolerance and far
below the owner ALIGNMENT rule's "a few px", so this is not a finding — but
`5_ui.md` never measured the art-circle inset (only the tile rects and
heights), and the existing art-circle proof
(`pip_nest_widget_test.dart:331-335`) compares the *left* inset, which is
centre-insensitive and therefore blind to this.

**Fix (UI stage, optional):** add `art.top - tile.top` to the art-circle
alignment proof so the 1 px stays pinned.

---

## Verified clean

### Architecture, DI/routes, domain shape
- Feature-first throughout; the diff adds no layer, service, use-case or fake
  data source. `presentation/{views,widgets,bloc}`, `domain/entities` +
  `domain/pip_repository.dart`, `data/pip_repository_impl.dart` — the
  ARCHITECTURE per-feature contract exactly.
- **Domain is entities + abstract repository only.** `PipBuyResult` and the
  two care-cost constants live inline on the abstract
  `PipRepository` (`pip_repository.dart:6-18, 67-71`), which the review's own
  iteration-3 finding #3 asked for; the presentation copy helper
  `pipStageName()` has left `domain/` for
  `presentation/widgets/pip_look.dart:18-25`. The view no longer names any
  `data/` file.
- One bloc per feature; `pip_di.dart` and `pip_routes.dart` are **untouched**
  vs `main` (verified: the diff for both files is empty), the bloc is a
  `get_it` factory, and each route wraps `BlocProvider(create: … ..add(
  PipLoadRequested()))` (`pip_routes.dart:29-34`).
- BLoC discipline: no reload-event re-add for refresh (`_onLoadRequested`
  guards on the live subscription, `pip_bloc.dart:34-51`, the K03-BUG-15
  pattern); the subscription is released on error and on `close()`
  (`:151-156`).

### Design-system usage — the mandatory 13:52 switch is complete
- All five batch-7 items adopted and the local forks deleted:
  `NestKidButton(trailing:)` for the care row (`pip_nest_view.dart:491-567`),
  `NestPetStage` with the documented K06 args — `nestWidth 230`,
  `nestHeight 206`, `fixedPipHeight 134`, `slotHeight 206`, `pipBottom 81`,
  `nestFit: BoxFit.contain`, `showGlow/GroundShadow false`
  (`:327-345`) — and `NestDashedBorder` for the locked tile
  (`pip_wardrobe_tile.dart:157-159`). `grep -r "PipCareButton\|PipNestSlot\|
  _DashedBorderPainter"` over `lib/features/pip/presentation/` is empty;
  `pip_care_button.dart` and `pip_nest_slot.dart` are deleted.
- Token hygiene: no `Color(0x…)`, no off-token literal sizes, no raw font
  families (`grep` clean over the feature). Sizes that CSS states directly and
  the 4 pt scale does not carry come from named constants
  (`kPipWardrobeArtSize 52`, `kPipWardrobeIconSize 30`,
  `kPipWardrobeTileHeight 116`, `kPipGrowthAvatarSize 30`,
  `kPipCoinIconSize 16`) or `NestSpacing.gap*`; the two heading overrides
  (`20/26` for `.k6-sec`, `18/24 w900` for `.k6-grow-top strong`) are
  `NestType.kidName(...)`/`NestType.h3(...)` `.copyWith(...)` at the call
  site, never a new type.
- `NestBalancedText` on the `.kid-title` heading (the BALANCED HEADINGS
  rule), `NestProgress` for `.progress.kid`, `NestIconButton` for the
  transparent `.nav-back.lg`, `NestLockButton` for `.lock-btn.lg`,
  `KidScope` for the sky gradient + meadow (no local hill anywhere), and
  `NestStatusBar` used as a height reserve only.
- No `google_fonts`/`GoogleFonts`, no `letterSpacing` added anywhere in the
  feature, no `Wrap`/`Row` of `NestChip` (the screen has no chip row),
  no `DateTime.now()`, no `newId` (the screen writes no rows), no
  `name[0]`, no `TODO`, no `debugPrint`, no `ignore:`.

### DESIGN_SPEC §5 K06 + orchestrator rules
- Every element is present in design order: back, Grown-ups lock, title,
  pet slot, growth card, three care buttons, section heading, four wardrobe
  tiles, caption. I read the design PNG and the app PNG side by side: same
  structure, same 20 px gutters, meadow to the physical edge, home
  indicator over it, no bottom bar (BOTTOM EDGE rule vacuously satisfied).
- **PIP rule:** the child's own `PipAvatar` everywhere — the nest slot
  (`pip_nest_view.dart:329-334`) and the growth card's next-stage preview
  (`:354-360`), both built from `PipProfile.style/skin/accessory/stage`
  through `pip_look.dart`. No v1 `pip_stage_*.svg` in the product path; the
  only v1 asset is `nest.svg` inside the shared `NestPetStage`.
- **Glyphs are the design's bytes** (the item that was a major in
  iterations 2-3). I read the SVG assets and compared them with the HTML
  inline paths myself: `ic_kid_feed.svg` =
  `M3 11h18a9 9 0 0 1-18 0Z` + `M12 11V5` + `M9 5a3 3 0 0 1 6 0`,
  `ic_kid_play.svg` = `<circle cx=12 cy=12 r=9>` +
  `M5 7.5c4 1 7 3.5 8 7.5M19 7.5c-4 1-7 3.5-8 7.5`,
  `ic_bubbles.svg` = the design's three circles,
  `ic_wardrobe_sun_hat.svg` = `M3 16h18l-1.6 2.4H4.6z` +
  `M7 16a5 5 0 0 1 10 0z` — all four match the design verbatim, and the
  live byte proofs in `pip_orchestrator_notes_test.dart` /
  `pip_care_glyphs_test.dart` now read their oracle from the HTML at test
  time. No `skip:` remains anywhere in `test/features/pip`.
- **COPY** byte-exact: `Pip · Fledgling` (U+00B7), `Pip's wardrobe` with the
  source's literal ASCII 0x27 apostrophe (not U+2019 — the copy-parity proof
  pins `codeUnitAt(3) == 0x27`), `Nothing here is a chore — it is all just
  for fun.` (U+2014), `Growing into a Songbird`, `175 coins` / `250 to grow`,
  `Feed`+5 / `Play`+`Free` / `Bath`+3, `Scarf` / `Sun hat` / `Wellies` /
  `Crown`. UK spelling audit clean; no `£` on this screen (coins only).
- **Locked style** (orchestrator item 1): `--surface-2` card, 3 px dashed
  `--ink-2` stroke painted as a `foregroundPainter` over the opaque fill,
  `--surface` art circle, no shadow — the design CSS exactly
  (`pip_wardrobe_tile.dart:74-88`, `pip_orchestrator_notes_test.dart`
  item 1 group). **Prices** (item 3): rendered from
  `PipStage.priceCoins`, never a literal; the seed now mirrors the design.
- **Data over mocks:** `totalCoins/evolveAtCoins` → `PipNest.growthFraction`
  → bar + the two captions; `coins` → Feed/Bath affordability; wardrobe
  order and names from the repository's explicit
  `scarf/sunhat/wellies/crown` map (never alphabetical).
- **Clock/ids** rules hold (no `DateTime.now()`, no clock-derived ids).

### Accessibility
- Every control exposes `SemanticsAction.tap` on a node that also carries
  `onTap`, per the ACCESSIBILITY ACTIONS rule: `NestIconButton` back
  (`nest_icon_button.dart:41-45` via `pip_nest_view.dart:225-240`),
  `NestLockButton` (`nest_lock_button.dart:25-28`), the three
  `NestKidButton`s (`nest_kid_button.dart:132-136`) and the four wardrobe
  tiles (`pip_wardrobe_tile.dart:161-173`, `Semantics(button: true, label:
  '<Name>, Owned' / '<Name>, <price> coins', onTap: …, excludeSemantics:
  true)`). No `excludeSemantics: true` anywhere without an `onTap` on the
  same node.
- Unaffordable Feed/Bath pass `onPressed: null`, so the shared button
  reports `enabled: false` and drops the action (RULES §8) — and the guard
  is not merely cosmetic: the repository's conditional write makes a
  zero-affordability write a silent no-op.
- Decoration is excluded from announcements so nothing is read twice
  (`PipCoinAmount`, `PipFreePill`, the inner label); the pet slot announces
  one `image` node ("Pip the Fledgling, stage 3 of 4") and the progress bar
  carries the design's own `aria-label` ("Pip is 70% of the way to
  Songbird", percentage from the DB).
- Tap targets: 56 back/lock, ≥88 care, 116-tall tiles. Fit matrix (320 and
  430 px × 1.0/1.3, both themes) is green with no overflow, and the
  `IntrinsicHeight` + `stretch` care row keeps the three columns equal at
  1.3× (K06-BUG-5).

### Performance and lifecycle
- One nest subscription for the screen, guarded against a stacked reload,
  cancelled on error and on `close()`. The load-failure path and the
  write-error path are separate, so a failed write never tears the stream
  down.
- Care and buy writes are single atomic conditional `UPDATE`s
  (`pip_repository_impl.dart:107-124`, `:138-146`) with the affordability
  test inside the statement, plus a refund path if a same-item double tap
  loses the claim race (`:150-168`): no read-modify-write, no lost charge,
  no negative balance, `happiness = min(happiness + 1, 5)`.
- No `Timer`/`AnimationController` outside the shared components; the only
  animation is `NestKidButton`'s `AnimatedContainer` through
  `NestMotion.resolve` (so `DISABLE_ANIMATIONS` still yields a still frame).
  `PipAvatar` is stateful and its `_sync`/`didUpdateWidget` only write on a
  real change, so a bloc rebuild cannot re-fire a mood one-shot. Rebuild
  scope is the screen body, which is what every sibling kid screen does.

### Error handling
- Loading, loaded, load-failure ("Oh no! Pip got lost." / "Let's try again." /
  "Try again" — the retry really re-subscribes because the error path nulls
  the subscription) and no-active-child ("Who's playing?" → the picker) all
  render inside the same chrome; the empty-wardrobe case omits the heading
  and strip but keeps the caption.
- Action outcomes ride a separate channel (`actionError` + `actionNonce`) so
  two identical refusals are still distinct states, and a refusal survives a
  sibling write's stream refresh (`copyWithLoaded` carries the pending
  outcome) — a real bug class that `PipBuyResult` now makes testable
  (`bought | cannotAfford | alreadyOwned | unavailable`, only
  `cannotAfford` toasts).

### Children's Code
- No analytics, ads, network, SDK or tracking import anywhere in the feature
  (the complete import list is in-repo only: flutter/flutter_bloc/go_router/
  get_it/drift/flutter_svg + `core/` + sibling route-constant files).
- No timers or cooldown on any choice; prices are coins, never debt-shaped;
  the refusal copy is encouraging; nothing in kid mode reaches parent
  content without the parental gate; the only child data shown is the
  active child's own.

---

## Process notes (not findings — the loop brief excludes these)

- The worktree is **not** at the committed state I reviewed: a concurrent
  stage is mid-sweep in it. `git status` shows
  `M test/features/pip/k06_bugs_test.dart` plus two untracked files,
  `test/features/pip/pip_care_glyphs_test.dart` (a genuine new proof — the
  three care glyphs byte-compared against `K06-pip.html`, closing the one
  gap `pip_orchestrator_notes_test.dart` still had) and
  `test/features/pip/zz_k06_iter4_probe_test.dart`, a self-declared
  "TEMPORARY … deleted before the stage ends" pixel probe that writes PNGs
  into a temp directory. The `zz_*` probe must not be committed (it is also
  the only reason `dart format --set-exit-if-changed` reports two changed
  files; both new files need a `dart format .` pass before they land). My
  `main...HEAD` review and every check above are against `006f3ed`, which is
  green.
- Handoff for the next `5_ui`: the committed app screenshot
  (`ui/app_light_3.png`) predates the iteration-4 glyph switch, so the Feed
  bowl, the Play seamed ball and the Sun hat need a fresh light+dark look,
  and the care row should be measured by its **painted** background rect
  (the shared `NestKidButton` adds 6 px of shadow padding below the 91 px
  card — `2b_build_ui.md` "LEFT FOR NEXT ITERATION" 1-2).
- Iteration-3 review items #1-#5 (component switch, `pipStageName` out of
  domain, view no longer naming the impl, `NestIconButton` reuse, the
  `.k6-item-p` w900 weight) are all closed and I re-verified each in the
  code above.

VERDICT: PASS
# K06 · Pip's nest — QA code review (stage 4, iteration 2)

Scope: `git diff main...HEAD` on `screen/K06` — 8 product files in
`app/lib/features/pip/**` (2 new entities/repo members, 1 bloc rewrite, 1 view
rewrite, 7 new feature widgets) + 9 test files in
`app/test/features/pip/**` + the notes in this directory. Reviewed against
`docs/ARCHITECTURE.md`, `docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5 K06,
`design/html-source/screens/K06-pip.html`, the design system in
`app/lib/core/design_system/`, `docs/screens/K06/1_plan.md` and the mandatory
`docs/screens/K06/ORCHESTRATOR_NOTES.md` (all four items).

Checks run by this stage (no simulator was booted, installed on, driven or
screenshot — stage rule; no `flutter clean`, no `analysis_options` change, no
image attached):

```
dart format --output=none --set-exit-if-changed .   → 567 files (0 changed)  exit 0
flutter analyze                                     → No issues found!
flutter test --timeout 120s test/features/pip       → +160 ~3: All tests passed!
flutter test --timeout 120s                         → +3552 ~5: All tests passed!
```

**No blocker and no major findings. 15 minor findings (5 carried from
iteration 1, 6 new, 4 informational). This stage's verdict is a PASS.**

---

## Architecture (feature-first, domain = entities + abstract repo, BLoC per screen)

1. **minor (carried, iteration 1 #2) — display copy in the domain layer.**
   `app/lib/features/pip/domain/entities/pip_nest.dart:27` — `pipStageName()`
   is a top-level display helper next to the entity, while
   `ARCHITECTURE.md` §Per-feature contract says `domain/ entities +
   abstract <feature>_repository.dart ONLY`.
   *Fix:* move it to `presentation/` (next to `widgets/pip_look.dart`, whose
   header already argues for feature-local Pip copy) and update its three
   consumers (`pip_nest_view.dart:345,355`, `pip_growth_card.dart:46`) plus
   the test imports. No behaviour change.

2. **minor (new) — the only presentation → concrete-data import in the repo.**
   `app/lib/features/pip/presentation/views/pip_nest_view.dart:28` imports
   `features/pip/data/pip_repository_impl.dart` and reads
   `PipRepositoryImpl.feedCostCoins` / `.bathCostCoins` at
   `:482-483, 505-508, 539-542`. The view therefore depends on the Drift impl
   class that `pip_di.dart` exists to hide behind `sl<PipRepository>()`
   (ARCHITECTURE §App shell / §Per-feature contract). Verified unique:
   `grep -rn "data/.*_repository_impl.dart" app/lib/features/*/presentation/`
   returns only this file.
   *Fix:* declare the two costs on the abstraction —
   `abstract class PipRepository { static const int feedCostCoins = 5;
   static const int bathCostCoins = 3; }` — and have `PipRepositoryImpl`
   reuse them; the view then reads `PipRepository.feedCostCoins` and the
   import disappears.

3. **minor (carried, iteration 1 #3) — `_switchMap` is a verbatim fork.**
   `app/lib/features/pip/data/pip_repository_impl.dart:225-253` duplicates
   `kid_home_repository.dart`'s `switchMapStream`. RULES §1 blocks the
   cross-feature import, so the fork is tolerable today, but it should be
   hoisted to `core/data/stream_combine.dart` (which already owns the
   `combineLatest*` helpers) through a SHARED_REQUEST entry rather than grown.

4. **minor (new, documentation only) — DESIGN_SPEC §5 K06 prose vs the HTML.**
   `docs/DESIGN_SPEC.md` §5 K06 asks for a "big Pip stage 3 (280px)" and
   "72px tiles"; `K06-pip.html:21,37` gives a 230 × 206 `.k6-pet` slot and
   four `flex:1` tiles of (350 − 3×12)/4 = **78.5** px. The screen follows the
   HTML + measured PNG (`5_ui.md`: pet slot, wardrobe tops and every card edge
   all Δ 0), which is the right oracle, so **no code change is wanted here**.
   *Fix:* the orchestrator should correct the two numbers in the spec (or the
   spec should point at the per-screen HTML), so the next screen does not
   inherit the contradiction.

## RULES §1 — edited paths

5. **minor (carried, documented) — one file outside the allowed paths.**
   `git diff --name-only main...HEAD` outside
   `features/pip/**`, `test/features/pip/**` and `docs/screens/K06/**` returns
   exactly `app/test/features/kid_home/kid_home_view_test.dart` (+16 lines).
   I read the hunk: the two `/pip` proofs swap a placeholder-title assertion
   for a route assertion (`expect(pushedPath(tester), '/pip')`), the tuple's
   third field becomes `String?` and `null` for the built destination. No K03
   behaviour, `hasTap` check or `performTap` activation is removed — the edit
   is strictly *stronger* (it can no longer pass against a stub), and it is
   filed in `SHARED_REQUEST.md` §4 with the repo's own precedent
   (`docs/screens/_shared/HEADER.md` line 6,
   `router_push_test_fix_REPORT.md` §5, P09 §3). Correctly escalated; the
   only remaining action is the orchestrator's `git add`.

6. **minor (new, working-tree hygiene; uncommitted work is the loop's job,
   not a blocker) — two untracked test files, one of them scratch.**
   `app/test/features/pip/pip_atomic_writes_test.dart` (17 tests, the
   iteration-2 boundary proofs for K06-BUG-1/2: zero-rows-changed no-op,
   unknown-child guard, mixed care bursts, the buy boundary) and
   `app/test/features/pip/zz_k06_iter2_probe_test.dart` (9 tests) are both
   untracked, so neither is in `main...HEAD`. Both are green today and both
   run in every suite.
   *Fix:* the loop's commit must `git add` `pip_atomic_writes_test.dart` —
   without it the branch carries the atomic-write fix with only the
   lost-update proof. `zz_k06_iter2_probe_test.dart` is labelled
   `// TEMPORARY iteration-2 probe file … Deleted before the stage ends`;
   delete it (its assertions are already in `k06_bugs_test.dart`,
   `pip_repository_test.dart` and `pip_atomic_writes_test.dart`) rather than
   committing a `zz_` scratch file into the suite.

## Design system and tokens

7. **minor (new) — `_BackButton` re-implements a component that already does
   this exact job.** `pip_nest_view.dart:234-273` hand-rolls the transparent
   56 × 56 back control (`Semantics` + `GestureDetector` + `SizedBox.square`
   + `NestIcon`) plus the bare literal `_kBackIconSize = 26` at `:273`.
   `NestIconButton` expresses it, and the sibling kid screen already uses it
   for the identical transparent 56 px back button:
   `app/lib/features/kid_home/presentation/views/kid_pin_view.dart:181-192`
   (`size: NestDevice.tapKid, iconSize: 26, backgroundColor/borderColor:
   Colors.transparent`, same `semanticLabel: 'Back'`, same canPop → pop /
   `go(fallback)` navigation). The design's `.nav-back` really is transparent
   (`components.css:59`), so the shared component with transparent colours is
   the faithful one — the fork also drops the shared press/ripple feedback.
   *Fix:* replace the body with
   `NestIconButton(icon: NestIcons.back, semanticLabel: 'Back',
   size: NestDevice.tapKid, iconSize: 26, backgroundColor: Colors.transparent,
   borderColor: Colors.transparent, onPressed: () => _goBack(context))`, keep
   `const Key('k06-back')` and `_goBack`, delete `_BackButton` and
   `_kBackIconSize`.

8. **minor (new, design parity) — the locked wardrobe price renders one weight
   step too light.** `K06-pip.html:42` `.k6-item-p { font-weight: 900;
   font-size: 14px }` vs `:31` `.k6-coin { font-size: 14px; font-weight: 800 }`.
   The care buttons correctly need w800, but the tile price reuses the same
   widget at its w800 default: `pip_wardrobe_tile.dart:182-185` →
   `pip_coin_amount.dart:61-65` (`fontWeight: FontWeight.w800`), so "40" and
   "120" draw lighter than the design. No layout shift (fixed-width tiles,
   centred text), but it is visible in band 6 and the note-level glyph weights
   are exactly what this loop audits. The *Owned* row beside it is already
   w900 (`pip_wardrobe_tile.dart:173-177`).
   *Fix:* add `final FontWeight fontWeight = FontWeight.w800;` to
   `PipCoinAmount` and pass `fontWeight: FontWeight.w900` from the tile.
   No test asserts either weight, so nothing else moves.

9. **(pass) No hard-coded colours, sizes or fonts.** Every colour in the seven
   new widgets and the view is a token (`tokens.peach / onWarm / sky /
   onAccent / surface / surface2 / lilacTint / ink / ink2 / leafInk /
   kidShadow`), spacing comes from `NestSpacing` (`s1 s2 s3 s4 gap3 gap9
   gap10 gap14 padSide`), radii from `NestRadii` (`allL / allPill / l / pill`),
   type from `NestType` with design-only deltas applied at the call site
   (`.k6-sec` 20/26 via `kidName.copyWith`, `.k6-item-n` 14/18 via
   `kidBody.copyWith`, `.k6-care` label 17/20 via `buttonKid.copyWith` — the
   sanctioned `copyWith` pattern, no `letterSpacing` anywhere). The remaining
   numerics are named, commented design values (52 / 30 / 16 / 91 / 116 /
   230 / 206 / 134 / 81 / dash 6·3 / `Offset(0, 6)` = `--sh-kid` /
   `opacity .45`, which is the literal `NestKidButton` itself uses).
   `kid.borderWidth` (3) and `NestDevice.tapKid` (56) are used for the CSS's
   `3px solid` and `.lg`. Fonts are the bundled faces; `grep google_fonts|
   GoogleFonts` over `lib/features/pip` + `test/features/pip` → 0 hits.

10. **(pass) Shared components are reused wherever they can express the
    design.** `NestBalancedText` on the `.kid-title` heading (the
    `text-wrap: balance` rule), `NestProgress(kid: true)` for
    `.progress.kid`, `NestLockButton(large)` for `.lock-btn.lg` with the K03
    one-gate-per-gesture `_busy` guard, `NestKidButton` for the failure and
    no-child cards, `KidScope` + `NestStatusBar` + `NestHomeIndicator`,
    `showNestToast`, `PipAvatar`, `nest.svg` / `coin.svg`.
11. **(pass) The three forks are each declared, not silent.**
    `PipCareButton` (no `trailing` row in `NestKidButton`),
    `PipNestSlot` (`NestPetStage` pins its block to K03's 236 × 188 geometry)
    and `_DashedBorderPainter` (Flutter has no dashed `BorderSide`) are each
    written up in `SHARED_REQUEST.md` §1-§3 with the design's own numbers.
    The dashed border is painted as a `foregroundPainter` on the exact CSS
    box (`border-style: dashed` over `background`, with the 3 px band
    reserved via `padding`, so owned and locked art circles share an inset) —
    K06-BUG-6's mechanism, correctly inverted.

## DESIGN_SPEC §5 K06 + copy

12. **(pass) Every element in the spec is present**, from the HTML source:
    status reserve, `.k6-top` back + lock pair (`padding 0 20 4`),
    `Pip · Fledgling` title, the 230 × 206 nest slot with the 134 px Pip at
    `bottom 81`, the `.k6-grow` card (next-stage Pip at 30 px, "Growing into a
    Songbird", kid progress, `175 coins` / `250 to grow`), the three care
    buttons with their price rows / `Free` pill, the `.k6-sec` heading, the
    four-tile wardrobe strip (2 owned, 2 locked with a coin price) and the
    caption. The "all free choices, no timers" note is honoured structurally:
    care is a tap, nothing is scheduled or nagged; the design's 5 / 3 coin
    prices are rendered, not invented.
13. **(pass) Copy is character-exact against the HTML bytes.** I re-read both
    sides rather than trusting the notes: `K06-pip.html:53` `Pip &middot;
    Fledgling` → the app's `U+00B7` (`pip_nest_view.dart:345`);
    `:71` `Pip's wardrobe` → ASCII `0x27` (`:388`, the plan's earlier U+2019
    was correctly reversed in iteration 2 and `1_plan.md` §1e was corrected
    with it); `:78` `&mdash;` → `U+2014` (`:409`). Wardrobe names
    (Scarf / Sun hat / Wellies / Crown) and their order come from the design
    order in the repository, `Feed` / `Play` / `Bath` / `Free` / `Owned` are
    verbatim, and `175 coins` / `250 to grow` / `Growing into a Songbird` are
    built from DB values with the design's wording. UK English throughout, no
    £ on this screen, coins only. *(Informational: `5_ui.md:40` still reports
    the heading as U+2019 — that copy line predates the BUG-3 fix; the shipped
    string is ASCII, matching the source.)*
14. **minor (carried, iteration 1 #10) — one string is not in the design.**
    `pip_nest_view.dart:435` `kPipNotWearable = 'That one is not something Pip
    can wear.'` fires when an owned, non-wearable tile (Wellies / Crown) is
    tapped. The design defines no copy for that case and the plan mandated a
    toast rather than a dead tap; kind, factual, shame-free. It needs an
    explicit orchestrator ratification (keep / reword / drop the toast and let
    the tap be inert), not a silent third state.
15. **minor (new, screen-reader only) — the pet's accessible name drifts from
    the design.** `pip_nest_view.dart:354-355` announces `Pip the Fledgling,
    stage 3 of 4` where the design's `alt` is "Pip the Fledgling in her nest"
    (`K06-pip.html:56`); `PipGrowthCard:89` now matches the design's
    `aria-label` exactly (iteration 1 #11 closed). The stage suffix is extra
    information for a non-visual user, so this is a judgement call, not a
    defect. *Fix (optional):* append the design's clause — e.g.
    `'Pip the Fledgling in her nest, stage 3 of 4'`.
16. **minor — ORCHESTRATOR_NOTES item 2 is unmet in-product and cannot be met
    screen-side.** The wardrobe glyphs are still the shared look-alikes
    (`app/assets/icons/ic_scarf.svg`, `ic_wellies.svg`, `ic_sun_hat.svg`); the
    note forbids substituting a glyph and RULES §1 forbids editing
    `app/assets/**`, so the correct action was escalation — and that is what
    happened: `SHARED_REQUEST.md` §5 carries the design's four glyphs
    verbatim from the HTML with a measured asset-vs-design table, and
    `pip_orchestrator_notes_test.dart:244-262` keeps three parked proofs that
    read the HTML at test time and compare normalised path data, so the fix
    goes green by itself when the asset lands. No substitution, no hard-coded
    glyph. Items 1 (dashed border + locked fills, `:97-104`), 3 (prices from
    `watchWardrobe`, `SHARED_REQUEST.md` §6) and 4 (regression guard at
    `:301-316`) are satisfied. **Action for the orchestrator, not the screen:**
    land the §5 asset swap on `main` (and §6's seed-or-design decision), then
    drop the three `skip: true`s.

## Accessibility

17. **(pass) Every interactive node is operable by VoiceOver/TalkBack, and the
    `excludeSemantics: true` wrappers all carry the action.** Back
    (`pip_nest_view.dart:249-253`, `onTap`), grown-ups lock (shared
    `NestLockButton`, one gate per gesture burst at `:286-294`), Feed / Play /
    Bath (`pip_care_button.dart:85-92` — `button`, `enabled: enabled`,
    `onTap: enabled ? … : null`, so an unaffordable care button exposes **no**
    tap action and reports `enabled: false`, per RULES §8), wardrobe tiles
    (`pip_wardrobe_tile.dart:76-82` — `button`, `'<Name>, Owned'` /
    `'<Name>, <price> coins'`), plus the failure card's "Try again" and the
    no-child "Choose". The decorative sub-rows are `ExcludeSemantics`
    (`pip_coin_amount.dart:42`, `pip_free_pill.dart:19`) so no control is
    announced twice and the coin icon never produces a coin-only node.
    `PipAvatar` carries no semantics of its own, so `PipNestSlot`'s single
    `image: true` label is the whole announcement. The feature suite asserts
    `hasAction(SemanticsAction.tap)` and drives the **real** DB through
    `performAction` (feed −5, bath −3, buy −price, equip writes the accessory)
    in `pip_nest_interactions_test.dart`, `pip_nest_states_test.dart`,
    `pip_nest_view_test.dart` and `k06_bugs_test.dart`.

## Performance

18. **minor (new) — the whole body rebuilds on writes K06 does not display.**
    `pip_nest_view.dart:75-89` rebuilds `_PipNestBody` on every `PipNest`
    emission, and `PipProfile.props` includes `happiness`
    (`pip_profile.dart:37`), so a Play tap — which only bumps happiness —
    re-emits the stream and rebuilds the title, pet slot, growth card, three
    care buttons and the wardrobe strip. It is one small subtree on a
    kid screen, so this is not a storm and nothing is wrong with the result;
    noting it because the brief asks for rebuild discipline. *Fix (optional):*
    either drop `happiness` from what K06 subscribes to, or give the growth
    card its own `BlocSelector`/projection. The stream is a single
    subscription guarded by `_nestSub` (`pip_bloc.dart:32-51`) and cancelled
    in `close()` (`:141-146`); press states are local (`PipCareButton`,
    `_GateLockButton`) so there is no other churn; const-ness is used wherever
    a value allows it (`_PipTopRow`, `NestHomeIndicator`, `PipFreePill`).
19. **minor (informational) — `IntrinsicHeight` in the care row.**
    `pip_nest_view.dart:493` costs one extra layout pass per build; it is the
    correct transcription of `.k6-care { align-items: stretch }` and it is
    what makes the three columns share a height at text scale 1.3
    (K06-BUG-5), so keep it. If it ever shows up in a profile, the fix is a
    shared kid button that accepts an explicit height, not a local rewrite.

## Error handling

20. **(pass)** Loading → `CircularProgressIndicator` with a "Loading Pip"
    label; load failure → the friendly card ("Oh no! Pip got lost.", "Let's
    try again.") with a working "Try again" that really re-subscribes (the
    subscription is released on error and on close, `pip_bloc.dart:44-50`), so
    the guard can never wedge the screen; no active child → "Who's playing?" +
    Choose; no wardrobe rows → the heading and strip are omitted and the
    caption stays. A thrown care/buy/equip write surfaces as
    `actionError` + `actionNonce` and a kind toast ("Not enough coins yet —
    keep going!" for the unaffordable case, a generic line otherwise) with no
    partial write, and the nonce makes a second identical refusal announce
    again. Money can never go negative: `_care` and `buyItem` make the
    affordability test part of the write (`pip_repository_impl.dart:112-173`),
    `buyItem` refunds a lost same-item race inside its transaction, and the
    bloc's stale pre-check is only the fast toast path. No `DateTime.now()`,
    no clock-derived ids, no `subscription_status` write anywhere in the diff.

## Children's Code (kid mode)

21. **(pass)** No analytics, no ads, no network, no third-party SDK and no
    child data leaving the screen: `grep` for `print|debugPrint|http|analytics|
    advert` over `app/lib/features/pip/**` → 0 hits. The screen shows the
    active child's own Pip (orchestrator PIP rule — style / skin / accessory /
    stage straight from the child's row, `pip_look.dart:13-40`, no
    `pip_stage_*.svg` anywhere) and no nickname, no £, no nagging, no red, no
    timers. Unaffordable actions are disabled rather than punishing, and the
    refusal copy is encouraging. Bottom edge: there is no bottom bar on this
    screen and the shared `KidScope` meadow runs to the physical edge
    (exactly one `KidScope` + one `NestMeadow`, 390 × 136, no local hill),
    so the owner BOTTOM EDGE rule cannot be violated in either theme.

## Tests

22. **(pass)** 160 green in `test/features/pip/`, 3 skipped, whole repo green
    (`+3552 ~5`, the 5 skips = K06's 3 glyph proofs + the two pre-existing
    ones in K01/P12 — see the tails above). Coverage matches the plan: repository (Drift memory
    + `Seed.demo`: costs, happiness clamp, insufficient-coin no-ops, atomic
    concurrency boundaries, wardrobe order/names/DB prices, null child), bloc
    (every event × loaded/no-nest/thrown/silent, subscription guard and
    release, `close()`), states (loading / failure + retry / no-child), view
    (title, own Pip, growth 0.7 + labels, care labels, wardrobe from the DB,
    semantics taps mutating the DB, back/lock navigation, dark, the
    320/430 × 1.0/1.3 matrix with the bundled faces loaded), copy parity read
    from the HTML bytes, the ORCHESTRATOR_NOTES groups and the six numbered
    bug proofs (`k06_bugs_test.dart`, all un-skipped and green under
    `--run-skipped` too). Nothing is weakened: `skip: true` appears exactly
    three times in the whole feature directory, all three being the
    shared-asset glyph proofs of §16; `analysis_options.yaml` is untouched;
    every pumped test ends with `disposeApp(tester)`. Stage 6's
    test-infrastructure nit (a width matrix that actually ran at 390) is
    fixed — `_pumpNest` now applies the surface *after* `pumpAppRoute` and
    asserts the resulting logical width.

## Hand-off

No blocker, no major. The cheapest real improvements, in order: #8 (one weight
step on two prices, 3 lines), #7 (reuse `NestIconButton`, ~30 lines deleted),
#2 (costs on the abstraction), #6 (add `pip_atomic_writes_test.dart` to the
commit and delete the `zz_` probe file), #14 (ratify or replace the
not-wearable toast), #16 (orchestrator: land the glyph assets and the seed
price decision on `main`, then un-skip the three proofs).

VERDICT: PASS
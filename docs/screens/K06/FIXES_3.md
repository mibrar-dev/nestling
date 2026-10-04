# Fix list after iteration 3

## From 4_review.md
# K06 · Pip's nest — QA code review (stage 4, iteration 3)

Scope: `git diff main...HEAD` on `screen/K06` — 8 product files in
`app/lib/features/pip/**` (repo/entities/bloc rewrite + PipBuyResult, the view,
six of the seven feature widgets) + 14 test files in
`app/test/features/pip/**` + this directory's notes. `main` now carries
`shared_batch7` (glyphs `NestIcons.wardrobeScarf/wardrobeWellies`, seed
prices 30/60, `NestPetStage` K06 slot params, `NestKidButton.trailing`,
`NestDashedBorder`); the worktree merges it (`ed76a69`). Reviewed against
`docs/ARCHITECTURE.md`, `docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5
K06, `design/html-source/screens/K06-pip.html`, the design system in
`app/lib/core/design_system/`, `docs/screens/K06/1_plan.md`, and the
mandatory `docs/screens/K06/ORCHESTRATOR_NOTES.md` (both rounds — 11:30 and
13:52 items are binding).

Checks run by this stage (no simulator was ever booted, installed on, driven
or screenshot on a code-review pass; no `flutter clean`, no
`analysis_options` change, no image attached): the review measures the
COMMITTED diff (`main...HEAD`, `HEAD == a17df6b`):

```
flutter analyze lib                                  → No issues found!
flutter analyze lib test                             → two analyzer errors
                                                          (see #8 — these
                                                          are NOT in
                                                          main...HEAD; they
                                                          come from an
                                                          uncommitted sweep
                                                          rewrite of
                                                          pip_orchestrator
                                                          _notes_test.dart)
flutter test --timeout 120s test/features/pip        → +207 ~1: All tests passed!
flutter test --timeout 120s                          → +3789 ~5: All tests passed!
```

On the tracked content (HEAD) there are zero red tests. The tree currently
carries three uncommitted stage-leftovers which the loop's own later stages
will finish; #8 enumerates them, and none of them is a finding about the
shipped code.

**One major finding, carried minors. Final stage verdict: FAIL.**

---

## Architecture and RULES (feature-first, domain = entities + abstract repo, BLoC per screen, paths)

0a. **(pass) On DI / routes / bloc discipl. The diff keeps DI and routes
   untouched at `app/lib/features/pip/pip_di.dart` and `pip_routes.dart`
   (both unchanged vs. main); the single `PipBloc` is factory-registered
   and subscribed via `emit.forEach` semantics (explicit `_nestSub`
   listener instead of `emit.forEach`, cancellations on error + close, no
   reload-event re-add). The domain expansion this iteration (the
   `PipBuyResult` enum) sits inline in the existing abstract
   `pip_repository.dart`, which ARCHITECTURE allows; no new layers,
   services or fake datasources appear.

0b. **(pass) Edited-path discipline under RULES §1.** A
   `git --name-status main...HEAD` sweep shows every changed line live
   inside `app/lib/features/pip/**`,
   `app/test/features/pip/**` and `docs/screens/K06/**`, with one
   deliberate exception already on file: `app/test/features/kid_home/kid_home_view_test.dart`
   (+16/−5, a route-assertion swap for the `/pip` placeholder title) is
   recorded in `SHARED_REQUEST.md` §4 with RV (orchestrator rules, precedent
   file `router_push_test_fix_REPORT.md` §5 / P09 §3) as the one-off hack
   allowed to keep the branch's feature suite green. `core/**` and `app/**`
   are only touched on `main` via shared batch 7, never in our diff.

1. **major (new, iteration 3) — the mandatory 13:52 component switch is
   only two-fifths landed.** The 13:52 orchestrator note says that once
   `main` has shared batch 7, "switch to the shared ones and delete the local
   copies, following the batch-7 report." Batch 7 adds five things and
   iteration 3 adopted only two:

   - §5 glyph swap — **done**: `pip_look.dart:57-60` now maps scarf/wellies
     to `NestIcons.wardrobeScarf`/`NestIcons.wardrobeWellies`, with the
     batch-7-rationalised sun-hat/crown exceptions documented inline.
   - §6 prices — **done**: `Seed._wardrobeDemo` is now 30/60 and the seed
     mirrors the design; every price assertion moved to the live row
     (edits are tracked; the former `Expected 80/40/120, got 90/30/60`
     premises are swept).
   - §1 kid-button trailing row — **not done**:
     `PipCareButton` (152 lines,
     `app/lib/features/pip/presentation/widgets/pip_care_button.dart`) still
     re-implements the whole kid-button, while main now has
     `NestKidButton({…, Widget? trailing})`.
   - SHARED_REQUEST §1 pet slot — **not done**: `PipNestSlot` (98 lines,
     `presentation/widgets/pip_nest_slot.dart`) still forks the explicit
     geometry, while `NestPetStage`'s doc comment literally instructs "K06
     passes `nestWidth: 230, nestHeight: 206, fixedPipHeight: 134, pipBottom:
     81, nestFit: BoxFit.contain, showGlow: false, showGroundShadow: false`".
   - SHARED_REQUEST §3 dashed border — **not done**:
     `_DashedBorderPainter` (45 lines) at
     `presentation/widgets/pip_wardrobe_tile.dart:228-273` is still the
     painter, while `core/design_system/components/nest_dashed_border.dart`
     exists with the same algorithm, the same dash 6/gap 3 metric and a
     K06-identifying doc comment.

   Evidence it's still the local forks that ship:
   `grep -r "NestDashedBorder\|PipNestSlot\|PipCareButton" app/lib/features/pip/`
   returns only K06 local widgets — zero hits for any batch-7 component
   inside the feature. Consequences: two dashed-border painters to maintain,
   `PipCareButton` drifting from `NestKidButton`'s press-physics/semantics,
   and the shared `NestPetStage` slot fixes (the batch-7 report fixes the
   K03 bleed) cannot reach K06.

   **Fix (mechanical):** in `pip_nest_view.dart` /
   `presentation/widgets/pip_wardrobe_tile.dart` make three swaps — care row
   uses `NestKidButton(trailing:)` (Feed coin trailing / Play `PipFreePill` /
   Bath coin trailing), the pet block uses `NestPetStage` with the documented
   K06 args, and the locked tile wraps its child in `NestDashedBorder`.
   Delete `pip_care_button.dart`, `pip_nest_slot.dart` and
   `_DashedBorderPainter`; keep the local geometry constants only as labels
   of the design where they remain meaningful. Re-target the two
   fork-coupled test fixtures (`pip_nest_widget_test.dart`,
   `pip_iter2_fixes_test.dart` widget imports) at the shared components.
   Roll the K06 fork SHARED_REQUEST §1/§2/§3 up to §5 as resolved
   ("adopted on main").

2. **minor (carried, open) — `pipStageName()` stays in `domain/`.**
   `app/lib/features/pip/domain/entities/pip_nest.dart:27`. The
   architecture doc's rule "domain = entities + abstract repository ONLY"
   is clear; move the helper next to `pip_look.dart` in
   `presentation/widgets/`, adjust its three call sites
   (`pip_nest_view.dart:345,355`, `pip_growth_card.dart:46`) plus the two
   test imports in `pip_repository_test.dart` / `pip_bloc_test.dart`.

3. **minor (carried, open) — the view import of the concrete repository
   impl.** `pip_nest_view.dart:482-483` and `:505-542` read
   `PipRepositoryImpl.feedCostCoins` / `.bathCostCoins`. Move both constants
   onto the `abstract PipRepository` (or a domain `PipCareCosts` token
   entity) so the view no longer names the impl — it also stops reaching
   into a Drift file for copy-rendering numbers.

4. **minor (carried, open) — `_BackButton` is a shared-component reuse miss.**
   `pip_nest_view.dart:234-267` hand-rolls the transparent 56×56 back
   control (`Semantics` + `GestureDetector` + `SizedBox` + `NestIcon`),
   while `NestIconButton(icon: NestIcons.back, size: NestDevice.tapKid,
   iconSize: 26, backgroundColor: Colors.transparent,
   borderColor: Colors.transparent, onPressed: …)` does it — exactly how the
   K02 kid screen wires it (`kid_pin_view.dart:181-192`). This also drops the
   local `_kBackIconSize` literal.

5. **minor (carried, open) — care-button label weight.** Design
   `.k6-item-p` is w900 while `.k6-coin` is w800; `PipCoinAmount`
   hard-codes w800 (`pip_coin_amount.dart:63`), so locked tile prices draw
   one step lighter. Add a `FontWeight` param or a distinct
   `PipItemPrice` used only by the tile. No test asserts either weight
   today, so the change is free.

6. **minor (carried, open) — DESIGN_SPEC prose vs the HTML.** §5 K06's
   "280px stage 3" and "72px tiles" predate the HTML/PNG (`.k6-pet` is
   230×206; the four `flex:1` tiles are (350−36)/4 = 78.5). The screen
   follows the measured PNG — that is the correct oracle (the stage-5
   table in `5_ui.md` carries every structural row at Δ 0). Runtime fix is
   not needed; the spec should be amended, otherwise the next K* screen
   that copies it will mismeasure.

## Design system, copy, accessibility, performance, errors, children-code

7. **(pass) Design system / token hygiene.** No colour literals, no
   off-token sizes, no `google_fonts`/`GoogleFonts` import, no
   `letterSpacing` added, `NestBalancedText` on the `.kid-title` heading,
   `IntrinsicHeight` + stretch on the care row (the one device that keeps
   all three buttons at the same height at text scale 1.3, pinned by
   `pip_iter2_fixes_test`), `NestKidButton`'s `opacity .45` disabled pattern.
   The two open weights issue in #5 and the fork-deletion in #1 are the
   only reuse gaps left.

8. **(process) Working-tree sweep leftovers — NOT part of main...HEAD.**
   Three things tracked git signals as in-flight / not-leftover-committed:

   - `test/features/pip/pip_orchestrator_notes_test.dart` (uncommitted
     edit): the sweep re-added a `const superseded = <String, String>{ … }`
     block at `:284-289` that wraps bare-string entries in a *map* literal,
     which is a syntax error under the analyzer (`expression_in_map`, two
     reds: `:285, :286`). `flutter analyze lib test` therefore fails, and
     that file no longer loads as a test. This edit is uncommitted and
     SHOULD NOT land — either the sweep finishes it (a `Set`/a list of
     two assets: `const superseded = <String>[…]`) or it is discarded and
     the file reverts to HEAD's working 410-line variant, whose only skip
     is the sun-hat proof.
   - `test/features/pip/k06_bugs_test.dart` (uncommitted edit): adds the
     end-to-end BUG-7 refusal-toast proof and rewrites the file header from
     "iteration-2" to "iteration-3" — consistent with the plan, commit it.
   - `test/features/pip/pip_buy_result_test.dart` (untracked, 18 lines
     proof of the BUG-7 contract): its two initial assertions were
     wrong-premise (post-buy `detail` is correctly `'Owned'`; the nonce
     log starts at `[0, 0, 1, 0, 1]` because `copyWithLoaded` re-emits a
     non-failing state first); the same sweep rewrote the file (mtime
     `Oct 4 15:32:47`) and it is now green. It should be added with the
     sweep, not left as an untouched dotfile.

   The temporary `zz_k06_iter3_probe*` files from the bug sweep were
   removed (`test/features/pip: no zz_*` now); they were already reviewed
   as scratch under iteration 2's header category ("delete at end of
   stage") and carried no importable logic. Bottom line: tracked
   main...HEAD itself carries no red; do not conflate the in-flationary
   tail of the local tree with it, and do not propose a DELETE
   directive for git HEAD content.

9. **(pass) BUG-7 fix is structurally sound.** `domain/pip_repository.dart`
   now returns `Future<PipBuyResult>` (`bought | cannotAfford |
   alreadyOwned | unavailable` — ARCHITECTURE allows the enum as part of
   the domain's abstract repo); `_onBuyRequested` (`pip_bloc.dart`) only
   toasts on `cannotAfford`, while `bought` stays event-free (the stream
   re-emits); and `PipState.copyWithLoaded` now carries `actionError` +
   `actionNonce` through refresh — that carry-through is exactly why the
   winning tap's stream refresh can no longer swallow the second tap's
   refusal. `withActionStarted` still resets per attempt, so the
   `1 → 0 → 1` announcement cadence is preserved across refusals separated
   by successes.

10. **(pass) Data-correctness premises honestly re-based.** Seed prices now
    mirror the designs (Wellies 30, Crown 60); the formerly brief-red
    re-sets (`repositories_test.dart` pip group, all feature price
    assertions, the 70-coin re-base in `k06_bugs_test.dart` for BUG-2 and
    the burst probe) now match main's shared test. Care writes remain
    conditional (`_care`: `WHERE id = ? AND coins >= ?`; happiness clamped
    0..5; play free; never negative). The unconditional `pip-
    WardrobeIcon` switch (#5 in the note) is the glyph fix D2 was waiting
    on; D2's red proofs in `pip_orchestrator_notes_test.dart` should flip
    green at re-test time.

11. **(pass) Copy / UK english / typography exactness.** Title is `Pip ·
    Fledgling` (U+00B7), section heading is the HTML's ASCII apostrophe
    `Pip's wardrobe`, caption carries the em dash `—`; the section heading
    matches HTML 0x27 byte-for-byte (iteration-2's K06-BUG-3 fix); the
    care row reads `Feed` / `5`, `Play` / `Free`, `Bath` / `3`; the growth
    card reads `175 coins` + `250 to grow`. Kid-wallet copy is £-free.
    Every §5 element is present: stage-3 Pip in the nest, name, growth
    bar toward Songbird (175/250), three care buttons with coin costs,
    4-tile wardrobe strip (2 owned, 2 coin-priced), the footnote — all
    from `K06-pip.html` verbatim.

11b. **(pass) UK spelling audit clean.** Scanned every K06-visible
     string for US defaults («-ize», «mom», «nov.»: none — the only
     candidate words `Growing into a Songbird`, `Fledgling`, `Owned`,
     `Free`, `Bath`, `keep going` are all ordinary British English).
     `Pip’s wardrobe` uses the source's literal ASCII apostrophe per the
     byte-level rule, and the em-dash in «Nothing here is a chore — it is
     all just for fun.» is correct British punctuation. The only on-screen
     string the design does NOT itself define is the kind refusal copy
     «Not enough coins yet — keep going!», already covered by
     `pip_bloc.dart:11` and flagged for orchestrator ratification in the
     same way the iteration-2 review's #14 flagged it.

12. **(pass) Accessibility.** Every interactive control exposes
    `SemanticsAction.tap`: back, gate (56×56 `NestLockButton` semanticLabel
    'Grown-ups' — one gate per gesture burst), Feed/Play/Bath (their
    `enabled: false` disables the tap and drops the action, per RULES §8),
    the four wardrobe tiles (`'<Name>, Owned'` / `'<Name>, <price> coins'`,
    tap-driven in the test suite). `PipNestSlot`'s `Semantics(image: true,
    label:)` announces one Pip; `PipCoinAmount`/`PipFreePill` stay
    `ExcludeSemantics` so the parent owns the single announcement. No
    semantics-leaking double textfield, no second control from a visible
    label.

13. **(pass) Performance and lifecycle.** Single `PipBloc._nestSub` guard
    (no stacked `watchNest` handlers on a second `PipLoadRequested`), the
    nest stream is one subscription, `PipBloc.close()` cancels it, press
    state is local (`_PipCareButtonState`), the whole-body rebuild is
    bounded, `const`-content is used on static subtrees, `IntrinsicHeight`
    is accepted for the 3-column stretch, and `AnimatedContainer` (the only
    animation) honours `NestMotion.resolve(context, NestMotion.fast)`
    (which respects `DISABLE_ANIMATIONS`).

14. **(pass) Error handling.** Load failure card offers `Try again` that
    really re-subscribes (subscription released on error/close); two
    visible child fallbacks (`_NoActiveChild`, the guard-tested "null child"
    path); the write-error channel is cleanly split from the load-failure
    channel; an unaffordable buy surfaces the kind copy via
    `actionError` + nonce. `Watch` failures do not leak into the nest
    stream because the outer handler is applied.

15. **(pass) Children's Code.** Zero analytics/ads/network/SDK imports in
    the feature (`grep` clean); the wardrobe choices have no timers, prices
    are not debt-shaped, and the refusal copy is encouraging ("Not enough
    coins yet — keep going!").

16. **minor (status, informational) — the only live skip is the sun-hat
    full-path-data proof** at `pip_orchestrator_notes_test.dart:316`. It
    still fails because it string-compares verbatim SVG path text against
    the design block, while batch 7 justifies the kept asset as
    semantics-equivalent (same silhouette, different coordinates). Either
    rewrite it to assert how the shared constant maps (`pipWardrobeIcon`
    surfaces `NestIcons.sunHat`) or fold it into SHARED_REQUEST §7 as a
    deferred item. A permanently-red-on-skip line is noise for the rest of
    the suite.

17. **minor (informational) — carried iteration-1 nits stay on file.**
    `PipNest.growthFraction` 0..1 clamp, six-person lifetime coin input, a
    320 px and 430 px × 1.0/1.3 fit matrix including the failure card and
    the no-child card, the zero-child and the empty-wardrobe omission —
    all read clean at HEAD.


## From 6_bugs.md
# K06 · Pip's nest — Stage 6 bug hunt (iteration 3)

Re-audit of the iteration-3 build (`a17df6b`, shared batch 7 merged). **All
seven filed findings are FIXED** and run live in
`app/test/features/pip/k06_bugs_test.dart`; this pass re-verified them
end-to-end, added the end-to-end refusal-toast regression, and probed the new
`PipBuyResult` contract and the carried action outcome. One **major** stays
open, shared-owned: the residual **sun-hat glyph** (`SHARED_REQUEST.md` §7 —
batch 7 fixed Scarf/Wellies and left the third tile). No product code was
changed by this stage.

```
flutter analyze test/features/pip/k06_bugs_test.dart   → No issues found!
flutter test --timeout 120s test/features/pip/k06_bugs_test.dart
  → +25: All tests passed!                 (no skips in this file)

flutter test --timeout 120s test/features/pip/
  → all green, exactly one skip: the parked sun-hat glyph
     proof in pip_orchestrator_notes_test.dart (item 2 / section 7 below)
```

## Status of every finding

| # | Severity | Status |
|---|---|---|
| K06-BUG-1 | major (iter 1) | **FIXED (2a), verified live** — atomic `_care`; 2 feeds 110, 5 feeds 95, feed+bath 112 |
| K06-BUG-2 | major (iter 1) | **FIXED (2a), verified live** — atomic `buyItem`; 70 coins → exactly one of 30+60 |
| K06-BUG-3 | minor (iter 1) | **FIXED (2b), verified live** — ASCII apostrophe, byte oracle green |
| K06-BUG-4 | minor (iter 1) | **FIXED (2b), verified live** — nest box 230×206, `BoxFit.contain` |
| K06-BUG-5 | minor (iter 1) | **FIXED (2b), verified live** — equal care heights at 1.3, 91 px at 1.0 |
| K06-BUG-6 | major (iter 1) | **FIXED (2b), verified live** — dashed border over the fill, light + dark pixel proofs |
| K06-BUG-7 | minor (iter 2) | **FIXED (3a), verified live** — `PipBuyResult` + `cannotAfford` toast; new end-to-end regression |
| ORCH item 2 · scarf/wellies | major (iter 2) | **FIXED (2/integrate), verified live** — exact shared assets + `pip_look.dart` switch; byte proofs green |
| ORCH item 2 · sun-hat (residual) | **major (design fidelity, shared-blocked)** | **OPEN** — `SHARED_REQUEST.md` §7; one parked proof; see below |
| ORCH item 2 · local-copy switch | minor (compliance, scheduled) | OPEN — `2_build.md` §5.1; refactor to `NestPetStage`/`NestKidButton`/`NestDashedBorder`; no functional impact |
| ORCH item 3 · prices | done | **FIXED upstream** — seed 30/60; every K06 test reads the seeded row (no typed price) |
| `kPipNotWearable` | minor (copy ratification) | OPEN — unchanged since iteration 1 |
| `NestProgress` kid highlight | shared | OPEN — shared component, out of screen scope |

**One open major remains** — the sun-hat glyph — so this stage's verdict is
**FAIL** until the shared asset lands. It is the same defect class the UI
stage rated D2 major in iteration 2 and the orchestrator mandated ("Wardrobe
icons must be the design's glyphs … Do not substitute"). Scarf and Wellies
are done; the sun hat was the third asset in `SHARED_REQUEST.md` §5 and batch
7 left it claiming it "already matches the design geometry", which the
byte-level proof shows it does not. No screen-side work remains for it.
K06-BUG-7 is fixed; the local-copy switch is a scheduled refactor with no
functional impact.

---

## ORCH item 2 residual — major — the sun-hat glyph is still not the design's

**Mechanism.** The wardrobe tile for the sun hat paints `NestIcons.sunHat`
(`assets/icons/ic_sun_hat.svg`). The design's inline glyph
(`K06-pip.html` line 74) is
`M3 16h18l-1.6 2.4H4.6z` + `M7 16a5 5 0 0 1 10 0z`; the asset draws
`M2.4 13.8h19.2l-1.6 2.8H4Z` + `M6.8 13.8a5.2 7 0 0 1 10.4 0Z` **plus an
extra `M7.4 11.6h9.2` stroke** — the brim sits 2.2 units higher in the
24-box, the dome is flatter (`ry 7` vs `5`), and the design has no third
stroke.

**Evidence.** `pip_orchestrator_notes_test.dart` item 2 (extra) compares the
asset's path data with the path data read from `K06-pip.html` at test time;
it fails deterministically under `--run-skipped` (verified this pass), and
it is the only `skip: true` left anywhere in `test/features/pip/`.
Scarf/wellies/crown are byte-correct.

**Failing test (test stage, parked).**
`ORCHESTRATOR NOTES item 2 (extra): the sunhat glyph is the design path` —
```
flutter test test/features/pip/pip_orchestrator_notes_test.dart --run-skipped
```

**Suggested fix.** Add a `wardrobeSunHat` asset with the design's two paths
(the scarf/wellies pattern from batch 7), point `NestIcons.sunHat` (or a new
constant the K06 mapping uses) at it, and unskip the proof. `features/pip/**`
cannot do it (RULES §1): `SHARED_REQUEST.md` §7 carries the paths.

---

## K06-BUG-7 re-verified (fixed in 3a) — a refused buy now announces itself

**The fix.** `PipRepository.buyItem` returns `PipBuyResult`
(`bought | cannotAfford | alreadyOwned | unavailable`); the bloc announces
`cannotAfford` with the existing `kPipNotEnoughCoins` toast; `PipState.
copyWithLoaded` carries a pending outcome so the refusal survives the sibling
write's stream refresh. All four result paths were probed on the real DB:
`bought` (30-coin wellies at 120 → 90), `alreadyOwned` (second same-item
tap), `unavailable` (unknown item and unknown child), `cannotAfford`
(5 coins vs 60-coin crown).

**Verified behaviour (real DB + real bloc + real view):**

- Burst Wellies(30)+Crown(60) from 70 coins → exactly one owned, balance
  consistent (40 or 10), **`actionError == kPipNotEnoughCoins`** and the toast
  visible (`find.text(kPipNotEnoughCoins)` finds one widget).
- Repeat refusal → the pinned `1 → 0 → 1` nonce sequence, so the second
  refusal toasts again (five rapid refusals each emit the
  started/failed pair — none swallowed).
- Carried outcome across a child switch (Maya's refusal → Leo's nest) never
  re-fires the listener (nonce unchanged), and a successful Leo purchase
  clears it (`null@0`).
- A failed care write and a failed buy still surface their own errors; a
  successful care action clears a carried refusal.

**New green regression added.** `a refused buy still shows the kind toast
end-to-end` — two simultaneous gestures on the two tiles, then the rendered
toast + balance + exactly-one-owned.

## Iteration-3 premises re-verified

- **Prices are the design's 30/60** for both children (probed from the seed
  rows: `maya:wellies=30, maya:crown=60, leo:wellies=30, leo:crown=60`;
  owned rows still 0). No K06 test types a price any more, so the next seed
  decision cannot silently re-green a stale number (the integrate stage
  re-based five premises to read the row and fixed two ambiguous cases:
  the two-item burst now runs at a balance strictly between the two prices,
  and Leo's two `30` tiles are matched per-tile by their announcements).
- **Scarf/Wellies glyphs are the design's**, byte-for-byte, verified by the
  live proofs that read `K06-pip.html` at test time.
- **The atomic write evidence is unchanged:** five concurrent feeds → 95,
  same-item double buy charges once, the refund path is unreachable under
  serialized transactions (harmless belt).

## Categories re-checked clean (green, in the suite)

| Area | Result |
|---|---|
| 0 children (`Seed.empty`) | "Who's playing?" + Choose renders; no crash |
| 6 children + long UK nickname | active child's nest unchanged; K06 shows no child name |
| Empty wardrobe | heading + strip omitted, caption kept |
| 9999 coins / 9999 lifetime coins | label renders, progress clamps to 1.0, no overflow |
| 3 coins | Feed disabled (`enabled:false`, no tap); Bath operable (3 → 0) |
| Deep-link `/pip` Back | lands on `/kid-home` |
| Grown-ups burst | one gate route; back returns to `/pip` |
| Restart (file-backed Drift reopen) | 120 − 5 feed − 30 wellies = 85 persists, item owned |
| Live active-child switch | one subscription follows maya → leo → none |
| Stale active child id (`ghost`) | `watchNest` emits null (no-child state) |
| Leo active | `Pip · Hatchling`, `PipAvatar` bolt / sky / stage 2 |
| Real 320 px @ 1.3× | renders with no overflow |
| Dark-mode contrast | 10 K06 pairs all ≥ 4.5:1 |
| Copy characters | middle dot U+00B7, em dash U+2014 exact |

## Notes (not product findings)

- **Local-copy switch (scheduled, minor).** The batch-7 report's "delete the
  local copies" half is still open: `PipNestSlot` (→ `NestPetStage` with
  `slotHeight: 206, pipBottom: 81, nestFit: BoxFit.contain, showGlow: false,
  showGroundShadow: false`), `PipCareButton` (→ `NestKidButton(trailing:)`)
  and the local `_DashedBorderPainter` (→ `NestDashedBorder`) remain in
  `presentation/widgets/`. `2_build.md` §5.1 records the deferral with the
  exact call shapes and the reason (a refactor of working, UI-verified code
  needs a build iteration + a `5_ui` re-check). No behaviour bug: the six
  proofs and the pixel probes are green against the local implementations,
  and the shared components were built to reproduce them.
- **Rapid repeated refusals queue toasts.** `showNestToast` (shared
  `nest_toast.dart`) uses `ScaffoldMessenger.showSnackBar` without hiding the
  current one, so five rapid taps on an unaffordable tile queue five 3 s
  toasts of the same message. Shared component, user-initiated, identical
  copy; noted, not filed.
- **`kPipNotWearable`** ("That one is not something Pip can wear.") is still
  the one on-screen string the design does not define; awaits ratification
  (`4_review.md` #10).
- **`NestProgress`'s kid highlight spans the whole track** — shared
  component, out of the screen's scope (`2b_build_ui.md` item 5).
- **Ghost active child id under widget-test fake async** — carried over: the
  real async path emits null (plain test green); the device shows the
  no-child card. Deliberately not a bug.
- **Timezone (BST) and money rounding** — K06 shows no dates/times and no £
  amounts; coins are integers end-to-end. Nothing to fail on this screen.
- **Parent/kid mode guard** — `/pip` remains reachable in parent mode by
  design; no path from K06 reaches parent-only content without the gate.


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

VERDICT: FAIL
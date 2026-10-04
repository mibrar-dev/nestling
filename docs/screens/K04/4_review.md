# K04 Quest detail — Stage 4 QA code review (iteration 4)

## Scope and method

Reviewed `git diff main...HEAD` (merge base `c95162c`) for the K04 screen:

- `app/lib/features/kid_home/presentation/views/quest_detail_view.dart` (new, 875 lines)
- `app/lib/features/kid_home/presentation/bloc/kid_home_bloc.dart` (+6: the `stepsFor` getter)
- `app/lib/core/design_system/components/nest_balanced_text.dart` (+23/−4, K04-BUG-1 fix)
- `app/test/features/kid_home/**` (`k04_bugs_test.dart`, `quest_detail_view_test.dart`,
  `quest_detail_bloc_test.dart`, `quest_detail_geometry_test.dart`,
  `quest_detail_matrix_test.dart`, `quest_detail_touch_targets_test.dart`,
  `quest_detail_view_icon_audience_test.dart`, `kid_home_repository_test.dart`,
  `kid_home_view_test.dart`, `k03_bugs_test.dart`)

against `docs/ARCHITECTURE.md`, `docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5 K04 +
Group C kid rules, `docs/design/SPACING_SPEC.md`, `docs/screens/K04/1_plan.md`,
`ORCHESTRATOR_NOTES.md` (all three updates, the 16:38 one included) and the design system in
`app/lib/core/design_system/`.

**No code was edited.** No simulator was booted, installed on, screenshotted or driven
(stage 5 only) — everything below is host-side.

### Commands actually run (evidence, not recollection)

```
$ flutter analyze --no-pub
No issues found! (ran in 3.0s)

$ flutter test --timeout 120s test/features/kid_home/quest_detail_view_test.dart \
    quest_detail_bloc_test.dart quest_detail_geometry_test.dart quest_detail_matrix_test.dart \
    quest_detail_touch_targets_test.dart quest_detail_view_icon_audience_test.dart k04_bugs_test.dart
00:03 +88: All tests passed!

$ flutter test --timeout 120s test/design_system/nest_balanced_text_test.dart \
    test/features/auth/typography_test.dart          # shared consumers of the edited core file
00:01 +37: All tests passed!

$ dart format --output=none --set-exit-if-changed <the 13 tracked files in the diff>
Formatted 13 files (0 changed)   # exit 0
```

`dart format` over the whole feature directory reports one file that *would* change —
the untracked duplicate named in finding 6.

## Findings

1. **minor — shared core file edited (RULES §1), filed but not yet upstream.**
   `app/lib/core/design_system/components/nest_balanced_text.dart:72-98` and `:132-144`.
   RULES §1 puts `app/lib/core/**` off limits to a screen agent; the edit is the K04-BUG-1
   fix (probe with the natural line count; bail out to full-width text when the natural
   count exceeds the caller's `maxLines`), it is recorded in `SHARED_REQUEST.md`, and
   `git show main:…/nest_balanced_text.dart` still shows the buggy capped probe — so the
   fix travels only if this branch is merged. No public API changed, the two shared
   consumers of the component pass (37 tests above), and the K04-BUG-1 proof is un-skipped.
   **Fix:** orchestrator-side only — merge this file onto `main` and drop it from the
   screen branch. No screen change; do not re-edit it here.

2. **minor — `balancedWidthFor`'s `maxLines` parameter is now dead.**
   `nest_balanced_text.dart:69` declares `int? maxLines`, but the probe at `:84-90` no
   longer forwards it, so the argument silently does nothing. `test/design_system/nest_balanced_text_test.dart:109,125`
   still passes it, so the parameter cannot simply be deleted. **Fix:** keep the signature
   and document it — `/// [maxLines] is accepted for call-site compatibility; the width
   probe is intentionally uncapped (K04-BUG-1), and [build] returns full-width text when
   the natural count exceeds the caller's cap.` — so the next caller does not expect capping.

3. **minor — `_StepRow` hard-codes `enabled: true`.**
   `quest_detail_view.dart:779`. The rows do stay tappable after a quest is done, so the
   flag is honest today; it becomes a lie the moment ticking is gated (the same shape of
   change as the `done` → `enabled: !done` polish noted in iterations 1-3). **Fix:** drop
   the argument — a `button: true` node that passes `onTap:` is already announced as
   enabled — or pass `enabled: tickingAllowed` from the caller.

4. **minor — local `_iconFor` pass-through for a single call site.**
   `quest_detail_view.dart:84-86`, used once at `:568`. It correctly delegates to
   `questIconFor(raw, audience: NestAudience.kid)` (ICONS rule satisfied), so this is
   shape, not behaviour. **Fix:** inline it — `NestIcon(questIconFor(quest.icon, audience: NestAudience.kid), …)`
   at `:568` — and keep the kid-audience comment where the call is, so the ruling stays
   visible without a 20-line wrapper.

5. **minor — `_kStepDivider = 2` re-declares an existing token.**
   `quest_detail_view.dart:53` (used at `:789` and `:797`), while `NestSpacing.gap2 == 2`
   exists in `tokens/spacing.dart:25`. The same file already aliases tokens when they
   exist (`_kBarGap = NestSpacing.s1` at `:67`), so the divider is the odd one out.
   **Fix:** `const double _kStepDivider = NestSpacing.gap2;` — one-line, keeps the PNG
   citation comment.

6. **minor — two overlapping ICONS guard files; one is untracked and unformatted.**
   `app/test/features/kid_home/quest_detail_view_icon_audience_test.dart` (tracked,
   320 lines, 4 cases) and `app/test/features/kid_home/quest_detail_icon_audience_test.dart`
   (untracked, 6 cases) both guard the same rule and both pass (verified separately);
   the untracked one additionally pins the table invariant over `questIconKeys`
   ("kid ≠ parent for exactly the divergent keys, unknown key falls back for both"), and
   it is the only one of the two that `dart format` would rewrite. The duplication, not
   the uncommitted state, is the substance here (the orchestrator rule keeps uncommitted
   work out of blocker/major). **Fix:** before the next checkpoint keep one file —
   prefer the untracked version for the extra invariant — and delete the other, then
   `dart format` it.

7. **minor — `1_plan.md` is stale in two places (doc drift only, no code impact).**
   - §(b) (`1_plan.md:98-104`) still lists the resolution order as "match → else `q-tidy`
     → first `to_do` → first". `_resolveQuest` (`quest_detail_view.dart:108-132`) now
     treats *any* string `questId` as authoritative and returns `_QuestMissing` when it
     does not resolve to the playing child (K04-BUG-2); the fallbacks serve direct
     launches only. The plan already records other deviations in §(d) — record this one
     the same way.
   - §(g) (`1_plan.md:210-221`) says "Do NOT file `SHARED_REQUEST.md`" and "only
     `quest_detail_view.dart` + `quest_detail_*_test.dart`", both superseded by
     iteration 2 (the `nest_balanced_text.dart` fix and `SHARED_REQUEST.md`).
   **Fix:** annotate the two paragraphs; no code change.

## Checks that passed

- **Orchestrator rules.** All three `ORCHESTRATOR_NOTES.md` updates honored: kid-audience
  glyphs via the shared `questIconFor(…, audience: NestAudience.kid)` (never the parent
  table, never the v1 `pip_stage_*.svg`); K04-BUG-5 closed as *accepted* and its proof now
  pins the accepted shipped state (`stroke-width="2"`, plus `isNot(contains('1.8'))` so a
  mixed asset fails) instead of asserting the superseded 1.8; the owed ICONS
  audience-difference regression guard exists and is rule-based (DB-driven keys, asserts
  rendered ≠ parent for the divergent keys, and that the glyph is column-driven). Pip is
  the child's own row look (`pipStyleOf/pipSkinOf/pipAccessoryOf`, `stage.clamp(1,4)`) at
  the design's 64 px slot; `NestStatusBar` reserves height only; DB numbers only
  (`quest.coins`, `quest.title`, `stepsFor`), nothing from the mock; period-aware status
  comes from the repo (`countsForCurrentPeriod`), so the disabled-button decision is
  period-correct; child order untouched; no `google_fonts`; zero added letter-spacing;
  no `DateTime.now()`; no `subscription_status` writes; no `name[0]`; no new ids; no
  `NestChip` rows on this screen (so `NestChipWrap` is N/A); the hero title uses
  `NestBalancedText` and no `.h2/.h3/.body/.caption` does.
- **Paths.** Only the one documented shared component (finding 1), kid_home presentation,
  feature tests and `docs/screens/K04/**` changed. `analysis_options.yaml` untouched; no
  test skipped, weakened or deleted by K04 (the only skips in the feature are K01/K03
  proofs owned by those screens).
- **Architecture.** `ARCHITECTURE.md:143` assigns `/quest-detail` → `QuestDetailView` on
  **`KidHomeBloc`**, so reusing it is the documented mapping, not a deviation; the new
  `stepsFor` getter (`kid_home_bloc.dart:26-30`) is a pure, sync, presentation-supporting
  read — no event, no state change, no repository or domain change, and the view never
  touches GetIt. Domain = entities + abstract repo only. No navigation inside the bloc
  (`go_router` appears in no bloc file). One state class per status switch; all five
  non-loaded/missing states render.
- **Design system / tokens.** Every painted element is a shared component
  (`NestStatusBar`, `NestIconButton`, `NestLockButton`, `NestBalancedText`, `NestCoinPill`,
  `NestKidButton`, `NestEmptyState`, `NestSpeechBubble`, `NestHomeIndicator`,
  `PipAvatar`, `KidScope`, `showNestToast`, `NestIcon`) with token colours only —
  `grep` finds no colour literal except `Colors.transparent`. Spacing uses
  `NestSpacing.padSide/s1/s3/s4/s8/gap3/gap6/gap14` (verified against
  `tokens/spacing.dart`); the six screen-local metrics are named constants with PNG
  citations, matching the K03 precedent and the only fixable one is finding 5. Geometry is
  transcribed from the HTML: `.k4-tile` 120 r24 peach-tint 3 ink `kidShadow`;
  `.k4-step` border-box 60 with the 2 px divider inside rows 2-3 (3+60+60+60+3 = 186);
  `.k4-dot` 40 ring with the tick glyph in both states (the design draws the check in
  `.k4-dot` *and* `.k4-dot.on`, only the fill/ink change); `.k4-cheer` gap 22;
  `.kid-bar` 12/20/10 with the 6 px `NestKidButton` shadow room handed back so the painted
  buttons land on the design rects. `quest_detail_geometry_test.dart` pins all of it
  against the PNG ÷3 (tile 109, title 233, pill 283, hint 339, card 375/186, rows at
  408/469/529, dividers 438/498, dot x 37, Pip 583, bubble 113-353, bar to y 844).
- **Accessibility.** Every control exposes `SemanticsAction.tap` (tested for *both* nodes
  carrying the duplicated label "Back"), `performAction(tap)` is asserted to flip real state
  (the ring fill and the semantics label), and `NestKidButton(onPressed: null)` correctly
  reports `enabled: false` with no tap action for a done quest. The `Semantics(excludeSemantics:
  true)` wrappers all pass their own `onTap:` (step rows, gate lock); the tile glyph is
  decorative (`ExcludeSemantics`, design `aria-hidden`) and the Pip node is `image: true`
  with the HTML `alt`. Labels match the design (`Back`, `Grown-ups`, `Plus 15 coins`,
  `{step}, ticked/not ticked`).
- **Performance.** `stepsFor` is a map lookup on the hot path, not a query; the tick set
  is local `State`; the tap latch releases on the next frame and is `mounted`-guarded;
  no `AnimationController`/`Timer` in the screen (motion-free, so `DISABLE_ANIMATIONS` is
  satisfied by construction and screenshots are deterministic); loading/failure subtrees
  are `const`; `PipAvatar` honours `kDisableAnimations`/`MediaQuery.disableAnimations` and
  disposes. The 12-pump matrix (2 themes × 3 widths × 2 scales) shows no layout exception,
  and every suite ends with `disposeApp(tester)` so no Drift timer leaks.
- **Error handling.** Loading, failure (+`Try again` re-dispatch), no-active-child,
  unknown/other-child quest id and empty-list states all render; a failed write toasts and
  keeps the checklist; the celebration rides the success channel only; the repository's
  `completeQuest` is transactional and period-idempotent, so a second dispatch cannot
  mint coins twice.
- **Children's Code.** Kid mode only: no analytics, no ads, no external links, no
  purchases, no network calls in the screen; coins, never `£` (RULES §4 — K09 is the only
  `£` screen); no red; the screen renders no nickname or other identifier, only the Pip
  look.
- **Copy / spelling.** Every visible string compared character-by-character with
  `design/html-source/screens/K04-quest-detail.html`: "Tick each bit off, then press the
  big button.", "Pip is doing a happy dance!", "I did it!", "Back", "Grown-ups" — all
  ASCII on this screen, so no curly/dash/ellipsis traps; the invented state copy
  ("Oh no! Pip got lost.", "Let's try again.", "Who's playing?",
  "Hmm, that did not work. Try again.") is verbatim-consistent with K01/K02/K03.
- **Tests.** `flutter analyze` clean; 88 K04 cases pass with nothing skipped; the two
  shared consumers of the edited core component pass; the new guard asserts the rule
  structurally rather than from a hard-coded seed list.

## Verdict

No blocker and no major findings. Seven minor items: one shared-file deviation awaiting
the orchestrator's merge (finding 1) plus one dead parameter (2), one accessibility
attribute to tighten (3), two code-shape nits (4, 5), one duplicated test file (6) and
one stale plan note (7). Nothing here changes behaviour, and none of them blocks the
merge of this screen.

VERDICT: PASS
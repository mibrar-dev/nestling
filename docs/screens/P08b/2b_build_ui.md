# P08b · 2b_build_ui — UI chunk (iteration 3)

Scope: `today` presentation/views + presentation/widgets only, plus
view/widget tests. No domain/data/bloc edits (logic builder owns those;
re-read `2a_build_logic.md` before finishing: this iteration it reports no
CONTRACT CHANGES — events, `TodayState` shape, repository interface, DI and
routes unchanged — so the UI codes against the existing `TodayState` fields
as before). Fixes every FIXES_2.md UI/layout/copy item: P08b-T07, P08b-T08.

## Files changed

- `app/lib/features/today/presentation/widgets/today_loaded_body.dart`
  - T07/B06: `_EmptyGreeting` no longer caps the h1 (`maxLines: 2` +
    `overflow: ellipsis` removed). P08b's `.greet h1`
    (`P08b-today-empty.html:4`) sets no nowrap and no line cap
    (`components.css:43` only gives `h1` `overflow-wrap: anywhere`), so the
    heading wraps to as many lines as the parent's name needs; the screen
    scrolls, so a third line costs nothing. Comment updated.
  - T08/B07: `_EmptyCard` message no longer caps at five lines
    (`maxLines: 5` + `overflow: ellipsis` removed). `.empty-card p` sets
    only `max-width: 260px`, so a long roster wraps to as many lines as the
    names need; the card is in a `ListView`, so a longer message just grows
    it. Comment added.
  - Untouched by design: greeting/date-line styles, PipAvatar
    mochi·sunny stage 1 size 140, h2, 260 measure, 52 primary, 44 link row
    with sky `decorationColor`, flush tip card, gutters x 20–370. The
    design-state render (Sarah, Maya+Leo, 390 px @1.0x) is unchanged: the
    greeting still fits one line and the two-name message still fits three
    lines (66 px), so no geometry test moves.
  - No `google_fonts`, no `DateTime.now()`, tokens only, no simulator used.
- `app/test/features/today/p08b_bugs_test.dart`
  - Un-skipped B06 + B07 (removed `skip: true`); header comment updated to
    record the iteration-3 fix. `dart format` re-indented the two bodies
    (mechanical only). No assertions touched.
  - No edits needed in `today_empty_view_test.dart`: its live T07/T08 proofs
    (`double-barrelled surname`, `every child name survives`) turn green on
    their own with this fix, as FIXES_2.md predicted.

## Verification

- `flutter analyze lib/features/today` + `today_empty_view_test`,
  `today_view_test`, `p08b_bugs_test` → No issues found.
- `dart format` on touched files → clean.
- `flutter test --timeout 120s today_empty_view_test today_view_test
  p08b_bugs_test` → **133 passed, 0 skipped, 0 failed** (B06/B07 green;
  the T07/T08 view proofs green; geometry pins still exact — greeting dy 0,
  card 74–508, link row 44, tip 90 flush, Pip 140; P08 populated-path tests
  in `today_view_test` green, so P08 does not move).
- Parallel-builder files (`2a_build_logic.md`, `.brief_build_*.md`) were
  modified by the logic builder in this same worktree — not touched here.

## LEFT FOR NEXT ITERATION

Nothing in the UI layer. Remaining loop work is the integrator's
(`flutter test` whole-app, `shot.sh` light+dark UI check with seed
`new_family`): expected deltas stay the accepted ones — PipAvatar
mochi·sunny stage 1 vs the v1 egg art (PIP rule), tab-bar surface to the
physical edge vs the PNG's old tint strip (BOTTOM EDGE owner rule), OS
status-bar glyphs, and the DB-driven day part.

VERDICT: PASS

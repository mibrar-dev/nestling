# P08b · 2b_build_ui — UI chunk (iteration 2)

Scope: `today` presentation/views + presentation/widgets only, plus
view/widget tests. No domain/data/bloc edits (logic builder owns those;
see `2a_build_logic.md` — re-read before finishing: no CONTRACT CHANGES,
`TodayState` fields unchanged, fresh-nest predicate + child order fixed
there). Fixes every FIXES_1.md UI/layout/copy item: T01–T04, B03–B05,
review findings 2/4–8.

## Files changed

- `app/lib/features/today/presentation/widgets/today_loaded_body.dart`
  - T01/B03 + review finding 2: `_EmptyGreeting` top padding removed
    (the 8 px belongs to P08's own `.greet` rule; P08b's CSS has none).
    Populated P08 `_Greeting` keeps its padding — P08 does not move.
  - T04/B04 + review finding 4: greeting is now plain `Text`
    (`NestType.h1`, `maxLines: 2`, ellipsis last resort) — wraps at
    320 px / 1.3x instead of clipping the parent's name. First attempt
    used `NestBalancedText`: it deliberately breaks one-line headings
    into two balanced lines, so the card sat at 108 instead of 74 and
    B03 still failed — plain `Text` keeps one line at 390 1.0x (card
    top 74) and wraps only when the width needs it.
  - T02 + review finding 5: link row is now
    `ConstrainedBox(minHeight: NestDevice.tapParent)` + centred glyph
    instead of `Padding(vertical: s3)` — exactly 44, tap floor kept.
  - T03 + review finding 6: `_TipCard` column `spacing: s1` removed —
    title and caption touch (16 + 22 + 36 + 16 = 90, as the PNG).
  - B05 + review finding 7: link style gains
    `decorationColor: tokens.sky` (was painting ink/near-white).
  - Stale `emptyMessageSuffix` doc comment fixed (eldest-first →
    creation order, per 2a's sort removal + CHILD ORDER ruling).
- `app/test/features/today/today_view_test.dart`
  - `320px + 1.3x` test now pins the link ROW at 44 (was glyph ≥ 22)
    + the sky `decorationColor` (review finding 8).
  - Stale "Eldest first" comment → creation order.
- `app/test/features/today/today_empty_view_test.dart`
  - T04 proof rewritten: the old assertion (single-line intrinsic width
    ≤ box width at 320 @1.3x) is unsatisfiable for a wrapping heading —
    it could never turn green. Now asserts `didExceedMaxLines == false`,
    the same semantics as B04 (nothing clipped). Test name/bug id kept.
- `app/test/features/today/p08b_bugs_test.dart`
  - `_loadBundledFonts` now also loads Nunito Black/Bold/ExtraBold.
    Without it the greeting measures in the square-advance fallback and
    wraps to 2 lines at 390 1.0x, so B03/B04 could never pass; with it
    the proofs are device-faithful (same rationale as Stage 3's own
    font loading in `today_empty_view_test.dart`). All five proofs
    un-skipped (B01/B02 by 2a, B03–B05 here).
- No `google_fonts`, no `DateTime.now()`, no hard-coded colours/sizes
  (tokens only), no simulator used.

## Verification

- `flutter analyze lib/features/today` + touched test files → No issues.
- `dart format` on touched files → clean.
- `flutter test --timeout 120s today_view_test today_empty_view_test
  p08b_bugs_test today_semantics_tap_test p08_bugs_test` → **142 passed,
  0 skipped, 0 failed** (all 5 P08b-B0x proofs green; P08 regression
  suites green — populated path byte-identical).
- Geometry proofs (today_empty_view_test, real fonts): greeting dy 0,
  card top 74 / bottom 508, link row 44, tip 90 tall with zero caption
  gap, Pip 140, gutters x 20–370 — match the plan's design numbers.

## LEFT FOR NEXT ITERATION

Nothing in the UI layer. Remaining loop work is the integrator's
(`flutter test` whole-app, `shot.sh` light+dark UI check): expected
deltas are the accepted ones — PipAvatar mochi·sunny stage 1 vs the
v1 egg art (PIP rule), tab-bar surface to the physical edge vs the
PNG's old tint strip (BOTTOM EDGE owner rule), OS status-bar glyphs,
and the DB-driven day part.

VERDICT: PASS

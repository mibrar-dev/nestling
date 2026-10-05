# K07 · Stage 2b — build, UI chunk (iteration 4)

Scope owned and touched: `app/lib/features/pip/presentation/views/**` and
`presentation/widgets/**` for K07, plus the presentation tests named in
`FIXES_3.md`. **No domain/, data/, bloc/ or route file was edited** — the only
`app/lib` diff is the two files below. No simulator was booted, installed on,
driven or screenshotted (only stage 5 may touch
`BC440E48-B3A3-43BC-971B-0EF5DB621874`), no `flutter clean`, no
`analysis_options` change, no `pkill`, no whole-app `flutter test`.

`2a_build_logic.md` carries **no CONTRACT CHANGES** for iteration 4, so this
stage codes against the same bloc surface iteration 3 shipped. Re-read before
finishing: nothing in the logic layer moved under this build.

## Files changed

| file | change |
|---|---|
| `lib/features/pip/presentation/widgets/pip_evolution_stats.dart` | `IntrinsicHeight` + `CrossAxisAlignment.stretch` around the stats `Row` — **K07-BUG-6** |
| `lib/features/pip/presentation/views/pip_evolution_view.dart` | dropped the hero's `maxLines: 4` and the sub's `maxLines: 2` + `TextOverflow.ellipsis` — **K07-BUG-7** |
| `test/features/pip/k07_bugs_test.dart` | dropped both `skip: true` flags (K07-BUG-6 and K07-BUG-7 are now run) |
| `test/features/pip/pip_evolution_copy_test.dart` | the one assertion that pinned the plan's `maxLines == 4` now pins `isNull` |

Nothing else needed work: the screen's layout, copy, a11y actions, tokens and
both theme palettes were already green through stages 3/4/5 of iteration 3, so
this iteration is deliberately the two-line FIXES_3 commit plus its knock-ons.

## K07-BUG-6 (MAJOR) — the three stat cards are now one height

`app/lib/features/pip/presentation/widgets/pip_evolution_stats.dart`, the
`PipEvolutionStats.build` row:

```dart
child: IntrinsicHeight(
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,   // CSS `align-items` default
    spacing: EvolutionStatsGeometry.gap,
    children: <Widget>[ … ],
  ),
),
```

`IntrinsicHeight` is required alongside the `stretch` and is the reason the
finding's own note matters: the row lives inside a `SingleChildScrollView`, so
its cross axis is unbounded and a bare `stretch` throws *"BoxConstraints forces
an infinite height"* in the 280×360 control. `IntrinsicHeight` bounds the cross
axis to the tallest child, which is precisely CSS `stretch`.

This is the fix `FIXES_3.md` verified and reverted, applied as specified — and
deliberately **not** a pinned card height, because the cards must still GROW at
large text scales and on a 320 px phone where the labels wrap; that growth is
what accessibility needs and what the browser does.

**Geometry is unchanged at the design width.** The 390 px proof in
`pip_evolution_widget_test.dart` (cards 110 wide at x 20/140/260, 84 tall, top
545 — i.e. `3 + 12 + 34 + 2 + 18 + 12 + 3`) still passes untouched: at 390 the
three cards were already one height, so `stretch` changes nothing there and
`5_ui` at ±2 px will not move. What changes is exactly the case the UI check
never measured — 320 px, where the labels wrap and the heights used to diverge
by 2.40 px with the demo seed and 11.67 px with a large coin total.

## K07-BUG-7 (minor) — the app-only line clamps are gone

`app/lib/features/pip/presentation/views/pip_evolution_view.dart`, the hero and
sub. Verified against the HTML source, not from memory:

```css
.k7-hero { text-align: center; overflow-wrap: anywhere; }   /* HTML:24 */
.k7-sub  { text-align: center; }                            /* HTML:25 */
```

No `-webkit-line-clamp`, no `max-height`, no `overflow` — in the browser these
two lines simply grow and `.scroll` scrolls. The app's `maxLines: 4` sat on a
`NestBalancedText` whose default overflow is `TextOverflow.clip`, so the 5th line
was cut mid-glyph with nothing to show for it; the sub's `maxLines: 2` +
ellipsis swallowed the tail of **the number that explains why Pip grew**.
`NestBalancedText` keeps `softWrap: true` by default, which is `.k7-hero`'s
`overflow-wrap: anywhere`, and keeps `textAlign: center` — so the design's break
(`.kid-title`'s `text-wrap: balance`) is preserved; only the cap is gone.

### The plan knock-on (deliberate, documented — not silent)

`FIXES_3.md` K07-BUG-7 flags two knock-ons "the build stage must handle in the
same commit", and asks for a re-ratification rather than a silent change. Both
are handled:

1. **`1_plan.md` §(a).3** specified `maxLines: 4` and §(a).4 specified
   `maxLines: 2, overflow: ellipsis`. The plan's own justification for the
   caps is now recorded as wrong: §(a).3 says `.k7-hero` adds
   `overflow-wrap: anywhere` "(≈ softWrap, keep default `softWrap: true`)", which
   says nothing about a line cap, and §(a).4's `maxLines: 2` was a guess that
   the HTML does not support. **`1_plan.md` is not mine to edit** (§1 of this
   stage's brief: the plan is the contract), so it is left as written and the
   deviation is recorded here and in the code comment instead. **The orchestrator
   should re-ratify `1_plan.md` §(a).3/§(a).4** — the shipped values are now
   "no cap on either, matching the CSS", which is what `pip_evolution_copy_test`
   and `k07_bugs_test`'s K07-BUG-7 pin.
   `1_plan.md`'s §(a).6 diagram line also says `Row(spacing: 10) stats`; the
   shipped tree is `IntrinsicHeight > Row(spacing: 10, stretch: true)`.
2. **`pip_evolution_copy_test.dart:334`** pinned `maxLines == 4` with the
   comment "the plan's maxLines 4". That one assertion was the only thing that
   failed when the cap was dropped (verified by the bug stage: `Expected: <4>
   Actual: <null>`). It now pins `isNull`, and the style and
   `textAlign == center` assertions around it are unchanged.

Both caps were **dropped**, not raised. Raising to the envelope's worst case
would have had to be a large arbitrary number to cover 3.16× at 280 px, and
would still be a cap the design does not have; dropping is safe because
`.k7-scroll` scrolls.

## Gates (this stage only, every run with `--timeout`)

```
$ dart format lib/features/pip/presentation/{views,widgets} \
      test/features/pip/{k07_bugs,copy}_test.dart
    Formatted 14 files (0 changed)

$ flutter analyze lib/features/pip \
      test/features/pip/k07_bugs_test.dart \
      test/features/pip/pip_evolution_copy_test.dart
    No issues found! (ran in 3.3s)

$ flutter test --timeout 120s test/features/pip/k07_bugs_test.dart
    → +30: All tests passed!      (was +28 ~2 — the two parked proofs now RUN)

$ flutter test --timeout 120s test/features/pip/pip_evolution_view_test.dart \
      test/features/pip/pip_evolution_widget_test.dart \
      test/features/pip/pip_evolution_copy_test.dart \
      test/features/pip/pip_evolution_a11y_test.dart
    → +87: All tests passed!

$ flutter test --timeout 120s test/features/pip/pip_evolution_sparks_test.dart \
      test/features/pip/pip_iter2_fixes_test.dart \
      test/features/pip/pip_orchestrator_notes_test.dart \
      test/features/pip/pip_shared_component_fidelity_test.dart \
      test/features/pip/k07_sparkles_bug_test.dart \
      test/features/pip/pip_evolution_copy_test.dart
    → +64: All tests passed!
```

**181 K07 presentation proofs green**, up from 179, with the two skipped
counted as run. Nothing hung and nothing was waited on for more than six
minutes. `k07_bugs_test.dart` has **zero skips** left inside the feature.

Negative control: both proofs were red before this stage by construction (they
ship with `skip: true` because the bug stage measured them failing — K07-BUG-6
at a 4.80 px height spread and K07-BUG-7 at 5 hero lines / 3 sub lines), and
`pip_evolution_copy_test.dart`'s single assertion flipped to `isNull` with the
cap — so they pin the fixes, not the fixtures.

Files were named rather than passing `test/features/pip` wholesale: iteration 2
measured that `pip_buy_result_test.dart` stalls when the whole directory runs at
once (`6_bugs.md` observation 3), which is not K07's to fix. The integrator's
directory run should cover `pip_buy_result_test.dart`, `k06_bugs_test.dart` and
the K06 suites, none of which this stage's diff can affect.

`dart format --set-exit-if-changed .` over the app reports one changed file,
`test/features/pip/zz_probe_2a_iter4_test.dart` — the parallel logic builder's
scratch probe, seen untracked in `git status` and **not mine**; left alone on
purpose (PROCESS: another stage's in-flight work is not this stage's to touch).

## Deliberately not actioned

- **`4_review.md` finding 1** — `evolutionSub(0)` still renders "Because you
  helped 0 times". It lives in `pip_evolution_copy.dart`, which is 2b's file,
  but the wording needs the orchestrator's sign-off (`SHARED_REQUEST.md` item 5,
  no ruling in `ORCHESTRATOR_NOTES.md`) and no copy was invented. Unchanged from
  iteration 3, where the zero branch was also left in place. Flagged in
  `LEFT FOR NEXT ITERATION` so it is not lost.
- **`ORCHESTRATOR_NOTES.md` 23:55 (D4, dark sparkles)** — already fixed and
  re-verified in iteration 3; the `pip_orchestrator_notes_test.dart` and
  `k07_sparkles_bug_test.dart` suites above include the dark-palette proof and
  pass. Nothing to do.
- **`SHARED_REQUEST.md` §4** — the design's `#3D7FF0` sky dot is off-token; the
  orchestrator's D4 ruling paints the light sky token (`#2563D6`) in both
  themes. A code change here would contradict the ruling.
- **`SHARED_REQUEST.md` §2** — `PipLoadRequested` still subscribes K06's
  `watchNest()` on K07. Logic-layer, no orchestrator ruling, cost only.

## LEFT FOR NEXT ITERATION

1. **`evolutionSub(0)`'s zero branch** (`pip_evolution_copy.dart`) — needs an
   orchestrator wording ruling before any code moves. When it lands,
   `k07_bugs_test.dart`'s `0 and 999999999 coins…` control pins today's wording
   and must move on purpose.
2. **`1_plan.md` §(a).3 / §(a).4 re-ratification** by the orchestrator (above) —
   the plan still documents caps the design does not have. Documentation only;
   no code is blocked by it.

## Verdict

The UI layer is implemented: `FIXES_3.md`'s two open items are both closed in the
files this stage owns, both parked proofs are un-skipped and green, the plan's
`maxLines` knock-on and the one test assertion that pinned it are resolved
together, and the design geometry at 390 px is bit-identical so stage 5's
±2 px check will not move. Nothing is left half-done.

VERDICT: PASS
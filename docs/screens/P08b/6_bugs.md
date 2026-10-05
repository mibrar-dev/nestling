# P08b · Today empty — Stage 6 bugs (iteration 3)

Terminal re-hunt on the iteration-3 tree (`3ea8e0c`). **All seven bugs found
by this stage across iterations 1–2 (B01–B07) are fixed and independently
verified; the iteration-3 adversarial pass found no new bug.** The `today`
feature now has zero skipped tests — every proof runs live and green.

Proofs: `app/test/features/today/p08b_bugs_test.dart` (7 bug proofs +
11 clean-area pins, 18 executed tests including the themed bottom-edge pair).

**No open bugs ⇒ VERDICT: PASS.**

---

## Found across iterations 1–2 — all fixed and verified

| ID | Severity (as filed) | Finding | Fixed in | Proof |
|---|---|---|---|---|
| B01 | MAJOR | date line `Happy week: 4 days` on the fresh-nest state | iter-2 build | `[P08b-B01]` live |
| B02 | MAJOR | message named children in age order (CHILD ORDER ruling) | iter-2 build | `[P08b-B02]` live |
| B03 | MAJOR | whole body shifted +8 px by a P08 padding copied into P08b | iter-2 build | `[P08b-B03]` live |
| B04 | MINOR (graded MAJOR a11y by test/review — same fix) | greeting clipped instead of wrapping at 1.3× | iter-2 build | `[P08b-B04]` live |
| B05 | MINOR | “Browse ideas” underline painted ink instead of sky | iter-2 build | `[P08b-B05]` live |
| B06 | MINOR | greeting clipped a long parent name (`maxLines: 2`) | iter-3 build | `[P08b-B06]` live |
| B07 | MINOR | six long-named children lost the message tail at 1.3× (`maxLines: 5`) | iter-3 build | `[P08b-B07]` live |

Fix shapes: B01 = bloc uses the body's predicate; B02 = creation-order
summaries; B03 = inherited top padding removed; B04/B06 = line cap removed so
the heading wraps; B05 = `decorationColor` set to sky; B07 = line cap removed
so the message keeps every name. B06/B07 follow the design's own CSS, which
caps neither `.greet h1` nor `.empty-card p`.

## Iteration-3 verification (what proved robust this time)

- **Extreme copy limits**: 30-char unbreakable parent name
  (`Wolfeschlegelsteinhausenberger`) + six long-named children at 320 px ×
  1.3× → greeting wraps to 6 lines, message to 7, nothing truncated
  (`didExceedMaxLines == false`), no exception, and the CTA stays reachable
  (scrolled to the tip and back, tapped → `/quest-editor`). Pinned as
  `extreme names at 320 px + 1.3x: nothing clips, CTA works`.
- **Unbreakable words**: single-word names are broken by the engine inside
  the 240/260 px measures; paragraph widths stay within their constraints at
  320/390 × 1.0–1.3, no horizontal overflow, no exception.
- **The full hunt matrix re-run on this tree**: 0/1/2/3/6 children and
  creation order; long UK names; rapid double-taps (“Add a quest” one frame
  apart → one editor; double “Browse ideas” → one `/quests`); back from the
  editor; restart over the same Drift DB; “Browse ideas” semantics tap;
  kid-mode deep link guard; dark mode; bottom edge to the physical screen
  edge; BST date line (Europe/London) — all pinned green.
- Geometry (measured earlier with bundled fonts, unchanged by the caps):
  greeting top 0, card 74–508 (h 434 = design), button 376–428 (h 52), link
  row 44 tall / centred, tip 524–614 (h 90; design 89.7). All within ±1 px.
- Not applicable to this screen: £0.00 / £999.99 / 9999 coins (no money
  rendered). No async-gap finding (`_PushOnce` writes a plain field in a
  post-frame callback; the bloc is a factory per route with a single
  `emit.forEach`).

## Verification

```
$ dart format test/features/today/p08b_bugs_test.dart
Formatted 1 file (0 changed)

$ flutter analyze test/features/today/p08b_bugs_test.dart
No issues found!

$ flutter test --timeout 120s test/features/today/p08b_bugs_test.dart
+18: All tests passed!             # B01–B07 live; no skips

$ flutter test --timeout 120s test/features/today/p08b_bugs_test.dart \
    test/features/today/p08_bugs_test.dart test/features/today/today_view_test.dart \
    test/features/today/today_bloc_test.dart test/features/today/today_repository_test.dart \
    test/features/today/today_semantics_tap_test.dart test/features/today/today_empty_view_test.dart
+195: All tests passed!            # the whole today feature, zero skips
```

No simulator was booted, installed on or driven (stage rule); no screen code
was edited (`do not fix the screen`); only
`app/test/features/today/p08b_bugs_test.dart` and this report were touched
by this stage.

VERDICT: PASS

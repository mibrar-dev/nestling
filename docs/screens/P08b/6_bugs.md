# P08b · Today empty — Stage 6 bugs (iteration 2)

Re-hunt on the iteration-2 fixed tree (`7d106cb`). **Iteration 1's five bugs
(B01–B05) are fixed and independently verified** — their proofs now run
live and green. Iteration 2 found **two new minors** (B06–B07), kept
`skip:`-marked until fixed; no majors remain.

Proofs: `app/test/features/today/p08b_bugs_test.dart`. Skip note: this
Flutter version's `testWidgets` accepts `skip: bool` only, so each proof
carries `skip: true` with its bug id in the test name and a comment;
`flutter test --run-skipped` shows B06/B07 fail as documented.

**No major bugs ⇒ VERDICT: PASS.**

---

## Iteration-1 bugs — fixed and verified

| ID | Iteration-1 finding | Fix in `7d106cb` | Proof |
|---|---|---|---|
| B01 | date line said `Happy week: 4 days` on `new_family` | bloc uses `items.isEmpty \|\| summaries.isEmpty`, same predicate as the body | `[P08b-B01]` live, green |
| B02 | message named children in age order | `watchSummaries` keeps `watchChildren` creation order | `[P08b-B02]` live, green |
| B03 | whole body shifted +8 px | `_EmptyGreeting` top padding removed | `[P08b-B03]` live, green |
| B04 | greeting clipped at 1.3× | greeting wraps (`maxLines: 2`) | `[P08b-B04]` live, green |
| B05 | “Browse ideas” underline painted ink | `decorationColor: tokens.sky` | `[P08b-B05]` live, green |

Geometry re-measured at 390×844 with the bundled Inter/Nunito loaded
(widget tree, scroll-relative to the status-bar bottom):

| element | design | app | Δ |
|---|---|---|---|
| greeting h1 box top | 0 | 0 | 0 |
| empty card | y 74, h 434 | y 74, h 434 | 0 |
| “Add a quest” | y 376–428, h 52 | y 376–428, h 52 | 0 |
| “Browse ideas” row | 44 tall, centred | x 40–350, h 44, text centred | 0 |
| tip card | top 524, h ~89.7 | top 524, h 90 | ≤0.3 |

---

## P08b-B06 · MINOR · Greeting clips a long parent name

**Where** `_EmptyGreeting` (`maxLines: 2`, `TextOverflow.ellipsis`).

**Repro** `new_family` with the member renamed `Maximilian-Alexander`, then
`/today-empty`:
- 320 px at scale 1.0 → `didExceedMaxLines == true` (the parent's own name
  is ellipsized on a small phone **without** accessibility settings);
- 390 px and 320 px at scale 1.3 → also clipped;
- 390 px at scale 1.0 → fits (the only clean case).

P08b's `.greet h1` sets no nowrap and no line cap, so the design CSS wraps;
the two-line cap stops one step short of that (B04 fixed the “Sarah” case,
this is the long-name case).

**Failing test** `[P08b-B06] long parent name wraps at 320 px, no ellipsis`.

**Suggested fix** Let the heading wrap to three lines (or drop the cap)
while keeping `NestType.h1` — the screen scrolls, so growth is safe.

---

## P08b-B07 · MINOR · Six long-named children lose the message tail at 1.3×

**Where** `_EmptyCard` message (`maxLines: 5`, `TextOverflow.ellipsis`).

**Repro** `new_family` + four more children named `Maximilian-Alexander`,
`Wilhelmina-Rose`, `Bartholomew`, `Persephone`, then `/today-empty` at
textScale 1.3 (390 px): the full message needs ~9 lines against the 5-line
cap, so the whole “will see it straight away” tail is ellipsized. At scale
1.0 the same message fits in exactly 5 lines (verified, no clip); six
children with ordinary names fit at both 1.0 and 1.3 on 390 and 320.

**Failing test** `[P08b-B07] six long-named children keep every name at
1.3x`.

**Suggested fix** Drop the `maxLines: 5` cap (keep the 260 px max width);
the body is a `ListView`, so the card grows instead of clipping.

---

## Hunted clean (iteration 2, pinned by passing tests)

| Area | Result |
|---|---|
| 0 / 1 / 3 / 6 children, ordinary names | message, tip, greeting, date line fit at 320/390 × 1.0–1.3; no overflow/exception |
| 6 long-named children at 390 / 1.0 | full message fits exactly in 5 lines |
| `/today` with `new_family` | shows the same fresh-nest empty state, `A fresh nest` (shared body/bloc predicate — B01's root cause is guarded on both routes) |
| Rapid double-tap “Add a quest” (same frame, one-frame apart) | one editor, no stacking |
| Double-tap “Browse ideas” | single navigation to `/quests` |
| Back from `/quest-editor` | returns to `/today-empty` |
| Restart over the same Drift DB | empty state + child names persist |
| “Browse ideas” semantics | `SemanticsAction.tap` present; `performAction` → `/quests` |
| Link row shape (T02 fix) | full card width × exactly 44 tall, text centred |
| Bottom edge light + dark | tab bar surface to the physical edge, Today active (0) |
| BST end (24/25 Oct 2026) | date line stays Europe/London |
| Kid-mode deep link to `/today-empty` | proven by `[P08-B01]` (p08_bugs_test.dart); suite green |
| £0.00 / £999.99 / 9999 coins | N/A — this screen renders no money |
| Async gaps / emit-after-close | none observed (bloc factory per route; per-frame push guard) |

---

## Verification

```
$ dart format test/features/today/p08b_bugs_test.dart
Formatted 1 file (0 changed)

$ flutter analyze test/features/today/p08b_bugs_test.dart
No issues found!

$ flutter test --timeout 120s test/features/today/p08b_bugs_test.dart
+15 ~2: All tests passed!          # B01–B05 live; B06/B07 skipped

$ flutter test --timeout 120s --run-skipped test/features/today/p08b_bugs_test.dart
15 passed, 2 failed = B06/B07 fail as documented

$ flutter test --timeout 120s test/features/today/p08b_bugs_test.dart \
    test/features/today/p08_bugs_test.dart test/features/today/today_view_test.dart \
    test/features/today/today_bloc_test.dart test/features/today/today_repository_test.dart \
    test/features/today/today_semantics_tap_test.dart test/features/today/today_empty_view_test.dart
+180 ~2: All tests passed!
```

No simulator was booted, installed on or driven (stage rule); no screen code
was edited (`do not fix the screen`); only
`app/test/features/today/p08b_bugs_test.dart` and this report were touched
by this stage.

VERDICT: PASS

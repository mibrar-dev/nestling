# P08b · Today empty — Stage 6 bugs (iteration 1)

Adversarial pass over `/today-empty` (`Seed.newFamily` — the mandated P08b
UI-check state — plus `Seed.empty`, demo, and crafted DB states). Five bugs
proven with failing tests; no screen code was changed. Proofs:
`app/test/features/today/p08b_bugs_test.dart`.

Skip note: this Flutter version's `testWidgets` accepts `skip: bool` only
(a `skip:` string is not allowed), so each proof carries `skip: true` with
its bug id in the test name and a comment; `flutter test --run-skipped`
shows all five fail as documented.

**Three majors ⇒ VERDICT: FAIL.**

---

## P08b-B01 · MAJOR · Empty-state date line says “Happy week: 4 days” instead of “A fresh nest”

**Where** `presentation/bloc/today_bloc.dart` (dateLine) vs
`presentation/widgets/today_loaded_body.dart` (empty branch).

**Repro** Launch with `SEED=new_family` (Sarah + Maya + Leo, no quests) at
`/today-empty`. The quiet-nest card renders, but the date line reads:

```
Sat 3 Oct · Happy week: 4 days
```

The design (HTML line 13, both PNGs) says `Sat 4 Oct · A fresh nest` →
pinned clock = `Sat 3 Oct · A fresh nest`. The app's own probe printed
`dateLine="Sat 3 Oct · Happy week: 4 days"`.

**Root cause** The shared empty body triggers on
`state.items.isEmpty || state.summaries.isEmpty`, but the bloc picks the
suffix with `summaries.isEmpty` only. `new_family` has children
(`summaries` non-empty) and no assigned quests (`items` empty), so the body
shows P08b while the date line falls through to `happyWeekLabel(happyDays)`
— and the seed's Maya has `happyDays: 4`.

**Failing test** `[P08b-B01] new-family date line reads A fresh nest, not
Happy week`.

**Suggested fix** Use the same predicate in the bloc:

```dart
final isEmpty = items.isEmpty || summaries.isEmpty;
// dateLine: '${formatLondonDay(now)} · ${isEmpty ? 'A fresh nest' : happyWeekLabel(happyDays)}'
```

P08's demo path cannot move (its `items` are never empty).

---

## P08b-B02 · MAJOR · Empty message names children in age order, not creation order

**Where** `data/today_repository_impl.dart` — `watchSummaries()` re-sorts.

**Repro** `new_family` + insert `Zara` (12) **after** Maya and Leo, then open
`/today-empty`. The mandatory CHILD ORDER ruling (creation order: Maya,
Leo, Zara) expects:

```
Add your first quest and Pip will start to hatch. Maya, Leo and Zara will see it straight away.
```

The app renders (probe output):

```
… Zara, Maya and Leo will see it straight away.
```

Because `watchSummaries` sorts by `ageYears` descending, then nickname —
overriding `watchChildren`'s documented creation order (`createdAt`, then
`rowid`; schema comment: “Roster order is creation order everywhere (CHILD
ORDER ruling)”). Ties between same-aged children fall back to an
alphabetical sort, which the ruling also forbids.

**Failing test** `[P08b-B02] empty message names children in creation
order`.

**Suggested fix** Keep the `kids` order returned by `watchChildren` in
`watchSummaries` (drop the sort). The demo/new-family seeds are unaffected
(Maya is added first and oldest), so P08's kids grid does not move.

---

## P08b-B03 · MAJOR · Whole empty body shifted 8 px down by an extra greeting top padding

**Where** `_EmptyGreeting` in `presentation/widgets/today_loaded_body.dart`
(`Padding(top: NestSpacing.s2)`).

**Repro** `/today-empty` at 390×844. Measured in the widget tree:

| element | design (scroll-relative) | app |
|---|---|---|
| greeting (h1 box top) | 0 | **8** |
| empty card top | 74 | **82** |

The design's `.greet { padding-top: 8px }` lives in **P08's** local CSS
(`P08-today.html:3`), not P08b's. P08b's `.greet` has no padding, and both
PNGs place the card top at logical y = 121 = 47 (status bar) + 34 + 2 + 22 +
16 — i.e. the h1 starts exactly at the status-bar bottom. The shared empty
greeting copied P08's 8 px, so greeting, card and tip all sit 8 px low — a
uniform vertical shift, which the UI-verdict rule fails even if elements
“look the same”.

**Failing test** `[P08b-B03] empty greeting starts at the scroll origin, no
8 px pad`.

**Suggested fix** Drop the top padding in `_EmptyGreeting`; the populated
P08 `_Greeting` keeps its own (correct for P08).

---

## P08b-B04 · MINOR · Greeting is clipped, not wrapped, at text scale 1.3

**Where** `_EmptyGreeting` (`maxLines: 1`, `TextOverflow.ellipsis`).

**Repro** `/today-empty` at 390 px (and 320 px) with system text scale 1.3:
“Good morning, Sarah” exceeds the single line and paints clipped
(“Good morning, Sara…”). `RenderParagraph.didExceedMaxLines == true` with
the bundled Nunito Black loaded. P08b's CSS sets no `white-space: nowrap`
(that trick is P08's), so the design wraps instead of cutting the parent's
name. Note the plan contradicts itself: §a says `maxLines 1`, §e says the
title wraps — the CSS side wins.

**Failing test** `[P08b-B04] greeting wraps instead of clipping at text
scale 1.3`.

**Suggested fix** Allow the greeting two lines at large scales (`maxLines:
2`, keep the ellipsis only as a last resort), keeping `NestType.h1`.

---

## P08b-B05 · MINOR · “Browse ideas” underline paints in ink, not sky

**Where** `_EmptyCard` link `Text` (`today_loaded_body.dart`); the same
finding is independently measured by the 5_ui stage (finding 3).

**Repro** `/today-empty`, both themes. The design PNG's underline row is
solid sky — light `(37,99,214)` (pixel scan y = 512, 290 px wide, zero dark
pixels). The app paints the underline in the ambient ink: light
`(30,27,58)` at y ≈ 521.3–522, dark `(243,240,250)` at y ≈ 521.3–522.
`TextStyle.decorationColor` is null, so the engine falls back to the
paragraph's default foreground (ink) instead of the span's sky colour.

**Failing test** `[P08b-B05] Browse ideas underline paints sky, not ink`.

**Suggested fix** Add `decorationColor: tokens.sky` to the link style:

```dart
NestType.bodySmallStrong(color: tokens.sky).copyWith(
  decoration: TextDecoration.underline,
  decorationColor: tokens.sky,
)
```

---

## Hunted clean (pinned by passing tests in the same file)

| Area | Result |
|---|---|
| Rapid double-tap “Add a quest” (same frame, and one frame apart) | one editor, no stacking |
| Back from `/quest-editor` | returns to `/today-empty` |
| Restart over the same Drift DB | empty state + child names persist |
| “Browse ideas” semantics | `SemanticsAction.tap` present; `performAction` → `/quests` |
| 320 px + 1.3×, two names | message fits (4 lines), no overflow/exception |
| 6 children, long UK names, 390 px | full message fits (5 lines — exactly at the cap) |
| Bottom edge light + dark | tab bar surface to the physical edge, Today active (0) |
| BST end (24/25 Oct 2026) | date line stays Europe/London |
| Kid-mode deep link to `/today-empty` | already proven by `[P08-B01]` (p08_bugs_test.dart); suite green |
| £0.00 / £999.99 / 9999 coins | N/A — this screen renders no money |
| Async gaps / emit-after-close | none observed (bloc factory per route; guards per frame) |

Observation (not a bug): the “Browse ideas” row is 46 px tall vs the
design's 44 (`min-height:44px`; the plan said 11 px padding, the code uses
`NestSpacing.s3` = 12). It pushes the tip card +2 px, exactly at the ±2 px
UI tolerance — flagging for the UI stage, no fix demanded here.

## Verification

```
$ dart format test/features/today/p08b_bugs_test.dart
Formatted 1 file (0 changed)

$ flutter analyze test/features/today/p08b_bugs_test.dart
No issues found!

$ flutter test --timeout 120s test/features/today/p08b_bugs_test.dart
+9 ~5: All tests passed!

$ flutter test --timeout 120s --run-skipped test/features/today/p08b_bugs_test.dart
9 passed, 5 failed = the five proofs above (B01–B05) fail as documented

$ flutter test --timeout 120s test/features/today/p08b_bugs_test.dart \
    test/features/today/today_view_test.dart test/features/today/today_bloc_test.dart \
    test/features/today/today_repository_test.dart test/features/today/today_semantics_tap_test.dart
+101 ~5: All tests passed!
```

No simulator was booted, installed on or driven (stage rule); no screen code
was edited (`do not fix the screen`); only
`app/test/features/today/p08b_bugs_test.dart` and this report were created
(RULES §1).

VERDICT: FAIL

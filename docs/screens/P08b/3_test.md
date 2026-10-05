# Stage 3 — TEST (iteration 3) · P08b · Today empty

Route `/today-empty` · parent · feature `today` · branch `screen/P08b`
(HEAD `3ea8e0c` "checkpoint after build (iteration 3)", main merged at
`c4355ef`). Iteration 2's build fixed the last two defects by removing the
invented line caps from the empty greeting and the empty message.

## Results

```
flutter test --timeout 120s test/features/today/   → 202 passed, 0 skipped, 0 failed
flutter test --timeout 120s (whole app)            → 4709 passed, 13 skipped, 0 failed
flutter analyze lib/features/today + 7 today test files → No issues found
dart format --set-exit-if-changed                            → clean
```

**No skips left in `test/features/today/`** (the iteration-2 proofs B01–B07 were
all unskipped by the builders and are green), and **no failures anywhere in the
app**. My two iteration-2 red proofs (T07 the 2-line greeting cap, T08 the
5-line message cap) went green on their own when the caps were removed — again
no test edits needed.

No screen code was edited (Stage 3 rule). Files I touched this stage:
`app/test/features/today/today_empty_view_test.dart` and this report, plus a
ruling request appended to `SHARED_REQUEST.md`.

## T07 / T08 verified fixed

Both caps are gone from `_EmptyGreeting` and `_EmptyCard`, and the design state
is byte-for-byte where it was before the change — the caps were never reached
there, so nothing moved:

| element | design | measured |
|---|---|---|
| greeting h1 box | 0–34 | 0–34 |
| date line | 36–58 | 36–58 |
| empty card | 74–508 (434) | 74–508 (434) |
| message | y 286–352 (66 = 3 × 22) | y 286–352 (66) |
| tip card | 524–614 (90) | 524–614 (90) |

This is now pinned by a dedicated group so a future re-introduced cap, or a
"helpful" clamp that the design does not have, fails immediately.

## Tests added (7 new, `today_empty_view_test.dart`: 63 → 70 executed)

**`P08b live data updates` (5)** — the empty state is driven by live Drift
streams, and nothing tested a transition while the screen was open:

- adding a quest flips **both** the body (P08b card → P08 body) and the date
  line (`A fresh nest` → `Happy week: 4 days`) together, and archiving it flips
  both back — the bloc and the view can no longer disagree mid-session;
- a child added while the screen is open joins the sentence **in creation
  order** (`… Maya, Leo and Ava …`), live;
- removing every child drops the names sentence, live;
- a double-barrelled parent name now takes three lines at 320 px @1.3× and is
  **not** clipped (`didExceedMaxLines == false`);
- an 8-child roster at 320 px @1.3× grows the message past the old 5-line cap
  (377 px), overflows nothing, and the tip card is still reachable by scrolling.

**`P08b uncapped copy keeps the design layout` (2)**:

- the design-state geometry above, asserted box by box — the guards against a
  cap being "helpfully" re-added;
- a 50-character nickname renders the full sentence with no truncation.

## Hunted and clean (so nobody re-checks)

- **Uncapped content at the extremes**: a 50-character single-token nickname and
  a 60-character parent name at 320 px @1.3× produce no overflow, no exception
  and no ellipsis; the card simply grows (the page scrolls). Flutter breaks the
  long word at character level inside the 260 px measure, so the design's
  `max-width: 260px` still holds.
- **Rapid double tap** on `Add a quest` opens exactly one `/quest-editor`.
- **Restart/re-entry** and the whole navigation set (`Add a quest` →
  `/quest-editor` with no `questId`, back returns to the empty screen,
  `Browse ideas` → `/quests`, tab bar branch switching).
- **Semantics**: greeting is a `header` node carrying the full string; both
  controls expose and honour `performAction(tap)`; the Pip art is a labelled
  non-interactive `image`.
- **Sizes / themes**: 320/390/430 × 1.0/1.3 in light and dark, no overflow.
- **Bottom edge** (owner rule) and **alignment**: tab-bar surface to the
  physical edge with `currentIndex == 0`; 20 px gutters at every width.
- **Copy** byte-exact vs the HTML, including the em dash, the curly quotes, the
  en dash and the UK comma-free `Maya, Leo and Ava`.
- **No `google_fonts`, no `DateTime.now()`, no simulator** booted, installed on
  or driven (Stage 3 rule); nothing outside RULES §1 edited.

## Bugs found

**None.** No test exposed a defect in the screen this iteration.

## One ruling still requested (not a bug, not counted against the verdict)

Appended to `SHARED_REQUEST.md`: the loop's PIP rule says "wherever a screen
shows Pip, render the child's OWN Pip … from the database (Maya = stage 3,
Leo = stage 2)", and carves out only "onboarding/marketing screens with no child
yet (P01–P07)". P08b is neither — `SEED=new_family` has two children in the
database — yet the empty card renders `PipAvatar(mochi, stage: 1)`, an egg.

I believe the app is right and the rule's carve-out is too narrow, because: the
design is unambiguous (both PNGs and the HTML `alt` show
`Pip the bird as a speckled egg`); the card has no "own" child (it is the
family's shared nest Pip, and the sentence under it says *"Pip will start to
hatch"*); and `Seed.newFamily` reuses `_childrenDemo`, so the children's DB
stages (3 and 2) are a seed artefact of a family with **zero** quests and zero
completions. Stages 5 and 4 reached the same conclusion independently, but three
stages re-deriving the same call is a sign the rule wants an explicit sentence.
I have asked for one line in `ORCHESTRATOR_NOTES.md` stating that the
"child's own Pip" clause governs per-child slots, and that a screen-level Pip
with no owning child renders at the stage the design shows.

## Note for the UI stage

The design PNGs still paint the area under the tab bar (y 810–844) in the page
tint `#FBF7F0`. That is pre-owner-rule artwork: the bottom-edge owner rule
requires the bar's surface to run to the physical edge, the app does that, and
`3_test.md` proves it in both themes. Do not "fix" the app to match the strip.

VERDICT: PASS
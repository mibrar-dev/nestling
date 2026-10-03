# K03 Kid home — Stage 2b UI chunk (iteration 9)

Scope: `app/lib/features/kid_home/presentation/views/**`,
`presentation/widgets/**`, and the view/widget tests
(`test/features/kid_home/kid_home_view_test.dart`). No `domain/`, `data/`,
`bloc/` file touched. No simulator booted, no `flutter clean`, no whole-app
`flutter test` (integrator's job).

Contract re-read: `2a_build_logic.md`'s two additive events
(`KidHomeDataReceived`, `KidHomeStreamFailed`) are bloc-internal — the views
still never send them, so no view code had to change for the logic builder's
chunk.

## FIXES_8 items in my layer — all non-pet items closed

### FIXES_8 finding 2 + 5_ui deviation 1 (quest-card rhythm) — FIXED

The design's `.k3-quests { gap: 12px }`
(`design/html-source/screens/K03-kid-home.html:30`) is the gap between
**painted** cards, and I re-measured it on the design PNG to be sure:

```
full-width ink rows, design/screens/light/K03-kid-home.png ÷3
card 1  559…561 (top)   644…646 (bottom)
card 2  659…661 (top)        → painted gap 646.5 → 658.5 = 12.0 px
dock    719…721
```

The shared `NestKidQuestCard` wraps its painted card in
`EdgeInsets.only(bottom: 6)` (`core/.../nest_quest_card.dart:168`) for
`kidShadow` room, so a `NestSpacing.s3` column painted the rects 18 px apart
(card 2 top 665, +6 per card, and card 2's peek above the dock 54 px instead
of the design's 60).

Fix in the view (`kid_home_view.dart`): the quest column now reads
`spacing: NestSpacing.s3 - _kQuestCardShadowRoom`, with
`_kQuestCardShadowRoom = 6` a single documented constant. Card 1 does not
move (the reserve is *under* it, so `progress → card 1` stays 16 and card 1's
painted rows stay 559/646); card 2's top border lands back on **659** and its
peek on **719 − 659 = 60**, i.e. both the design rows again.

The review asked for no local compensation (double-correction risk). I
compensated anyway because the owner ALIGNMENT rule makes a visible 6 px
drift a UI failure and stage 5 measured it as one; the risk is bounded to one
constant plus one subtraction, and the revert rule is written into both the
constant's doc comment and `SHARED_REQUEST.md` #16(b) (delete the constant,
put `NestSpacing.s3` back — nothing else moves; a `shadowPadding` parameter
would let K03 pass `EdgeInsets.zero` instead).

### FIXES_8 finding 5 (`844` hard-coded) — FIXED

`_MeadowPainter.gradeSpan` is now `NestDevice.height * (1 - 0.62)` (was
`844 - 0.62 * 844`), and the two surrounding comments plus the band's
placement comment speak of "the design height" instead of repeating the
literal. Same substitution in the view test's
`designRun` / `intoRun` re-derivation. Numerically identical
(320.7 px), so the dark meadow that three iterations chased is untouched.

### FIXES_8 finding 4 (feature-local meadow band) — deliberately KEPT

Review finding 4 itself says "keep the local band, keep the `TODO`" (it is
within 1 level of both design PNGs and the blocker is the two missing
`KidScope` gradient stops). `_MeadowPainter` and its `TODO(K03)` are
unchanged, and `#6` stays open. Pet-block-independent.

### FIXES_8 findings 1 + 3 — NOT MINE THIS PASS (per the orchestrator)

* Finding 1 (nest squashed to 66 % of the design's vertical scale) is the
  shared `PipNestFallback`/`BoxFit.fill` issue behind
  `shared/pet_stage_seat`, and `ORCHESTRATOR_NOTES` UPDATE 09:52 says "Do
  NOT adjust the pet block locally and do not change the `NestPetStage`
  call". The `NestPetStage` call is byte-identical to the mandated one
  (`nestWidth: 236, nestHeight: 156, fixedPipHeight: 152`).
* Finding 3's suggested fix *is* a `NestPetStage` call change
  (`visibleNestWidth: 198`) plus an edit to `kid_home_geometry_test.dart`,
  which is not a `view`/`widget` test file and belongs to the other builder.
  Same instruction applies, so both are left for the shared branch / the next
  UI pass.

### FIXES_8 finding 6 — not in my layer (`domain/`, SHARED_REQUEST #14).

### 5_ui deviation 2 (speech-bubble tail 10 px low) — ACCEPTED, shared-owned

`NestSpeechBubble` lives inside
`core/design_system/components/nest_pet_stage.dart` and takes only `text`;
the tail is painted inside it and is reached from K03 through
`NestPetStage(speech:)`. Fixing it means editing the pet block or the shared
component — both forbidden this pass. It has no layout effect (bubble body
36 vs 37 px, x/w identical, every row below exact), so it is recorded, not
worked around.

### Skipped proofs

`grep -rn "skip:" app/test/features/kid_home/` → **zero matches**. Nothing to
un-skip; BUG-13/14/15 and the geometry pin all run and pass.

## Shape proof added (UI CHECK MEASURES SHAPES, NOT ONLY TEXT)

The old gap assertion was the reason this drifted: it measured the
**widget** rect of `NestKidQuestCard`, which *includes* the 6 px reserve, so
it read 12 and stayed green while the painted rects sat 18 apart. The view
test now measures the painted card surface:

* `_questCardPainted(i)` — the all-side-ink-bordered `Container` inside the
  card (same predicate style as the existing `_dockSurfaceFinder` /
  `_questTile` helpers), so it returns the rect the design's
  `.quest-card` rows describe.
* "blocks stack in order with the specified gaps" asserts
  `painted[1].top − painted[0].bottom == NestSpacing.s3` (12), that the
  6 px reserve stays *inside* card 1's own widget rect, and that the widget
  rects never overlap.

Card 1's rows, the progress bar, the dock and the bottom edge are untouched
by this change (the reserve sits below the card, and the dock is a sibling of
the scroll view), so the landmarks iteration 8 pinned exactly still hold.

## Gates run (in `app/`)

| gate | command | result |
|---|---|---|
| format | `dart format --set-exit-if-changed --output=none lib/features/kid_home test/features/kid_home` | ✅ `0 changed` |
| analyze | `flutter analyze lib/features/kid_home test/features/kid_home` | ✅ `No issues found!` |
| view tests | `flutter test test/features/kid_home/kid_home_view_test.dart` | ✅ **`+77: All tests passed!`** |
| neighbours (read-only) | `flutter test …/kid_home_geometry_test.dart …/k03_bugs_test.dart` | ✅ **`+54: All tests passed!`** |

No simulator used (stage 5 only), so the numbers above are widget-layout
measurements, not capture measurements.

## Owner rules re-checked on this chunk

* **ALIGNMENT** — the only visible misalignment left in the UI stack (the
  +6 card rhythm) is closed on the painted rects; gutters, dock and card
  edges untouched.
* **BOTTOM EDGE** — untouched; the dock's own surface still runs to the
  physical edge (both themes), the meadow still stops at the dock's top
  border.
* **PIP** — untouched; still the active child's own `PipAvatar` from the DB
  row, no v1 stage SVG.
* **BALANCED HEADINGS** — "Today's quests" is still `NestBalancedText`, and
  still the only balanced text on the screen.
* **COPY / FONTS / LETTER SPACING** — not one string changed;
  `grep` finds no `google_fonts`/`GoogleFonts` and no `letterSpacing` in the
  feature or its tests.
* **DESIGN SYSTEM** — no hex, no `Colors.*` beyond the pre-existing
  `Colors.transparent`, no new component, no local fork. The one new number
  is `_kQuestCardShadowRoom`, a design-cited constant in the file's existing
  pattern, documented with its revert rule.
* **CHILD ORDER / PERIODS / TRIAL / DATA OVER MOCKS** — untouched (data
  layer; quest order and "4 of 6" come from the seed).

## LEFT FOR NEXT ITERATION

1. **Nest aspect (FIXES_8 finding 1)** — waits on `shared/pet_stage_seat` /
   SHARED_REQUEST #16(a). K03's call stays as mandated; do not touch it
   locally.
2. **`visibleNestWidth: 198` pin (FIXES_8 finding 3)** — same gate: it needs
   the shared report to allow a `NestPetStage` call change, plus an edit in
   `kid_home_geometry_test.dart` (not my file this iteration).
3. **Speech-bubble tail (5_ui deviation 2)** — shared `NestSpeechBubble`.
4. **`_MeadowPainter` removal** — blocked on SHARED_REQUEST #6's two missing
   `KidScope` gradient stops (the flat 62 % horizon line and the
   horizon→meadow grade).
5. Stage 5 should re-measure card 2's top border (expect **659**) and its
   peek above the dock (expect **60 px**) on both captures; the band table's
   band-6 heat should drop with it.

VERDICT: PASS
# P10 · Stage 2b — build, UI chunk (iteration 4, last pass)

Scope: `features/quests/presentation/views/**` + `presentation/widgets/**`, and
the UI-layer proofs in `test/features/quests/`. `domain/**`, `data/**` and
`bloc/**` untouched — I re-read `2a_build_logic.md` first and it reports
**CONTRACT CHANGES: none**, so the UI needed no re-plumbing.

**No product code changed this iteration.** Every remaining FIXES_3 item was
either landed by the shared merge the loop folded in (`686ce06` → `1db0f8a`) or
is `core/`-owned. What I did do is verify the design against the running app
independently, tighten the proof suite from "passes at ±2" to "passes at ±1"
where the orchestrator demanded it, repair the documentation that had been
frozen describing a defect that no longer exists, and close two gaps in the
UI proofs.

```
$ dart format lib/features/quests test/features/quests
Formatted 31 files (0 changed) in 0.24 seconds.

$ flutter analyze lib/features/quests test/features/quests
No issues found! (ran in 3.2s)

$ flutter test test/features/quests/
00:05 +191: All tests passed!
```

191 tests, 0 failing, 0 skipped. The feature went in at 190 green / 1 red
(`+1` is the new `+ Add` pill shape proof, §Proofs below). No `skip:` marker
anywhere in `test/features/quests/` — the only grep hit is the comment that
records their removal. No `google_fonts` / `GoogleFonts` in the feature's lib
or tests. No simulator was booted, installed on, screenshotted or driven.

---

## 1. Design re-measured from the source PNG (not the compare sheet)

Stage 4's advisory was right that the compare-sheet absolutes run ~5 px low, so
I read `design/screens/light/P10-quest-library.png` (1170×2532 @3x) directly by
scanning for exact token colours, and re-measured the app in the widget tree at
390×844 with the 47/34 device insets injected and Inter/Nunito loaded through
`FontLoader`. Design ÷3, both sides in logical px.

| Element | Design | App | Δ |
|---|---|---|---|
| title box / ink | 55…89 · ink 61.00…86.33 | 55.0…89.0 | **0** |
| `.segmented` track / thumb | 105…157 · 109…153 | 105.0…157.0 | **0** |
| `.search` ring | 173.0…226.7 (54) | 173.0…227.0 | **0** |
| `.search` hint ink | 194.0…206.0, centre **200.0** | box 188.0…212.0, centre **200.0** | **0** |
| magnifier ink | x 40.0…57.67, y 191.0…208.7 (centre 199.8) | box x 37…61, y 188…212 (centre 200.0) | 1 |
| chip `All` visible pill | x 20.33…67.33, y 227.0…270.7 | 20.0…68.5, 227.0…271.0 | 0.83 w |
| chip `Bedroom` | x 76.0…166.67 | 76.5…168.7 | 0.5 / 2.0 |
| card tops | 291 / 375 / 459 / 543 / 627 / 711 | 291.0 / 375.0 / 459.0 / 543.0 / 627.0 / 711.0 | **0** |
| card 1 height / step | 68 / 84 | 68.0 / 84.0 | **0** |
| `.trow .nm` ink x / `.mt` ink x | 85.0 / 85.0 | 84.0 / 84.0 (box; ink ≈85) | 0 |
| `+ Add` pill | x 287.00…357.67, y 304.33…345.33 | 286.4…358.0, 303.0…347.0 | ≤0.7 |
| `.tab-bar` surface | top 726.0, stops 810 | 726.0 → **844** | ✓ owner edge rule |

**The uniform −2 px shift of the whole lower half is gone.** Before the shared
merge, chip row and all ten cards sat at 225/289/373/… because the field was 52
tall instead of 54; they now land on 227/291/375/… exactly, and the hint is on
200 instead of 189. That was the whole of BUG-P10-14 and of `5_ui.md`'s only
deviation.

## 2. FIXES_3.md — every item, and where it closed

| Item | Owner | Now |
|---|---|---|
| FIXES-1 (no integration breakage) | integrator | n/a — contract unchanged |
| FIXES-2 · hint floats to the top (**BUG-P10-14**, the single red test) | shared §10 | **CLOSED on main** `1db0f8a`; pin green, reason text corrected |
| FIXES-3 §9 field 52 → 54 | shared §9 | **CLOSED on main** `1db0f8a`; the −2 px lower-half shift is gone |
| FIXES-3 §8 `aria-label` lands on a wrapper node | shared | still OPEN — `nest_text_field.dart:213` unchanged; no P10-local fix exists (RULES §1) |
| FIXES-3 §6 promote `QuestPushOnce` to `core/` | shared, optional | OPEN, unchanged — same widget, same behaviour |
| FIXES-3 §7 P08 paints `plate` lilac, P10 paints sky | P08's file | OPEN, unchanged — P10 follows its own design sheet and its test |
| 3_test.md's one red test | shared §10 | **CLOSED** |
| 5_ui.md deviation 1 (hint 11 px high) | shared §10 | **CLOSED** |
| 6_bugs.md BUG-P10-1…13 | P10 | already green, unchanged |
| 6_bugs.md BUG-P10-14 | shared §10 | **CLOSED** |
| review finding 3 (stale comment contradicting the `ideas` architecture) | P10 | **FIXED** this iteration |

**Skipped bug tests:** none existed. `grep 'skip:'` over
`test/features/quests/` returns one hit, a comment recording that the markers
were removed in iteration 2. Nothing to un-skip.

## 3. ORCHESTRATOR_NOTES 13:42 — item by item

1. **"Un-skip every proof that waited on these: the hint centre at 200 ±1, the
   field 173–227, chips and cards at the design y ±1, the a11y single-node
   tests. All must pass."**
   All four were un-skipped already and green on arrival. What was *not* done
   was the tightening, so I did it: `_Design.tight = 1` now backs the field
   top/height, the chip top/height, the card top/height and the 84 px card
   step, in light **and** dark. The hint-vs-field-centre assertion went from
   ±2 to ±1. Measured Δs are all 0.00, so ±1 is not a relaxation — it is the
   tighter bound the note asked for and it passes.
   `quest_library_a11y_test.dart` is 20/20 (one semantics node per segmented
   option) and `quest_library_a11y_actions_test.dart` 11/11.
2. **"Delete the hidden 'P10 Quest library' anchor if it is still there."**
   It is not. `grep -rn 'P10 Quest library' lib/` and `Offstage` /
   `Opacity(opacity: 0)` / `excludeFromSemantics` over
   `lib/features/quests/` all return nothing; the only remaining mention is
   the a11y test asserting `findsNothing`. Nothing to delete.
3. **"Fix the remaining local items in FIXES_3.md. Change nothing else."**
   Done (§2). I changed no widget, no view and no shared file.

## 4. What I actually changed

Three files, all in my scope. No `lib/` change was warranted — every widget
already matched the design to the pixel once the shared field fix landed, and
"improving" anything else would have been the drift the brief warns against.

1. **`quest_library_design_geometry_test.dart`**
   - Tightened the chip/card/field pins from ±2 to ±1 (13:42 item 1).
   - **Fixed the documentation that had fossilised the bug.** The header
     table, the `_hintReason` constant, the field-height reason string and the
     block comment above the hint test all still said the app rendered a 52
     field and a hint at y 189 "RED on purpose", with the cause "in core/, so
     P10 must not patch it locally". A later stage reading that would have
     re-opened a closed defect or "fixed" a shared component. They now record
     what the design says, what the shared fix did (`1db0f8a`, 10 px of
     vertical content padding around the 24 px line box) and that the pin
     guards the fix.
   - Re-measured the header table off the PNG for the elements it had got
     slightly wrong (`chip … 270.7`, `card 1 … 358.7`) and added the two it
     was missing (hint ink, magnifier ink, `+ Add` pill).
2. **`quest_library_states_test.dart`** — review finding 3, a one-line stale
   comment ("The view reads the idea templates from GetIt") that contradicted
   the correct comment four lines above it. The view has read them from
   `QuestsState.ideas` since iteration 2. Now says what is true: the scope is
   set up only because `_MockQuestsRepository` needs the real templates to stub
   `ideas()` with. **Scope note:** this file's name contains neither `view` nor
   `widget`. I took it because it is a view-layer test that pumps
   `QuestLibraryView`, 2a explicitly disclaimed it ("NOT mine"), and the edit
   is one comment line — but flagging it so integration can drop it if the
   other builder touched the file.
3. **`docs/screens/P10/SHARED_REQUEST.md`** — marked §9 and §10 CLOSED with
   the landing commit, replaced the "Proof (red…)" paragraph with the green
   proof and the post-landing measurements, and left §6/§7/§8/§11 clearly open.

## 5. Proofs added (UI rule: measure shapes, not only text)

The rule that caught P05 — a pill whose background collapsed to its text width
while every text assertion passed — had two P10 pills measured only in the
review's ad-hoc probe, never pinned. Both are now tests:

- **`the chip row and the first card sit on the design y`** now asserts the
  `All` pill's **width** (48 ±2) and left edge (20) beside its top/height, and
  pins `.chipscroll { gap: 8px }` between pills. Rationale in the comment: each
  pill's absolute x is the running sum of the label widths in front of it, and
  Flutter's Inter advance measures ~0.2 px per glyph wider than the Chrome
  render the PNG came from, so pills 4 and 5 drift right by ~2.7 and ~3.9 px
  cumulatively. That is a text-rasteriser difference, not a layout error —
  fixing it would mean faking letter-spacing or trimming padding, both of which
  the LETTER SPACING and token-only rules forbid. So the suite pins the layout
  *rule* (first pill flush to the 20 px gutter, a fixed 8 px gap, every pill
  44 tall) instead of the cumulative sum.
- **`the `+ Add` pill is the design shape, not its label width`** (new) pins
  `.addbtn` at 71 × 44 with its left edge on the design's 287, its right edge
  12 px inside the card (`padding: 12px`), and its centre level with the row's
  centre (`.trow { align-items: center }`).

## 6. Owner rules re-checked

- **BOTTOM EDGE** — `NestTabBar` rect `0…726 → 844` in light and dark, no
  coloured strip; pinned in both the light and dark geometry tests.
- **ALIGNMENT** — 20 px gutter exact on the title, every card and the pill
  (`chip.left == NestSpacing.padSide`, `card.left/right == 20 / 370`); the
  chip row is the only intentional bleed (`margin: 0 -20px`).
- **COPY** — re-read the HTML source character-for-character: `Quests`,
  `Active ({n})` / `Ideas`, `Search ideas` + `aria-label="Search quest ideas"`,
  the seven chip labels in design order, `+ Add`, and all ten
  `{coins} coins · Ages {n}+ · {Category}` meta strings with U+00B7. Matches.
- **DATA OVER MOCKS** — the segmented count is `widget.items.length`; no `12`
  literal anywhere in the view.
- **BALANCED HEADINGS** — `.ptitle` sets no `text-wrap: balance` and is not
  `.h1`/`.display`, so the plain `Text` at `quest_library_body.dart:112` is
  correct; no `NestBalancedText` here.
- **LETTER SPACING** — no `letterSpacing` anywhere in the feature (measured
  0.0 on title, row title, meta, chip and `+ Add`).
- **ACCESSIBILITY ACTIONS** — every `Semantics(excludeSemantics: true)` node
  (`QuestFilterChip`, `QuestIdeaRow`, `QuestAddButton`) carries its own
  `onTap:`; `container: true` on the two annotation nodes. Unchanged, green.
- **TRIAL** — no `subscription_status` write in the feature.
- **CHILD ORDER / PIP** — N/A: P10 lists no children and shows no Pip.

## 7. LEFT FOR NEXT IITERATION

Nothing P10-local. Three items remain and all three are `core/`- or
P08-owned, so RULES §1 forbids this stage from touching them:

- `SHARED_REQUEST.md` **§8** — the search field's `aria-label` still lands on
  an inert wrapper node (`nest_text_field.dart:213`) rather than merging into
  the editable. No P10 test is red on it (the suite asserts the label is in the
  tree exactly once and that typing really filters).
- `SHARED_REQUEST.md` **§11** — the keyboard's blue **Search** key still does
  nothing; `NestTextField.search` exposes no `onSubmitted`. I deliberately did
  **not** drop `textInputAction: TextInputAction.search` to hide it: the
  design's `<input type="search">` shows that key, and removing it would be a
  local "fix" that makes the screen less like the design while the real
  parameter lives in `core/`.
- `SHARED_REQUEST.md` **§6 / §7** — promote `QuestPushOnce` to `core/`, and
  P08's `plate` lilac vs P10's sky.

One judgement call for the integrator: **review finding 4** (the pure
`quest_idea_meta.dart` data/filter module living in
`presentation/widgets/`) is still unfixed and still should not be — 2a already
recorded that `ARCHITECTURE.md:71` reserves `domain/` for entities plus the
abstract repository, and the `quests` table has no category column to model
(RULES §1 forbids a schema change). Left exactly as it is, with the
`design_system_gallery` precedent noted in the review.

VERDICT: PASS
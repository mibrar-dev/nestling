# P09 — stage 3 · TEST (iteration 3)

Scope: `app/test/features/quests/**` only. No screen code, no shared code and
no `tools/` touched; `flutter clean` never run; no simulator booted, installed
on, screenshotted or driven; no `skip:` added, no test weakened, no
`analysis_options.yaml` change; `google_fonts` appears nowhere.

Iteration 3's tree is different in two ways: `shared/shared_batch5` is now
merged (`87cf5d4`/`9bbf65a`) and stage 2 fixed BUG-P09-6/7/8 plus four review
findings. Both are recorded below — including the three assertions that batch5
broke and that the mandated integrator change will fix.

## 1. What changed, and what this stage did about it

### 1.1 The shared merge broke 6 of my assertions; 6 are now correct

`shared_batch5` item 2 made the **51×31 track the toggle's laid-out box** and
moved the 59×44 tap area into `_ToggleHitSlop`; item 3 made the shared
`NestStepper` draw **U+2212** (the design's minus).

| Was | Now | Why |
|---|---|---|
| `kGlyphs` listed `'-'` | `'−'` | item 3 — the third item of `2_build.md` §3 names this file |
| `getSemantics(find.byType(NestToggle)).label` | node addressed by **label + `toggled` role** | the widget finder now resolves to `_ToggleHitSlop`, which owns no label; the card's *title* is a text node with the same label |
| toggle box ≥ 44 high | track is 51×31, tap area 59×44 | the 44 px target moved into hit slop |
| edge taps on the toggle box | taps at ±6.5 / ±4 **around the track** | same, asserted relative to the track so the pending `toggleTrackOffset` removal cannot move it |

The same `getSemantics(find.byType(NestToggle))` mistake also sat in
`quest_editor_view_test.dart`'s a11y test (stage 2b's file, in this feature's
test dir) — fixed the same way, and its assertions were strengthened (the
announcement must follow the real state, plus the widget's `value`).

### 1.2 Tests added (9 new, 3 files)

| File | Before → after | New tests |
|---|---|---|
| `quest_editor_coin_rules_test.dart` | 9 → 12 | the BUG-P09-6 repair contract (3) |
| `quest_editor_data_integrity_test.dart` | 18 → 23 | BUG-P09-7 inert alias tap, BUG-P09-8 nicknames (3), `?id=` outranks `?idea=` |
| `quest_editor_a11y_test.dart` | 14 → 15 | the due row announces the current choice, and follows it |

**The BUG-P09-6 repair contract** (iteration 2 deliberately left this open):
the reward is still *shown* as stored, and the save is now **blocked with an
announced reason** instead of being silently clamped. What the block must
guarantee, and what these three pin: the caption `Coins must be 1–100` exists,
is a **live region**, and uses the design's **en dash** (U+2013, asserted by
code point); the Save pill has **no tap action** for VoiceOver as well as no
handler for the finger; tapping it **writes nothing** (the row is still 9999,
no toast, no navigation); and one step back into range **clears** the caption,
re-enables Save, and stores the repaired value.

**BUG-P09-7**: tapping the already-highlighted alias tile is inert — the
highlight does not drop, exactly one tile stays selected, and the stored key
survives the save.

**BUG-P09-8**: an emoji-leading nickname (`😀 Sam`) and a nickname that is
*only* an emoji (`🧹`) both paint without throwing, the avatar carries the
**whole first grapheme** (not half a surrogate pair), the roster still reads in
creation order, and such a child can be selected and saved.

**Route contract**: `?id=q-hoover&idea=idea-bed` opens the *quest* (Edit quest,
20 coins, Delete present) and never the template — the documented precedence in
`2a_build_logic.md`, previously untested.

**Due-row announcement**: `Due by, Before tea (5pm)` → after picking another
option the stale label is *gone* (not duplicated) and the row is still
operable under `Due by, Before bed (7:30pm)` (review finding 6).

## 2. Results

```
$ dart format --set-exit-if-changed .
Formatted 495 files (0 changed) in 6.82 seconds.          (exit 0)

$ flutter analyze
Analyzing app...
No issues found! (ran in 5.0s)

$ flutter test test/features/quests/
00:52 +384 ~7 -3: Some tests failed.

$ flutter test
04:14 +2598 ~8 -4: Some tests failed!
```

Feature totals per file (all green unless noted): states 20, data-integrity 23,
coin-rules 12, robustness 17, copy 8, a11y 15, bloc 7, bugs 23, library/idea
suites unchanged.

The `~8` skips are stage 6's parked iteration-3 proofs (BUG-P09-9..12) plus
the pre-existing repo skip in `p12_bugs_test.dart:320`. Nothing this stage
skips.

## 3. Failures and bugs

### P09-TEST-3 — major — the approval block misses the design after batch5 (3 red assertions)

`shared_batch5` changed the toggle's box; the screen's compensation for the old
component has not been removed yet, so **the approval card renders 68 px high
where the design says 72**. Measured, light and dark alike:

| Test | Line | Asserted | Measured |
|---|---|---|---|
| `quest_editor_view_geometry_test.dart` "reward, repeats, approval and due blocks are on the rects" | 313 (and 450 for dark) | card `(20, 600, 350, 72)` | height **68** (4 px short) |
| `quest_editor_view_test.dart` "vertical positions match the design (±2px)" | 622 | `toggle.height == NestDevice.tapParent` (44) | **31** (the track is now the box) |

Repro: `flutter test test/features/quests/quest_editor_view_geometry_test.dart`
→ `Expected: a numeric value within <2.0> of <72.0> Actual: <68.0>`.

Why 68: the row is now driven by its text (16/22 + 13/18 = 40) instead of by
the toggle's 44-high box, and the card keeps the iteration-2 compensation
`padding: fromLTRB(s4, s4, s4, s3)` → 16 + 40 + 12 = 68. The design's 72 is
16 + 40 + 16, which is what the CSS gives (`.card{padding:16px}` with the
`.toggle::before` hit area hanging outside the layout).

**This is the integrator's mandated change, not a test problem** — ORCHESTRATOR
_NOTES 20:09 and `shared_batch5_REPORT.md`'s P09 follow-up. The fix, when the
product code moves:
1. delete `QuestEditorMetrics.toggleTrackOffset` and its `Transform.translate`
   (`quest_editor_view.dart:995-997`) — the track now aligns by layout;
2. drop the compensating bottom padding on the approval card so it is `s4` all
   round (16 + 40 + 16 = **72**), which also puts the track back on the
   design's rect: row 616→656, track centred → **x 303→354, y 620.5→651.5** —
   exactly the values the geometry file's own header table (lines 32-33)
   documents and asserts;
3. update the three assertions above (the geometry file's `toggleBox.width ==
   59` / `height == 44` / `top == 614` lines 328-342 describe the *old*
   component; they become the track rect `51×31` at `620.5`);
4. switch the six tiles to `questBed / questDishes / questHoover / questBins`
   (book and paw unchanged) — which also replaces the `NestIcons.*` list in
   `quest_editor_data_integrity_test.dart`'s glyph-order test.

Stage 6 filed the same thing independently as **BUG-P09-9** (approval block),
**BUG-P09-10** (see below) and **BUG-P09-12** (legacy glyphs), so it is not a
new discovery here; my contribution is the measured numbers and the exact test
lines.

### P09-TEST-4 — minor — an out-of-range reward has no practical repair

With the save now blocked (correctly, per BUG-P09-6), a stored 9999 needs 9899
taps of `−` before Save comes back. The screen shows the value and explains
the block, but offers no way to jump to a legal value — no clamp, no "reset to
100" affordance, no field to type into. Repro: open `?id=q-huge` with
`coins: 9999`; `Save` stays disabled and `−` steps one coin at a time.
Stage 6 filed this as **BUG-P09-11**; same defect, same conclusion. Design has
no frame for a corrupt value, so the fix is a product decision, not a
restoration.

### P09-TEST-5 — minor — my own blind spot: the toggle slop test cannot see the clipping

`shared_batch5`'s 59×44 tap area needs 44 of row height; the design's
`.switchrow` is 40 high, so stage 6's **BUG-P09-10** reports the slop being
clipped at the top and bottom. My new slop test (taps at ±6.5 above/below and
±4 beside the track) **passes anyway**, because the widget-test font wraps
`Coins land after your thumbs-up` onto two lines: the row is ~76 high there,
not 40. In other words the test is font-dependent and would not catch a real
clipping regression at the design's real metrics. Recording it rather than
papering over it: the honest version of that proof belongs in the real-font
geometry suite (`quest_editor_view_geometry_test.dart`, which loads the bundled
faces through `FontLoader`), and it has to be written together with the
P09-TEST-3 fix because both depend on the row's final height.

### Resolved since iteration 2

- **P09-TEST-1 (the U+002D minus)** — `shared_batch5` fixed the component;
  `kGlyphs` now carries `'−'` and the copy audit asserts the design's glyph.
- **P09-TEST-2 (the emoji nickname crash)** — fixed with
  `nickname.characters.first`; three tests of mine now cover the grapheme, the
  empty-of-ASCII case and the select-and-save path.

### Observation, outside this screen's scope

`test/core/family_time_test.dart:319` ("kid_home completions are stamped with
the family zone") fails on this tree: after `Seed.movedToDubai(db)` the second
completion is stamped with the wrong zone. It is a `core/` test (not mine to
edit — RULES §1) and `shared_batch5` touched no zone plumbing
(`git show --stat 9bbf65a` lists only icons, toggle, stepper, text field and
their tests), so it is not a consequence of this iteration's merge. Flagged for
the orchestrator with the repro; it needs whoever owns `core/`.

## 4. Notes for the next stages

- **Coupled test sites** for the pending integrator change (all in
  `app/test/features/quests/`): `quest_editor_view_geometry_test.dart:313`,
  `:328-342`, `:450`; `quest_editor_view_test.dart:622`;
  `quest_editor_data_integrity_test.dart`'s glyph list (4 of 6 names).
  Nothing else in my suites depends on the toggle's box or the glyph names —
  the slop test is relative to the track, so it survives.
- **`buildWhen`** (review 7) and the `ValueListenableBuilder` (review 4) remain
  untested: both are performance properties with no observable contract.
- **Observation, unreachable today:** `QuestEditorView.didChangeDependencies`
  fetches `?id=` once (`if (_loadedQuest != null) return`), so going straight
  from `/quest-editor?id=a` to `?id=b` on the same `State` would keep showing
  quest `a`. Every in-app path pushes a new page, so nothing reaches it — but a
  future "switch to another quest from this screen" affordance would inherit
  it.
- Every widget test here ends with `disposeApp(tester)`, and every semantics
  handle is disposed **inside** the test body.

VERDICT: FAIL
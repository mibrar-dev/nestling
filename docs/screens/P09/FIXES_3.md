# Fix list after iteration 3

## From 3_test.md
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


## From 4_review.md
# P09 — stage 4 · QA code review (iteration 3)

Scope reviewed: `git diff main...HEAD` on branch `screen/P09` against
`docs/ARCHITECTURE.md`, `docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5 P09
(line 168), `docs/design/SPACING_SPEC.md`, the design system in
`app/lib/core/design_system/`, the HTML source
`design/html-source/screens/P09-quest-editor.html`, both design PNGs, and every
mandatory item in `docs/screens/P09/ORCHESTRATOR_NOTES.md` (17:14, 17:57,
19:19, 20:09).

`git merge-base main HEAD` = `7afc8ad` = `main`. **The branch is not behind
main** — batch 5 (`shared/shared_batch5`) is merged in and its changes are on
disk at HEAD. That matters for findings 1–3: nothing here is a merge-order or
process artefact, the screen simply has not absorbed the shared change that
landed under it.

No code was edited. Only this file was written. No simulator was booted,
installed on, screenshotted or driven; `flutter clean` was never run.

Because the loop may be writing in this worktree, every gate was run against an
isolated `git archive HEAD` export
(`/…/opencode/p09-clean`, and a second scratch copy `/…/opencode/p09-r3` used to
measure candidate fixes):

```
$ cd …/opencode/p09-clean/app && flutter analyze
No issues found! (ran in 6.8s)

$ flutter test                       # full suite at HEAD
02:32 +2583 ~1 -10: Some tests failed.        # the ~1 skip is main's P12-BUG-05

$ flutter test test/features/quests/
00:23 +368 -10: Some tests failed.
```

All 10 failures are in P09's own test files. Nothing outside
`features/quests/**` regressed (`test/features/today/` is green).

`git diff --stat -- app/lib/core app/lib/app tools` is empty;
`analysis_options.yaml` and `pubspec.yaml` are untouched; no `skip:`, no
`// ignore:`, no `google_fonts`/`GoogleFonts`, no `print`/`debugPrint`, no
`TODO(` left anywhere in the diff.

## Verdict summary

**One blocker and two majors. The blocker is the `flutter test` done-criteria
gate (RULES §7.1) — 10 of this screen's own tests are red at HEAD. Both majors
are the same missed hand-off: the shared batch-5 change landed on `main` and
`ORCHESTRATOR_NOTES.md` (20:09) explicitly instructed this branch to absorb it,
but neither the icon switch nor the removal of the two now-stale compensations
was done. VERDICT: FAIL.**

The screen is otherwise a careful, faithful build: no hard-coded colours,
sizes or fonts; shared components reused rather than re-implemented; copy
matches the HTML character for character; every screen-local tappable carries
`onTap:` on its own `Semantics` node; streams and controllers disposed; the
per-keystroke rebuild storm is gone; and the geometry test pins the design's
absolute rects against the bundled real fonts.

---

## Findings

### 1. BLOCKER — the `flutter test` gate is red: 10 failures, all in `test/features/quests/`

**Where:** `quest_editor_copy_test.dart:85`, `quest_editor_copy_test.dart:262`,
`quest_editor_a11y_test.dart:479-491`, `quest_editor_view_test.dart:612-625`,
`quest_editor_view_test.dart:778-782`, `quest_editor_robustness_test.dart:256-281`,
`quest_editor_view_geometry_test.dart:327-358`,
`quest_editor_data_integrity_test.dart:170`.

**Why it is a blocker.** `docs/screens/RULES.md` §7.1 makes
"`flutter test` → all pass" a hard done-criteria gate, and the failures are
behavioural, not cosmetic. Four independent causes:

**(a) The copy audit still pins the glyph batch 5 removed (3 failures).**
`quest_editor_copy_test.dart:85` reads `'-', // .stepper buttons` (U+002D).
Iteration 2's finding 7 said, in writing, to *"flip the hyphen entry in the same
commit that fixes `NestStepper`"* and *"do not delete the entry without
replacing it"*. `nest_stepper.dart:30-32` is now `label: '−'` (U+2212, with a
comment saying so). Result:

```
quest_editor_copy_test.dart:189  Expected: empty   Actual: Set:['−']  unlisted copy on screen
quest_editor_copy_test.dart:302  Expected: empty   Actual: Set:['−']
quest_editor_copy_test.dart      Expected: contains '-'
```

so `the screen invents no copy beyond the design`,
`every design string is on screen, character for character` and
`the stepper announces Decrease reward / Increase reward` all fail. **Fix:**
`quest_editor_copy_test.dart:85` → `'−', // .stepper buttons (U+2212, per §5)`.

**(b) Three tests read the toggle's semantics through the wrong node
(3 failures).** `NestToggle` now puts its `Semantics` *below* the new
`_ToggleHitSlop` hit-test proxy (`nest_toggle.dart:36-44`), so
`tester.getSemantics(find.byType(NestToggle))` walks **up** from the proxy and
returns the ancestor node — label `''`, `hasAction(tap)` false:

```
quest_editor_a11y_test.dart:480   Expected: 'Needs my approval'   Actual: ''
quest_editor_view_test.dart:779   Expected: true                  Actual: <false>
quest_editor_copy_test.dart:263   Expected: 'Needs my approval'   Actual: ''
```

This is a **test** problem, not an a11y regression: the `Semantics` node is
still in the tree, still labelled and still actionable, and
`shared_batch5_REPORT.md` says exactly this ("the outer hit-slop render carries
no semantics (the `NestChip` pattern)") and fixed P14's tests the same way.
**Fix:** address the node by label, e.g.
`tester.getSemantics(find.bySemanticsLabel('Needs my approval'))`, in
`quest_editor_a11y_test.dart:479/491`, `quest_editor_view_test.dart:778/782`
and `quest_editor_copy_test.dart:262`.

**(c) Two tests assert the toggle's old 59×44 box (3 failures).**
`quest_editor_robustness_test.dart:268` (`Expected >= 44, Actual 31`) and
`quest_editor_view_test.dart:620` (`Expected 44, Actual 31`) sweep
`getRect(find.byType(NestToggle))` as if it were the hit box. The box is now
the 51×31 track by design. **Fix:** drop the toggle from the ≥44 sweep, pin
`size == Size(51, 31)` instead, and keep a live proof that a tap **4 px** left
of / **7 px** above the track still flips it (the `::before` overhang), which is
how P14's `rewards_a11y_test.dart` handles it.

**(d) `quest_editor_data_integrity_test.dart:170`** pins the tile list as
`NestIcons.bed / dishwasher / hoover / book / bin / paw` — the pre-batch-5 list.
It passes today and must be updated **in the same commit as finding 2 below**,
or it will fail the moment the picker is switched.

*(Cause (a) and cause (b)/(c) survive finding 2: in the scratch copy, applying
finding 2's fix took the suite from 10 failures to 9, of which these 6 remain.)*

---

### 2. MAJOR — the approval card and its toggle now miss the design by 4 px / 2 px, because both batch-5 compensations are still in place

**Where:** `quest_editor_view.dart:969-974` (card bottom padding
`NestSpacing.s3`) and `quest_editor_view.dart:996-997`
(`Transform.translate(offset: QuestEditorMetrics.toggleTrackOffset)`);
`quest_editor_widgets.dart:35-49` (`toggleTrackOffset = Offset(4, -2)`).

**Why it is wrong.** Both lines exist only to compensate for the *old*
`NestToggle`, which was a 59×44 box with the 51×31 track centred inside it.
Batch 5 made the track the widget's own box (`nest_toggle.dart:12-16,52-53`)
and moved the 59×44 area into a non-layouting hit slop. `ORCHESTRATOR_NOTES.md`
(20:09) is explicit: *"delete the `toggleTrackOffset` Transform.translate, as
in `docs/screens/_shared/shared_batch5_REPORT.md` lines ~87-90 and ~209"* — and
that report's own follow-up list names this branch's two compensations. The
compensations now **double-count**:

* the card's bottom padding was shaved 16→12 to absorb the toggle's 44-high
  box; with a 31-high track the row is driven by the 40-high text block, so the
  card renders **68** where the design is **72**;
* the `Transform` now pushes the track **4 px past the content edge** and
  **2 px up**.

Measured, HEAD vs design (÷3, bundled Inter, light):

| element | design (PNG) | app at HEAD | Δ |
|---|---|---|---|
| `.card` approval | 20 / 600 / 350 / **72** | 20 / 600 / 350 / **68** | **−4 h** |
| `.toggle` track | **303** / **620.5** / 51 / 31 | **307** / **618.5** / 51 / 31 | **+4 x, −2 y** |

Design figures are my own pixel probe of
`design/screens/light/P09-quest-editor.png`, not the builders' table: at
`x = 300 px` the white card runs `y 1800 → 2016` px = logical `600.0 → 672.0`;
at `y = 1900 px` the leaf-green track runs `x 909 → 1061` px = logical
`303.0 → 353.7` and the card's white ends at `x 1110` = logical `370.0`, so the
track's right edge is flush with the content edge `370 − 16 = 354`. The
green-column centre at `x = 310` is `636.5`, giving a 31-high track centred on
`636` ⇒ `620.5 → 651.5`. Both deltas are outside the owner's ±2 px rule, so
stage 5 must fail this as it stands.

**Fix (two lines, and I verified both in the scratch export).** Delete
`quest_editor_view.dart:996-997` and restore the bottom padding:

```dart
padding: const EdgeInsets.fromLTRB(
  NestSpacing.s4,   // 16 — unchanged
  NestSpacing.s4,   // 16 — was s3, the compensation for the old 44-high box
  NestSpacing.s4,
),
```

With only those two edits the probe returns
`card = Rect.fromLTRB(20, 600, 370, 672)` (height **72**) and
`toggle = Rect.fromLTRB(303, 620.5, 354, 651.5)` — the design rects exactly,
with the 44 px tap target still reaching 59×44 through the shared hit slop.
Then delete `QuestEditorMetrics.toggleTrackOffset`
(`quest_editor_widgets.dart:35-49`) and its now-false comment block at
`quest_editor_view.dart:991-995`, and update
`quest_editor_view_geometry_test.dart:327-358` / `quest_editor_view_test.dart:612-625`
to assert the track itself at `303 / 620.5 / 51 / 31` (the header table's
`.toggle track 303 / 620.5 / 51 / 31` row is already correct and needs no edit).

---

### 3. MAJOR — mandatory orchestrator item 20:09 not done: four of the six icon tiles still draw the wrong glyph

**Where:** `quest_editor_view.dart:293` (`NestIcons.bed`), `:298`
(`NestIcons.dishwasher`), `:300` (`NestIcons.hoover`), `:306`
(`NestIcons.bin`).

**Why it is wrong.** `ORCHESTRATOR_NOTES.md` 17:57 item 1 (still binding) bans
look-alike substitutions: *"If a glyph is missing from `app/assets/icons`, write
`SHARED_REQUEST.md` … rather than substituting a look-alike."* Batch 5 answered
that request — `ic_quest_{bed,dishes,hoover,bins}.svg` and
`NestIcons.questBed / questDishes / questHoover / questBins` are on `main`
(`nestling_assets.dart:119-137`, `nest_icon.dart:36-39`) and carry the design's
exact paths (`M4 11h16v9…`, `M3 18v-8a2 2 0 0 1 2-2h14…`, the canister with
`M7 16v3M11 16v3` legs, the case with the `M10 12h4` clasp). The 20:09 note
orders the switch. It has not happened, so four tiles still draw glyphs that
**no** P09 frame contains:

| tile | design | still painted | delta |
|---|---|---|---|
| Bed | flat frame, no headboard | `ic_bed.svg` has a headboard arc | wrong object |
| Dishes | handled basket | `ic_dishwasher.svg` appliance with rack line + 2 control dots | wrong object (P08 item 2 of iteration 2) |
| Hoover | angular canister + hose + 2 legs | `ic_hoover.svg` rounded canister + dot wheels | wrong object |
| Bins | handled case + clasp | `ic_bin.svg` wheelie bin | wrong object |

Iteration 2's own UI note measured whole-tile MAE at **4.5 / 17.5 / 20.5 /
17.3** for these four tiles; the fix is now one constant each, so stage 5 can
expect those to collapse to raster residue.

**Fix.**

```dart
(key: 'bed',       aliases: <String>['sofa'], label: 'Bed',    icon: NestIcons.questBed),
(key: 'dishwasher',aliases: <String>['plate'],label: 'Dishes', icon: NestIcons.questDishes),
(key: 'hoover',    aliases: <String>[],       label: 'Hoover', icon: NestIcons.questHoover),
(key: 'book',      …),                                                  // unchanged
(key: 'bin',       aliases: <String>['bins','shirt','bag'], label: 'Bins', icon: NestIcons.questBins),
(key: 'paw',       …),                                                  // unchanged
```

The stored `key` values (`bed`/`dishwasher`/`hoover`/`bin`) must **not** change —
they are what `quests.icon` holds in the database and what the alias table
resolves — so this is an artwork swap only, and
`quest_editor_data_integrity_test.dart:170` must move to the same list in the
same commit (finding 1d). The stale comment at
`quest_editor_view.dart:281-290` needs no edit beyond confirming it still
describes the aliases.

---

### 4. MINOR — a parent-facing toast can still carry a Dart error string

**Where:** `quests_bloc.dart:55-61, 78-84, 101-107` →
`quest_editor_view.dart:153-154` (`showNestToast(context, error)`).

Carried from iteration 2 (finding 10). `editorError: error.toString()` means a
bypassed guard would put `Invalid argument (coins): 9999: Quest coins must be
1..100` in front of a parent. `_save` clamps and `_canSave` blocks, so it is
unreachable today.

**Fix.** Map to parent-safe copy at the bloc boundary
(`'Could not save the quest. Try again.'`) and log `error`.

---

### 5. MINOR — `SHARED_REQUEST.md` still describes four landed shared batches as open

**Where:** `docs/screens/P09/SHARED_REQUEST.md` §2 (line 19), §4 (line 77,
"**BLOCKS P09 UI check**"), §5 (line 177), §6 (line 206).

All four were answered by `shared/shared_batch5` — the SVGs exist on `main`
(verified: `app/assets/icons/ic_quest_{bed,dishes,hoover,bins}.svg`),
`NestToggle` is 51×31, `NestStepper` is U+2212, `NestTextField`'s default
horizontal padding is 12. §4's "BLOCKS" banner is now false and is exactly what
told findings 2 and 3 to wait instead of adapting.

**Fix.** Retitle §2/§4/§5/§6 `— RESOLVED on main (shared/shared_batch5)` in the
style of §1, and note the P09-side follow-ups each still owes (this file is
inside RULES §1, so no request is needed).

---

### 6. MINOR — two stage notes still name `NestIcons.basket` as the design glyph for Dishes

`docs/screens/P09/3_test.md:74` and `docs/screens/P09/FIXES_2.md:77`: *"design's
order and glyphs (`NestIcons.basket` for Dishes, per 2b's …)"*. The basket was
the banned look-alike, reverted in iteration 2; `2b_build_ui.md` and `5_ui.md`
were corrected (finding 8 is otherwise closed — the false "main redrew the
glyphs" claim is gone and the apostrophe sentence is now right).

**Fix.** Correct both lines to `NestIcons.dishwasher` / `questDishes`.

---

### 7. MINOR — `DESIGN_SPEC.md` §5 P09 is stale on the tile size (carry, no change here)

`docs/DESIGN_SPEC.md:168` says *"Icon picker row (6 SVG icons in **48px**
tiles, one selected)"*. The CSS is `.ic{width:44px;height:44px}` and my probe of
the PNG confirms 44 (border strokes at `x = 20, 81, 142, 204, 265, 326`,
`20 + i·61.2`, last tile ending at 369.67). `app/lib/core/**` and `docs/**` are
off-limits to a screen agent, so this is for the orchestrator's doc pass; the
code's 44 is correct.

---

### 8. MINOR — the interface doc promises `[ArgumentError]`, but debug builds throw `AssertionError`

`quests_repository.dart:22-24` (*"Out-of-range values throw `[ArgumentError]`"*)
vs `quests_repository_impl.dart:98-107`, where the `assert` precedes the
`ArgumentError` — so in debug (and in every `flutter test`) the `ArgumentError`
is unreachable, and `quests_repository_test.dart:416/434` asserts
`isA<AssertionError>()`. The behaviour is intentional and documented in the
impl; only the contract comment is untrue in debug.

**Fix.** One line in `quests_repository.dart`: *"throws `AssertionError` in
debug, `ArgumentError` in release (see `QuestsRepositoryImpl._checkCoins`)"*.

---

### 9. MINOR — the view resolves its repositories through `GetIt.instance` with no graceful degradation

`quest_editor_view.dart:54`, `:75`, `:431-432`. If the locator has no
registration, `didChangeDependencies`/`initState` throw during build and the
screen becomes an error widget. The sibling P10 screen took the opposite
decision for the same class of failure (`p10_bugs_test.dart` "BUG-P10-8 — the
view silently degrades when its DI lookup fails"), and the same view already
handles a *missing row* (`Quest not found`) and a *failed stream* (`onError`),
so the asymmetry is visible.

**Fix (cheap, optional).** Wrap the two lookups in a `hasRegistration` check:
a missing repository yields the load-failure panel (`_QuestLoadFailure`) with
`Try again`, and `initState` skips the two subscriptions. Do **not** rewire the
bloc away from `QuestsBloc` — `buildWhen` and `editorStatus` are correct and
out of scope.

---

## What was checked and found correct

* **RULES §1 file scope.** `git diff --stat main...HEAD -- app/` touches only
  `lib/features/quests/{presentation,domain,data}` + `quests_routes.dart` and
  `test/features/quests/**`, plus two pre-authorised P08 test files
  (`test/features/today/{today_view_test,p08_bugs_test}.dart`, +68/−25) whose
  only change is swapping a `find.text('P09 Quest editor')` placeholder anchor for
  `pushedPath`/`_pushedUri` + `find.byType(QuestEditorView, skipOffstage: false)`
  — `SHARED_REQUEST.md` §3 cites `router_push_test_fix_REPORT.md` §4/§5 for it
  and `test/features/today/` is green (110 pass). Nothing in
  `app/lib/core/**`, `app/lib/app/**` or `tools/**` is touched.
* **Architecture.** Feature-first intact; `domain/` still only entities + the
  abstract repository; one bloc per feature with three editor events added
  (`QuestsCreateRequested` / `UpdateRequested` / `DeleteRequested`); routes and
  query contract centralised in `quests_routes.dart` (`QuestsEditorQuery` with
  `questId` / `legacyQuestId` / `ideaId` and doc comments); `/quest-editor` →
  `QuestEditorView` + `QuestsBloc` exactly as `ARCHITECTURE.md`'s route table
  says. `editorStatus`/`editorError` stay orthogonal to `status`, so
  `emit.forEach` on `watchItems()` is untouched and **no reload event was
  introduced** — the watch-stream contract in RULES §4.1 holds. The one
  cross-feature read (`FamilyRepository.watchChildren()`) is read-only, is
  unsubscribed in `dispose`, and has an in-feature precedent for a feature repo
  reading the `families` row (`today_repository_impl.dart:110`). No new folder,
  no use-case class, all imports `package:nestling/…`.
* **Design system, no hard-coding.** No colour literal in the whole diff
  (`Colors.transparent` ×3 only — always on a `Material` whose colour comes from
  tokens); every gap through `NestSpacing`/`NestDevice`/`NestRadii`; every style
  through `NestType`; no `letterSpacing` anywhere (P09's CSS sets none, so the
  `main fd92d95` rule needs no call-site override); no `NestBalancedText` (no
  `text-wrap: balance` heading in P09's CSS — correct to omit); no
  `NestChip` row, so `NestChipWrap` is correctly absent. Shared components
  reused, none re-implemented: `NestStatusBar`, `NestTextField`, `NestCard`,
  `NestStepper`, `NestSegmented`, `NestDayPicker`, `NestToggle`, `NestAvatar`,
  `NestIcon`, `NestButton`, `NestModal`, `NestBottomSheet`, `NestToast`. The six
  screen-local numbers (`iconTileRadius` 14, `hairline` 1.5, `savePadding` 18,
  `saveMinWidth` 64, `cancelPadding` 6, `dueRowMinHeight` 56) live in
  `QuestEditorMetrics` with their CSS quoted — the `NestPager` precedent. The
  `.person` padding arithmetic still reconciles with the CSS
  (`4+1.5` left, `12+2+1.5` right = CSS `4`/`14` + the hairline that
  `Material.shape` paints outside the child).
* **Copy, character by character against the HTML.** `Cancel`, `New quest`,
  `Save`, `Quest name`, `Icon`, `Who's it for?` (U+0027 — hexdump of both the
  HTML and the view), `M`, `Maya`, `L`, `Leo`, `Anyone`, `Reward`,
  `= 15p at payout`, `15`, `Repeats`, `Once`/`Daily`/`Weekly`, `M T W T F S S`,
  `Needs my approval`, `Coins land after your thumbs-up` (U+002D, asserted
  against `’`/`–`), `Due by`, `Before tea (5pm) ›` (U+203A). Every non-design
  string is enumerated in `kScreenLocalCopy` with the plan section that sanctions
  it. UK spelling throughout.
* **Iteration-2 findings that are now closed.** Finding 2 (`?idea=` is live:
  `QuestsEditorQuery.ideaId`, `_ideaTemplateOf`, a CREATE with a fresh id, the
  alias table covers all 10 template icons so every `+ Add` seeds a selected
  tile, stale `TODO(P10)` comments deleted) — closed, with the test the review
  asked for. Finding 3 (`Tooltip('Back')` deleted; the P10 sites use
  `handlePopRoute()`; a test now pins exactly one `byTooltip('Back')` absence) —
  closed. Finding 4 (the `ValueListenableBuilder<TextEditingValue>` over `_title`
  means a keystroke rebuilds only `QuestSavePill`) — closed.
  Finding 5 (`listEquals` guard on the roster, `onError` on **both**
  subscriptions) — closed. Finding 6 (`semanticLabel: 'Due by, $_dueLabel'`, so
  the value is announced and the card still exposes `onTap`) — closed.
  Finding 9 (the P08 test edits must travel on the merge) — still true.
* **Accessibility.** Every screen-local tappable passes `onTap:` on its own
  `Semantics` node next to the `InkWell`, with `excludeSemantics: true` on that
  node: `QuestCancelButton`, `QuestSavePill`, `QuestIconTile`,
  `QuestPersonPill`, `QuestDueOptionRow`, and the due `NestCard`
  (`semanticLabel` + `onTap`, verified in `nest_card.dart:61-83`).
  `QuestSavePill` reports `enabled: false` and drops the action while disabled or
  while a write is in flight. `Semantics(header: true)` on the title and the
  three group labels (the test pins exactly 4 headers); the icon row is a
  `container` named `Quest icon`, matching the HTML's `role="radiogroup"`. The
  only semantics problem in the tree is the three stale test lookups in
  finding 1b — the node itself is intact, and
  `shared_batch5_REPORT.md` prescribes the same fix for P14.
* **Children's Code.** `/quest-editor` is in the router's `parentOnly` list;
  kid mode is redirected to `/parental-gate` (proven by a test). No analytics,
  no ads, no network, no child data leaving the device — the screen reads the
  family's own children and writes only to `quests`. No `subscription_status`
  written anywhere; no period/`countsForCurrentPeriod` logic is needed on P09;
  no Pip on this screen, so the PIP ruling does not apply.
* **Error handling.** Save/update/delete failures surface a toast, keep the
  editor on screen, leave the Drift row untouched and re-enable the pill through
  `clearSaveGuard()`; the route-level load failure offers `Try again` that
  really re-subscribes. Coins are validated in the repository before Drift is
  touched, so a corrupt row can never be re-persisted.
* **Performance / lifecycle.** `buildWhen: previous.status != current.status`
  stops `watchItems()` re-emissions from rebuilding the form; both subscriptions
  are `late` fields created once in `initState` and cancelled in `dispose`, as is
  `_title`; neither subscription rebuilds on an unchanged value; `const` is used
  everywhere it compiles; the sheet's `minHeight: constraints.maxHeight` keeps
  the paper to the physical edge while still scrolling in edit mode. Iteration 2's
  two perf findings are closed and I found no new rebuild storm.
* **Bottom edge, alignment, child order.** The sheet is a `tokens.paper`
  container inside a `tokens.surface2` backdrop, so no coloured strip can appear
  under it in either theme (a test samples the last physical row). Gutters are
  `NestSpacing.padSide` (20) on every row, the icon row is `space-between` over
  350 and the assignee pills are a `Wrap`, so nothing is a few px off at 390,
  320 or 430. Children come from `watchChildren()`, which the shared repository
  already orders by creation (`createdAt`, `rowid`) — Maya then Leo, never
  alphabetical — and a new quest defaults to `_children.first`.

## LEFT FOR THE LOOP

1. **Finding 1** — 6 test-side edits (one character, three lookups, two sweep
   pins, one icon list). Nothing crosses a feature boundary; all of it is in
   `app/test/features/quests/**`.
2. **Finding 2** — delete `Transform.translate` + `QuestEditorMetrics.toggleTrackOffset`,
   restore the card's bottom padding to `NestSpacing.s4`, update the two
   geometry assertions. Verified to land the card and the track exactly on the
   design rects.
3. **Finding 3** — switch four `NestIcons` constants; the same commit updates
   `quest_editor_data_integrity_test.dart:170`.
4. **Findings 4-9** — small; 4 and 8 are one-liners.
5. **Finding 9 of the closed list** (the two `test/features/today/` files) must
   travel on the merge, not be reverted.
6. **Do not** re-open the icon question: `2b_build_ui.md` and `5_ui.md` are
   corrected, and the design PNG + CSS are the authority (44 px tiles, not the
   spec's 48).
7. No simulator was used in this stage; stage 5 owns the ±2 px verdict and can
   lean on `quest_editor_view_geometry_test.dart` (compare bands, not absolute
   y, if the device status bar is taller than 47 px). Expect the four icon tiles
   and the toggle/card block to move; re-shoot after findings 2 and 3.

## Process note (not findings)

While this review ran, another stage was writing in this same worktree. Its
files are the loop's business and are **not** reported here, but the next
iteration should not commit them blind:

* `HEAD` was `aaea888` for the whole review and every measurement above was
  taken from a `git archive HEAD` export, so none of this is affected by them.
* After the review finished, `app/test/features/quests/quest_editor_copy_test.dart`
  had an uncommitted one-line change and `app/test/features/quests/_diag3_test.dart`
  appeared — a scratch diagnostic probe. **The probe must not be committed**
  (it would run in `flutter test`). The one-line change looks like finding 1(a)
  being fixed; re-check finding 1 against whatever that stage finally writes.


## From 5_ui.md
# P09 — 5_ui · UI check (iteration 3, stage 5)

Route `/quest-editor`, simulator 604697A9-11DA-462F-9837-396E9CA2493A (390×844).
Shots: `docs/screens/P09/ui/app_light_3.png`, `app_dark_3.png` (seed demo,
parent, maya, `DISABLE_ANIMATIONS=1`). Compare sheets: `cmp_light_3.png`,
`cmp_dark_3.png`. All px below are logical (design px ÷ 3). Status-bar glyphs
excluded per orchestrator STATUS BAR rule. Shared batch5
(`87cf5d4`: exact quest icons, 51×31 toggle, stepper U+2212, field 17 px
inset) is merged into this branch — but the P09-local follow-ups from
ORCHESTRATOR_NOTES.md 20:09 (switch picker to the `quest*` icons, delete
`toggleTrackOffset`) were NOT applied: the picker still uses
`bed/dishwasher/hoover/book/bin/paw` (`quest_editor_view.dart:293-308`)
and the `Transform.translate(toggleTrackOffset)` is still in place (:996).
No Pip on this screen; no `NestChip` rows, no `text-wrap: balance`, no
`letter-spacing` (all correctly absent).

## Mean diff

- Light: **1.81 %** (bands 0–7: 1.64 / 0.91 / 1.53 / 1.62 / 0.65 / 1.72 /
  3.31 / 3.10; iter2 was 1.79 %).
- Dark: **1.62 %** (bands: 1.65 / 0.94 / 1.41 / 1.56 / 0.70 / 1.82 / 3.06 /
  1.85; iter2 was 1.62 %).
- Improvements vs iter2: band 1 (field text now at design x), band 5
  (stepper minus now U+2212). Regression: band 6 (toggle + cards, see 2–3).

## Measured y (design vs app, logical px, top edge)

Best-fit uniform vertical shift over y 60–800 is **dy = 0 px** — no uniform
shift. Rows above the approval card are unchanged from iter1/2 (all Δ ≤ 1):

| Element | Design y | App y | Δ |
|---|---|---|---|
| Grabber (40×5) | 58.7–63.7 | 58.7–63.7 | 0 |
| Screen title `New quest` (text peaks) | 100.3 / 106.6 | 100.3 / 106.6 | 0 |
| First control: `Cancel` box / Save pill | 90 / 80–124 | 90 / 80–124 | 0 |
| `Quest name` label | 136.8 | 136.8 | 0 |
| Name input (52 high) | 156.2 | 156.2 | 0 |
| Field text ink x (orchestrator item (b)) | 38.3 | 37.7 | 0.6 ✓ |
| `Icon` label | 207.2 | 207.2 | 0 |
| Icon tiles (6× 44×44) | 232 | 232 | 0 |
| `Who's it for?` label | 276 | 276 | 0 |
| Person pills (48 high) | 300.8 | 301.0 | 0.2 |
| Reward card (inset, 76) | 363.7 | 363.7 | 0 |
| `Repeats` label | 461.0 | 461.0 | 0 |
| Segmented track (52) | 479.7 | 479.7 | 0 |
| Day row (44) | 540.2 | 540.7 | 0.5 |
| Approval card top | 599.7 | 599.7 | 0 |
| Approval TEXT (top→ink bottom) | 621.3→654.3 | 621.3→654.3 | 0 |
| Approval card bottom | 671.7 (h 72) | 667.7 (h 68) | **4** ✗ |
| Toggle track rect | x 303→353.7, y 621→651.7 | x 307→357.7, y 618.7→649 | **+4/−2.3** ✗ |
| Due-by card | 683.7–771.7 (h 88) | 679.7–767.7 (h 88) | **4 up** ✗ |
| `Due by` title ink top (x 37.3 both) | 722.3 | 718.3 | **4 up** ✗ |

Shape check otherwise unchanged: Save pill, field, tiles, pills, segmented
+ Weekly thumb, day cells, stepper — all Δ ≤ 2 (nearly all 0). Gutters
exactly 20 both themes. Bottom edge paper-to-edge both themes (home-zone
paper at y = 830). No overflow/clipping/ellipsis. Child order
Maya → Leo → Anyone. Copy unchanged and matching the HTML source.

Closed since iter2 (shared batch5, verified in these shots): field text x
(38.3 vs 37.7 — orchestrator 17:57 item (b) DONE); stepper minus U+2212
(band-5 residue 2.39 → 1.72 light); exact DS icons
`questBed/questDishes/questHoover/questBins` exist in core (not yet used).

## Deviations (all P09-local fixes; shared sides are DONE)

1. (BLOCKER — icon choice) The picker still renders the OLD glyphs:
   whole-tile MAE vs design bed 4.5 / dishes 19.9 / hoover 20.5 / book 4.1 /
   bins 17.3 / paw 1.9 — identical to iter1. (The iter-2 `basket`
   substitution is gone — correctly reverted per the look-alike ban.)
   - Design value: exact P09 SVGs (quoted in `SHARED_REQUEST.md` §4).
   - App value: `NestIcons.bed/.dishwasher/.hoover/.bin` (baseline bytes).
   - Fix (P09-local, per ORCHESTRATOR_NOTES.md 20:09 + batch5 report):
     switch `_questIcons` to `NestIcons.questBed / .questDishes /
     .questHoover / .book / .questBins / .paw` in the design order
     (`quest_editor_view.dart:291-309`). Expect tile MAEs → raster residue.

2. (BLOCKER — toggle position) The track is shifted exactly
   `toggleTrackOffset (4, −2)` off the design rect: app x 307→357.7 /
   y 618.7→649 vs design 303→353.7 / 621→651.7 (right edge 4 px past the
   content edge — visible double-image in the diff heat-map, both themes).
   Batch5 made the 51×31 track the laid-out box, so the old compensation
   now misaligns it.
   - Fix (P09-local): delete the `Transform.translate` (:996-1003, use
     bare `NestToggle`) and remove `QuestEditorMetrics.toggleTrackOffset`.
     Track must land x 303→354, y 620.5→651.5.

3. (BLOCKER — approval-card height + due-card shift) Approval card is 68
   tall, not 72 (bottom 667.7 vs 671.7; pixel-verified: app paper at
   y = 668–670 where the design is still card-white; text identical
   621.3→654.3 in both). Cause: `_approvalCard` keeps the workaround
   bottom padding `s3` (12) that compensated the OLD 44-tall toggle box
   (:969-974); with batch5's 51×31 box the row is 40 tall, so the card
   needs 16 + 40 + 16 = 72 again. The due card keeps its 88 height but
   rides 4 px high (679.7–767.7, title ink 718.3 vs 722.3) on the
   shrunken card above.
   - Fix (P09-local): restore uniform `s4` (16) card padding; due card
     and its content return to 683.7 / 722.3 with no other change.

No other deviations. Explicitly not findings: status-bar time/glyphs and
home-indicator pill rendering (OS regions), pill right-edge +0.5–1.5 px
and day-cell 44.9 vs 44 (anchored edges exact, inside ±2 px), text-edge
diff heat (antialiasing), due-card shadow-softness row at y ≈ 772.


## From 6_bugs.md
# P09 — stage 6 · FIND BUGS (iteration 3)

Tree: `aaea888` (“P09: checkpoint after build (iteration 3)”, includes the
shared batch-5 merge) + the proofs below. No screen code was changed — the
brief forbids fixing here.

Adversarial area sweep (iteration 3): the eight earlier proofs re-run, then
new probes over the iteration-3 changes (`?idea=` prefill, Save-pill rebuild
scope, subscription `onError`, Due-by semantics, Cancel without a Tooltip) and
the batch-5 integration (`NestToggle` 51×31 + hit slop, U+2212 stepper, exact
quest icons, text-field inset): data edge cases (0 / 1 / 6 children,
emoji-leading and long UK names, £0.00 / £999.99 / 9999 coins), rapid double
taps, back navigation and deep links, Drift restart persistence, the
parent/kid guard, dark-mode contrast, 320 dp × text scale 1.3, async gaps,
Europe/London wall-clock storage and integer-pence money.

All proofs live in `app/test/features/quests/p09_bugs_test.dart`. The
iteration-3 proofs are `skip: true` (bug id in the group name) so the suite
stays green; run them with `--run-skipped` to see them fail. Every probe in
the “attacks that hold” group runs unskipped.

## Iteration-1/2 findings — all FIXED, proofs unskipped and green

| id | what was wrong | fix | proof |
|---|---|---|---|
| BUG-P09-1 | payout helper hard-coded 1p/coin | streams `watchCoinValuePencePerCoin()` | runs green |
| BUG-P09-2 | double-tap Save created the quest twice | `_saving` guard + pill disabled while saving | runs green |
| BUG-P09-3 | non-picker icon showed no selected tile | `_questIcons.aliases` covers every seeded key | runs green |
| BUG-P09-4 | out-of-range coins unreachable after a tap | `_coinFloor`/`_coinCeiling` widen to the stored value | runs green |
| BUG-P09-5 | removed child left an orphaned assignee | roster-unknown assignee falls back to `Anyone` | runs green |
| BUG-P09-6 | out-of-range reward silently clamped on save | Save blocked + live-region `Coins must be 1–100` | runs green (2 tests) |
| BUG-P09-7 | tapping the alias-highlighted tile rewrote the key | an already-selected tile's tap is inert | runs green |
| BUG-P09-8 | emoji-leading nickname threw a UTF-16 paint error | `_initial` takes the first grapheme | runs green (2 tests) |

All ten proofs run unskipped in the file (23 passing tests: 10 proofs +
13 probes). No regression.

## Summary — iteration 3

| id | severity | one-liner | failing test (group › test) |
|---|---|---|---|
| BUG-P09-9 | **major** | batch 5 left P09’s two toggle compensations stale: the approval card renders 68 (design 72, due card 680 vs 684) and the track paints 307/618.5 instead of 303/620.5 | `BUG-P09-9 — the approval block misses the design after batch 5` › `the approval card is 72 high and the due card starts at 684` **and** `the toggle track is the design rect 303/620.5/51/31` |
| BUG-P09-10 | minor | the shared 59×44 hit slop is clipped by the 40-high approval Row: the toggle’s effective tap target is ~51×40, so taps 5 px above/below or 2 px right of the track miss | `BUG-P09-10 — the 59x44 hit slop is clipped by the approval Row` › `5 px above…` / `5 px below…` / `2 px right…` |
| BUG-P09-11 | minor | an out-of-range reward has no practical repair: a 9999-coin row needs 9899 `−` taps before Save unblocks | `BUG-P09-11 — an out-of-range reward has no practical repair` › `one step must bring 9999 into the 1..100 range` |
| BUG-P09-12 | **major** | four of the six icon tiles still draw the legacy glyphs (Bed, Dishes, Hoover, Bins); the mandatory 20:09 note says use `questBed/questDishes/questHoover/questBins` | `BUG-P09-12 — four icon tiles still draw the legacy glyphs` › `the six tiles draw the design glyphs in design order` |

BUG-P09-9 and BUG-P09-12 are **independently tracked**: `4_review.md` §2/§3
found them and `ORCHESTRATOR_NOTES.md` 20:09 orders both fixes (delete
`toggleTrackOffset`, switch the picker). The proofs here pin the exact
rects/glyphs so the loop can unskip them with the fix; BUG-P09-10 and
BUG-P09-11 are **not** covered by any existing note.

---

## BUG-P09-9 — major — the approval block misses the design after batch 5

**Where:** `quest_editor_view.dart:969-974` (card bottom padding
`NestSpacing.s3`) and `:996-997`
(`Transform.translate(offset: QuestEditorMetrics.toggleTrackOffset)`) +
`quest_editor_widgets.dart:49` (`toggleTrackOffset = Offset(4, -2)`).

**Why it is wrong:** both lines compensated the *old* `NestToggle` (a 59×44
box with the 51×31 track centred inside it). Batch 5 made the track the
widget’s own layout box and moved the 59×44 area into a non-layouting hit
slop (`nest_toggle.dart:12-16,36-44`), so the compensations now double-count:

* the card’s bottom padding was shaved 16→12 to absorb the old 44-high box;
  with a 31-high track the row is driven by the 40-high text block, so the
  card renders **68** where the design is **72** and everything below it (due
  card 680 vs 684, Delete button) sits 4 px high;
* the `Transform` pushes the track **4 px past the content edge** and **2 px
  up** (307/618.5 vs the design 303/620.5).

Measured at HEAD with the bundled Inter (matches `4_review.md` §2’s probe):

| element | design (PNG ÷3) | app at HEAD | Δ |
|---|---|---|---|
| `.card` approval | 20 / 600 / 350 / **72** | 20 / 600 / 350 / **68** | −4 h |
| `.toggle` track | **303** / **620.5** / 51 / 31 | **307** / **618.5** / 51 / 31 | +4 x, −2 y |
| `.card` due | 20 / **684** / 350 / 88 | 20 / **680** / 350 / 88 | −4 y |

Both deltas are outside the owner’s ±2 px rule, and the geometry tests
(`quest_editor_view_geometry_test.dart`, `quest_editor_view_test.dart`) fail
on them today (they are the three P09 failures in the tree-wide suite).

**Repro:** pump `/quest-editor` with the bundled fonts; measure
`getRect(NestCard).at(1)` → height 68; `getRect(NestToggle)` → 307/618.5.

**Suggested fix (verified by 4_review.md §2):** delete the
`Transform.translate` and restore the card’s bottom padding to
`NestSpacing.s4` (16). With only those two edits the card is
`20/600/350/72` and the track `303/620.5/51/31` exactly; then delete
`QuestEditorMetrics.toggleTrackOffset` and its stale comment, and update the
geometry/view tests to assert the track itself (51×31) instead of the old
59×44 box.

## BUG-P09-10 — minor — the shared hit slop is clipped by the approval Row

**Where:** `NestToggle`’s `_ToggleHitSlop` (`nest_toggle.dart:96-168`, shared,
`minWidth 59 / minHeight 44`) used inside the approval `Row`
(`quest_editor_view.dart:975-1005`).

**Why it is wrong:** the slop’s overhang is clipped by the parent `Row`’s
bounds — Flutter hit testing stops at the first render box whose
`size.contains(position)` fails, and the Row is only 40 high (the 16/22 title
+ 13/18 sub) and ends at the content edge (x 354). The design’s `::before`
area is 59×44 centred on the track (x 299→358, y 614→658) and overflows the
row into the card’s padding, which CSS does not clip. Measured at HEAD:

* taps flip at y 616.5…655.5 only (the Row’s bounds) — **615.5 and 656.5 do
  nothing**, so the effective vertical target is **40**, below the 44 minimum
  (RULES §8 / plan §5 “toggle 44 wrapper”);
* the right overhang is dead too: a tap at x 356 (inside the design hit area
  and, at HEAD, even inside the painted track 307→358) does not flip.

The review’s suggested replacement proof (“a tap 7 px above the track still
flips it”, `4_review.md` finding c) would fail for the same reason: 7 px above
620.5 is 613.5, outside the Row. The review’s claim that the 44 px target
“still reaches 59×44 through the shared hit slop” after its two-line fix is
not correct — after removing the Transform the Row is still 40 high.

**Repro:** pump `/quest-editor` (bundled fonts), tap at `(328.5, 615.5)`,
`(328.5, 656.5)` and `(356, 635.5)`: the toggle stays ON.

**Suggested fix:** give the toggle a ≥44-high layout parent so the slop is not
clipped, while keeping the design geometry — e.g. wrap it in
`SizedBox(height: 44)` with the track aligned 4.5 px from the row top and the
card’s bottom padding 12 (card stays 72, track stays 620.5, target 44), or
raise the row’s min height and re-balance the card padding; the invariant the
proofs pin is card 72 + track 303/620.5 + a 59×44 hit area. A component-side
alternative (hit-test the slop against an unclipped ancestor) is a shared
change for the DS, not a P09 fork.

## BUG-P09-11 — minor — an out-of-range reward has no practical repair

**Where:** `_coinsOutOfRange` + the widened `_coinFloor`/`_coinCeiling`
(`quest_editor_view.dart:366-372, 472-478`) and the one-step stepper
(`:889-899`).

**Why it is wrong:** the BUG-P09-6 fix correctly blocks Save with the
`Coins must be 1–100` caption, and BUG-P09-4 widened the stepper so the stored
value is reachable — but the only repair path is one tap per coin. A 9999-coin
row needs **9899 `−` taps** before Save unblocks; a 0-coin row needs one `+`.
The parent is stuck with a blocked save on a corrupt row and no practical way
out (the brief’s “9999 coins” edge case).

**Repro:** plant `coins: 9999`, open `?id=q-9999` (caption on, Save dead), tap
`decrease` once → `9998`, caption still on, Save still dead.

**Suggested fix:** make the first step jump the boundary — when
`_coins > _maxCoins`, `−` sets `_coins = _maxCoins` (and when
`_coins < _minCoins`, `+` sets `_minCoins`) — so one tap repairs the row and
the caption clears; alternatively show a one-tap `Use 100` action beside the
caption. Keep the displayed-as-stored value until the parent acts.

## BUG-P09-12 — major — four icon tiles still draw the legacy glyphs

**Where:** `_questIcons` (`quest_editor_view.dart:293, 298, 300, 306`):
`NestIcons.bed / dishwasher / hoover / bin`.

**Why it is wrong:** `ORCHESTRATOR_NOTES.md` 17:57 item 1 bans look-alike
substitutions and 20:09 + `docs/screens/_shared/shared_batch5_REPORT.md`
(lines ~87-90, ~209) deliver the exact design paths as
`NestIcons.questBed / questDishes / questHoover / questBins`
(`nest_icon.dart:36-39`, `assets/icons/ic_quest_*.svg`). The picker still
draws the legacy assets (`ic_bed.svg`, `ic_dishwasher.svg`, `ic_hoover.svg`,
`ic_bin.svg`), which is the stage-5 UI check’s blocking deviation (whole-tile
MAE 17.5–20.5 for Dishes/Hoover/Bins; `5_ui.md` deviation 1). Book and Paw
are byte-identical to the design and stay unchanged.

**Repro:** open `/quest-editor`; `QuestIconTile.icon` for the four keys is
`assets/icons/ic_bed.svg` etc., not `assets/icons/ic_quest_*.svg`.

**Suggested fix:** switch the four entries to
`NestIcons.questBed / questDishes / questHoover / questBins` (design order is
already correct) and update the icon pins in
`quest_editor_data_integrity_test.dart:170` in the same commit (the review
flagged that stale pin too).

---

## Attacks that hold (probes, unskipped — 13 tests)

- **Rapid double taps:** double-tap `Delete quest` → one confirm modal;
  double-tap `Due by` → one option sheet; double-tap `Cancel`, a due-sheet row
  and `Keep it` never pop a second route; double-tap **Save** is guarded
  (iteration-1 proof green).
- **Restart persistence:** save → dispose the app → new `NestlingApp` over
  the same Drift DB → the quest is on the library’s Active tab.
- **Parent/kid guard:** kid mode + `/quest-editor` (plain **and** with
  `?id=`) lands on `/parental-gate`.
- **320 dp × text scale 1.3**, new and edit mode: no overflow/exception.
- **One-child family:** the new quest defaults to that child.
- **Six children with long names** at 320 × 1.3: pills wrap in creation order,
  `Anyone` last.
- **Dark mode:** the Save pill’s `--surface` on `--leaf` keeps ≥ 4.5:1.
- **Back navigation:** a quest pushed from Today (`?questId=`) → Cancel
  returns to `/today`.
- **Zone/BST:** with the family moved to `Asia/Dubai`, the due time is still
  stored as the wall-clock `17:00` (`Before tea (5pm)`).
- **A11y actions:** due-sheet rows and the delete-confirm buttons expose
  `SemanticsAction.tap`; `performAction(tap)` moves the real state/DB.
- **`?idea=` prefill** (new in iteration 3) is covered by
  `quest_editor_view_test.dart` (prefill, fresh id on save, unknown-id
  fallback) and passes — no new proof needed here.

## Verification

```
$ dart format --set-exit-if-changed test/features/quests/p09_bugs_test.dart
Formatted 1 file (0 changed)
$ flutter analyze test/features/quests/p09_bugs_test.dart
No issues found!
$ flutter test test/features/quests/p09_bugs_test.dart
00:05 +23 ~7: All tests passed!        # 10 fixed proofs + 13 probes
$ flutter test test/features/quests/p09_bugs_test.dart --run-skipped
+23 -7: Some tests failed              # the seven iteration-3 proofs fail as documented
$ flutter test test/features/quests
01:12 +384 ~7 -3: Some tests failed    # only BUG-P09-9's three geometry rects
$ flutter test
02:53 +2598 ~8 -4: Some tests failed   # tree-wide
```

The tree-wide run has four failures, all outside this file: the three P09
geometry/view tests that pin the pre-batch-5 toggle (they fail on BUG-P09-9’s
rects — the review already documented their needed updates), and a core
`family_time_test.dart` `.single` failure (`Bad state: Too many elements`)
that belongs to `test/core/`, not this feature. Neither is a new P09 finding.

No simulator was booted, installed on, screenshotted or driven; `flutter
clean` was never run; no `// ignore:` and no shared file was touched.

**Out of scope (process, not findings):** the worktree also carries other
stages’ uncommitted work (briefs, UI PNGs, `5_ui.md`, etc.); it was left
untouched.


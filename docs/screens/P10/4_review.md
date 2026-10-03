# P10 · Quest library (`/quests`) — Stage 4 QA code review (iteration 3)

Scope: `git diff main...HEAD` (branch `screen/P10`) = 9
`features/quests/presentation/**` files + 11 `test/features/quests/**` files +
this screen's notes. **No product or test code was edited**; two temporary
measurement probes were written under `test/features/quests/`, run and deleted
(`git status` shows only the expected notes/screenshots).

Reviewed against: `docs/ARCHITECTURE.md` (per-feature contract, §55-110),
`docs/screens/RULES.md` (§1 paths, §4 data, §7 gates, §8 semantics_tap),
`docs/DESIGN_SPEC.md` §5 P10 (line 170), `docs/design/SPACING_SPEC.md`,
`design/html-source/screens/P10-quest-library.html` + `components.css`,
`design/screens/light|dark/P10-quest-library.png` (1170×2532 @3x, measured
pixel-by-pixel), `app/lib/core/design_system/`, `1_plan.md`,
`ORCHESTRATOR_NOTES.md` (all three updates, all items accounted for below),
`SHARED_REQUEST.md`.

## Verdict of the previous iteration, item by item

| Iter-2 finding | Status now |
|---|---|
| 1 BLOCKER — `NestSegmented` announced every option twice | **CLOSED** — landed on `main` as `ab1ba06` (`excludeSemantics: true`); all three proofs green |
| 2 MAJOR — applied search filter invisible after a tab round-trip | **CLOSED** — `TextEditingController` owned by the body (`quest_library_body.dart:50`) |
| 3 MAJOR — `Try again` leaked a watcher per tap | **CLOSED** — `_closeOnError` transformer (`quests_bloc.dart:39-51`) + a subscription-count test |
| 4 MAJOR — 2 px drift below the search field | **carried, shared** — `SHARED_REQUEST.md` §9 (see "Carried" below) |
| 5 MINOR — `aria-label` on an inert node | **carried, shared** — §8 |
| 6 MINOR — row title rebuilt `bodyStrong` by hand | **CLOSED** — `quest_idea_row.dart:83` |
| 7 MINOR — the two empty states did not share the 20 px gutter | **CLOSED** — `quest_library_body.dart:183` |
| 8 MINOR — bare `40` for the icon tile | **CLOSED** — `NestSpacing.s10` (`quest_idea_row.dart:60-61`) |
| iter-2 advisory 1 — `setText` assertion that can never pass | **CLOSED** — the assertion was replaced with a label + real-list assertion (`quest_library_a11y_actions_test.dart:339-354`) |

Every P10-local defect raised in iterations 1 and 2 is closed, with a test that
fails if it regresses.

---

## Gates I ran myself (no simulator)

```
dart format --output=none --set-exit-if-changed .   → 439 files, 0 changed
flutter analyze                                      → No issues found! (7.4 s)
flutter test                                         → +1953 −1
flutter test test/features/quests                    → +188 −1
```

The **one** failure in the whole app is
`quest_library_design_geometry_test.dart` →
`the hint is centred in the field, not floated to the top`. Its cause is in
`core/design_system/components/nest_text_field.dart` and it is filed with the
exact fix recipe in `SHARED_REQUEST.md` §10; the orchestrator's own instruction
for this item (`ORCHESTRATOR_NOTES.md` 12:17 item 1) is "if the cause is in
shared `NestTextField`, write `SHARED_REQUEST.md`", which is done. It is also
the *only* thing in the repository's suite that is red, and no other feature's
tests break. See "Carried" — P10 cannot clear it and the loop forbids skipping
the proof (`3_test.md:121`), so the resolution is the shared batch.

`git diff main...HEAD --name-only` filtered against RULES §1: **nothing** outside
`features/quests/presentation/**`, `test/features/quests/**` and
`docs/screens/P10/**`. `core/`, `app/app/**`, `tools/**`, the schema, the seed,
the DI and `quests_routes.dart` are all untouched.

---

## Measured geometry — design vs app (UI VERDICT RULE)

Design read directly off `design/screens/light/P10-quest-library.png`; app from
`docs/screens/P10/ui/app_light_3.png` (the iteration-3 UI capture) **and**
independently from the widget tree at 390×844 with the 47/34 device insets
injected and Inter/Nunito loaded through `FontLoader`. All side gutters measure
exactly 20.0 … 370.0 in both.

| Element | Design (y) | App (y) | Δ |
|---|---|---|---|
| title **ink** bbox | 61.00 … 86.33 | 61.00 … 86.33 | **0.00** |
| title box | 55 … 89 | 55 … 89 | 0 |
| `.segmented` track | 105 … 157 (52) | 105 … 157 (52) | **0** |
| `.segmented` thumb | 109 … 153 (44) | 109 … 153 (44) | **0** |
| `.search` ring, top border | 173 … 174 | 173 … 174 | **0** |
| `.search` ring, bottom border | 226 … 227 | 224 … 225 | **−2** (shared §9) |
| chip pill `All` (visible rect) | 227 … 271, x 20.00 … 68.67, 48.00 × 44.00 | 225 … 269, x 20.00 … 69.00, 48.33 × 44.00 | −2 y, +0.33 w |
| card 1 top | 291 | 289 | **−2** (shared §9) |
| cards 2-6 top | 375 / 459 / 543 / 627 / 711 | 373 / 457 / 541 / 625 / 709 | −2 each |
| card height / step | 68 / 84 | 68 / 84 | **0 / 0** |
| `.trow` title x | 84 (ink 85.0) | 84.0 | **0** |
| `.trow` title / meta line boxes | 22 / 18 | 303-325 (22) / 325-343 (18) | **0** |
| `+ Add` pill (visible rect) | 303 … 347, x 287.00 … 358.67, 71.00 × 44.00 | 301 … 345, x 286.67 … 358.67, 71.33 × 44.00 | −2 y, +0.33 w |
| search magnifier box | 24 × 24 at x 36 | 24 × 24 at x 37 | +1 |
| search hint ink | 194 … 206 (centre 200), x 74.0 | 183 … 194.7 (centre 188.8), x 72.0 | **−11.2** (shared §10) |
| tab-bar surface | top 726, stops at 810 | top 726, runs to **844** | ✓ owner bottom-edge rule |

**Reading.** Shapes, not just text, were compared (the UI rule's P05 trap): both
pills are the design's full width to within 0.33 px and exactly 44 high — none
has collapsed to its text width. Above the search field the screen is
pixel-exact, including the title's ink bbox. Everything below it carries one
uniform **−2 px** shift whose single cause is the shared field being 2 px short
(§9), and the hint's own −11 px whose cause is §10. Both are in `core/`; there
is no P10-local shift, and the gutter, the 84 px card step and the tab-bar
geometry are exact.

---

## Findings

Five, all **minor**. None blocks; all are cheap.

### 1. MINOR — the keyboard's Search key is an affordance that does nothing

`app/lib/features/quests/presentation/widgets/quest_library_body.dart:146`
(`textInputAction: TextInputAction.search`).
`app/lib/core/design_system/components/nest_text_field.dart:44-58, 171-192`.

`NestTextField.search` exposes no `onSubmitted`/`onEditingComplete`, and
`_buildSearch` forwards neither, so the blue **Search** key dismisses nothing
and changes nothing (the filter already applied per keystroke through
`onChanged`). The design's `<input type="search">` sits in no form, so its Enter
key is equally inert — this is a polish gap, not a mismatch — but P10 cannot
even drop the action key, because that parameter lives in `core/`.

**Fix (shared, now filed as `SHARED_REQUEST.md` §11):** add
`onSubmitted` to `NestTextField` and forward it; P10 then passes
`(_) => FocusScope.of(context).unfocus()`.

### 2. MINOR — the design's hint ink starts 2 px further right than the app's

`quest_library_body.dart:141-148` (via the shared field's
`contentPadding: EdgeInsets.only(left: -4)`).

Measured: design hint ink x **74.0**, app **72.0**. The extra ~2 px is Chrome's
default `input` padding — a browser artefact the CSS box model adds and Flutter
has no equivalent of. `quest_library_design_geometry_test.dart:235-238` already
pins this at ±4 with that reasoning, so it is *documented*, not drift.

**Fix:** none. Recorded so a later UI check does not read the 2 px as
misalignment (the ALIGNMENT rule) — the gutter and the icon are exact.

### 3. MINOR — a test comment still describes the pre-2a architecture

`app/test/features/quests/quest_library_states_test.dart:45` — *"The view reads
the idea templates from GetIt, so the scope is set up the same way
`pumpAppRoute` does"*. The view no longer does: since the `ideas` moved into
`QuestsState` (`quests_state.dart:15-21`) the view reads them from the bloc.
The comment at `:33-37` above it is already correct, so the file contradicts
itself.

**Fix:** one-line comment update. (`_pumpView` genuinely still needs the scope,
so the code is right — only the sentence is stale.)

### 4. MINOR (informational) — a data/filter module lives in `presentation/widgets/`

`app/lib/features/quests/presentation/widgets/quest_idea_meta.dart` holds a
const metadata map, an id→asset switch and the pure `filterQuestIdeas()`
function — no widgets.

`ARCHITECTURE.md:71` reserves `domain/` for "entities + abstract
`<feature>_repository.dart` ONLY", so moving it there would break the contract,
and the `quests` table has no category column to model (RULES §1 forbids a
schema change). Presentation is the only honest home, and there is precedent
(`design_system_gallery/presentation/widgets/gallery_colors.dart`). Recorded so
a later reviewer does not "fix" it.

**Fix:** none.

### 5. MINOR — the chip row allocates a new shader on every keystroke

`quest_category_chips.dart:61-68`. `shaderCallback` builds a fresh
`LinearGradient` + `createShader(bounds)` each time it runs, and the whole body
rebuilds on every `setState` from the search field's `onChanged`
(`quest_library_body.dart:147`), so the `.chipscroll` right-edge fade is
re-allocated ~10×/second while typing.

At seven chips this is free, and the alternative (a `CustomPaint` or a cached
shader) would add code for nothing today. **Fix:** none needed; if the body
ever grows, cache the gradient per width or take the chip row out of the
query-dependent subtree.

---

## Carried, shared-owned, deliberately NOT counted against P10

Per `ORCHESTRATOR_NOTES.md` 10:00 (*"Until main has these, do not hack them
locally, and they are not P10 findings"*) and the K03 precedent, these live in
`core/design_system/`, which RULES §1 forbids this screen from editing. All are
filed with measured numbers, exact `file:line` and a fix recipe.

1. **`NestTextField.search` hint floats to the top of the field** —
   `nest_text_field.dart:169-191`. Design hint ink centre y **200**, app
   **188.8**; the magnifier is correctly centred at 199, so the fix must not
   move the icon. Cause: a *tight* 44 px `SizedBox` around a `TextField` whose
   editable box measures 24 (the intrinsic line box), so `textAlignVertical`
   centres inside 24, not 44. Fix: give the editable the 44 px box
   (`contentPadding` vertical `(44−24)/2 = 10`, a strut, or fill the slot).
   `SHARED_REQUEST.md` §10. **This is the single red test in the repository**
   (`quest_library_design_geometry_test.dart:276`) and the reason
   `5_ui.md` returned FAIL. It cannot be skipped (loop rule) or patched
   (RULES §1) — it turns green the moment §10 lands.
2. **`NestTextField.search` renders 52 high where `.search` computes to 54** —
   `nest_text_field.dart:149-155`. `min-height:52px; padding:4px 16px;
   border:1px` under the global `box-sizing: border-box` is 4 + 44 + 4 + 2 =
   **54**; the widget sums 3 + 44 + 3 + 2 = 52. Result: the chip row and all
   ten cards sit a uniform 2 px high. `SHARED_REQUEST.md` §9. Composes with #1
   (once both land, the field is 173…227 and the hint centre is exactly 200).
3. **The search field's accessible name is its hint, not the design's
   `aria-label`** — `nest_text_field.dart:199-202` wraps the row in
   `Semantics(label: …, textField: true, child: row)` with no
   `container`/`excludeSemantics` and no action, so the node that carries
   "Search quest ideas" is inert while the editable announces "Search ideas".
   `SHARED_REQUEST.md` §8.
4. **`NestChip` exposes no tap action** (`nest_chip.dart:119-137`) — shared half
   of the `Semantics(excludeSemantics: true)` ruling. P10 does not use
   `NestChip` (its `QuestFilterChip` passes `onTap` **and** `container: true`),
   so no P10 test is red on it. `SHARED_REQUEST.md` §5.
5. **P08 paints `plate` lilac, P10 paints it sky** — the same title ("Lay the
   table") changes tile colour between the Today board and the library.
   Informational; `SHARED_REQUEST.md` §7.

## What is verified clean (no action)

- **ARCHITECTURE**: feature-first layout intact; `domain/` and `data/` untouched;
  one bloc per feature with the `initial/loading/loaded/failure` status set; the
  view owns no repository access (`ideas` travels on `QuestsState`, read once per
  load at `quests_bloc.dart:26`); `QuestPushOnce` is a widget, not a navigator
  helper; no `GetIt` import anywhere in `presentation/` (verified by grep).
- **RULES §1/§4**: paths clean; no schema or seed fork; money/period rules N/A
  (no `£`, no dates); quest order is the repository's creation order
  (`watchActiveQuests`, main's shared batch4), not alphabetical.
- **Design-system reuse**: `NestSegmented`, `NestTextField.search`, `NestButton`,
  `NestEmptyState`, `NestIcon`, `NestRadii`, `NestSpacing`, `NestDevice`,
  `NestTileTint`, `tokens.cardShadow`. `.trow` is correctly **not** `NestCard`
  (r-m 16 per `.trow`, `NestCard` is r-l 24), `QuestFilterChip` is correctly 44
  high per SPACING_SPEC §9.5 rather than `NestChip`'s 32, and the chip row
  correctly uses a horizontal `SingleChildScrollView` (not `NestChipWrap`, which
  is a `Wrap` — this row scrolls, it never wraps).
- **Token-only**: no literal colour except `Colors.transparent`/`Colors.black`
  in the shader mask (as `NestChip` does), no `fontSize`, **no `letterSpacing`**
  (measured 0.0 on the title, row title, meta, chip and `+ Add`), no
  `google_fonts`/`GoogleFonts` in the feature or its tests.
- **Fonts resolved**: `Inter` 16 w700 / 22 for `.nm`, `Inter` 13 w400 ink-2 /
  18 for `.mt`, `Inter` 14 w600 for `.chip`, `Inter` 14 w700 for `.addbtn`,
  `Nunito` 28 w900 / 33.6 for `.ptitle` — all confirmed in the rendered tree.
- **Colour values**: chip and `+ Add` fills are `leafTint` (227,245,236) with a
  1.5 px `leaf` border (23,128,79), matching the design PNG to the pixel; dark
  tiles stay tinted (62,38,29 peach, 23,58,43 leaf), never grey.
- **COPY**: character-for-character against the HTML — `Quests`,
  `Active ({n})` / `Ideas`, `Search ideas`, `Search quest ideas`, the seven chip
  labels in design order, `+ Add`, the ten `Add {title}` labels, and all ten meta
  strings with U+00B7 MIDDLE DOT (verified by codepoint, not by eye). UK
  spelling; no US variants in copy.
- **BALANCED HEADINGS**: `.ptitle` sets no `text-wrap: balance`
  (`components.css` puts balance on `.display`/`.h1`/`.kid-title`/`.kid-hero`/
  `.balance`; the HTML renders `class="ptitle"`), so the plain `Text` at
  `quest_library_body.dart:112` is correct — no `NestBalancedText` and no stray
  `LayoutBuilder`.
- **DATA OVER MOCKS**: the segmented count is `widget.items.length`; no literal
  `12` in the view.
- **ACCESSIBILITY ACTIONS**: all three `Semantics(excludeSemantics: true)` nodes
  (`quest_filter_chip.dart:29-37`, `quest_idea_row.dart:133-140`, `:157-168`)
  carry `onTap:`, and the two annotation nodes carry `container: true` so their
  labels do not bubble into the row. 11 tests fire
  `SemanticsOwner.performAction(…, SemanticsAction.tap)` and assert a real state
  or route change — the exact gesture VoiceOver/TalkBack performs.
- **CHILD ORDER / BOTTOM EDGE / ALIGNMENT**: quest order from the DB; the
  tab-bar surface runs 726 → **844** in both themes with no coloured strip
  (verified on the rendered PNG, `x = 8` is (255,255,255) from 727 to 843);
  every card, pill and bar shares the 20 px gutter, with only the chip row
  bleeding by design.
- **Performance**: no `Timer`, no `AnimationController`, no animation gate to
  honour; 10 rows rebuilt per keystroke over a `const`-heavy list; no intrinsic
  or double-pass layout; `TextEditingController` disposed at
  `quest_library_body.dart:53-56`; the bloc's Drift watcher cancels on
  `bloc.close()` and the retry path provably holds one subscription.
- **Error handling**: `_closeOnError` (`quests_bloc.dart:39-51`) makes the first
  error terminal so `emit.forEach` completes and cancels — the retry starts
  exactly one fresh watcher. Pinned by
  `quests_bloc_test.dart:202` (`a failed load releases its watcher so retry
  subscribes exactly once`). Loading/failure/empty are all covered
  (19 tests in `quest_library_states_test.dart`).
- **Children's Code**: parent screen — no analytics, ads, telemetry, network or
  child data beyond the family-scoped quest rows. PIP is N/A (no Pip on P10).
  **TRIAL**: no `subscription_status` write anywhere in the feature (grepped).
- **Test quality**: 188 tests in `test/features/quests`, no `skip:` anywhere, no
  suppression, every widget test ends with `disposeApp(tester)`.

## Advisory (process, not findings)

- Untracked scratch files must not be committed by the loop: the concurrent
  test/bugs stages left `app/test/features/quests/quest_library_seed_empty_test.dart`
  in the tree during this stage (an earlier one, `zz_probe_empty_test.dart`, was
  already cleaned up). This stage's own probes are deleted and `git status`
  carries no new code files.
- `5_ui.md`'s absolute y numbers (segmented 100.0, cards 297.0/381.0…) are read
  off the scaled compare sheet, not the source PNGs. Measured directly on both
  1170×2532 files the segmented track is **105 … 157 in the design and 105 … 157
  in the app**, and the card step is exactly 84 in both — the deltas it reports
  are right, its absolutes are ~5 px low. Stage 5 should measure the source PNGs.

## Verdict

P10's own code is clean. Every defect this screen ever had is either fixed with
a regression test (the invisible filter, the watcher leak, the gutter, the
type-scale duplication, the tile literal, and the `NestSegmented` duplicate
label now that it has landed) or is a `core/` defect filed with measurements
and an exact fix recipe. Measured against the design PNGs with real fonts, the
title's ink bbox, the segmented track and thumb, the card height and 84 px step,
the row type scale, both pill shapes, the 20 px gutters and the tab-bar
geometry are all exact; the only deltas are the shared field's 2 px and the
shared hint's 11 px.

Findings are five minor items, none of them a gate. The one red test in the
repository belongs to a shared component P10 may not edit and has already filed,
which is the same division of labour K03 passed under; landing P10 still
requires the shared batch to implement `SHARED_REQUEST.md` §10 (and §8/§9 with
it).

VERDICT: PASS

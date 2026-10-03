# P10 · Quest library (`/quests`) — Stage 4 QA code review (iteration 4)

Scope: `git diff main...HEAD` (branch `screen/P10`) = 9
`features/quests/presentation/**` files + 12 committed
`test/features/quests/**` files + this screen's notes (64 paths total).
**No product or test code was edited.** Three temporary measurement probes were
written under `test/features/quests/`, run and deleted; `git status` now shows
only the one untracked file that belongs to a concurrent stage
(`quest_library_typography_test.dart` — see *Advisory*).

Reviewed against `docs/ARCHITECTURE.md` (per-feature contract §65-89),
`docs/screens/RULES.md` (§1 paths, §4 data, §6 motion, §7 gates, §8
`semantics_tap`), `docs/DESIGN_SPEC.md` §5 P10 (line 170),
`docs/design/SPACING_SPEC.md`,
`design/html-source/screens/P10-quest-library.html` + `components.css` +
`tokens.css`, `design/screens/light|dark/P10-quest-library.png` (1170×2532
@3x, measured pixel-by-pixel with PIL, independent of any test),
`app/lib/core/design_system/`, `1_plan.md`, `ORCHESTRATOR_NOTES.md` (all four
updates), `SHARED_REQUEST.md`, and every owner rule in the brief.

No simulator was booted, installed on, screenshotted or driven.

---

## Verdict of iteration 3, item by item

| Iter-3 review finding | Status now |
|---|---|
| Carried #1 (MAJOR) — `NestTextField.search` hint floated 11 px high | **CLOSED on main** (`1db0f8a`) — hint centre measured **200.0** = the design's 200 |
| Carried #2 (MAJOR) — `NestTextField.search` 52 high, whole lower half −2 px | **CLOSED on main** (`1db0f8a`) — field **173…227 (54)**, cards back on 291/375/459/543/627/711 |
| Carried #3 (MINOR) — `aria-label` on an inert wrapper node (`§8`) | **still OPEN in `core/`** — no P10 test is red; carried, not a P10 finding |
| Carried #4 (MINOR) — `NestChip` exposes no tap action (`§5`) | **CLOSED on main** — `nest_chip.dart` now passes `onTap:` + `excludeSemantics` |
| Carried #5 (informational) — P08 paints `plate` lilac, P10 sky (`§7`) | still cross-screen; raised for the orchestrator, not a P10 edit |
| Finding 1 (MINOR) — Search key does nothing | **still OPEN in `core/`** (`SHARED_REQUEST.md` §11); not a P10 finding |
| Finding 2 (MINOR) — hint ink 2 px left of the design | measured 2 px, documented, unchanged, within tolerance |
| Finding 3 (MINOR) — stale comment in `quest_library_states_test.dart` | **CLOSED** |
| Finding 4 (MINOR/informational) — data map in `presentation/widgets/` | unchanged, still the right home (`ARCHITECTURE.md:71`) |
| Finding 5 (MINOR) — chip-row shader re-allocated per keystroke | **still present** → finding 4 below |

Nothing from iterations 1–3 regressed, and the whole feature suite is green for
the first time (202/202).

---

## Gates I ran myself (no simulator)

```
dart format --output=none --set-exit-if-changed .   → 442 files, 0 changed
flutter analyze                                      → No issues found! (3.6 s)
flutter test                                         → +1988 : All tests passed!
flutter test test/features/quests                    → +202 : All tests passed!
```

Zero failures anywhere in the repository — the first fully green iteration for
this screen. (An earlier whole-app run reported `+1991 −1`; the single failure
was my own temporary probe, since deleted, which accounts for the 4-test
difference.)

`git diff main...HEAD --name-only` filtered against RULES §1: **nothing** outside
`features/quests/presentation/**`, `test/features/quests/**` and
`docs/screens/P10/**`. `core/`, `app/app/**`, `tools/**`, the schema, the seed,
the DI and `quests_routes.dart` are untouched. The hidden `"P10 Quest library"`
anchor is gone (ORCHESTRATOR_NOTES 13:42 item 2); P09's own
`"P09 Quest editor"` anchor remains and is P09's to remove.

---

## Measured geometry — design vs app (UI VERDICT RULE)

Design read directly off `design/screens/light/P10-quest-library.png` with PIL
(scanning for the exact token colours `--surface`, `--surface-2`, `--line`,
`--leaf`, `--ink-3`); app measured from the widget tree at 390×844 with the
47/34 device insets injected and Inter/Nunito loaded through `FontLoader`.
Identical values in dark.

| Element | Design (y) | App (y) | Δ |
|---|---|---|---|
| title box | 55 … 89 | 55 … 89 | **0** |
| title **ink** bbox | 61.00 … 86.33 | (inside the box) | **0** |
| `.segmented` track | 105 … 157 (52) | 105 … 157 (52) | **0** |
| `.segmented` thumb | 109 … 153 (44) | 109 … 153 (44) | **0** |
| `.search` ring | 173 … 227 (54) | 173 … 227 (54) | **0** |
| magnifier (24 box) | ≈187.8 … 211.8, centre 199.8 | 188 … 212, centre 200.0 | **≤ 0.2** |
| search hint | ink 194.0 … 205.67, centre 199.83 | centre **200.0** | **0** |
| `.chipscroll` row | y 227 … 275 | 227 … 275 | **0** |
| chip pill `All` (visible rect) | x 20.33 … 67.33, y 227 … 270.67 (47 × 44) | x 20.00 … 68.51, y 227 … 271.00 (48.5 × 44) | **0 y, +1.5 w** |
| **card 1 top** | **291** | **291** | **0** |
| **card 2–6 tops** | **375 / 459 / 543 / 627 / 711** | **375 / 459 / 543 / 627 / 711** | **0** |
| card height / step | 68 / 84 | 68 / 84 | **0 / 0** |
| `.trow` title x, line boxes | 84, 22 / 18 | 84.00, 22 / 18 | **0** |
| `+ Add` pill (visible rect) | x 287.00 … 357.67 (71 wide) | x 286.40 … 358.00 (71.6 wide) | **≤ 0.6** |
| **gap under the last card at max scroll** | **32** (`.scroll` padding) | **32.0** | **0** |
| tab-bar surface | top 726, stops at 810 | top 726, runs to **844** | ✓ owner bottom-edge rule |
| tab icon / label box | 736…760 / 764…778 | 737…761 / 765…779 | +1 / +1 |

**Reading.** Every shape is measured, not just the text: both pills are the
design's full width to within 1.5 px and exactly 44 high — neither has collapsed
to its label width (the P05 trap). The two shared defects that held the whole
lower half 2 px high and the hint 11 px high are gone; the screen is now
pixel-exact from the title down to the last card, in both themes, and the
end-of-list gap is the design's 32 px exactly. The residual +1 on the tab-bar
icon/label boxes is inside the shared `NestTabBar` and inside ±2.

All side gutters measure exactly 20.00 … 370.00 in both themes; only the chip row
bleeds, which the design does on purpose (`.chipscroll { margin: 0 -20px }`).

---

## Findings

Six, all **minor**. None blocks; none is a gate.

### 1. MINOR — the failure state shows the raw exception string to a parent

`app/lib/features/quests/presentation/views/quest_library_view.dart:40`
→ `state.errorMessage ?? 'Something went wrong'`.
The bloc sets `errorMessage: error.toString()`
(`app/lib/features/quests/presentation/bloc/quests_bloc.dart:33`), so a real Drift
or SQLite failure renders as e.g. `SqliteException(14): unable to open database
file` in 16 px ink in the middle of the screen. The tests pin that as intended
behaviour (`quest_library_states_test.dart:160,183,238` assert
`'Exception: Database is offline'`).

Every other screen in the app does **not** do this: P08's `TodayFailureBody`
(`lib/features/today/presentation/widgets/today_loaded_body.dart`) renders
*"We couldn't load today's quests. Your data is safe — please try again."* in
`bodySmall`/`ink2` and never reads `errorMessage` at all. P10 is the only screen
that leaks internal error text into the UI.

**Fix.** Mirror `TodayFailureBody`: replace `state.errorMessage ??
'Something went wrong'` with fixed parent-facing copy and keep the raw string
out of the tree (log it in the bloc if it is wanted). Update the three
assertions above to assert the new copy instead of the exception string.
(`1_plan.md` (d) only asked for "centered message + `Try again`", so this is a
consistency/quality fix, not a plan deviation.)

### 2. MINOR — `QuestsState.copyWith` cannot clear `errorMessage`

`app/lib/features/quests/presentation/bloc/quests_state.dart:34` —
`errorMessage: errorMessage ?? this.errorMessage`.

After a failed load, a *successful* retry emits
`copyWith(status: loaded, items: …, ideas: …)` and the stale error text survives
in the state forever. It is harmless today because the view only reads
`errorMessage` inside the `failure` branch, but it is a latent trap: the next
feature that surfaces it in a snackbar would replay a resolved error. The same
"null means keep" rule is correct for `items`/`ideas` (a null argument is
indistinguishable from "not supplied") and wrong for a nullable message.

**Fix.** Either clear it on the `loaded` path in
`quests_bloc.dart:onData` (`errorMessage: null` via a sentinel such as
`copyWith(clearError: true)`), or add a `bool clearError` flag. Add one
assertion to `quests_bloc_test.dart`: a failed load followed by a successful
retry must leave `state.errorMessage == null`.

### 3. MINOR — `SHARED_REQUEST.md`'s status table is stale

`docs/screens/P10/SHARED_REQUEST.md:9-22`. The table still reads
*"§1 … **OPEN** — now the ONLY thing keeping P10's suite red"* and *"§5 … the
shared `NestChip` half is **OPEN**"*. Both landed on `main` (`ab1ba06` and the
`nest_chip.dart` `onTap`/`excludeSemantics` fix), and the per-section headers
were updated but the table was not. §8 is still genuinely open and should stay
listed as open. `1_plan.md` §(g) said "SHARED_REQUEST: none" and
§7 `docs/screens/RULES.md` §7.3 asks for the file to be accurate.

**Fix.** Refresh the four status cells; leave §8 open.

### 4. MINOR — the chip row allocates a fresh `ui.Gradient` on every keystroke

`app/lib/features/quests/presentation/widgets/quest_category_chips.dart:61-68`.
`shaderCallback` builds a new `LinearGradient` + `createShader(bounds)` each
time it runs, and the whole body rebuilds on every `setState` from the search
field's `onChanged` (`quest_library_body.dart:147`), so the `.chipscroll`
right-edge fade is re-allocated ~10×/second while typing.

Carried from iteration 3 (finding 5). At seven chips this is free and the
alternatives (`CustomPaint`, a cached shader) are more code than the problem
deserves, so this is a note rather than a demand.

**Fix (optional).** Cache the gradient per `bounds.width`, or lift the chip row
out of the query-dependent subtree so it stops rebuilding on each keystroke.

### 5. MINOR — an a11y test comment is factually wrong, and hides reachable chips

`app/test/features/quests/quest_library_a11y_test.dart:35-36`:
*"`Pets`, `School` and `Kindness` sit off-screen in the scrolling row, so their
semantics are not built"* — and `_visibleChips` limits the assertions to four.

I measured it: all seven chips have exactly one semantics node, including the
three that are scrolled off the right edge (`Pets` at x 526…613, `School` at
621…736, `Kindness` at 744…887 on a 390-wide viewport). A horizontal
`SingleChildScrollView` builds its whole `Row`, so nothing is dropped.

The suite is not wrong — it asserts a subset — but the stated reason is false and
it means three addressable, tappable controls go unasserted. That matters: this
is exactly the case where a label or action regression would hide.

**Fix.** Delete the second half of the comment and iterate `kQuestCategories`
(all seven) in both loops at `:116` and `:399`.

### 6. MINOR (informational, shared) — the unselected segmented label is w500, the CSS says w600

`app/lib/core/design_system/components/nest_segmented.dart:86-88` renders the
unselected option as `NestType.chipLabel(color: ink2).copyWith(fontWeight:
FontWeight.w500)`; `design/html-source/components.css:125` sets
`.segmented button { font-weight: 600 }` for **both** options and only recolours
the selected one. Measured on `/quests`: `Ideas` (selected) Inter 14 w600,
`Active (12)` Inter 14 w500, both `letterSpacing 0`.

This is in `core/`, which RULES §1 forbids P10 from editing, and the same
100-unit difference exists on every other screen that uses `NestSegmented`, so it
is not a P10 finding — it is recorded so the next orchestrator pass can put it in
a shared batch. Visible impact is minimal (a half-pixel at 14 px), which is why
it is minor.

---

## What is verified clean (no action)

- **ARCHITECTURE**: feature-first layout intact; `domain/` and `data/` untouched
  (`git diff main...HEAD` shows nothing under either); one bloc per feature with
  `initial/loading/loaded/failure`; the view owns **no** repository access —
  `ideas` travels on `QuestsState` and is read once per load
  (`quests_bloc.dart:26`), verified by grep: zero `get_it` imports in
  `features/quests/presentation/`. `QuestPushOnce` is a widget, not a navigator
  helper. DI + routes untouched.
- **RULES §1 / §4**: paths clean; no schema or seed fork; quest order is
  `watchActiveQuests` creation order (main's shared batch4), **not** alphabetical
  — verified: the Active tab renders `q-dishwasher, q-reading, q-bins, q-tidy,
  q-hoover, q-table, q-bed, q-biscuit, q-bag, q-plants, q-washing, q-living`, the
  seed's insertion order. `Periods` and `london_time.dart` are N/A (P10 renders no
  dates and no completion state). `TRIAL`: zero `subscription_status` writes in
  the feature.
- **Design-system reuse**: `NestSegmented`, `NestTextField.search`, `NestButton`,
  `NestEmptyState`, `NestIcon`, `NestRadii`, `NestSpacing`, `NestDevice`,
  `NestTileTint`, `tokens.cardShadow`. `.trow` is correctly **not** `NestCard`
  (`.trow` r-m 16, `NestCard` r-l 24); `QuestFilterChip` is correctly 44 high per
  `SPACING_SPEC` §9.5 rather than `NestChip`'s 32, because `.chipscroll .chip`
  sets `min-height:44px` and the row scrolls; the chip row is a horizontal
  `SingleChildScrollView`, **not** `NestChipWrap` — `NestChipWrap` is a `Wrap`, and
  this row must scroll (`.chipscroll { overflow-x:auto }`) and must carry the
  design's `mask-image` fade. The 44 px tap floor the CHIP ROWS rule protects is
  already satisfied by construction (each pill is 44 tall and 44+ wide).
- **Token-only**: no literal colour except `Colors.transparent` and the
  `Colors.black` mask alpha (exactly as `NestChip` does), no `fontSize`, no
  literal spacing (`s1…s10`, `padSide`, `gap10`, `gap14` only). The two bare
  `1.5`s are the design's `border:1.5px solid` on `.chip.selected` / `.addbtn` and
  match `nest_chip.dart:51` and `nest_day_picker.dart:89`; the two `height: 22/16`
  ratios match the `.trow .nm { line-height:22px }` CSS and follow the same
  `.copyWith(height: n/m)` precedent as P06/P07/P12.
- **LETTER SPACING**: measured **0.0** on the title, both segmented labels, the
  row title, the meta line, the chip label and `+ Add`, and on the tab-bar label
  (guarded by `quest_library_typography_test.dart`). No Material tracking
  anywhere; no `google_fonts` / `GoogleFonts.*` in `lib/features/quests` or
  `test/features/quests`.
- **BALANCED HEADINGS**: the design renders `class="ptitle"`, whose CSS
  (`font-family/weight/size/line-height/padding-top` only) sets **no**
  `text-wrap: balance`, so the plain single-line `Text` at
  `quest_library_body.dart:112` is correct — no `NestBalancedText` anywhere on
  the screen, in either tab or either theme.
- **Fonts resolved in the rendered tree**: `.ptitle` Nunito 28 w900 lh 34;
  `.nm` Inter 16 w700 lh 22; `.mt` Inter 13 w400 ink-2 lh 18; `.chip` Inter 14
  w600; `.addbtn` Inter 14 w700; `.segmented button` Inter 14.
- **Colour**: chip and `+ Add` fills are `leafTint` with a 1.5 px `leaf` border;
  every tile is tinted (no grey `neutral` for any of the 11 seed icon keys) and
  dark tiles stay tinted rather than grey.
- **COPY** (character-for-character against the HTML): `Quests`,
  `Active ({n})` / `Ideas`, `Search ideas`, `Search quest ideas`, the seven chip
  labels in design order, `+ Add`, the ten `Add {title}` labels, and all ten meta
  strings `"{coins} coins · Ages {n}+ · {Category}"` with U+00B7 MIDDLE DOT.
  Verified by codepoint, not by eye, for `·` (U+00B7, not U+2022) and the
  seed's `Reading – 20 minutes` en dash (U+2013, no ASCII hyphen, no `––`).
  UK spelling; no US variants.
- **DATA OVER MOCKS**: the segmented label is `Active (${widget.items.length})`
  read from the seeded stream; no literal `12` in `presentation/`. The
  `Seed.demo()` → 12 / deactivate → 11 transition is proved.
- **ORCHESTRATOR_NOTES 13:42 item 1** — every proof that waited on the shared
  batch is un-skipped and green: hint centre **200 ±1**, field **173…227 (54) at
  ±1**, chip row and all six card tops at ±1 (tightened from the rule's ±2
  ceiling), and the a11y single-node tests (`find.bySemanticsLabel('Ideas')`
  finds exactly one node). `rg 'skip:'` over `test/features/quests/` returns only
  the comment recording that the markers were removed. **Item 2** — the
  `"P10 Quest library"` anchor is deleted. **Item 3** — `FIXES_3.md`'s remaining
  local items (`bodyStrong` reuse, both empty states on the 20 px gutter,
  `NestSpacing.s10` for the tile, the stale comment) are all closed.
- **BOTTOM EDGE (owner)**: the `NestTabBar` surface runs 726 → **844** in both
  themes, asserted at the surface top, the physical bottom and the absence of a
  coloured strip; the design's own 810 stop is overridden by the owner rule, and
  the bar's *content* stays at the design's y (icon 737, label 765 vs the design's
  736/764).
- **ALIGNMENT (owner)**: every card, pill, empty state and control shares the
  20 px gutter; the title, segmented, field and rows are all exactly 350 wide;
  only the chip row bleeds, by design.
- **CHILD ORDER**: N/A — P10 lists no children.
- **PIP**: N/A — no Pip on this screen.
- **ACCESSIBILITY ACTIONS**: all three `Semantics(excludeSemantics: true)` nodes
  (`quest_filter_chip.dart:29-37`, `quest_idea_row.dart:133-140` and `:157-168`)
  carry `onTap:`, and both annotation nodes carry `container: true` so their
  labels cannot bubble into the row (the measured BUG-P10-9 signature). The
  suites assert `hasAction(SemanticsAction.tap)` for every chip, every `+ Add`,
  every Active row and both segmented options, and fire
  `SemanticsOwner.performAction(…, SemanticsAction.tap)` — the exact gesture
  VoiceOver/TalkBack performs — asserting a real state, list or route change.
  Parent mode, so the 44 px floor applies (the 56 px kid floor does not; the
  parent-only redirect to `/parental-gate` in kid mode is proved).
- **Performance**: no `Timer`, no `AnimationController`, nothing gated by
  `DISABLE_ANIMATIONS` (RULES §6 N/A). 10 rows rebuilt per keystroke over a
  `const`-heavy list; no intrinsic or double-pass layout; `TextEditingController`
  owned and disposed at `quest_library_body.dart:53-56`; `NestTextField` disposes
  its own focus node. Finding 4 is the only measured cost and it is negligible.
- **Streams / error handling**: `_closeOnError`
  (`quests_bloc.dart:39-51`) makes the first error terminal so `emit.forEach`
  completes and cancels — the retry provably holds exactly one subscription
  (`quests_bloc_test.dart`, "a failed load releases its watcher so retry
  subscribes exactly once"). `bloc.close()` cancels the Drift watcher. Loading /
  failure / both empty states are all covered.
- **Children's Code**: P10 is a **parent** screen — no analytics, no ads, no
  telemetry, no network (`rg 'analytics|firebase|http|HttpClient|package:http|advert'`
  over `lib/features/quests` → nothing), and no child data beyond the
  family-scoped active-quest rows the parent is entitled to see.
- **Test quality**: 202 tests across 13 files, **no `skip:`**, no suppression, no
  analysis_options weakening, and every widget test ends with `disposeApp`.
  `dart format --set-exit-if-changed` → 0 changed.

## Advisory (process, not findings)

- `app/test/features/quests/quest_library_typography_test.dart` is **untracked**
  in the tree (P10-owned, and correct: it pins `letterSpacing 0`, the absence of
  `NestBalancedText`, the type roles/line-heights, the U+2013 and U+00B7 codepoints
  and the seven-chip scroll at 320). It is left by a concurrent stage and the loop
  commits each iteration, so it will land; flagged only so nobody mistakes it for
  a stray file. I ran it — it passes.
- `main` has moved ahead with P12 (`0aec5fd`, `909fd39`) since the last merge;
  merge order is the loop's, not a finding.
- `nest_text_field.dart:213` still wraps the search row in
  `Semantics(label: …, textField: true, child: row)` with no `container` and no
  action (`SHARED_REQUEST.md` §8). No P10 test is red on it and P10 may not edit
  `core/`, so it stays carried.

## Verdict

P10's own code is clean and the screen is now geometrically exact against the
design PNG: the title box, the segmented track and thumb, the 54-high search
field, the centred hint, the 44-high chip pill, all six card tops on an exact
84 px step, the 32 px end-of-list gap and the owner-rule bottom edge all measure
0 px of drift in light and dark. The two shared defects that were the sole
blockers have landed, every proof that waited on them is un-skipped and green,
the whole feature suite is 202/202 for the first time, and every defect this
screen ever raised is either fixed with a regression test or filed with
measurements against a file P10 may not edit.

Findings are six minor items — none a blocker, none a major. Three are real but
small quality gaps in P10's own code (raw exception text in the failure state, an
uncancellable `errorMessage`, an inaccurate a11y comment that under-covers three
reachable chips); the rest are a stale status table, a negligible per-keystroke
allocation and one shared `NestSegmented` weight drift recorded for a batch.

VERDICT: PASS

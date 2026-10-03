# P10 · Quest library (`/quests`) — Stage 4 QA code review (iteration 2)

Scope: `git diff main...HEAD` (branch `screen/P10`) = 9 `presentation/` files
+ 9 `test/features/quests/` files. No code edited during this stage (temporary
measurement probes were written, run and deleted).

Reviewed against: `docs/ARCHITECTURE.md`, `docs/screens/RULES.md`,
`docs/DESIGN_SPEC.md` §5 P10, `docs/design/SPACING_SPEC.md`,
`design/html-source/screens/P10-quest-library.html`,
`design/screens/light|dark/P10-quest-library.png` (measured pixel-by-pixel),
`app/lib/core/design_system/`, `1_plan.md`, `ORCHESTRATOR_NOTES.md`
(mandatory — all 6 items accounted for below).

## Verification I ran myself (no simulator)

- `dart format --output=none --set-exit-if-changed` → **31 files, 0 changed**.
- `flutter analyze` → **No issues found**.
- `flutter test` on the nine **committed** test files →
  **150 pass, 4 fail** (findings 1 and 2).
- Design PNG measured directly from `design/screens/light/P10-quest-library.png`
  by scanning for the exact token colours (`--line`, `--surface-2`, `--leaf`,
  `--leaf-tint`, `--surface`, `--ink`, `--ink-2`, `--ink-3`, `--paper`, the five
  tile tints), and the app measured at 390×844 with the 47/34 device insets
  injected — the table is under "Measured geometry" below.
- `git diff main...HEAD --name-only` filtered against RULES §1 → **no path
  outside `features/quests/{presentation,domain,data}`, `test/features/quests`,
  `docs/screens/P10`**.

---

## Measured geometry — design vs app (UI VERDICT RULE)

Design values read off the light PNG (÷3); app values from a 390×844 surface
with `top:47, bottom:34` insets. All x gutters measured exactly 20.0…370.0 in
both.

| Element | Design y | App y | Δ |
|---|---|---|---|
| Screen title `Quests` (box) | 55 … 89 | 55 … 89 | 0 |
| `.segmented` track | 105 … 157 (52) | 105 … 157 (52) | 0 |
| `.segmented` selected pill | 109 … 153 (44) | 109 … 153 (44) | 0 |
| **`.search` field (border box)** | **173 … 227 (54)** | **173 … 225 (52)** | **−2 (bottom edge)** |
| **chip row (`All` pill)** | **227 … 271 (44)** | **225 … 269 (44)** | **−2** |
| **card 1** | **291 … 359 (68)** | **289 … 357 (68)** | **−2** |
| **card 2** | **375 … 443** | **373 … 441** | **−2** |
| **card 3** | **459 … 527** | **457 … 525** | **−2** |
| **card 4** | **543 … 611** | **541 … 609** | **−2** |
| **card 5** | **627 … 695** | **625 … 693** | **−2** |
| **card 6** | **711 … 726 (clipped by the bar)** | **709 … 777** | **−2** |
| card step | 84 | 84 | 0 |
| `.trow` title text x | 84 (ink 85.3) | 84 | 0 |
| `+ Add` pill | x 287 … 358, y 303 … 347 | x 286.4 … 358, y 301 … 345 | −0.6 / −2 |
| `.search` magnifier | box x 37 … 61 | x 37 … 61 | 0 |
| placeholder left | field x + 50 | field x + 51 | 1 |
| tab bar surface | top 726, ends 810 (owner rule: app must reach 844) | 726 … 844 | correct |
| tab icon box | ≈ 737 … 761 | 737 … 761 | 0 |
| tab label | ink 768 … 778 (box ≈ 764 … 778) | 765 … 779 | +1 |

**Reading:** everything above the search field is pixel-exact. Everything from
the search field down is a **uniform 2 px upward shift**, caused by one box
model error in the shared search row (finding 4). No misalignment, no gutter
drift, no coloured strip under the bar (the tab-bar surface runs 726 → 844 in
both themes), so the OWNER BOTTOM-EDGE and ALIGNMENT rules hold.

---

## Findings

### 1. BLOCKER — the committed suite is red: `NestSegmented` announces every option label twice

`app/test/features/quests/quest_library_a11y_test.dart:49,121,196` (three
tests) vs `app/lib/core/design_system/components/nest_segmented.dart:53-59`.

```
P10 segmented control each option is one labelled, tappable button   [E]
P10 icon buttons every interactive node announces what it does        [E]
P10 dark mode the same semantics contract holds in dark               [E]
  Expected: exactly one matching candidate
    Actual: Found 2 widgets with a semantics label named "Active (12)" / "Ideas"
```

The semantics tree I dumped confirms it — two nodes per option:

```
#21 label="Active (12)" actions=[tap]
  └#22 label="Active (12)" actions=[tap, focus]
#23 label="Ideas"       actions=[tap]
  └#24 label="Ideas"       actions=[tap, focus]
```

`nest_segmented.dart:53` wraps each option in `Semantics(button:, selected:,
label:, onTap:)` with **no `excludeSemantics: true`**, so the option's own
`Text(option.label)` (`:80`) stays in the tree and a screen reader walks the
label twice. RULES §7.1 requires `flutter test` → all pass, so this branch
cannot land as-is.

**Fix (one line, shared — `core/`, which RULES §1 forbids P10 from editing):
add `excludeSemantics: true` to the per-option `Semantics` at
`nest_segmented.dart:53`**; the `onTap` batch4 added stays, so the node keeps
its action (the pattern to copy is `nest_chip.dart:119-137`). Already filed as
`SHARED_REQUEST.md` §1 — it needs the orchestrator to land it on `main`.

P10 must **not** work around it: wrapping the control in `ExcludeSemantics`
would delete its tap actions, re-implementing it locally is forbidden, and
softening the three proofs to `findsWidgets` would mask the defect.

### 2. MAJOR — the applied search filter goes invisible after a tab round-trip (reproduced)

`app/lib/features/quests/presentation/widgets/quest_library_body.dart:38`
(`String _query`), `:118-131` (the search field is only built while
`filtersOn`, i.e. on the Ideas tab).

Reproduced on the committed code (type `pet` → tap `Active (12)` → tap
`Ideas`):

```
rows after typing:            1
field text after round-trip:  ""
rows after round-trip:        1
"Make your bed" present:      false
```

Because the search field is lifted out of the tree on the Active tab, its
`EditableText` state is discarded, while `_query` in
`_QuestLibraryBodyState` survives. The parent comes back to an **empty search
box with 9 of 10 ideas missing** and no way to tell why — to un-filter they
must type something and delete it again. (`_category` survives the same way but
stays *visible*, because the chip row returns with its selection, so the
invisible half of the filter is the text query only.)

**Fix (in scope, `quest_library_body.dart`):** own a `TextEditingController`
in the state and pass it to `NestTextField.search(controller: …)`, syncing
`_query` in `onChanged` — the field then always shows the query that is
actually applied, which is also what the design implies (the filters persist
across a tab switch). Dispose the controller in `dispose()`. The alternative —
clearing `_query` in the segmented `onChanged` when leaving Ideas — also
removes the dead end but silently throws the parent's filter away; prefer the
controller.

The working-tree `p10_bugs_test.dart` now runs this proof un-skipped and fails,
which is the correct expectation until the fix lands.

### 3. MAJOR — `Try again` leaks a live database watcher on every tap

`app/lib/features/quests/presentation/bloc/quests_bloc.dart:23`
(`await emit.forEach<List<Quest>>(_repository.watchItems(), …)`), reached from
`app/lib/features/quests/presentation/views/quest_library_view.dart:44-51`.

`QuestsBloc` is the only bloc in the app that subscribes with a bare
`emit.forEach`. Drift `watch()` streams never close, so when the stream errors
the handler's `onError` fires but the subscription stays open; the `Try again`
button then starts a **second** concurrent `emit.forEach` while the first is
still alive. Measured with a fake repository:

```
subscriptions after 1st load: 1
status after error:          QuestsStatus.failure
subscriptions after retry:   2      ← the failed one is still subscribed
subscriptions after 2nd retry: 3
```

Every other multi-stream bloc carries the exact guard for this, with a comment
naming the leak: `today_bloc.dart:80`, `family_bloc.dart:110`,
`pocket_money_bloc.dart:174` (`_closeOnError` — "otherwise the failed load's
watchers stay subscribed and every 'Try again' leaks another full set").
P10 duplicates none of it.

**Fix (in scope, `quests_bloc.dart`):** terminate the stream on the first
error before handing it to `emit.forEach`, e.g.

```dart
final _closeOnError = StreamTransformer<List<Quest>, List<Quest>>.fromHandlers(
  handleError: (error, stackTrace, sink) => sink..addError(error, stackTrace)..close(),
);
…
await emit.forEach(_repository.watchItems().transform(_closeOnError), …);
```

so `emit.forEach` completes, cancels the watcher and lets the retry start
clean. (A `StreamSubscription` field cancelled before re-subscribing works
too.) Add a bloc test asserting the subscription count is 1 after two
retries.

### 4. MAJOR — 2 px design drift: everything below the search field sits 2 px high

`app/lib/core/design_system/components/nest_text_field.dart:151-155` (shared),
reached from `app/lib/features/quests/presentation/widgets/quest_library_body.dart:124`.

`NestTextField.search` builds `minHeight: 52` + `vertical: NestSpacing.gap3` (3)
+ `border: 1` = **52 total**, and its doc comment claims "the row measures
exactly 52". The design is `box-sizing: border-box` globally
(`tokens.css:200`), so `.search { min-height:52px; padding:4px 16px;
border:1px }` with a 44-high input computes to 4 + 44 + 4 + 2 = **54**, which
is what the PNG shows (the `--line` ring spans y 173 … 227). Result: the chip
row and all ten cards are 2 px above the design (table above) — exactly on the
UI VERDICT RULE's ±2 px boundary, and a uniform shift of every element below
the field, which the rule explicitly calls a failure mode.

**Fix (shared — file in `SHARED_REQUEST.md`, do not hack locally):** make the
search row 54 tall — either `padding: EdgeInsets.symmetric(vertical:
NestSpacing.s4)` with `minHeight: 54`, or keep the 3 px padding and raise the
constraint to 54. Both keep the content centred exactly as the design paints
it. P10 must not wrap or re-pad the shared field locally.

### 5. MINOR — the search field's accessible name lands on an inert node

`app/lib/core/design_system/components/nest_text_field.dart:201`
(`return Semantics(label: semanticLabel, textField: true, child: row);`),
supplied by P10 at `quest_library_body.dart:126`.

The wrapper has no `container`, no `excludeSemantics` and no action, so the
tree carries two text-field nodes:

```
#26 label="Search quest ideas"  isTextField=true  actions=[]      ← inert
#28 label="Search ideas"        isTextField=true  actions=[tap, focus]
```

VoiceOver therefore announces the field as **"Search ideas"** (its hint), not
the design's `aria-label="Search quest ideas"` (`P10-quest-library.html:19`),
and the node that carries the intended label cannot be focused or typed into.
The field is still operable, so this is not a blocker, but the accessible name
is wrong and there is a phantom text field in the tree.

**Fix (shared):** merge the label onto the `TextField` itself — either
`ExcludeSemantics` the hint and put `label` on a `container: true` wrapper
that owns `SemanticsAction.setText`, or move the label into
`InputDecoration.labelText`/`semanticCounterText` so one node carries it. Add
to the existing `SHARED_REQUEST.md` §3.

### 6. MINOR — the row title rebuilds `bodyStrong` by hand

`app/lib/features/quests/presentation/widgets/quest_idea_row.dart:83-84`:
`NestType.body(color: tokens.ink).copyWith(fontWeight: FontWeight.w700, height:
22 / 16)`. `NestType.bodyStrong(color)` is already Inter 16/24 w700 and is what
`NestQuestCard` (`nest_quest_card.dart:74-76`) and `NestListRow`
(`nest_list_row.dart:83-86`) use for the same 22/16 override.

**Fix:** `NestType.bodyStrong(color: tokens.ink).copyWith(height: 22 / 16)` —
same pixels, one less duplicated weight literal to drift.

### 7. MINOR — the two empty states do not share the 20 px gutter

`app/lib/features/quests/presentation/widgets/quest_library_body.dart:159-167`
returns `const <Widget>[NestEmptyState(...)]` with **no** `_gutter`, while the
Ideas empty state (`:183-192`) wraps the same widget in `_gutter(...)`.
`NestEmptyState` adds its own 16 px, so the Active empty state starts 16 px
from the screen edge and the Ideas one 36 px — the OWNER ALIGNMENT rule asks
for one consistent 20 px gutter on a screen.

**Fix:** wrap the Active `NestEmptyState` in `_gutter(...)` like its sibling.

### 8. MINOR — the icon-tile edge is a bare `40` where a token exists

`app/lib/features/quests/presentation/widgets/quest_idea_row.dart:60-61`
(`width: 40, height: 40`). `NestSpacing.s10 == 40`, and the shared
`NestListRow` carries the same literal, so this is app-wide rather than
P10-specific — but the "tokens only" rule is what the design system is for.
Either use `NestSpacing.s10` or (better) ask the orchestrator for a
`NestTile` size token next to `NestDevice`, since `.icon-tile` is a component
dimension, not a spacing step. Add to `SHARED_REQUEST.md` §6/§7.

---

## What is verified clean (no action)

- **RULES §1**: no path outside `features/quests/presentation/**`,
  `test/features/quests/**`, `docs/screens/P10/**` in `git diff main...HEAD`.
- **Architecture (iteration-1 findings 2, 5 closed)**: `QuestLibraryView` no
  longer touches `GetIt`; `ideas()` is read once in `_onLoadRequested` and
  travels in `QuestsState`; the hidden `_QuestLibraryRouteAnchor` and its
  `Stack` wrapper are gone. DI, routes, the repository and the schema are
  untouched.
- **Design-system reuse**: `NestSegmented`, `NestTextField.search`,
  `NestButton`, `NestEmptyState`, `NestIcon`, `NestRadii`, `NestSpacing`,
  `NestTileTint`, `tokens.cardShadow`. `.trow` is correctly *not* `NestCard`
  (r-m 16, per `.trow`) and `QuestFilterChip` is correctly 44-high per
  SPACING_SPEC §9.5 rather than `NestChip`'s 32 — and the chip row is a
  scrolling `SingleChildScrollView`, so `NestChipWrap` (a `Wrap`) is the wrong
  container here; the whole pill is already the 44 px target.
- **Tokens only**: no literal colour (`Colors.transparent` only, as
  `NestChip` does), no `fontSize`, no `letterSpacing` (LETTER-SPACING rule
  respected), no `google_fonts`/`GoogleFonts` anywhere in the feature or tests.
- **Copy**: character-for-character against the HTML — `Quests`,
  `Active ({n})`/`Ideas`, `Search ideas`, `Search quest ideas`, the seven chip
  labels in design order, `+ Add`, `Add {title}` aria-labels, and all ten meta
  strings with U+00B7 middot and spaces (`5 coins · Ages 4+ · Bedroom` …).
  UK spelling throughout; no US spellings in copy.
- **DATA OVER MOCKS**: the segmented count is `widget.items.length`; no literal
  `12` in the view. **CHILD ORDER**: `QuestsRepository` creation order, not
  alphabetical (the repo test asserts Maya's 6 → Leo's 4 → Anyone's 2).
- **Copy `+ Add` semantics / tap targets**: the semantics tree shows one node
  per chip (`All`…`Kindness`, all `actions=[tap]`), one node per `+ Add`
  (`label="Add Make your bed"`, `actions=[tap]`, `container: true` so it does
  not bubble into the row), and one node per Active row carrying
  `"<title>. <meta>"` with `tap` — iteration-1 findings 8 and the
  `Semantics`/`onTap` rule are satisfied.
- **Iteration-1 finding 1 closed**: row text is start-aligned at card x + 64
  (measured 84.0 absolute; pinned by
  `quest_library_view_test.dart:400`).
- **Iteration-1 finding 6 closed**: `.chipscroll`'s right-edge fade is a
  `ShaderMask(dstIn)` over the viewport, exactly as the CSS mask.
- **Iteration-1 finding 7 closed**: `.ptitle` has no `text-wrap: balance`
  (`components.css` puts balance on `.h1`/`.display`, and the HTML renders
  `class="ptitle"` only), so the plain `Text` is correct — no
  `NestBalancedText`, no stray `LayoutBuilder` per rebuild.
- **Performance / lifetime**: no `Timer`, no `AnimationController`,
  `DISABLE_ANIMATIONS` irrelevant here; 10 rows rebuilt per keystroke over a
  `const` list; `QuestPushOnce` schedules only a post-frame callback (no
  controller to dispose, and a disposed state is never `setState`d); the
  bloc's watcher is cancelled on `bloc.close()` (verified: `hasListener`
  false afterwards).
- **Children's Code**: parent screen — no analytics, ads, telemetry or child
  data beyond the family-scoped quest rows.
- **Design system is honest about its own limits**: `SHARED_REQUEST.md`
  §1/§5/§6/§7 are accurate and still open; nothing in this diff contradicts
  them.

## Advisory (process, not findings)

The working tree — not `git diff main...HEAD` — currently adds
`test/features/quests/quest_library_a11y_actions_test.dart` and
`quest_library_design_geometry_test.dart` (untracked) and modifies
`p10_bugs_test.dart`. Two things the next stage should know, since the loop
commits the worktree:

1. `quest_library_a11y_actions_test.dart`'s search case asserts
   `hasAction(SemanticsAction.setText)` on the `TextField`. I checked the
   framework baseline: a **plain** `MaterialApp` + `TextField` in this Flutter
   build exposes `tap, focus` and **no** `setText`, so that assertion can never
   pass here and will sit red for a reason unrelated to P10. Assert on the
   label + `tap`/`focus` (or drive the field with `tester.enterText`) instead.
2. The new geometry test pins `field.height` at `54 ± 2`, which **passes at 52**
   and so locks finding 4's 2 px shift into the suite as "correct". Once the
   shared box model lands, tighten it to ±1 or exact so the drift cannot come
   back.

## Verdict

The iteration-1 architecture and accessibility findings are genuinely closed,
and the screen is token-clean, copy-exact and well aligned. What remains is
one blocker (three committed tests red on a shared one-line defect) and three
majors: an invisible filter after a tab round-trip that I reproduced on the
committed code, a retry path that leaks a database watcher per tap, and a 2 px
uniform drift of the whole lower half of the screen from a shared box model.
Findings 2 and 3 are fixable inside `features/quests/**`; 1 and 4 need the
orchestrator to land `SHARED_REQUEST.md` §1 and a new search-field item.

VERDICT: FAIL

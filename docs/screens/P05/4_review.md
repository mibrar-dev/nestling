# P05 · Add children — QA code review (STAGE 4, iteration 1)

Scope reviewed: `git diff main...HEAD` + the uncommitted working tree for
`screen/P05` (RULES §1 paths only). No code was edited in this stage; one
throwaway measurement probe was created and deleted
(`app/test/features/family/zz_probe_tmp_test.dart`).

Reviewed against: `docs/ARCHITECTURE.md`, `docs/screens/RULES.md`,
`docs/DESIGN_SPEC.md` §5 P05, `docs/design/SPACING_SPEC.md` §§1–3/6/10,
`app/lib/core/design_system/`, the design PNGs and
`design/html-source/screens/P05-add-children.html`.

Independent verification run in this stage:

```
flutter analyze   →  No issues found!   (full app, exit 0)
flutter test      →  not re-run in full; see "Tests" below (88 test/blocTest
                     declarations, 0 skips, 0 weakened assertions found by grep)
git status        →  only features/family/presentation/**, test/features/family/**,
                     docs/screens/P05/**
```

**Result: 1 major, 12 minor. The major finding is the already-filed
`NestChip` full-width defect (P05-BUG-1), which still leaves the screen
visually and functionally broken — and its "P05 cannot work around it"
premise is disproved by measurement (evidence below).**

---

## Findings

### 1. MAJOR — the age-chip row renders as 4 stacked full-width rows; `10–12`, `13+` and all five avatar swatches sit under the bottom CTA, and a swatch tap navigates to `/pocket-money-setup` instead of choosing a colour

`app/lib/features/family/presentation/widgets/add_child_form_card.dart:70-82`
(root cause `app/lib/core/design_system/components/nest_chip.dart:69-90`).

`NestChip`'s interactive branch is `ConstrainedBox(min 44×44) → Center →
Material → InkWell → Ink`. `Center` is an `Align` with no factors, so it takes
`constraints.biggest`; inside a `Wrap` run that is the full available width, so
each chip claims a 322×44 box at 390 px and the `Wrap` breaks after every one.
`SPACING_SPEC` §10.6 requires the 44-min tap wrapper to **"keep visual size"**
and the chip row to be `flex wrap gap 8` (§ `.chip-row`), i.e. one visual row
of pills — the P05 call site is the correct construction; the component is not.

Measured impact (from `3_test.md`, reproduced independently below): form card
≈298 px (design) → ≈470 px (app); 2 of 4 age bands reachable without
scrolling; a tap at a swatch's position lands on the CTA's **Continue** button
and leaves the screen.

**The `SHARED_REQUEST.md` "P05 cannot work around it" claim is wrong.** I
measured the alternatives in a throwaway probe on the real form-card content
box (page gutter 20 + card padding 14, `spacing: 8, runSpacing: 8`):

| container | 390 @1.0 | 390 @1.3 | 320 @1.0 | 320 @1.3 |
|---|---|---|---|---|
| `NestChip` direct (today) | 4 rows, 322×44 each | 4 rows | 4 rows, 252×44 | 4 rows |
| `Row` (rejected by build) | 1 row | **overflows 32** | — | **overflows 102** |
| `IntrinsicWidth(child: chip)` | **2 rows, 0 overflow** | **2 rows, 0 overflow** | **2 rows, 0 overflow** | **2 rows, 0 overflow** |

`IntrinsicWidth` collapses the four full-width rows to at most two, keeps every
box at 44 px tall and ≥44 px wide (the `ConstrainedBox` min survives), and
never overflows the card horizontally in any of the four required
configurations (`overflowPastRightEdge = 0.0` in every cell). With the real
Nunito face the four pills total ≈252–304 px ≤ the 342 px content width, i.e.
**one row, exactly as the design**, degrading to two rows at 320 px / 1.3×,
which is what `.chip-row { flex-wrap: wrap }` does.

Fix (either path closes this):

1. *Shared (preferred, already filed as `SHARED_REQUEST.md` #3)* — in
   `nest_chip.dart:74` replace the greedy `Center` with
   `Center(widthFactor: 1, heightFactor: 1)` (keeping the 44-min minimum on
   the pill's own `ConstrainedBox`), or wrap the pill in
   `Stack(alignment: Alignment.center)` inside a
   `ConstrainedBox(min 44×44)` so the tap area does not drive the flow size.
2. *P05-local, unblocks this iteration* — in `add_child_form_card.dart:70-82`
   wrap each chip: `IntrinsicWidth(child: NestChip(...))`. Add the regression
   test from `SHARED_REQUEST.md` #3 (all four chips share one `dy` at 390 px
   and 1.0, ≤2 rows and no overflow at 320 px / 1.3×).

The UI gate cannot pass until at least the chip row is fixed; the UI stage
should not be run on the current build.

### 2. MINOR — "Add another child" can reach the repository twice inside one frame

`app/lib/features/family/presentation/bloc/family_bloc.dart:86-124`,
`app/lib/features/family/presentation/views/add_children_view.dart:116-118`.

The only guard is a rebuild one frame after the bloc emits
(`onPressed: null` / `loading: true`). With bloc's default concurrent
transformer, two taps delivered before the first rebuild both enter
`_onAddChildRequested` and both read the same `draftNickname`. A next-frame
double tap is already covered by a test, so the practical window is one frame;
`addChild` also derives its id from
`DateTime.now().millisecondsSinceEpoch`
(`app/lib/features/family/data/family_repository_impl.dart:62`), so the second
insert collides on the primary key, throws, and is surfaced to the parent as a
spurious "Something went wrong — try again" on a nickname that was in fact
saved.

Fix: ignore the event when a save is already in flight —
`if (state.saveInProgress) return;` as the first line of
`_onAddChildRequested`, or register it with
`transformer: droppable()`.

### 3. MINOR — `FamilyLoadRequested` never closes its stream on error, so "Try again" leaks a second set of Drift watchers

`app/lib/features/family/presentation/bloc/family_bloc.dart:44-55`
(and the same pattern at `:63-72`).

Per bloc 9.2.1's own `Emitter.forEach` docs (`lib/src/emitter.dart:43-46`),
supplying `onError` **"will not result in … cancelations to the internal
stream subscription"**, so the handler never returns and the watchers stay
live. `Try again` (`add_children_view.dart:98-100`) then starts a second
handler and a second watcher set that is never released. This is exactly the
B08 defect P08 already fixed with `_closeOnError`
(`app/lib/features/today/presentation/bloc/today_bloc.dart:78-88`, test
`app/test/features/today/p08_bugs_test.dart:285`, recorded as P08-B08/MINOR);
P05 reintroduces it.

Fix: copy the P08 helper and apply it here —
`combineLatest2(...).transform(_closeOnError)` before `emit.forEach` in
`_onLoadRequested` (and to `_repository.watchChildren()` in
`_onChildrenRequested`).

### 4. MINOR — `FamilyChildrenRequested` is dead code, and the comment that justifies the design is factually wrong

`app/lib/features/family/presentation/bloc/family_bloc.dart:15, 26-27, 34-38, 58-72`.

Nothing dispatches `FamilyChildrenRequested` in production (the route only adds
`FamilyLoadRequested` — `app/lib/features/family/family_routes.dart:24-26`), so
the handler exists purely for tests. Worse, the comment *"A second
`emit.forEach` in another handler would never run while this one is open"* is
incorrect: bloc's default transformer is `concurrent()` and each `on<E>` bucket
is independent, so an `emit.forEach` in a *different* event handler does run
concurrently. The stated constraint therefore does not exist, and the comment
will mislead P15, which shares this bloc.

Fix: delete `FamilyChildrenRequested`, its handler and the comment (the load
subscription already covers children), or dispatch it from the route and
correct the comment.

### 5. MINOR — the age-chip group has no group semantics (design has `role="group" aria-label="Age band"`)

`app/lib/features/family/presentation/widgets/add_child_form_card.dart:70-82`.

The swatch group has `Semantics(container: true, label: 'Avatar colour')`
(`:91-93`) and the design HTML wraps the chip row in
`role="group" aria-label="Age band"`
(`design/html-source/screens/P05-add-children.html:70`); the chip row has
nothing, so a screen-reader user hears four bare pills with no group context.

Fix: wrap the chip `Wrap` in
`Semantics(container: true, label: 'Age band', child: Wrap(...))`.

### 6. MINOR — swatches are the only interactive control in product code built on a raw `GestureDetector`

`app/lib/features/family/presentation/widgets/add_child_form_card.dart:143-167`.

Every other tappable thing in `features/**` uses the design-system
`Material` + `InkWell` pattern (`kid_card_grid.dart:108-111`,
`today_loaded_body.dart`, and every DS component); a `grep` for
`GestureDetector` in `app/lib/features` returns this file and one dev-only
gallery widget. Consequences: no press feedback, no hover/focus highlight, and
no keyboard focus stop for a selection control.

Fix: `Material(color: Colors.transparent, shape: const CircleBorder(), child:
InkWell(customBorder: const CircleBorder(), onTap: onTap, child: Container(...)))`
and drop the outer `GestureDetector`.

### 7. MINOR — the h1 is not a semantics header

`app/lib/features/family/presentation/views/add_children_view.dart:192-197`.

The codebase convention wraps raw headings in `Semantics(header: true)`
(`app/lib/features/onboarding/presentation/views/welcome_view.dart:235`,
`app/lib/features/today/presentation/widgets/today_loaded_body.dart:375`,
`nest_chrome.dart:71`), so P05's "Who's in your nest?" is the only screen
heading with no header landmark.

Fix: wrap the `Text` in `Semantics(header: true, child: Text(...))`.

### 8. MINOR — kid-card content is vertically centred; the design top-aligns it, so the avatar sits 5 px low

`app/lib/features/family/presentation/widgets/kid_card_grid.dart:24-31, 71`.

`cardH` = 22 chrome + 44 avatar + 2 + 24 name + 4 + 18 age + 10 pencil
clearance = 124, while the padded content is 114. `Center` (`:71`) splits the
10 px surplus 5/5, so the avatar's top lands at 5 + 12 = 17 px instead of the
design's `padding: 12px 10px 10px` → 12 px, and the "Age 7–9" line ends 5 px
from the card bottom instead of 10
(`design/html-source/screens/P05-add-children.html:18`).

Fix: `Align(alignment: Alignment.topCenter)` instead of `Center` (or move the
10 px pencil clearance from the bottom of `cardH` to the top chrome, keeping
the card 124 tall for the pencil while the content starts at 12).

### 9. MINOR — `_onContinue` branches on the `TextEditingController`, not the bloc

`app/lib/features/family/presentation/views/add_children_view.dart:48-59`.

Every other read of the draft goes through `state.draftNickname`; this is the
one place the widget's controller decides behaviour, so the form has two
sources of truth for the same value and the "bloc is the source of truth"
comment at `:66-68` does not hold for the navigation branch.

Fix: `if (state.draftNickname.trim().isNotEmpty)` (the controller is still
correctly owned by the view for the field and the post-save refocus).

### 10. MINOR — a navigation `VoidCallback` is carried on the event and invoked from inside the bloc

`app/lib/features/family/presentation/bloc/family_event.dart:30-37`,
`app/lib/features/family/presentation/bloc/family_bloc.dart:86, 115`.

The bloc performs a `context.go(...)` side effect (`add_children_view.dart:51`)
at the far end of a handler, and the callback is the reason `onSaved` can fire
twice in finding 2. It also makes the event non-serialisable and couples the
bloc to a navigation outcome.

Fix (optional, low risk): emit a state flag (e.g. `lastSavedChildId`) and let
the existing `BlocListener` in the view do the navigation / refocus.

### 11. MINOR — presentation formatting helpers live in the bloc file and are imported by a widget

`app/lib/features/family/presentation/bloc/family_bloc.dart:11-22` consumed at
`app/lib/features/family/presentation/widgets/kid_card_grid.dart:6, 77, 92`.

`avatarColourFor` (a DB-string → `NestAvatarColor` mapping) and
`displayAgeBand` (a storage-format → display-format mapping) are exported from
the bloc file, so the widget layer depends on a bloc file for pure formatting.

Fix: move both into a feature-private presentation file
(`presentation/widgets/child_display.dart`) or make them `static` members of
`KidCardGrid`'s file; re-export nothing from the bloc.

### 12. MINOR — the save-failure path swallows the error with no log

`app/lib/features/family/presentation/bloc/family_bloc.dart:116-123`.

`on Exception catch (_)` replaces the cause with a generic string; the parent
loses any way to tell a disk-full from a constraint error. No other bloc logs
either, so this is a codebase-wide gap rather than a P05 regression — flagged
only so the error path does not get closed off.

Fix: at minimum `debugPrint('P05 addChild failed: $error')` (or the app's
logger, if one lands) alongside the inline error.

### 13. MINOR — two hard-coded 1 px offsets with no token

`app/lib/features/family/presentation/widgets/kid_card_grid.dart:102-104`
(`Positioned(top: 1, right: 1)`).

Faithful to `.edit { top: 1px; right: 1px }`
(`design/html-source/screens/P05-add-children.html:21`) but the only values in
the P05 diff that are neither a token nor zero (`NestSpacing` has no 1 px
entry). Every other spacing in the diff goes through `NestSpacing.gapN` /
`padSide` / `tapParent`.

Fix: add `NestSpacing.gap1 = 1` to the shared scale and use it (a shared
change → `SHARED_REQUEST.md`), or keep it with an explicit
`// mirrors .edit { top: 1px }` comment.

---

## Confirmed clean (no action)

* **RULES §1 scope.** `git status` touches only
  `features/family/presentation/{bloc,views,widgets}`, `test/features/family/`
  and `docs/screens/P05/`. **No `domain/` or `data/` edits**, so the shared
  `FamilyBloc`/state/event changes stay purely additive for P15 (no renames, no
  signature changes — `FamilyLoadRequested` untouched).
* **ARCHITECTURE.md.** Feature-first layout respected; one BLoC per feature
  (`FamilyBloc`), one view per route (`AddChildrenView`), feature-private
  widgets under `presentation/widgets/`, no use-case classes, no new folders,
  all imports `package:nestling/...`. The route already provides the bloc via
  `BlocProvider` + `FamilyLoadRequested`; the view does not re-create it.
* **Design-system reuse.** `NestStatusBar`, `NestNavBar`, `NestCard`,
  `NestAvatar`, `NestTextField`, `NestChip`, `NestButton`, `NestBottomCta`,
  `NestIcon` — nothing re-implemented. Colours only via `context.nest`; sizes
  only via `NestSpacing` / `NestDevice` / `NestAvatarSize` / DS props; type
  only via `NestType` (`h1`, `h3`, `body`, `caption`, `fieldLabel`). No raw
  hex, no raw `TextStyle`, no Google-font call outside the DS.
* **Copy and UK spelling** — exact match with the design HTML: "Who's in your
  nest?", "Nicknames only — no photos, no email.", "Add a child", "Nickname",
  "e.g. Ollie", "Age band", "4–6 / 7–9 / 10–12 / 13+", "Avatar colour" (en-dash
  and *colour* both correct), "We only ask for an age range so quests suit
  them.", "+ Add another child", "Continue", "You can change any of this later
  in Family." `.kid-age` renders `Age 7–9` / `Age 4–6` from the DB.
* **DATA OVER MOCKS.** Age bands and avatar colours come from the seeded rows
  (`seed.dart:152-177`: Maya `7-9`/lilac, Leo `4-6`/peach) and age text is
  derived (`displayAgeBand`), not hard-coded. The swatch fills map to the
  strong brand tokens (`tokens.lilac/peach/sky/leaf/coin`) while the avatars map
  to the `*Tint`/`a*` pairs — matching the design's two different treatments of
  the same `a-*` class.
* **Owner bottom-edge rule.** `NestBottomCta` is the last child of the column
  with its own `SafeArea(top: false)` and `tokens.surface` fill; the Scaffold
  is `tokens.paper`. No strip under the bar or around the home indicator in
  light or dark.
* **Owner alignment rule.** Page gutter `NestSpacing.padSide` (20) on the
  `ListView`, so head, grid, form card, CTA buttons and caption share the same
  left/right edges; the grid column is computed `(W − 40 − 10)/2`
  (`SPACING_SPEC` §10.2) instead of a fixed 170.
* **Spacing spec.** `.scroll` `0 20 32` (§1), `.bottom-cta` 16/20 with gap 8
  and a centred caption (§2), `.form-card` padding 14 (§3), `.kid-card`
  `12 10 10` (§3), `.avatar` s44 (§4), `.field` label 13 w600 ink-2 (§
  `.field`), swatch 44×44 with a 3 px ink selection ring (`boxShadow
  spreadRadius`), edit button 44×44 r12 at 20 px ink-3. Button icon 24 px is
  inside the spec's 20–24 range for P-screens.
* **Tap targets.** back 44×44, pencil 44×44, chips 44-min (DS), swatches
  exactly 44×44, Add-another 48, Continue 52.
* **Error/empty/loading handling.** `initial|loading` → centred spinner;
  `failure` → message + `Try again` re-dispatch; empty nickname → inline error
  with no repository call; >24 chars → inline error; repository throw → inline
  "Something went wrong — try again" with the form preserved; save clears only
  the nickname draft and keeps band/colour for the next child.
* **Resource hygiene.** The `TextEditingController` and `FocusNode` are
  disposed (`add_children_view.dart:30-35`); no `AnimationController`,
  `Timer`, `StreamSubscription` or `Listener` is created by this screen; the
  bloc's stream subscription is owned by `emit.forEach` (see finding 3 for the
  error path).
* **Performance.** No rebuild storm: the only per-keystroke rebuild is one
  `BlocBuilder` over a short list, `KidCardGrid` is a `shrinkWrap` grid over a
  family-sized list, and every `const`-able widget is `const` (`NestStatusBar`,
  the `SizedBox` separators, `NestIcon`, the empty grid).
* **Children's Code.** Parent-only screen; no analytics, ads, telemetry,
  network calls, child data in logs, or `PipAvatar` (the design shows
  initial-letter avatars marked `aria-hidden`, so the Pip rule is correctly
  N/A here). Nothing leaks between kid and parent mode.
* **Tests.** 88 test/blocTest declarations in one file; zero `skip:`/ignored
  tests; no `analysis_options.yaml` change; every app-pumping test ends with
  `disposeApp`; the suites cover light+dark, 320/390/430 × 1.0/1.3, both
  seeds, loading/error/retry, DB round-trip, navigation, semantics and tap
  targets.

## For the next stages (not findings)

* **Autofocus.** The design PNG shows the nickname field with its leaf focus
  ring because the HTML has `autofocus`. No screen in the app autofocuses a
  field (the only `requestFocus` in `features/**` is P05's post-save refocus),
  so treat the design's focused ring as a mock state — do **not** add autofocus
  to match the pixels.
* **Roster order.** `app_database.dart:293` orders `watchChildren` by nickname,
  so the grid shows Leo (left) before Maya (right) while the design mock shows
  Maya first. P05 correctly does not fork the order; the orchestrator owns the
  mock-vs-ordering call (already recorded as P05-BUG-3).
* **Compact nav bar.** `NestNavBar` compact is 44 px, `SPACING_SPEC` §1 says 52
  (`SHARED_REQUEST.md` #4). P05 consumes the component as-is; the ~16 px
  vertical offset that causes will be a uniform band drift, not a P05 defect.
* **`title: ''` workaround.** Compact + `title: null` asserts inside
  `NestNavBar` (`SHARED_REQUEST.md` #1). The `''` workaround is visually
  identical and correctly flagged with `TODO(P05)`; do not "clean it up" to
  `null`.
* **Bugs stage.** P05-BUG-2 and P05-BUG-3 are folded into findings 2 and the
  roster-order note above; P05-BUG-1 is finding 1. No new product-code bug was
  found in this stage.

VERDICT: FAIL

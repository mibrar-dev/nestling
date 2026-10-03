# Fix list after iteration 1

## From 3_test.md
# P05 · Add children — test notes (STAGE 3, iteration 1)

Route `/add-children`, feature `family`, parent mode. Tests live in
`app/test/features/family/add_children_test.dart` (28 → **65** tests, all
green). No screen code was changed in this stage.

**Result: one real, screenshot-verified bug blocks the UI gate
(P05-BUG-1, design-system root cause), plus two smaller findings. The suite
passes and `flutter analyze` is clean, but a bug was found — see
`SHARED_REQUEST.md` and *Bugs found* below.**

## Test inventory (65)

`bloc_test` / unit — every event and state path:

| Area | Covered |
|---|---|
| `FamilyState` defaults | `initial`, empty draft, `7-9`, `peach`, no error, not saving |
| `copyWith` | keeps `nicknameError` when omitted (sentinel), clears on explicit `null`, leaves other fields, equals original |
| `FamilyLoadRequested` | loading → loaded (members **and** children), stream error → failure |
| `FamilyChildrenRequested` | loaded with roster, stream error → failure |
| roster re-emission | `StreamController` pushes `[]` → kids → one kid; each replaces the cards |
| `FamilyDraftChanged` | each field, partial change leaves others, empty change emits nothing, nickname edit clears the error, age-band change does **not** clear it |
| `FamilyAddChildRequested` | empty → error + `addChild` never called; whitespace-only → same; >24 chars → length error; 24 chars → accepted; valid → trimmed nickname + draft band/colour; `onSaved` called once on success, **not** called when the repository throws; repo failure → inline error, form preserved; success clears the nickname draft only; second save reuses band/colour |
| helpers | `avatarColourFor` all 5 + fallback, `displayAgeBand` en-dash + `13+` passthrough |

Widget tests:

| Area | Covered |
|---|---|
| Light + dark | full content in both; failure state in dark too; **bottom-edge rule in both** |
| Widths | 320 / 390 / 430 × text scale 1.0 and 1.3 (6 combinations) — no overflow, CTA intact, scroll-through of every form label |
| Empty | `Seed.fresh` (form only, no cards) and `Seed.empty` (onboarded parent, no children → no grid, Continue still advances) |
| Loading | full-body spinner, head not shown |
| Error | message + `Try again` recovers to the loaded screen |
| Save states | both buttons disabled + Continue spinner while saving; the next-frame tap cannot re-submit; failed save keeps the text and re-enables; empty/whitespace and 25-char rejections are inline, never reach the DB |
| Real DB | saved row is trimmed and carries the selected band/colour, roster repaints from the stream, no navigation; 5 children → 3 rows of the computed tile height; roster order == DB order |
| Navigation | Back → `/privacy`; each pencil → `/child-profile?childId=<id>`; Continue (empty) → `/pocket-money-setup`; Continue (with text) saves then → `/pocket-money-setup`; add-another / chip / swatch taps stay put |
| Semantics | `Back`, `Edit <name>` (merged node, regex match), 5 `Avatar colour <name>` labels, nickname field labelled + `TextInputAction.done`, chip + swatch `selected` state, pencil node label read from the semantics tree and tapped through it |
| Tap targets | back 44×44, both pencils ≥44×44, 4 chips ≥44×44, 5 swatches exactly 44×44, Add another ≥48, Continue ≥52 |
| Alignment (owner rule) | head / kid grid / form card / CTA button / caption all on `left = 20` and `right = W − 20` at 320, 390, 430; form card edges == CTA button edges; grid column width computed (`(W − 40 − 10)/2`, 135 at 320); pencil stays inside its card |
| Bottom edge (owner rule) | `NestBottomCta` bottom == the physical screen height, full-bleed 0…W, panel colour == `tokens.surface`, Scaffold == `tokens.paper`, and the two differ so a short bar would be visible |

Every test that pumps the app ends with `disposeApp(tester)` (RULES §7).

## Results

```
dart format .        clean
flutter analyze      No issues found!            (full app)
flutter test         00:11 +544: All tests passed!   (full suite, 65 of them P05)
```

Probe scaffolding used to measure geometry was deleted; the only test file is
`add_children_test.dart`.

## Bugs found (recorded, not patched)

### P05-BUG-1 — age chips render as 4 stacked full-width rows, and the swatches
### end up under the bottom CTA (major, design-system root cause)

`NestChip`'s interactive branch
(`app/lib/core/design_system/components/nest_chip.dart:69-90`) is
`ConstrainedBox(min 44×44) → Center → …`. `Center` is an `Align` without
factors, so it takes `constraints.biggest` — inside a `Wrap` run that is the
full available width, so every chip claims a 322×44 box at 390 px and the
`Wrap` breaks after each one.

Repro (widget geometry, demo seed, 390×844):

```
add_child_form_card.dart:70  Wrap(spacing: 8, runSpacing: 8, NestChip × 4)
  ageChip-4-6   box 34,519 → 356,563   (322 × 44)
  ageChip-7-9   box 34,571 → 356,615   (322 × 44)
  ageChip-10-12 box 34,623 → 356,667
  ageChip-13+   box 34,675 → 356,719
  visible pill (Ink) ≈ 74–102 wide, centred in each 322-wide row
```

The design (`design/screens/light/P05-add-children.png`) shows **one row of
four** chips (`components.css` `.chip-row { display:flex; gap:8px;
flex-wrap:wrap }`), so every chip should sit on the same `dy`.

Impact, all reproduced:

1. The form card grows from ≈298 to ≈470+ px.
2. Only `4–6` and `7–9` are on screen; `10–12`, `13+` and all five avatar
   swatches sit **underneath** the `NestBottomCta` (chips at y 519/571/623/675
   vs the CTA top at y 658).
3. A tap at a swatch's position lands on the CTA's **Continue** button:
   `tester.tap(find.byKey(Key('swatch-sky')))` without scrolling navigates to
   `/pocket-money-setup` instead of choosing a colour (this is what broke my
   first draft of two navigation tests — the tests had to scroll the swatches
   clear of the CTA to exercise them).
4. Screenshot proof: `docs/screens/P05/ui/bug_evidence_chips_light.png`
   (`shot.sh /add-children`, demo seed, light, 390×844 @3x) — chips stacked
   and centred, `10–12`/`13+` clipped behind the bar.

Not a P05 workaround: `Row` typesets the widths correctly but the chip box
fills the row height (560 px) and the four chips overflow by 32 px at 390/1.3×
and 102 px at 320/1.3×, which `SPACING_SPEC` §10 forbids. Fix filed in
`SHARED_REQUEST.md` with a suggested construction and the regression test to
add once it lands.

### P05-BUG-2 — "Add another child" can save twice inside one frame (minor)

`add_children_view.dart:116-125` guards the double submit by rebuilding with
`onPressed: null` / `loading: true`, i.e. one frame after the bloc emits. Two
taps delivered in the same frame both reach `_onAddAnother`, and with bloc's
default concurrent transformer both handlers read the same draft nickname.

Repro (deterministic — repository gated on a `Completer`, one insert counted
per call):

```dart
await tester.tap(find.text('Add another child'));
await tester.tap(find.text('Add another child'));   // no pump between
await tester.pump();
// → repo.addChild called 2×; in production: two children rows, onSaved twice
```

Real-world window is one frame (a real double-tap lands ~6 frames later, and
that path *is* covered — "a tap in the next frame cannot submit a second
time" asserts `addChild` called exactly once). Recorded as-is; a bloc-level
guard (ignore `FamilyAddChildRequested` while `saveInProgress`, or a
`droppable()`/sequential transformer on that event) would close it.

### P05-BUG-3 — roster order: Leo first, Maya second (design order differs)

`app/core/data/app_database.dart:291-296` orders `watchChildren` by
`nickname`, so "Leo" < "Maya" and the grid shows Leo in the left column; the
design mock shows Maya first (seed insertion order). Not a P05 defect — every
roster screen inherits the same order — but the design mocks and the DB
disagree, and with mixed-case or accented names the order gets worse. Locked
into a test ("roster order comes from the database (nickname order)") so the
behaviour is explicit rather than accidental. Orchestrator call: align the
mocks, or switch the ordering to creation order.

## Observations for the UI stage (not bugs)

* The compact `NestNavBar` renders 44 px tall; `SPACING_SPEC` (lines 83, 88)
  specifies 52. The app screenshot's h1 ink sits at y 96.3 vs 112.3 in the
  design. Filed as a shared request (one-line `minHeight` change).
* Kid card tile: app 124 px vs the design's auto-height 116 px
  (`cardH` = padding 22 + avatar 44 + 2 + 24 + 4 + 18 + 10 pencil clearance).
  The 8 px is deliberate pencil headroom; compare.py will show it as a
  uniform band drift on the form card below.
* Measured gutters are exact: 20 px everywhere, form card edges == CTA button
  edges at 320/390/430, and the CTA surface runs white to the physical bottom
  edge in light **and** dark. The design PNG is the one that breaks the owner's
  bottom-edge rule: it is `#FBF7F0` (page tint) from y≈810 to y=843, i.e. a
  34 px cream strip under the CTA, while the app screenshot is `#FFFFFF` at
  y = 800/820/838/843 — the app is the correct one.
* `flutter_test` uses a fallback font (wider than Inter/Nunito), so in-test
  line counts are pessimistic. The 320 + 1.3× overflow tests are therefore
  conservative; real-text wrapping is shorter.


## From 4_review.md
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


## From 5_ui.md
# P05 · Add children — UI check (STAGE 5, iteration 1)

Route `/add-children`, simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB (390×844).
Shots: `SEED=fresh`, parent mode, `THEME=light|dark` (mandated command).
Comparisons: `tools/screens/compare.py` vs `design/screens/light|dark/P05-add-children.png`.

- Light: `docs/screens/P05/ui/app_light_1.png` vs design → `cmp_light_1.png`, **mean diff 6.61%**
- Dark: `docs/screens/P05/ui/app_dark_1.png` vs design → `cmp_dark_1.png`, **mean diff 6.76%**

Per-band drift (light): band0 0–105: 2.79% · band1 105–211: 11.88% · band2 211–316: 3.82% ·
band3 316–422: 4.57% · band4 422–527: 5.04% · band5 527–633: 19.21% · band6 633–738: 1.77% ·
band7 738–844: 3.71%. Dark is near-identical (band1 12.26%, band5 21.22%).

No Pip slot on this screen (avatar initials only) → PIP rule N/A.
Status-bar time/glyphs and home-indicator pill ignored (OS-drawn; `NestStatusBar` reserves height only).

## Deviations

1. [FAIL — blocks gate] Age-band chips render as 4 stacked full-width rows.
   Design: one row of 4 pills (`4–6`, `7–9` selected, `10–12`, `13+`), `gap 8`, form card ≈298 px tall.
   App (light + dark): 4 centred pills stacked vertically, one per row; form card ≈170 px taller;
   bands 5 drift 19–21% is almost entirely this. Same defect as review finding 1 / P05-BUG-1 /
   `SHARED_REQUEST.md` #3 (interactive `NestChip`'s factorless `Center` claims the full `Wrap`
   run width). A designer would reject this on sight.
   Fix: shared `nest_chip.dart` fix (e.g. `Center(widthFactor: 1, heightFactor: 1)` keeping the
   44-min tap area on the pill itself), already filed as blocking; or P05-local
   `IntrinsicWidth(child: NestChip(...))` per review evidence (2 rows max at 320 px / 1.3×, 1 row at 390 px).

2. [Expected — not a defect] Kid cards absent (Maya/Leo).
   Design: 2 cards (Maya lilac M Age 7–9, Leo peach L Age 4–6, edit pencils); band1 drift ≈12% is this.
   App: no cards — `SEED=fresh` means zero children, and the empty form-only layout IS the P05
   empty state per `1_plan.md` §d (DATA OVER MOCKS: the database is correct, here empty).
   Fix: none in product code. Re-shoot with `demo` seed next iteration to check the grid itself
   against the design (order note: DB sorts by nickname → Leo left, Maya right; design mock shows
   Maya first — orchestrator owns that call, recorded as P05-BUG-3).

3. [Minor — filed, no action] Compact nav bar 44 px vs spec 52 px.
   Design: h1 ink ≈ y112. App: h1 ≈ y96 (whole head block sits ≈8–16 px high; part of band0/1 drift).
   Fix: shared `NestNavBar` `minHeight` change, `SHARED_REQUEST.md` #4 (blocks: no). P05 consumes the DS component as-is.

4. [Accepted — no action] Nickname field has no leaf focus ring.
   Design: field shows focused ring (HTML `autofocus` mock state).
   App: unfocused. Per review: no screen autofocuses fields — do NOT add autofocus to chase pixels.

5. [Pass] Bottom edge (owner rule): `NestBottomCta` surface runs to the physical edge in both
   modes — no coloured strip under the bar or around the home-indicator area. Band7 drift (≈3.7–3.8%)
   is only the mock-vs-OS home-indicator pill and status glyphs.

6. [Pass] Everything else matches in both modes: copy (incl. en-dashes, "Avatar colour",
   "Nicknames only — no photos, no email."), title style/position (modulo #3), 20 px gutters with
   head/card/CTA/caption on the same edges, card padding/radii/shadows, swatch row (5 × 44 px,
   peach selected with ink ring), caption text, secondary "+ Add another child" (48) + primary
   "Continue" (52) + centred caption, dark-mode tokens (surface cards on paper, leaf-tint selected
   chip, mint Continue). No overflow, clipping, or ellipsis faults at 390 px.

## Verdict basis

Deviation 1 is a visible, designer-rejectable layout break present identically in light and dark;
it is already filed as the blocking shared request. Deviation 2 is seed-mandated and must not be
"fixed" in code. All owner rules (bottom edge, alignment, PIP N/A) otherwise hold.


## From 6_bugs.md
# P05 · Add children — bug hunt (STAGE 6, iteration 1)

Route `/add-children` (feature `family`, parent mode). Adversarial pass on
`screen/P05` at `90cb27c` (main merged mid-stage: compact nav 44 → 52 px,
`onboarding_kids` seed, P05 feature code unchanged).

Proofs: `app/test/features/family/p05_bugs_test.dart` — **8 tests, all
`skip: true`** with the bug id in the test name, so the normal suite stays
green. Verified failing with
`flutter test --run-skipped test/features/family/p05_bugs_test.dart`
→ **8/8 fail for the recorded reason**.

Gates on this build: `dart format .` 357 files clean · `flutter analyze`
No issues found! · `flutter test` **552 passed, 8 skipped, 0 failed** ·
no file outside RULES §1 touched.

**Result: 1 major (P05-BUG-1, still open), 5 minor, 1 observation.
and lets a tap meant for a swatch land on the bottom CTA.

---

## P05-BUG-1 — MAJOR — age chips render as 4 stacked full-width rows; the swatch row (and `10–12`/`13+`) sits under the bottom CTA

**Where:** call site `app/lib/features/family/presentation/widgets/add_child_form_card.dart:70-82`
(chips) and `:91-106` (swatches); root cause
`app/lib/core/design_system/components/nest_chip.dart:74` — the interactive
branch is `ConstrainedBox(min 44×44) → Center → …`, and a factorless `Center`
takes `constraints.biggest`, so inside a `Wrap` run every chip claims the whole
card content width and the `Wrap` breaks after each one.

**Repro (390×844, demo seed, current build):**

```
ageChip-4-6   322×44 box at y 535–579
ageChip-7-9   322×44 box at y 587–631
ageChip-10-12 322×44 box at y 639–683   ← centre 661 is under the CTA (top 658)
ageChip-13+   322×44 box at y 691–735
swatch-sky    y 765–809                 ← below the scroll viewport (bottom 658)
```

* Design (`.chip-row { display:flex; gap:8px }`): one row of four pills; form
  card ≈298 px; every swatch on screen above the CTA.
* App: form card ≈470+ px; `10–12` and `13+` are clipped behind the CTA and all
  five swatches are off-screen.
* Tapping where a swatch is (`tester.tap(swatch-sky)`, no scroll) hits the
  **bottom CTA**, not the swatch; selection never changes. With the pre-merge
  44 px nav the same tap navigated to `/pocket-money-setup` instead.
* After the mid-stage main merge (nav 52 px) the `10–12` chip centre also falls
  under the CTA: a plain tap on `10–12` hits the CTA and the chip is never
  selected.

**Proofs:** `[P05-BUG-1] the four age chips render in one row at 390`
(4 distinct tops `{535, 587, 639, 691}`, expected 1);
`[P05-BUG-1] the avatar swatches are visible and selectable without scrolling`
(swatch bottom 809 > viewport 658; tap leaves peach selected).

**Suggested fix:** the shared `nest_chip.dart` fix already filed in
`SHARED_REQUEST.md` #3 — replace the greedy `Center` with
`Center(widthFactor: 1, heightFactor: 1)` (keeping the 44-min on the pill) or
wrap the pill in `Stack(alignment: Alignment.center)` inside the 44-min
`ConstrainedBox`; or P05-local `IntrinsicWidth(child: NestChip(...))` per the
stage-4 measurement (1 row at 390, ≤2 rows and no overflow at 320/1.3). The
skipped proofs un-skip into the regression test once either lands.

*Note (not a separate finding):* because of this bug the merge of the 52 px
nav pushed `10–12` under the CTA and broke two existing tests
(“age chips are single-select”, “a saved child lands in the database…”). Both
were updated with the same documented scroll workaround the sibling tests
already use; the assertions are unchanged. They pass again, and BUG-1’s own
proofs still fail until the layout is fixed.

---

## P05-BUG-2 — MINOR — two taps delivered in one frame double-submit the same draft

**Where:** `app/lib/features/family/presentation/views/add_children_view.dart:116-126`
(the only guard is `onPressed: null` / `loading: true`, i.e. one frame late);
handlers `bloc/family_bloc.dart:86-124` run concurrently (bloc’s default
transformer), so both read the same `draftNickname`.

**Repro:** with `addChild` gated on a `Completer`, dispatch two taps before any
pump — both `Add another child` ×2 and `Add another child` + `Continue` call
`repo.addChild` **twice**. Against the real repository the two concurrent
inserts produce either **two duplicate child rows** (measured ids
`child-…391` / `child-…395`, both inserted) or, when both land in the same
millisecond, a primary-key collision on `child-<ms>`
(`family_repository_impl.dart:62`) surfaced as a spurious “Something went
wrong — try again” after the first child was in fact saved.

**Proofs:** `[P05-BUG-2] two "Add another child" taps save once`,
`[P05-BUG-2] "Add another child" then "Continue" in one frame saves once`
(both expected 1 call, actual 2).

**Suggested fix:** first line of `_onAddChildRequested` →
`if (state.saveInProgress) return;` (or register the event with
`transformer: droppable()`); optionally make the id collision-proof
(`child-<ms>-<counter>`).

---

## P05-BUG-4 — MINOR — “Try again” leaks the failed load’s watchers

**Where:** `bloc/family_bloc.dart:44-55` (and `:63-72`). `emit.forEach` with an
`onError` callback deliberately does **not** cancel the subscription, so after
a stream error the first `combineLatest2(watchItems, watchChildren)` keeps its
Drift watchers alive; each retry starts another set. P08 fixed the identical
defect with `_closeOnError` (`features/today/presentation/bloc/today_bloc.dart:78-88`).

**Repro / proof:** `[P05-BUG-4] Try again releases the failed load before
re-subscribing` — first `watchItems` subscription errors, “Try again” is tapped;
`watchItems` is called twice but the first subscription’s `onCancel` never runs
(cancels 0, expected 1).

**Suggested fix:** copy the P08 `_closeOnError` stream transform and apply it to
`combineLatest2(...)` in `_onLoadRequested` and to `watchChildren()` in
`_onChildrenRequested`.

---

## P05-BUG-5 — MINOR — typing during an in-flight save is silently discarded

**Where:** `views/add_children_view.dart:66-73` — the save-success
`BlocListener` clears the controller unconditionally, and
`bloc/family_bloc.dart:108-115` emits `draftNickname: ''` unconditionally, so a
nickname typed while the spinner is up (field stays enabled) is wiped from both
the controller and the bloc draft.

**Repro / proof:** `[P05-BUG-5] text typed while the save spinner runs is
preserved` — gated `addChild`; enter “Ollie”, tap Add another, type “Ada” while
saving, complete the insert → field is `''`, expected `'Ada'`.

**Suggested fix:** capture the saved nickname; only clear the controller/draft
when the field still holds that nickname (`state.draftNickname.trim() ==
saved`), or disable the nickname field while `saveInProgress`.

---

## P05-BUG-6 — MINOR — new children always store `ageYears = 7`, whatever band was chosen

**Where:** `data/family_repository_impl.dart:56-75` — `addChild` never writes
`ageYears`, so the schema default 7 (`core/data/app_database.dart:57`) stands
even for a `13+` child (seeded children carry real ages: Maya 9, Leo 6). P08
orders the family “eldest first” by `ageYears`
(`features/today/data/today_repository_impl.dart:82-87`), so every newly added
child sorts as a 7-year-old.

**Repro / proof:** `[P05-BUG-6] a 13+ child stores age years inside its band` —
add “Zara” with the `13+` chip → row `ageBand='13+'`, `ageYears=7` (expected
≥13).

**Suggested fix:** derive `ageYears` from the band inside `addChild`
(monotonic mapping, e.g. 4-6→6, 7-9→9, 10-12→12, 13+→13) or extend the
repository interface with an `ageYears` parameter and pass it from the bloc.

---

## P05-BUG-7 — MINOR — “Who’s in your nest?” is not a header landmark

**Where:** `views/add_children_view.dart:192-197` — raw `Text`; every other
screen heading is wrapped in `Semantics(header: true)` (e.g.
`features/onboarding/presentation/views/welcome_view.dart:235`,
`features/today/presentation/widgets/today_loaded_body.dart:375`), so P05’s h1
is the only heading with no header landmark for screen-reader navigation.

**Proof:** `[P05-BUG-7] Who's in your nest? is exposed as a header`
(`flagsCollection.isHeader` false, expected true).

**Suggested fix:** `Semantics(header: true, child: Text(...))`.

---

## P05-BUG-3 — OBSERVATION — roster order: DB sorts by nickname, the mock shows Maya first

`core/data/app_database.dart:291-296` orders `watchChildren` by `nickname`
(BINARY collation: uppercase before lowercase, accents after ASCII), so the
grid shows Leo (left) then Maya (right); the design mock shows Maya first
(seed insertion order). This is **not a P05 defect** — the screen consumes the
DB order as required by RULES §4, and the existing test locks the behaviour.
No skipped proof: the mock-vs-DB call belongs to the orchestrator (align the
mocks, or switch the shared ordering to creation order). Mixed-case nicknames
(`ada` vs `Zoe`) sort case-sensitively today.

---

## Verified sound (adversarial probes, not findings)

| Area | Result |
|---|---|
| Data edge cases | 0 children → form-only layout; 1 child → one 170 px card; 6 children → 3 rows of the computed tile height, no overflow; empty `watchChildren` list → no grid, CTA intact |
| Long UK names | “Maximilian-Alexander” (20 chars) + 5 more children at 320 px / 1.3× → no exception, ellipsis on the cards; 24-char boundary accepted, 25 rejected inline |
| Money edge cases | P05 renders no coins/£ — £0.00, £999.99, 9999 coins N/A by construction (no money widgets in the diff) |
| Rapid double taps | next-frame re-tap already cannot resubmit (existing test); sub-frame window = P05-BUG-2 |
| Back / deep links | Back → `/privacy`, double-tap idempotent; direct `/add-children` launch lands on the screen; edit → `/child-profile?childId=<id>` per card |
| Kid-mode guard | kid mode deep-link to `/add-children` → `/parental-gate` (onboarding locations are parent-only in `router.dart:96-117`) |
| Restart / Drift persistence | a child added, then a fresh app launch over the same DB → card present |
| Dark mode | token contrast on the dark surface: `ink2` 9.82:1, `ink3` 6.19:1 (≥4.5/3); dark-mode widget tests pass |
| Text scale 1.3 × width 320 | 320/390/430 × 1.0/1.3 matrix green; six children + long names at 320/1.3 no overflow |
| Async gaps / emit after close | closing the bloc mid-save drops late emits cleanly (bloc 9.2.1); `onSaved` callbacks are `mounted`-guarded |
| Timezone / money rounding | P05 has no dates or money — N/A by construction |
| Bottom edge / alignment (owner rules) | `NestBottomCta` surface to the physical edge, 20 px gutters, form card == CTA edges — existing owner-rule tests pass on the merged build |

### Cleanup notes for the fix pass (not findings)

* `NestNavBar` now supports `title: null` after the shared nav fix, so the
  `title: ''` + `TODO(P05)` workaround in `add_children_view.dart:88-92` can be
  simplified.
* Review findings not re-proved here (code quality, no functional defect):
  duplicate `displayAgeBand`/`_displayBand` helpers, presentation helpers
  exported from the bloc file, `onSaved` navigation callback carried on the
  event, swatches on a raw `GestureDetector` (no press feedback/focus stop),
  age-chip group semantics missing, swallowed error log.


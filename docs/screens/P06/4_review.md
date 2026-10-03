# P06 Pocket money setup — QA code review (Stage 4, iteration 6)

Reviewed `git diff main...HEAD` per `docs/ARCHITECTURE.md` (feature-first;
domain = entities + abstract repo only; BLoC per feature/screen; DI + routes
per feature), `docs/screens/RULES.md` (edited only allowed paths), the design
system in `app/lib/core/design_system/` (tokens only, components reused),
`docs/DESIGN_SPEC.md §5 P06` (every element, copy character-exact, UK
spelling), accessibility, performance (no rebuild storms, `const` widgets,
streams disposed), error handling and Children's Code hygiene. **No code was
edited by this stage** (the one temporary probe file created for finding 2 was
deleted; `git status` shows no `app/lib/**` or test change from this stage —
see "Worktree note").

## Method / evidence

| Check | Result |
|---|---|
| `git diff main...HEAD --stat` | 14 code files, all in `app/lib/features/pocket_money/**` + `app/test/features/pocket_money/**` (+ `docs/screens/P06/**`) ✔ |
| `flutter analyze lib/features/pocket_money test/features/pocket_money` (this stage) | **No issues found!** (exit 0) |
| `flutter test test/features/pocket_money/` (this stage) | **+170: All tests passed!** (exit 0, 0 skips) |
| `dart format --set-exit-if-changed` on the diff files | 0 changed |
| Design PNG re-measurement (PIL, ÷3, light + dark) + app shots `ui/app_light_6.png`, `ui/app_dark_6.png` | anchors reproduced below |
| Semantics probe (temporary, deleted): real app at `/pocket-money-setup`, `onboarding_kids`, `ensureSemantics()` | action flags quoted in finding 2 |
| Simulator | **not used** by this stage (stage 5 only, allowed UDID) |

Independent design anchors I re-measured off `design/screens/light/P06-pocket-money.png`
(÷3), each matched by `app_light_6.png` to ≤0.7 px:

| Element | Design | App |
|---|---|---|
| H1 | box 107–175 (ink 113–172) | 107–175 ✔ |
| Option cards | tops 191 / 263 / 335, height 64 (borders 191–193 … 253–255) | identical ✔ |
| Settings card | top 415, bottom border 685 | identical ✔ |
| `Payout day` label ink | 438–447 | 438–447 ✔ |
| Day pills | y 455–487 (32 tall); x runs 36.00–75.67 / 82.00–122.67 / … / 314.00–353.67 | 455–487; x 36.00–76.00 … 313.67–353.67 ✔ (≤0.7 px, same left/right edges) |
| Dividers | 495, 620 | 495, 620 ✔ |
| `Weekly base` ink | 511.7–518 | 511.7–518 ✔ |
| CTA top border | 685 | 685 ✔ |
| Bottom edge (owner rule) | design paints paper below 810; app must not | app rows to y 2531 are CTA `surface` in both themes (255,255,255 light / 31,28,46 dark) ✔ |

## Findings

### 1. MAJOR — the coin-value text is **not** right-aligned to the card's inner padding (33 px short); this is the new mandatory `ORCHESTRATOR_NOTES.md` "UPDATE (09:30)" item
`app/lib/features/pocket_money/presentation/views/pocket_money_setup_view.dart:774-781`

```dart
Expanded(child: Text('Coin value', …)),        // flex: 1, tight
Flexible(child: Text('10 coins = ${10 * coinValuePencePerCoin}p',
    style: NestType.bodySmall(color: tokens.ink2), softWrap: false, …)),
```

`Expanded` and `Flexible` are **both flex: 1**, so the Row first gives each of
them half the free space and *then* the loose `Flexible` sizes its `Text` to
the intrinsic width inside that half. With the default `TextAlign.left` the
value therefore hugs the middle of the row instead of the trailing edge.

Measured ink on the trailing string, same scan, same row:

| | ink start | ink end | vs card content edge (354) |
|---|---|---|---|
| `design/screens/light/P06-pocket-money.png` | 256.0 | **352.7** | −1.3 (right-aligned) |
| `ui/app_light_6.png` | 224.3 | **320.7** | **−33.3** |

The design's right edge is the same as the Sun pill's (353.67) and the `+`
buttons'; the app's is 33 px inside it. This is a visible misalignment (owner
ALIGNMENT rule: "nothing a few px off") and it is exactly the item the
orchestrator added at 09:30.

**Fix** — make the trailing value a tight, end-aligned flex child (no layout
change to the row, the ellipsis backstop is kept):

```dart
Expanded(
  child: Text(
    '10 coins = ${10 * coinValuePencePerCoin}p',
    style: NestType.bodySmall(color: tokens.ink2),
    textAlign: TextAlign.end,
    softWrap: false,
    overflow: TextOverflow.ellipsis,
  ),
),
```

**Test to add** (real fonts, as `pocket_money_setup_view_geometry_test.dart`
already does): `expect(tester.getRect(find.text('10 coins = 10p')).right,
moreOrLessEquals(tester.getRect(find.byType(NestCard)).right - NestSpacing.s4,
epsilon: 1))` at 390 **and** at 320/430, light and dark. Note that at 320 the
value must still ellipsis rather than push the tile — `Expanded` + `softWrap:
false` keeps that behaviour.

### 2. MAJOR — the three option cards and the seven day cells are announced as buttons but carry **no `SemanticsAction.tap`**, so a screen-reader user cannot operate them
`app/lib/features/pocket_money/presentation/views/pocket_money_setup_view.dart:313-319` (`_PocketOptionCard`) and `:556-567` (`_DayCell`)

Both use

```dart
Semantics(button: true, selected: selected, label: …, excludeSemantics: true,
    child: GestureDetector(onTap: onTap, …)),
```

`excludeSemantics: true` drops **every descendant semantics contribution** —
including the `GestureDetector`'s `onTap` action — while the node itself keeps
`isButton`/`isSelected`. The result is a control that says "button" and cannot
be activated (WCAG 2.1 AA SC 4.1.2 Name/Role/Value and SC 2.1.1 Keyboard;
VoiceOver double-tap and TalkBack double-tap both send `SemanticsAction.tap`).

Probe this stage, real app, `onboarding_kids`, semantics handle on
(temporary file, since deleted):

```text
PROBE option both  label="Both, Weekly base + bonus for extra quests" button=true selected=true tap=false actions=0
PROBE day sat      label="Payout day: Sat"                         button=true selected=true tap=false actions=0
PROBE back         label="Back"                                   button=true                 tap=true  actions=4194305
PROBE control  (Semantics(button, excludeSemantics:true) > GestureDetector(onTap))  tap=false
```

`Back` (shared `NestNavBar`) and the stepper buttons (plain `InkWell`, no
`excludeSemantics`) both expose the action, so the defect is exactly the
`excludeSemantics: true` wrapper — and it hits the screen's **two primary
controls**: the money-style choice and the payout day.

The suite asserts `flagsCollection.isButton` for all 16 controls
(`pocket_money_setup_view_test.dart:1072-1180`) but never the *action*, which
is why this survived six iterations.

**Fix** (keeps the single-node announcement the existing tests rely on):

```dart
return Semantics(
  key: cardKey,
  button: true,
  selected: selected,
  label: '$title, $sub',
  onTap: onTap,            // ← restores the dropped action
  excludeSemantics: true,
  child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, …),
);
```

and the same one line in `_DayCell`. **Test to add:** for all three option
cards and all seven day cells,
`tester.getSemantics(f).getSemanticsData().hasAction(SemanticsAction.tap)`
is `true`; plus one test that performs `tester.getSemantics(card).performAction(SemanticsAction.tap)`
and asserts the DB changed (mode / payout day), so the action is proven
wired, not just declared.

### 3. MAJOR (shared code — cannot be fixed in this branch; needs a SHARED_REQUEST) — the same `excludeSemantics` pattern strips the tap action from the shared `NestButton` and `NestChip`
`app/lib/core/design_system/components/nest_button.dart:152-180`, `app/lib/core/design_system/components/nest_chip.dart:119-137`

The probe also returns, for this screen's CTA:

```text
PROBE continue label="Continue" button=true tap=false actions=0
```

`NestButton` wraps its `InkWell` inside `Semantics(label: …, excludeSemantics:
…)`, and `NestChip` does the same — so **every** button and chip in the app
(including P06's `Continue`) announces as a button that cannot be activated.
RULES §1 forbids editing `app/lib/core/**`, so this stage cannot fix it; it
belongs in `docs/screens/P06/SHARED_REQUEST.md` as its own item: *"interactive
design-system components must expose `SemanticsAction.tap` — add
`onTap:` to the `Semantics` wrapper (or keep the inner label excluded with
`ExcludeSemantics` instead of dropping the whole subtree)"*, with P06 as the
repro. Findings 2 and 3 are the same class; only finding 2 is in scope.

### 4. MINOR — the feature re-implements child ordering with a factually wrong rationale, bypassing the canonical query
`app/lib/features/pocket_money/data/pocket_money_repository_impl.dart:92-103`

```dart
/// Children in the order they were added (Maya, then Leo). Never
/// `AppDatabase.watchChildren` — it orders by nickname (Leo first).
Stream<List<ChildrenData>> _watchChildrenInsertionOrder() {
  return _db.customSelect('SELECT * FROM children WHERE family_id = ? ORDER BY rowid', …)
```

Both halves of that comment are now stale. `AppDatabase.watchChildren`
(`app/lib/core/data/app_database.dart:433-442`, main/shared) **already**
implements the CHILD ORDER ruling — `ORDER BY createdAt, rowid` — and the
schema comment says so (`app_database.dart:93-94`). It does not order by
nickname. Behaviour today is still correct (Maya 08:00 then Leo 08:01 in
`Seed._childrenDemo`, `createdAt: now()` per insert in
`family_repository_impl.dart:78`, so `createdAt` order == `rowid` order) and
is pinned by tests, so this is duplication/drift risk rather than a visible
bug — but a raw `ORDER BY rowid` silently ignores `createdAt`, so the moment a
child row is backdated or imported the roster order could differ between P06
and P15.

**Fix:** delete `_watchChildrenInsertionOrder` and use
`_db.watchChildren(Seed.familyId)` in `watchSetup()` (keeping the comment about
insertion order, minus the wrong "orders by nickname" claim).

### 5. MINOR — `_FailureBody` re-subscribes to the bloc, defeating the `buildWhen` filter
`pocket_money_setup_view.dart:179`

```dart
final state = context.watch<PocketMoneyBloc>().state;
```

`_FailureBody` is built *inside* the `BlocBuilder` that already filters with
`buildWhen: setup/status/errorMessage` (`:50-53`), so the nested
`context.watch` re-subscribes and rebuilds the failure screen on **every**
state emission, including ledger-only ones — the exact rebuild storm finding
#14 of the iteration-4 review was filed to remove.

**Fix:** give `_FailureBody({required this.errorMessage})` and pass
`state.errorMessage` from the builder (`:67-70`), dropping the `watch`.

### 6. MINOR — option cards announce as generic buttons, not radios
`pocket_money_setup_view.dart:313-318`

The HTML source uses `role="radiogroup"` / `role="radio"` + `aria-checked`
(`P06-pocket-money.html:41-56`); the Flutter node is `button + selected`, so
a screen reader says "selected button" and never communicates mutual
exclusivity or position. `Semantics(inMutuallyExclusiveGroup: true,
checked: selected, button: true)` is the faithful mapping ("radio, 3 of 3,
selected"). Purely additive on top of finding 2's `onTap`. The radiogroup
container label (`Semantics(container: true, label: 'Pocket money style')`,
`:272-274`) is already correct.

### 7. MINOR — screen-authored empty-state copy still unratified
`pocket_money_setup_view.dart:462-465` — `'Add children to set weekly amounts.'`
has no source in `DESIGN_SPEC.md §5` or the HTML. Mandated by `1_plan.md §4`
(so the behaviour is right), but the wording still needs an orchestrator
yes/no. Carried forward from iteration 5's review #5; unchanged for two
iterations, so it should be ratified or replaced now.

### 8. MINOR — a spacing token is used as a size
`pocket_money_setup_view.dart:401-402` — `width: NestSpacing.gap10,
height: NestSpacing.gap10` for the selected radio's 10 px dot (the CSS
`inset 0 0 0 4px leaf-tint` read). The derivation is documented in the
doc-comment above (`:377-378`), but `gap10` reads as "10 px gap" to the next
maintainer. A private `static const _radioDot = 10` (with the CSS derivation
in its comment) is clearer.

## Verified OK (no action at this review)

* **RULES §1 scope** — the whole diff is inside `app/lib/features/pocket_money/**`,
  `app/test/features/pocket_money/**` and `docs/screens/P06/**`. No
  `app/lib/core/**`, no `app/lib/app/**`, no `tools/screens/**`, no
  `analysis_options.yaml`, no `flutter clean`, no interactive `flutter run`,
  no simulator by this stage.
* **ARCHITECTURE** — feature-first split respected; `domain/` holds only the
  Equatable entities + the abstract repository (streams/Futures + entities,
  no Drift types leak: `watchSetup`/`setMode`/`setPayoutDay`/
  `setWeeklyBasePence` are the only new surface, `:39-54`); one
  `PocketMoneyBloc` per feature per the architecture's "one bloc per feature"
  rule; DI/routes untouched (route + redirect already existed on main).
* **Tokens only, components reused** — no colour literal anywhere in the diff
  (every colour comes from `context.nest`); the two documented, TODO-marked
  component forks (`P06WeeklyStepper`, `_DayPill`) are filed as
  `SHARED_REQUEST.md` items 1/4/5 and match their shared twins token-for-token
  (verified against `components.css`: `.stepper button` 44/1px line/surface,
  `.chip.day` 32 high, `0` padding, 13 px, pill radius, 1.5 px transparent
  border, selected `leafTint` + `leaf` + `leafInk`). Remaining raw literals
  (13, 22, 60, 200, 1.5, ~300) are the design's own CSS numbers and are
  carried by `SHARED_REQUEST.md` item 2 rather than invented.
* **Copy / UK spelling** — every string is character-identical to the HTML
  source (verified programmatically against
  `design/html-source/screens/P06-pocket-money.html`): title, all six option
  strings, `Payout day`, `Mon…Sun`, `Weekly base`, `Coin value`, `Continue`,
  and the caption (split across two adjacent literals, concatenating to
  `Nestling never holds or moves money. You pay your way; we keep score.`).
  `10 coins = 10p` is built from the DB
  (`'10 coins = ${10 * coinValuePencePerCoin}p'`), which is DATA OVER MOCKS,
  not a deviation. `Back` comes from `NestNavBar`.
* **Design fidelity (independently re-measured, table in Method)** — H1,
  option cards, settings card, day strip x-runs, dividers, labels, CTA border
  and the bottom edge all match the design PNG to ≤0.7 px in both themes.
* **Owner rules** — BOTTOM EDGE: the CTA `surface` reaches the physical edge
  in light and dark, no strip, no tint around the indicator. ALIGNMENT: single
  20 px gutter on every element (geometry test + my x-run scan). BALANCED
  HEADINGS: `.h1` renders through `NestBalancedText`, two lines, the design's
  break after `money` (pinned by the real-font geometry test). CHIP ROWS: the
  day strip is a `NestChipWrap`, so the ±5 px slop taps work. LETTER SPACING:
  no local tracking added anywhere (`NestType` defaults 0). STATUS BAR:
  `NestStatusBar` only reserves height. PIP: none on this screen. TRIAL:
  `subscription_status` is never touched.
* **Data over mocks + child order** — mode/day/base/coin value all come from
  `watchSetup`; `£3.00`/`£1.50` are the seeded values; children are listed in
  insertion order (Maya, then Leo) and the order is pinned by a test.
* **Accessibility** — 16 labelled controls, every one ≥44 dp tall (day pills
  32 + `NestChipWrap` hit slop = 44, which is the orchestrator's own override
  of the ≥44-wide rule), `Semantics(header: true)` on the H1, decorative coin
  icon excluded, stepper labels verbatim from the HTML, contrast from tokens.
  Findings 2, 3 and 6 are what is left.
* **Performance / lifecycle** — `buildWhen` keeps ledger-only emissions off the
  form (except in the failure state — finding 5); `emit.forEach` on the single
  combined stream (no second `forEach`, no re-added load events); the
  terminal `_closeOnError` transformer prevents a leaked watcher per Retry;
  `emit.isDone` guards on every post-`await` emit; no `Timer` /
  `AnimationController` in the feature; `const` where it fits; `CustomPaint`
  only inside shared chrome.
* **Error handling** — load failure → message + `Retry`; a failed write keeps
  the form and shows an inline `danger` message that clears on the next
  confirmed emission; invalid mode/day are rejected with an assert (debug) and
  an `ArgumentError` past it (release).
* **Children's Code / privacy** — no analytics, no ads, no network, no
  `print`/`debugPrint` in the feature or its tests, no identifiers leaving the
  device, parent-mode route only (kid mode redirects to the gate, pinned by a
  test), no `google_fonts`/`GoogleFonts` anywhere.
* **Tests** — 170 passing, 0 skips, every widget test that pumps the app ends
  with `disposeApp(tester)`; the real-font geometry test pins the orchestrator's
  y anchors in light **and** dark; the 07:58 minus-glyph note is pinned
  positively (`== U+2212`, not merely `!= U+002D`).

## Worktree note (not a finding — process owned by the loop)

While this review was running, other stages of the same iteration were
editing this worktree: `p06_bugs_test.dart`, `pocket_money_setup_view_test.dart`,
`5_ui.md`, `6_bugs.md` and `ORCHESTRATOR_NOTES.md` changed under me, and a new
mandatory orchestrator item appeared ("UPDATE (09:30) … Coin value row … Do not
touch anything else"), which is finding 1 above. No `app/lib/**` file changed
during the review, so the production code reviewed here is exactly what
`git diff main...HEAD` contains; `flutter analyze` and `flutter test` were both
re-run by this stage on that tree. Per the brief, uncommitted work, branch
position and merge order are not findings.

VERDICT: FAIL
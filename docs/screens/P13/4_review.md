# 4 — QA code review (iteration 1) — P13 Payout (parent)

Scope reviewed: `git diff main...HEAD` — 9 code/test files, all inside the
RULES §1 allow-list for `pocket_money` (`presentation/bloc`, `presentation/
views`, `presentation/widgets`, `test/features/pocket_money`, `docs/screens/
P13`). No `core/`, no `app/`, no other feature, no `tools/screens`,
`analysis_options.yaml` untouched. Domain and data layers are unchanged —
`recordPayout` already existed, which is the right call.

Evidence gathered by this stage (no simulator used, no code edited):

- `flutter analyze` → **1 issue** (see finding 4; not in the committed diff).
- `dart format --output=none --set-exit-if-changed` on all 9 changed
  files → 0 changed.
- Design truth read from `design/html-source/screens/P13-payout.html`,
  `design/html-source/components.css`, `design/html-source/tokens.css`,
  `docs/DESIGN_SPEC.md:176`, and pixel-sampled
  `design/screens/{light,dark}/P13-payout.png` with a local reader.
- Design system read for every component used (`NestButton`, `NestToggle`,
  `NestAvatar`, `NestIcon`, `NestCard`, `NestEmptyState`, `NestType`,
  `NestSpacing`, `NestRadii`, `NestDevice`, `NestToast`, `NestBottomSheet`,
  `NestModal`).

## Verdict summary

| # | Severity | Area | One-line |
|---|---|---|---|
| 1 | **major** | Design fidelity / hit target | The scrim does **not** cover the dimmed header — the design's `.scrim` is `inset: 0`, the app starts it below the summary card |
| 2 | **major** | Data integrity | No in-flight guard on "Mark as paid": a second tap writes a second payout row and leaves a negative balance |
| 3 | **major** | Data integrity | A ticked child who owes £0.00 still gets a `Paid · <date> £0.00` row written into the ledger |
| 4 | **major** | Gate hygiene | Leftover scratch probe test breaks the `flutter analyze` gate and would be committed by the loop |
| 5 | minor | Flutter correctness | `_prime` mutates `State` inside the `BlocBuilder` builder |
| 6 | minor | Accessibility | Dimmed chrome is not `ExcludeSemantics`-d, contradicting both the plan §e and the code's own doc comment |
| 7 | minor | Copy / data | Saverow copy hard-codes "her Lego fund" for an arbitrary goal-bearing child |
| 8 | minor | Design system | Grabber height duplicates `NestSpacing.gap5` and hangs off the wrong class |
| 9 | minor | Accessibility | Sheet title announced twice; scrim has no semantics node to dismiss with |
| 10 | minor | Consistency | `_FailureBody` omits the `NestStatusBar` reserve every other state includes |

No blocker. Three majors in product code plus one gate failure ⇒ **FAIL**.

---

## Findings

### 1. MAJOR — the scrim does not cover the dimmed ledger header (design `inset: 0`)

**Where:** `app/lib/features/pocket_money/presentation/views/payout_view.dart:216-265`
(`_DimmedLedger`), specifically `:255-263`; the class doc at `:204-206`
claims the opposite; contradicted test comment at
`app/test/features/pocket_money/payout_view_test.dart:365`.

**Evidence.** The design puts one overlay over everything:

```html
<!-- P13-payout.html:19-21 -->
<div class="bg-fake">…<div class="ptitle">Pocket money</div><div class="card">…</div></div>
<div style="flex:1"></div>
<div class="scrim" aria-hidden="true"></div>
```
`components.css:164` → `.scrim { position: absolute; inset: 0; background:
var(--scrim); z-index: 20 }`, and `.pay` is `z-index: 30`, so the scrim
covers the **whole screen including the status bar, the title and the
summary card** and only the sheet sits above it.

Pixel proof from `design/screens/light/P13-payout.png` (÷3):

| Sample (logical) | Design pixel | Meaning |
|---|---|---|
| (195, 13) — above the title | `(151,148,158)` | paper `#FBF7F0` under `rgba(30,27,58,.45)` |
| (195, 300) — middle gap | `(151,148,158)` | same |
| (60, 120) — inside the summary card | `(154,152,166)` | surface `#FFFFFF` under the same scrim |
| (195, 700) — inside the sheet | `(23,128,79)` | unscrimmed leaf CTA |

Dark PNG agrees: `(8,7,12)` for paper `#15131F` under `rgba(0,0,0,.62)` and
`(12,11,17)` for surface `#1F1C2E` under it.

The app instead paints the scrim in an `Expanded` that starts **below** the
card (`payout_view.dart:257-263`), so `y = 0…~151` renders unscrimmed —
paper `(251,247,240)` and card `(255,255,255)` — producing a hard bright
band above a dimmed one in both themes, over 151 px of a 390×844 screen.
The same mistake removes the dismiss hit area: in the design tapping the
title/card region closes the sheet (`inset: 0`), in the app only the strip
below the card does.

**Fix.** Overlay the scrim over the whole ledger, not inside the column —
e.g. build `_DimmedLedger` as

```dart
Stack(children: <Widget>[
  const Column(children: <Widget>[NestStatusBar(), /* title */, /* card */]),
  Positioned.fill(
    child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onDismiss,
      child: ColoredBox(color: tokens.scrim)),
  ),
]),
```

and pin it with a test asserting the scrim rect (`tester.getRect` of the
`ColoredBox` descendant) starts at `top == 0`, plus correct the comment at
`:255` and the test comment at `payout_view_test.dart:365`. This is a
visual-only change: the design y-coords the geometry test pins (title 55,
card 101…151, sheet 343) are unaffected because the scrim is painted, not
laid out.

### 2. MAJOR — "Mark as paid" can be submitted twice; the second write corrupts the balance

**Where:** `payout_view.dart:165-180` (`_submit`, no guard; `:179`
`setState(() => _submitted.addAll(_ticked))`), `payout_sheet.dart:157-158`
(`canSubmit`, unaware of `_submitted`), `payout_sheet.dart:228-231`
(`onPressed: canSubmit ? onSubmit : null`, no `loading:`).

**Evidence.** `NestButton` has no debounce (`nest_button.dart:170-181` is a
plain `GestureDetector.onTap`) and `PayoutSheet` is not told a submit is in
flight, so between the first tap and the first `watchLedgerData` re-emission
(i.e. until the DB write round-trips) the CTA stays enabled and
`_owedOf(data, childId)` still returns the **pre-payout** owed. A second tap
in that window dispatches a second `PocketMoneyPayoutSubmitted` per ticked
child, and `recordPayout` inserts unconditionally
(`data/pocket_money_repository_impl.dart:339-352`) — no idempotency key, no
amount check. Maya's ledger becomes `−£4.20` (a negative balance on P12),
and the confirmation still fires: `_payoutLanded`
(`payout_view.dart:184-194`) only rejects `now > 0`, so `-420` passes, the
toast says "Payout recorded — enjoy the celebration" and the sheet pops.
Silent ledger corruption behind a success message. `_submitted` is only ever
*read* (`listenWhen`), never used to lock the button.

**Fix.** Make the in-flight set authoritative:

```dart
void _submit(MoneyLedgerData data) {
  if (_submitted.isNotEmpty) return;                 // re-entry guard
  …
  setState(() => _submitted.addAll(_ticked));
}
```

and pass `busy: _submitted.isNotEmpty` into `PayoutSheet`, folding it into
`canSubmit` and into the button's `loading:` (`NestButton` already disables
and shows a spinner when `loading` is true). Test: tap the CTA twice inside
the write window, then assert exactly one new `payout` row per ticked child.

### 3. MAJOR — a ticked child with nothing owed still writes a "Paid £0.00" row

**Where:** `payout_view.dart:168-177` (one event per id in `_ticked`,
irrespective of the owed total) → `data/pocket_money_repository_impl.dart:
340-352` (`amountPence: -amountPence.abs()`, no `> 0` guard) → rendered by
`presentation/widgets/money_history_row.dart:174-183` and `:212-223`.

**Evidence.** `canSubmit` only requires that *some* ticked child owes money
(`payout_sheet.dart:157-158`), so a zero-owed child can ride along. Reachable
path: pay Maya only, re-open `/payout` (Maya now £0.00, Leo still £2.10 so
`_prime` ticks Leo), tick Maya as well, tap the CTA → `_submit` sends
`PocketMoneyPayoutSubmitted('maya', 0, 0, null)` and the repository writes a
`payout` row with `amountPence: 0` and note `Paid · Sat 3 Oct`. On P12 that
is a leaf-tinted history tile reading **"Paid · Sat 3 Oct   £0.00"** — a
payment record for money that never moved. (The builder's own `zz_probe_test`
PROBE A only covers the all-paid case, where `canSubmit` happens to be false;
this mixed case is not covered by any test.)

**Fix.** Skip non-paying children before dispatching:

```dart
for (final childId in _ticked) {
  final owed = _owedOf(data, childId);
  if (owed <= 0) continue;                       // nothing was handed over
  …
}
```

Optionally harden `recordPayout` with the same `amountPence > 0` guard
(feature-owned file, so it is in bounds), and add a regression test: pay
Maya, re-open, tick Leo (£0.00) alongside Maya, submit, assert no `payout`
row exists for Leo.

### 4. MAJOR — leftover scratch probe test fails the analyze gate and would be committed

**Where:** `app/test/features/pocket_money/zz_probe_test.dart` (untracked,
not in the diff). Its own header: *"TEMPORARY probe file — deleted before the
stage ends."*

**Evidence.** `flutter analyze` in this worktree:

```
info • Empty class bodies should be written using a ';' rather than '{}' …
      test/features/pocket_money/zz_probe_test.dart:30:59 • empty_container_bodies
1 issue found.
```

RULES §7.1 requires `flutter analyze` → *No issues found*. The file is 9
`debugPrint` probes with no assertions; because the loop commits the worktree
each iteration, an untracked file inside `app/test/` is exactly what would be
swept into a commit. Running it also did not complete here: PROBE A finished
and PROBE B never started after ~10 minutes (other screen loops were building
concurrently, so this is reported as an observation, not a diagnosis — but a
file that can stall the suite must not survive the stage).

**Fix.** `rm app/test/features/pocket_money/zz_probe_test.dart` before the
loop commits, then re-run `flutter analyze`. Its findings must be promoted
into real assertions — which is findings 2 and 3: add the double-submit test
and the zero-owed-child test to `payout_view_test.dart`, and keep the
regression tests from the temporary file (`payout_widget_geometry_test.dart`
already covers the rest of what the probes measured).

### 5. MINOR — `_prime` mutates `State` during the build phase

**Where:** `payout_view.dart:97` (`_prime(data)` called from inside the
`BlocBuilder` builder), writing `_primed` and `_ticked` at `:129-140`.

**Evidence.** A builder must be pure; here it mutates two fields of the
`State` and relies on the *same* build reading the freshly mutated set in
`PayoutSheet` (`:107`). It happens to work only because
`buildWhen` (`:79-82`) lets every emission through. Any later narrowing of
`buildWhen`, a `didChangeDependencies` rebuild, or a second consumer of the
sheet would read a half-updated `_ticked`, and the mutation is invisible to
the framework.

**Fix.** Move the priming out of `build`: seed it from a `BlocListener` on
the first `loaded` emission (the same place the error/success listeners
already run) with a `setState`, or guard it in
`PocketViewState.didChangeDependencies`-equivalent. Keep `build` free of
writes.

### 6. MINOR — the dimmed chrome is not `ExcludeSemantics`-d (plan §e, and the code's own comment)

**Where:** `payout_view.dart:204-206` (doc comment) vs `:216-265` (no
`ExcludeSemantics` anywhere).

**Evidence.** The class doc states *"`ExcludeSemantics` — it is not
actionable and a modal sheet must not leave a focus trap behind itself"*, and
plan §e requires *"summary card behind scrim `ExcludeSemantics`"*, but the
`Semantics(header: true)` title at `:228-236` and the summary text at
`:246-252` stay in the semantics tree. VoiceOver/TalkBack can therefore still
land on the ledger title and the "Maya is owed £4.20 · Leo is owed £2.10"
card behind a modal sheet — precisely the trap the comment claims to close.

**Fix.** Wrap the covered chrome in `ExcludeSemantics(child: …)`, keeping the
dismiss `GestureDetector` outside it (after finding 1 the scrim is a sibling,
so the chrome Column can be excluded wholesale).

### 7. MINOR — the saverow copy hard-codes a gendered, goal-specific noun

**Where:** `payout_sheet.dart:399-408` with `saveChild` resolved at `:84-89`
and `:137-141`.

**Evidence.** The row belongs to "the first child in creation order that has
a savings goal", but the copy is the design's literal
`Move £1.00 of {nick} to her Lego fund`. Any family whose goal-bearing child
is Leo — or whose goal is not the Lego one — gets **"Move £1.00 of Leo's to
her Lego fund"**. The design string is correct for the seeded
Maya/`goal-lego` case, and character-for-character copy is the rule, so this
cannot be silently reworded here.

**Fix.** Raise it as a `SHARED_REQUEST` (or an `ORCHESTRATOR_NOTES` item)
asking for the data-driven form, e.g. *"Move £1.00 of {nick}'s money to
{goal.title}"*, and use it whenever `goalFor(id)?.title != 'Lego Friends
set'`. Keep the design string verbatim on the seeded path. Until then the
risk is documented at the call site (the build note flags the decision but
not the data-driven failure mode).

### 8. MINOR — the grabber height duplicates `NestSpacing.gap5` on the wrong class

**Where:** `payout_sheet.dart:451` (`static const double grabberHeight = 5;`
declared on `PayoutCheck`) used at `:58` by `_PayoutGrabber`.

**Evidence.** `NestSpacing.gap5 == 5` exists (`tokens/spacing.dart:29`) and
`NestBottomSheet` uses it for the identical 40×5 grabber pill
(`nest_bottom_sheet.dart:49`). One pill, two sources of truth, and the
constant sits on a class it has nothing to do with.

**Fix.** Delete `PayoutCheck.grabberHeight` and use
`height: NestSpacing.gap5` in `_PayoutGrabber`. (Keep `size`/`radius`/
`borderWidth` as feature-local documented consts — 48/14/2 are not on any
token scale and `core/` is off-limits per RULES §1.)

### 9. MINOR — the sheet's dialog semantics double-announce the title, and the scrim cannot be dismissed from the semantics tree

**Where:** `payout_sheet.dart:160-163` (`Semantics(container: true, label:
title, explicitChildNodes: true)`) together with `:190-198`
(`Semantics(header: true, child: Text(title))`); `payout_view.dart:257-262`.

**Evidence.** The design is `role="dialog" aria-modal="true" aria-label=
"Saturday payout"` (`P13-payout.html:22`). The Flutter approximation sets the
title as a container label *and* as a header child, so "Saturday payout" is
announced twice on entry, and the dismiss surface is a bare
`GestureDetector` with no `Semantics` node — a screen-reader user has no
labelled control to close the sheet (only the platform back gesture, which
the design's semantics do not offer either).

**Fix.** Drop `label:` from the container and keep `container: true` +
`explicitChildNodes: true`, so the header text is the single announcement;
and give the scrim `Semantics(button: true, label: 'Close payout',
onTap: onDismiss)` (per the brief's `excludeSemantics`/`onTap` rule) or state
in the code that dismissal is deliberately back-gesture-only.

### 10. MINOR — `_FailureBody` skips the status-bar reserve the other states include

**Where:** `payout_view.dart:336-362` vs `:292` (`_EmptyBody`) and `:219`
(`_DimmedLedger`).

**Evidence.** Every other body on this route mounts `NestStatusBar()`
(47 px reserve). The failure body is a bare centred `Column`, so on a short
screen (the 320×568 case the view tests already exercise) the message and
the "Try again" button are centred on the full window rather than on the safe
area, and the two states disagree about the chrome. Cosmetic only in the
844-tall case.

**Fix.** Wrap the failure body in the same `NestStatusBar()` + `Padding`
chrome as `_EmptyBody` (or move the reserve up into `PayoutView` so all
three states inherit it).

---

## Checked and found correct (no action)

- **Architecture.** Feature-first; no new domain/data files (the existing
  `recordPayout` is reused); one BLoC per feature with a new event + handler
  that mirrors the P12 add/spend write-through pattern; the route already
  provides the bloc and `PocketMoneyLoadRequested`
  (`pocket_money_routes.dart:48-58`) and the kid-mode guard is in
  `router.dart:95`. No DI or route edits, none needed.
- **RULES §1.** Every path in the diff is inside the allow-list.
- **Copy, character-by-character** against `P13-payout.html`: ASCII `0x27` in
  `you've` / `Maya's`, `&` (not `&amp;`) in the CTA, U+00B7 (`kMoneyDot`) in
  the summary and in `Weekly + quests · £4.20`, U+2014 spaced em dash in the
  success toast, `£1.00` from `moneyPounds(100)`. No US spellings.
  `NestBalancedText` correctly **not** used: the design sets
  `text-wrap: balance` only on `.display/.h1/.kid-title/.kid-hero/.balance`,
  and `.pay h2` / `.bg-fake .ptitle` are none of those.
- **Tokens only.** No literal colour anywhere; `scrim`, `surface`, `line`,
  `leaf`, `paper`, `cardShadow` all from `context.nest`; sizes from
  `NestSpacing`/`NestRadii`/`NestDevice`; the only numeric literals are the
  documented `.pay h2` 24/30 w900 and `.nm` 16/22 call-site overrides plus
  the sheet-local 88 % / 48 / 14 / 2 / 5 (finding 8 covers the one that has
  a shared token). No Material letter-spacing reintroduced; no
  `google_fonts`.
- **DS reuse.** `NestStatusBar`, `NestCard`, `NestButton`, `NestToggle`,
  `NestAvatar`, `NestIcon`, `NestEmptyState`, `NestToast` reused.
  `NestBottomSheet`/`NestModal` legitimately not usable for `.pay` (left
  h3 + close button + 92 % vs a centred 24/30 w900 title + grabber, 88 %),
  and `PayoutCheck` has no DS equivalent (the shared check is the kid 56 px
  ring).
- **Owner rules.** Bottom edge: the sheet's `paper` reaches the last pixel
  row (`homeH + s4` bottom pad, `sheet.bottom == 844`, pinned by
  `payout_widget_geometry_test.dart:100-124`). Alignment: 20 px gutters on
  title, both rows, saverow and CTA, all pinned by rect assertions.
  Child order: creation order everywhere (rows, saverow, summary string,
  `_prime`, `saveChildId`), asserted by
  `payout_view_test.dart:478-491`. Zero dark-mode branches.
- **Accessibility actions.** Every control exposes `SemanticsAction.tap`;
  both `excludeSemantics: true` wrappers (`PayoutCheck` at
  `payout_sheet.dart:457-464`, and the button inside `NestButton`) pass
  `onTap:`; `performAction` is asserted to change the real state
  (`payout_view_test.dart:193-235`); the disabled CTA passes no tap and
  reports `enabled: false` (`:237-256`). Tap targets: check 48, toggle ≥ 44,
  CTA 52, scrim full width.
- **Data over mocks.** Amounts, weekday, avatar tint and the goal all come
  from `Seed.demo`; nothing design-specific is hard-coded except the
  design-fixed £1.00. Child order follows creation order, not alphabetical.
- **Error handling.** A rejected write keeps `loaded`, toasts the friendly
  message and stays on the sheet; the success toast/pop fires only from the
  stream proof (never optimistically). The stale-error-after-retry case
  self-heals because the load handler emits `clearErrorMessage: true` on the
  next stream emission (`pocket_money_bloc.dart:81`), so a retry that
  succeeds is not swallowed by finding 9's sibling condition.
- **Performance.** No `Timer`/`AnimationController` (so the
  `DISABLE_ANIMATIONS` contract holds trivially), no stream subscriptions to
  leak (only `BlocListener`/`BlocBuilder`), `buildWhen` narrowing the
  rebuild to `status`/`data`/`errorMessage`, `_goBack` and the toast are
  guarded by `mounted`. No rebuild storm found.
- **Children's Code.** Parent-mode screen; no analytics, ads, tracking or
  third-party SDK anywhere in the app's `pubspec.yaml`, nothing added by this
  diff, no child data leaves the device (all reads are local Drift), and no
  `£` copy appears in kid mode from this screen.
- **Test hygiene.** `money_ledger_states_test.dart`'s single-line change
  (`tester.pageBack()` → `tester.binding.handlePopRoute()`) is mechanics only
  — the real `/payout` has no app bar, so there is no back button to find —
  and the original assertions (`/money`, "Maya is owed") are intact. Not a
  weakening.
- **Format.** `dart format` clean on all 9 changed files.

## Recommended order of work

1. Delete `zz_probe_test.dart`, re-run `flutter analyze`
   (finding 4) — restores the §7.1 gate.
2. Fix the submit path: in-flight guard + busy CTA, and skip zero-owed
   children (findings 2, 3), each with the regression test the probe was
   written to justify.
3. Move the scrim over the whole ledger and pin it with a `top == 0`
   assertion (finding 1), then re-shoot light + dark.
4. Tidy-ups: findings 5-10.

VERDICT: FAIL
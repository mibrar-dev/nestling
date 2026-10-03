# P06 Pocket money setup — QA code review (Stage 4, iteration 7)

Reviewed `git diff main...HEAD` per `docs/ARCHITECTURE.md` (feature-first;
domain = entities + abstract repo only; BLoC per feature/screen; DI + routes
per feature), `docs/screens/RULES.md` (edited only allowed paths), the design
system in `app/lib/core/design_system/` (tokens only, components reused),
`docs/DESIGN_SPEC.md §5 P06` (every element, copy character-exact, UK
spelling), accessibility, performance (no rebuild storms, `const` widgets,
streams disposed), error handling and Children's Code hygiene.
**No code was edited by this stage** — see "Worktree note".

## Method / evidence

| Check | Result |
|---|---|
| `git diff main...HEAD --name-only` (excluding `docs/`) | 8 lib files, all `app/lib/features/pocket_money/**`; 6 test files, all `app/test/features/pocket_money/**` ✔ |
| `flutter analyze` (full app, this stage) | **No issues found!** (exit 0) |
| `flutter test test/features/pocket_money/` (this stage, on the committed tree — run at 09:53, before the stage-3/stage-6 test edits landed; `git status` confirms **no `app/lib/**` change since**) | **+176: All tests passed!** (exit 0, **0 skips**) |
| Widened `PocketMoneyRepository` blast radius | every fake of the abstract repo lives inside `test/features/pocket_money/**` (7 fakes, all in this feature's test dir), so the four new members break no other feature's tests or compiles |
| `dart format --set-exit-if-changed lib/features/pocket_money test/features/pocket_money` | 0 changed |
| Design anchors re-measured off `design/screens/light\|dark/P06-pocket-money.png` ÷3 and compared pixel-for-pixel against the iteration-7 device shot `ui/app_light_7.png` / `ui/app_dark_7.png` (PIL, no simulator) | table below |
| `P06WeeklyStepper` vs shared `NestStepper` (`diff` of the two `_StepBtn` bodies) | identical except the constructor name |
| Simulator | **not used** by this stage (stage 5 only, allowed UDID) |

### Pixel evidence, design → `app_light_7.png` (logical px, ÷3)

| Anchor | Design | App (iteration 7) |
|---|---|---|
| Option-card top borders / 3rd card bottom | 191 / 263 / 335 → 397 | identical ✔ |
| Settings card top / dividers / CTA top border | 415 / 495 / 620 / 685 | identical ✔ |
| Day-pill run (x) | 36.00–76.00 … 314.00–**354.00** | 36.00–76.33 … 313.67–**354.00** (outer edges equal; interior cells ≤0.7 px from the 1/7 grid) ✔ |
| Day label `Mon` ink box | x 43.0–69.0, y 466.3–476.0 | x 43.3–68.7, y 466.7–475.7 ✔ (the stale "glyph ~10–11 px" deviation no longer exists) |
| Option-card title ink box | x 71.0–242.33, y 206.33–231.67 | identical ✔ |
| `10 coins = 10p` ink | x 253.7–**353.0** | x 254.0–**353.0** ✔ (was 224.3–320.7 in `app_light_6.png`) |
| Caption ink box | x 36.7–353.7, y 704.3–734.3 | x 37.0–353.7, y 704.3–734.3 ✔ |
| Selected radio (22 ring + 4 inset + 10 leaf dot) | leaf/tint/leaf pixel grid | identical ✔ |
| Dark page / card face / selected Sat pill | 21,19,31 / 31,28,46 / 142,230,188 | identical ✔ |
| Bottom edge | design paints the page tint under the CTA (y 810–844) | app keeps the CTA `surface` to y 2531 in **both** themes — the owner BOTTOM EDGE override, i.e. the app is the correct one ✔ |

## Iteration-6 findings — all closed (verified, not just claimed)

| # | Was | Now | Evidence |
|---|---|---|---|
| 1 MAJOR | trailing coin value 33 px short of the card content edge (a loose `Flexible`, flex:1) | tight `Expanded` + `TextAlign.end` (`pocket_money_setup_view.dart:813-821`) | design vs `app_light_7.png` ink above; committed test `pocket_money_setup_view_test.dart` "coin-value trailing alignment" (light+dark at 390, dark+390/430) |
| 2 MAJOR | 3 option cards + 7 day cells announced as buttons with **no** `SemanticsAction.tap` | `onTap:` re-declared on the `Semantics` node (`:335`, `:592`) | committed tests: `pocket_money_setup_view_test.dart` "every option card and day cell exposes a tap action" (all 10, plus the radiogroup flags) and "performing the tap action really writes the choice" (`performAction` flips `per_quest` and `Mon`, reading the state the write-through stream emits) |
| 3 MAJOR | shared `NestButton`/`NestChip` drop the tap action | **out of scope** per the 09:42 orchestrator ruling (`shared/semantics_tap`); core untouched ✔ | `git diff main...HEAD` shows no `app/lib/core/**` change |
| 4 MINOR | hand-rolled `ORDER BY rowid` child query with a false "orders by nickname" rationale | deleted; `watchSetup` subscribes to the canonical `AppDatabase.watchChildren(Seed.familyId)` (`ORDER BY createdAt, rowid`) | `pocket_money_repository_impl.dart:60-64`; insertion order still pinned |
| 5 MINOR | `_FailureBody` re-subscribed with a nested `context.watch`, defeating `buildWhen` | message passed in from the builder (`:70`, `:176-183`) | no nested `watch` left in the file |
| 6 MINOR | option cards announced as generic buttons | `checked` + `inMutuallyExclusiveGroup` map the HTML `role="radiogroup"`/`role="radio"` (`:328-329`) | assertions on `isInMutuallyExclusiveGroup` / `isChecked`; see finding 3 below for the residual redundancy |
| 7 MINOR | empty-state copy unratified | unchanged (see finding 9) | — |
| 8 MINOR | `NestSpacing.gap10` used as a size | `_RadioDot._dotDiameter = 10` (`:407`) | measured dot = 10 px in both PNGs ✔ |

All `ORCHESTRATOR_NOTES.md` items hold: seed `onboarding_kids` with Maya £3.00
then Leo £1.50 from the DB in insertion order (04:05 #1), the 7 pills inside the
card's 16 px padding ending on the same 354 edge (04:05 #2), no local tracking
(#3), the gold coin **illustration** tile matching the HTML's
`<img src="../assets/coin.svg">` (#4), the 07:22 y anchors with real fonts in
light and dark, the U+2212 minus (07:58 #2), the 09:30 right-aligned coin value,
and the 09:42 tap actions + tests.

## Findings

**No blocker and no major finding.** All ten below are minor.

1. **MINOR — a raw `error.toString()` is rendered to the parent.**
   `presentation/bloc/pocket_money_bloc.dart:71, 88, 113, 146` →
   `presentation/views/pocket_money_setup_view.dart:194` (failure body) and
   `:231-236` (inline `danger` caption).
   A Drift/SQLite exception string reaches the widget tree, so a parent can see
   e.g. `SqliteException(1): no such table: children (code 1)`.
   **Fix:** keep the technical text out of the state that the view renders —
   emit a fixed string (`'We couldn't save that. Please try again.'`) and, if
   the detail is wanted, log/record it on the state behind a field the view does
   not print. The tests assert on `state.errorMessage`'s content, so they need
   the same one-line update.

2. **MINOR — the inline write-error message is not announced.**
   `pocket_money_setup_view.dart:230-238` — the `Text` appears after a tap with
   no live region, so VoiceOver/TalkBack stay silent until the user swipes onto
   it. **Fix:** wrap it in
   `Semantics(container: true, liveRegion: true, child: Text(...))`.

3. **MINOR — the option cards announce two states for one control.**
   `pocket_money_setup_view.dart:322-328` sets `button`, `selected` **and**
   `checked`, so a screen reader reads "selected, checked" for a radio.
   `checked` (+ `inMutuallyExclusiveGroup`) is the faithful mapping of the
   HTML's `aria-checked`; `selected` is right for the day chips, not for radios.
   **Fix:** drop `selected: selected` from `_PocketOptionCard` only (keep it in
   `_DayCell`) and update the two `isSelected` assertions on the option cards
   (`pocket_money_setup_view_test.dart:1271-1292`, `:2754`) to `isChecked`.

4. **MINOR — inconsistent `emit.isDone` guard in the stepper handler.**
   `pocket_money_bloc.dart:143-149` emits the failure state after
   `await _repository.setWeeklyBasePence(...)` with no guard, while the success
   path guards at `:151` and both other handlers guard at `:84`/`:109`.
   Harmless on bloc 9.2.1 (`_Emitter.call` asserts only `_isCompleted`, and a
   cancelled emitter no-ops), but it is the one path that would throw on an
   older bloc and it reads like an oversight.
   **Fix:** `if (emit.isDone) return;` before that `emit` (keep the
   `_requestedBase.remove` above it, which must run either way).

5. **MINOR — the weekly-base ceiling is written out three times.**
   `pocket_money_repository_impl.dart:169` (`clamp(0, 2000)`),
   `pocket_money_bloc.dart:134` (`clamp(0, 2000)`) and the step size at
   `pocket_money_setup_view.dart:24` (`stepPence = 50`). Nothing ties the view's
   step to the bloc's clamp. **Fix:** one `PocketMoneySetup.maxWeeklyBasePence`
   constant next to the entity, referenced by all three.

6. **MINOR — dead, sibling-inconsistent widget.**
   `pocket_money_setup_view.dart:111` calls `NestHomeIndicator()`, which returns
   `SizedBox.shrink()` unless the gallery-only `NestStatusBar.showMockGlyphs`
   (`core/.../nest_chrome.dart:225`) — so it can never paint on this screen,
   and P05 (`family/.../add_children_view.dart`) does not call it. **Fix:**
   delete the line.

7. **MINOR — the day strip's width is derived from the viewport, and only the
   390 case is pinned.** `pocket_money_setup_view.dart:537-544` computes
   `cellWidth` from `MediaQuery.sizeOf(context).width` minus the gutter/padding
   arithmetic rather than from the card's real width (a `LayoutBuilder` cannot
   be inserted there — it would re-clamp `NestChipWrap`'s ±6 px hit slop, as
   the comment explains). The 3-width coin-value guard does not cover the pill
   strip. **Fix (test-only):** assert
   `tester.getRect(dayPill(7)).right == card.right − NestSpacing.s4` at 320 and
   430 next to the existing coin-edge assertions.

8. **MINOR — two widget tests do not end with `disposeApp(tester)`.**
   `pocket_money_setup_view_test.dart:2673` and `:2757` pump
   `SizedBox.shrink()` instead. Both pump a bare `MaterialApp` with a fake
   repository (no Drift subscription), so RULES §7's drain is not needed and the
   suite is green — but the file's own header contract and RULES §7 read
   "every widget test that pumps the app MUST end with `disposeApp`".
   **Fix:** call `await disposeApp(tester);` in both.

9. **MINOR — the screen-authored empty-state copy is still unratified.**
   `pocket_money_setup_view.dart:488` `'Add children to set weekly amounts.'`
   has no source in `DESIGN_SPEC.md §5` or the HTML (it is mandated by
   `1_plan.md §4`). Open since iteration 5. **Needs:** an orchestrator yes/no,
   or a replacement string — not a code change by the screen loop.

10. **MINOR — design-geometry literals are still outside the token scale.**
    `13` / `60` / `22` / `200` / `300` / `1.5` in
    `pocket_money_setup_view.dart:345, 341, 413, 166, 667, 632` and `64` in
    `p06_weekly_stepper.dart:54`. Each is the design's own CSS number and each
    is recorded in `SHARED_REQUEST.md` item 2, which is still open after seven
    iterations. **Fix:** the shared track should land the tokens; nothing for
    this loop. Listed so it is not mistaken for a fresh defect.

## Verified OK (no action at this review)

* **RULES §1 scope** — the entire diff is `app/lib/features/pocket_money/**`,
  `app/test/features/pocket_money/**`, `docs/screens/P06/**`. No
  `app/lib/core/**`, no `app/lib/app/**`, no `analysis_options.yaml`, no
  `tools/screens/**`, no `flutter clean`, no interactive `flutter run`, no
  simulator by this stage.
* **ARCHITECTURE** — feature-first split respected; `domain/` holds only the two
  Equatable entities and the abstract repository (the four new members are
  streams/futures + entities, no Drift types leak); `data/` holds the impl only;
  one `PocketMoneyBloc` per feature (the same bloc serves P12/P13 — `setup` is
  additive and `items` is untouched); DI and routes untouched; the two
  cross-feature imports are route *constants*
  (`family_routes.dart`, `paywall_routes.dart`), the same pattern P05 uses for
  `PocketMoneyRoutePaths`; every `PocketMoneyRepository` fake lives inside this
  feature's test directory, so widening the interface breaks nothing else.
* **Tokens only, components reused** — no colour literal except
  `Colors.transparent` (the CSS's `border: 1.5px solid transparent` on the
  unselected pill and the ink `Material`); every colour comes from
  `context.nest`; sizes come from `NestSpacing`/`NestDevice`/`NestRadii` except
  the ten literals in finding 10. Shared components used, not re-implemented:
  `NestStatusBar`, `NestNavBar`, `NestCard`, `NestChipWrap`, `NestButton`,
  `NestBottomCta`, `NestAvatar`, `NestBalancedText`, `NestlingIllustrations.coin`.
  The two documented, TODO-marked forks (`P06WeeklyStepper`, `_DayPill`) match
  their shared twins token-for-token — `diff` of `P06WeeklyStepper._StepBtn`
  against `NestStepper._StepBtn` differs only in the constructor name, and both
  match `components.css:141-143` (44 circle, 1 px `line` on `surface`, 20 w700
  glyph, 64-wide centred value).
* **Copy / UK spelling** — every string is character-identical to
  `design/html-source/screens/P06-pocket-money.html` (title, all six option
  strings, `Payout day`, `Mon…Sun`, `Weekly base`, `Maya`/`£3.00`,
  `Leo`/`£1.50`, `Coin value`, `Continue`, and the caption split across two
  adjacent literals). `10 coins = 10p` is derived from the DB
  (`10 * coinValuePencePerCoin`) — DATA OVER MOCKS, not a deviation. No
  spelled-out prose, so no UK/US spelling risk.
* **Design spec §5 P06** — all seven specified elements present and in order:
  H1, three radio option cards (`Both` selected, from
  `families.pocket_money_mode`, default `'both'`), the settings card with
  `Mon…Sun` (Sat selected, default `payoutDay = 6`), the per-child weekly-base
  steppers, the `Coin value` row, the caption and the `Continue` CTA. Back →
  `/add-children`, Continue → `/paywall`.
* **Owner rules** — BOTTOM EDGE: CTA `surface` reaches y 2531 in light and dark,
  no strip, no tint around the indicator (measured). ALIGNMENT: one 20 px gutter
  everywhere; the day strip, the `+` column and the coin value all end on the
  same 354 px edge. BALANCED HEADINGS: the H1 renders through
  `NestBalancedText`, two lines, breaking after "money". CHIP ROWS: the strip is
  a `NestChipWrap`, so ±5 px taps work (pinned by the bugs suite). LETTER
  SPACING: no local tracking anywhere. STATUS BAR: `NestStatusBar` only reserves
  height. PIP: none on this screen. TRIAL: `subscription_status` is never
  touched (grepped). FONTS: no `google_fonts`/`GoogleFonts` in the feature or its
  tests. CHILD ORDER: Maya then Leo, from the canonical `createdAt, rowid` query.
* **Accessibility** — every feature-owned control (3 cards, 7 cells, 4 stepper
  buttons) exposes `SemanticsAction.tap`: asserted in the committed suite for
  the 10 screen controls, and `performAction` is shown to move the real
  write-through state (mode → `per_quest`, day → `Mon`); the four stepper
  buttons inherit the tap action from their un-excluded `InkWell` inside
  `Semantics` (`p06_weekly_stepper.dart:94-108`), which is why the same pattern
  was required of the cards. `Semantics(header: true)` on the H1; radiogroup
  container label; each control's accessible name contains its visible text
  (WCAG 2.5.3); day cells are 32 + 2 × 6 hit slop = 44; option cards ≥ 60;
  CTA 52; back 44; the decorative coin SVG is excluded; stepper labels
  verbatim from the HTML aria-labels. Findings 2 and 3 are what is left.
* **Performance / lifecycle** — `buildWhen` keeps ledger-only emissions off the
  form (the nested `watch` that defeated it is gone); ONE `emit.forEach` over a
  `combineLatest2`, no second `forEach`, no re-added load events; the terminal
  `_closeOnError` transformer stops a leaked watcher per Retry; `MediaQuery.sizeOf`
  (not `of`) so the day strip does not rebuild on unrelated MediaQuery changes;
  bloc's duplicate-state suppression makes the optimistic stepper emit
  non-rebuilding; no `Timer`/`AnimationController`; `const` where it fits; no
  raw `SvgPicture` outside the tile.
* **Error handling** — load failure → message + `Retry` (which re-adds the load
  event once the terminal stream has closed, so the queued handler cannot
  deadlock); a failed write keeps the form and shows an inline message that
  clears on the next confirmed emission; `emit.isDone` guards on the post-`await`
  emits; invalid mode/day are asserted in debug **and** enforced with
  `ArgumentError` in release (the assert is stripped there). Finding 1 is the
  copy, not the mechanism.
* **Children's Code / privacy** — parent-mode route only (kid mode redirects to
  the parental gate, pinned by a test), no analytics, no ads, no network, no
  `dart:io`/`http`, no `print`/`debugPrint`, no identifier leaves the device,
  nothing read from the child rows except nickname/avatar colour/weekly base.
* **Tests** — 176 passing, 0 skips (the previous iteration's single skip,
  P06-BUG-13, is now un-skipped and green); real-font geometry pins the
  orchestrator's y anchors in light **and** dark; the 320/390/430 × 1.0/1.3
  matrix runs with the bundled faces; every widget test that pumps the Drift
  app ends with `disposeApp(tester)` (finding 8 covers the two fake-repo
  exceptions); no `skip:` anywhere in the feature.

## Worktree note (not a finding — process owned by the loop)

Stage 5 was running against this same worktree while the review was in
progress: it produced `ui/app_light_7.png`, `ui/app_dark_7.png`,
`cmp_light_7.png`, `cmp_dark_7.png`, extended
`test/features/pocket_money/p06_bugs_test.dart` with the iteration-7
accessibility + coin-alignment guards (all un-skipped), and is rewriting
`5_ui.md`. Stages 3 and 6 then started editing the same two test files
(`mtime` 10:31/10:32) and dropped a temporary
`test/features/pocket_money/zz_p06_probe_iter7_test.dart`.
`git status --short -- app/lib` is empty throughout, so the production code
reviewed here is exactly what `git diff main...HEAD` contains, and the
`+176 / All tests passed` run above is that tree. Per the brief, uncommitted
work, branch position and merge order are not findings.

One documentation note for stage 5, not a code defect: the `5_ui.md` text that
was on disk when this review started still lists "day-chip glyph size"
(deviation 2) and `NestIcons.poundCoin` (deviation 3) as deviations. Neither
exists in iteration 7 — the day labels measure 13 px
(x 43.3–68.7 × y 466.7–475.7, against the design's 43.0–69.0 × 466.3–476.0)
and the tile uses the `coin.svg` illustration the HTML shows.

### In-flight observation for stages 3/6 — the suite is red right now (NOT counted against this review)

**Do not let the loop commit either test as it stands** — with one of them
hanging, the whole feature file fails to load and every test after it is
skipped, which would fail the next iteration's test gate on a green product diff.
Because the two test stages are mid-edit, `flutter test
test/features/pocket_money/` on the *live* tree currently reports
`+180 -2` (and `+170 -1` a few minutes earlier), always with the same
signature: one semantics-action test "did not complete", the test file then
fails to load (`Bad state: Cannot close sink while adding stream`), and the
rest of that file never runs. It moves with whatever the stages are editing:
first `p06_bugs_test.dart` "performAction(tap) … writes the DB", then
`pocket_money_setup_view_test.dart` "performAction(tap) on 'More weekly
pocket money for Maya' writes the child row". Both pass when run in isolation
(`--name "performAction"` → `+1: All tests passed!`; `--name "iteration-7"` →
`+3`), so it is an ordering/lifetime interaction, not a product defect —
`SemanticsAction.tap` on the option cards and the steppers demonstrably reaches
the bloc and the database (both `hasAction` assertions and the state-change
assertions pass).

Two things worth handing to whoever finishes those tests:

1. The NOTE at `pocket_money_setup_view_test.dart:3024-3029` ("dispatch through
   `tester.semantics.performAction(finder, action)`; calling
   `node.owner!.performAction(node.id, action)` directly bypasses the test
   framework's action plumbing, and the dropped future never settles") is
   **not** the fix — `SemanticsController.performAction`
   (`flutter_test/lib/src/controller.dart:393-410`) ends in exactly the same
   `node.owner!.performAction(node.id, action, args)`. Both call sites are
   equivalent, which matches the symptom moving between them.
2. The likely mechanism is the line *after* the action:
   `await (await repository.watchSetup().first)` reads a Drift query stream
   **after** the last `tester.pump`, with no further pump to drive the
   widget-test FakeAsync clock, so that future never settles. Fix by pumping
   while you wait (a bounded `for (…) { await tester.pump(50ms); if (done)
   break; }`), or by reading the value through the widget tree
   (`find.text('£3.50')`) instead of a bare stream await.

VERDICT: PASS

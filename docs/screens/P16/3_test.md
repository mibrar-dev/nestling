# P16 Settings — Stage 3 TEST (iteration 6)

Job: re-prove the screen after the iteration-6 build, and pin every behaviour
that build changed — four of the seven review findings landed in product code
this iteration, and **not one of them was visible to the suite as it stood**.

**Outcome: PASS — all gates green, `flutter analyze` clean, and for the first
time in this loop's six iterations P16 has no bug of its own open and no
skip-marked test at all. Nothing new was found because nothing new was broken:
this iteration the screen was corrected, and the stage's whole job was proving
the corrections stick.**

Numbers: **+6 tests** (151 in `test/features/settings` = the 145 the integrator
committed + these 6), **0 failures**, **0 new bugs**, **0 skips**, and the last
open finding of mine (**P16-T04**) closed by the build and now held by a live
proof.

> Count note, so the drop from my earlier reading is not a mystery: the `+154`
> I recorded at the start of this iteration counted **transient probe files**
> other stages had open in the same directory at that moment. The committed
> baseline is the integrator's `+145`; `151 = 145 + 6`.

---

## 1. What iteration 6 changed, and what I did about each change

The 12:52 mandate was one rule ("P16-T04: replace both hand-rolled avatar
initials with the shared `nestAvatarInitial` … Nothing else: the layout is
done"), plus the review findings in `FIXES_5.md`. Product-code deltas:
`settings_view.dart` ±99, `settings_repository_impl.dart` ±24,
`settings_rows.dart` +14, `settings_di.dart` ±5.

| change | risk of regression | what now holds it |
|---|---|---|
| **P16-T04** — both avatar initials call `nestAvatarInitial` | the helper trims and owns the `'?'` fallback; a screen that stops calling it silently regresses | my **iteration-5 skip-marked proof, now live and green** (the build un-skipped it) |
| **review 2 (major)** — three `P16TransientGuard.run` wrappers deleted from `NestToggle.onChanged` | the fix is a *deletion*. Nothing in the suite asserted that a switch is unfenced, so re-wrapping one "for consistency" would have been invisible — and the deleted wrappers were what made the screen work | **2 new tests** (`p16_transient_guard_test.dart`) |
| **review 3** — the link row gets its own `Material` (its ripple was painting behind the card) | the ripple is paint; no widget test can see it, and the previous shape did not fail any assertion | **1 new test** (`settings_navigation_test.dart`) |
| **review 4** — `.lockhint` copy consolidated into `settingsHintStyle()` (was `NestType.chipLabel(…).copyWith(w400)`) | the style is now one helper, with a follow-up filed for a real `NestType.hint` token; a token swap changes 14/20 silently | **2 new tests** (`settings_responsive_test.dart`) |
| **review 5** — `watchMembers` delegates to the shared `AppDatabase.watchMembers()` | the CHILD ORDER owner rule now lives in a file outside the feature, and no test in the suite pinned the order | **1 new test** (`settings_states_test.dart`) |
| **review 1/6** — `nestAvatarInitial` (see above); `FamilyZoneService` injected through DI instead of built inline | additive optional parameter + DI wiring; the picker → DB write path is already covered end-to-end by the zone tests | existing tests |

Also verified as unchanged: the un-fork's metrics. The iteration-5 geometry
proofs still hold against the new layout — section label 16 px, subcard 16 px
radius / 16 × 14 padding, switch row **56 px** (the number I pinned last
iteration precisely because batch 6's `_TrailingSlop` is what prevents the
56 → 64 growth I had measured), track flush right at 303–354, one 20 px gutter
at 320 / 390 / 430 × light / dark × scale 1.0 / 1.3.

## 2. Tests added (6)

### a. The switch is live on the very next tap after the zone sheet closes
`p16_transient_guard_test.dart`, two tests, **+2**.

Review 2 was the iteration's one major defect, and it deserves the strongest
form of proof I can write, because the fix is invisible and the bug was a *dead
tap*: the user picks a zone, reaches for the switch below it, and nothing
happens — with no feedback to tell them why.

1. **The end-to-end sequence** — open the picker, pick `Karachi`, and with the
   window asserted still open (`P16TransientGuard.suppressing isTrue`, pinned
   immediately before the tap so the test cannot pass by the guard having
   expired) tap `Approvals waiting`. Both the rendered track and the
   `settings.notif_approvals` row must move. Both controls are put in view
   *before* the sheet opens, so nothing scrolls while the window is open.
2. **The invariant, with the guard armed deliberately** — in one armed window, a
   row tap must still be fenced (`/settings`, no navigation) *and* a switch flip
   must still reach the DB. This pins the boundary rather than one call site:
   it is the pair that says what the guard is for (rows that open a route or a
   dialog) and what it must never touch.

### b. The link row's ink surface, and its full-height hit area
`settings_navigation_test.dart`, **+1**.

Review 3's complaint was "paints no ripple", and ripple is paint — this stage
owns no simulator, so the test pins the cause and the felt consequence:

* the row's 52 px height (`.linkrow { min-height: 52px }`, a parent target) and
  a tap in its **empty lower band**, 6 px above its bottom edge and below the
  label's line box, navigates to `/paywall` — the whole row is the target, not
  just the words;
* `Material.of` for the row is **not** the same `MaterialData` the rest of the
  card resolves to. The plan title sits outside the row and still resolves to
  the Scaffold's `Material` — the one *behind* the card's opaque surface, which
  is exactly why the ripple was invisible. Drop the local `Material` and the
  two resolve alike again, so the test fails naming the mechanism.

### c. `.lockhint` is 14/20
`settings_responsive_test.dart`, **+2**.

`font-size:14px; line-height:20px` (`P16-settings.html:11`). Both call sites
used to reach for `NestType.chipLabel(…).copyWith(fontWeight: w400)` — the
right line box from the wrong token, which is the bug review 4 found. Asserted
as the **CSS values** on the lock hint and on the move banner, plus once as a
rendered check that the copy occupies whole 20 px line boxes at scale 1.0 and
1.3 (a declared style that never lands is the other half of a token swap). It
survives the filed §9 follow-up: a real `NestType.hint` that lands on 14/20
satisfies every assertion here.

### d. CHILD ORDER is the order children were added
`settings_states_test.dart`, **+1**.

Owner rule, and the code path moved this iteration. Measured as **geometry**
(`getTopLeft().dy`), so it states what a parent sees top to bottom and fails if
anything sorts the rows on the way to the screen: `Maya · 7–9` above `Leo · 4–6`,
and `Sarah — you` above `James — co-parent` — the second pair is the one a
query ordered by name would get backwards, since *James < Sarah*.

## 3. Results

```
$ dart format .
Formatted 564 files (0 changed) in 1.72 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 2.9s)

$ flutter test test/features/settings --timeout 120s
00:16 +151: All tests passed!

$ flutter test test/features/settings --run-skipped --timeout 120s
00:15 +151: All tests passed!

$ flutter test --timeout 120s
05:38 +3534 ~2: All tests passed!
```

`--run-skipped` selects **no** test — the feature is 151 passed, 0 skipped, the
third consecutive iteration with none. The full suite's `~2` are K01's and
P12's, not P16's. Every run used `--timeout 120s` (TEST TIMEOUTS) in the
foreground.

## 4. Bugs

**None found this iteration.**

**Closed: P16-T04 (minor, mine, iterations 5 → 6).** The build applied the two
one-line swaps I filed; my iteration-5 skip-marked proof now runs live and
passes, with the expectation still computed by hand (trim + first grapheme)
rather than through the helper, so it cannot simply agree with itself. Under
`--run-skipped` there is nothing left to run, which is the honest signal.

**Closed earlier and still green:** T01 (delete-confirm navigator), T02 (44 px
switch target), T03 (4 px horizontal slop), B01–B08, B10, B11 (switch
alignment), B09 (linked IANA ids).

## 5. Open items — filed, not bugs, nothing failing

1. **§6 — `SettingsRow` is still forked** for five rows (four avatar-leading +
   the danger row). This is the last of `ORCHESTRATOR_NOTES` (06:58) item 3's
   three un-forks, and it is the one that cannot land screen-side: the shared
   row has no `leading` widget slot and no danger `titleColor`. Filed in
   `SHARED_REQUEST.md` §6 with the measured cost ("Blocks: no"). The screen is
   correct; this is fork debt, and I am flagging it rather than burying it,
   because a green suite is not the same as no debt.
2. **§7** `_linkRowMinHeight = 52` is screen-local (the 4 pt grid has no 52) —
   now pinned by my 52 px assertion above, so if a token lands the test tells
   you the value did not move.
3. **§8 / §9** filed this iteration by the build (guard lifetime in the shared
   modal helpers; a real `NestType.hint`).
4. **The Family list still announces as one node.** Its two static rows have no
   semantics node of their own, so a screen reader announces
   `"Sarah — you / … / James — co-parent / … / Invite co-parent"` as a single
   button. Unchanged across six iterations; the cause is the shared
   `NestListRow`'s no-`onTap` branch, and the integrator recorded that a local
   label breaks the tappable-node contract for the whole section. This is the
   one loose end I would most like filed as a shared request — I have not filed
   it myself because it is not a P16 defect to fix and the request file belongs
   to the build stage.
5. **A fenced tap ripples but does nothing** (the 300 ms guard, on rows only).
   Deliberate, per `ORCHESTRATOR_NOTES`; a silent dead tap if the window is ever
   widened, which is why test (a) now pins where the window may and may not
   reach.
6. **The dialog Cancel still wraps at 320 × 1.3** — shared `NestButton` padding.
7. **`watchMembers()` takes no family id.** The shared query defaults to
   `fam1`, which is `Seed.familyId`, and the shared core test
   (`test/core/data/members_email_test.dart`) pins that default. Single-family
   by design, so not a bug — noted only because the repository now inherits a
   default it does not pass explicitly.

## 6. Harness notes (new this iteration)

- **`Material.of(context)` returns `MaterialData`, not the `Material` widget.**
  My first attempt compared it against `tester.widget<Material>(…)` and failed
  for that reason alone. The useful comparison is `Material.of` at two points —
  inside the row, and just outside it — which needs no widget-type assertion at
  all.
- **`Finder` has no `.single`** in this Flutter version; use
  `expect(finder, findsOneWidget)` then `getRect(finder)`, or `.first`.
- **`tapAt` takes no `warnIfMissed`** here (3.47.5): `tapAt(Offset, {pointer,
  buttons, kind, view})`.
- **A declared style can live on the span.** The lock hint is a `Text.rich`
  (the design bolds "On"), so `Text.style` is null and the style is on
  `textSpan.style`; the banner copy is a plain `Text`. Read both.
- **A long copy needs a line-box assertion, not a height.** The banner's copy
  takes three lines (60 px), so `closeTo(20, …)` was simply the wrong claim; the
  test asserts whole 20 px line boxes instead, which is true at one line or
  three.
- Unchanged from iterations 1–5: Drift streams need `settleSettings`
  (`runAsync`); `bloc.close()` must be `unawaited` in a widget test;
  `scrollUntilVisible` walks down only; a `ListView` un-builds rows scrolled
  past; `tester.ensureVisible` jumps the offset without a frame (useful inside a
  guard window); `pumpAndSettle` would expire a time-windowed guard; a
  semantics-tree walk misses un-passed nodes.

## 7. What I did not do

No product code was edited this stage. No test was skipped, no lint weakened,
no `analysis_options` touched, no simulator booted or driven (the UI stage's
simulator only, and not by me), no `google_fonts`, no image attached. All six
tests express a rule (the guard's boundary, the ink target, the CSS type
metrics, the owner ordering) rather than a widget class, so they survive the
filed §6 revert when it lands.

---

VERDICT: PASS

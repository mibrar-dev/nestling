# K02 Kid PIN — QA code review (Stage 4, iteration 3)

Scope: feature `kid_home`, route `/kid-pin`, kid mode, designs
`design/screens/{light,dark}/K02-pin.png` (1170×2532 @3x). Reviewed
`git diff main...HEAD` (4 lib files, 5 test files, `docs/screens/K02/**`) against
`docs/ARCHITECTURE.md`, `docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5 K02,
`docs/design/SPACING_SPEC.md`, the design system in
`app/lib/core/design_system/`, `1_plan.md`, `ORCHESTRATOR_NOTES.md` (07:13
keypad mandate + 10:32 hang mandate), `SHARED_REQUEST.md`, and the stage notes
1→6 of all three iterations.

**This stage edited no product code** — only this file. **No simulator was
booted, installed on, screenshot or driven** (SIMULATORS rule: only stage 5 may).

## What changed in iteration 3 (verified by `git diff 060d869..HEAD`)

* Product code: exactly one hunk, in
  `app/lib/features/kid_home/presentation/views/kid_pin_view.dart` (`:79-87`) —
  the K02-BUG-5 fix below.
* Tests: `k02_bugs_test.dart` gains the K02-BUG-5 regression proof
  (un-skipped) and its header is rewritten to describe the suite as all-fixed
  (iteration-2 finding 5 closed); the 10:32 test-hang fix is complete-cycle
  rationale comments + `setUpTestScope()` before every re-pump, plus
  per-name-cycle discipline in the nickname matrix.
* One merge of `main` (`a967441`), which is shared-owned: kid_trial_gate
  redirect, shared list-row semantics, shared_batch6 typography. The K02 screen
  code carries over untouched except the hunk above.

## Gates (run in `app/`)

| gate | command | result |
|---|---|---|
| format | `dart format --set-exit-if-changed --output=none lib/features/kid_home test/features/kid_home` | ✅ `Formatted 36 files (0 changed)` |
| analyze | `flutter analyze` | ✅ **No issues found!** (whole package, tests included) |
| test (K02 adversarial suite) | `flutter test --timeout 120s test/features/kid_home/k02_bugs_test.dart` | ✅ `+32 ~1 in 3 s` for the *committed* set — all K02-BUG-1..5 proofs un-skipped and green, **and the file finished in 3 s** (the 10:32 hang is gone). Two working-tree edits that are not yet committed (see process note below) fail, as expected for an in-flight probe |
| scope | `git diff main...HEAD --name-only` | ✅ only `app/lib/features/kid_home/presentation/{bloc,views}`, `app/test/features/kid_home/**`, `docs/screens/K02/**` |
| fonts | `grep google_fonts\|GoogleFonts` in `lib/features/kid_home` + its tests | ✅ none in code |
| suppressed | `grep 'skip: true\|ignore_for_file'` in the 5 K02 test files | ✅ none; the only feature skip is the pre-existing K01-BUG-7 park at `k01_bugs_test.dart:569`, untouched by this loop |
| analysis_options | `git diff main...HEAD -- analysis_options.yaml` | ✅ untouched, not weakened |

**Process note (not a finding).** While this stage ran, the iteration-3 loop
had in-flight uncommitted work in the same worktree: `k02_bugs_test.dart` +54
(a `K02-BUG-5 extension` probe plus a *scratch* "kid mode + expired trial"
probe with `debugPrint('SCRATCH…')`), `kid_pin_view_test.dart` +170
(`K02 iteration 3 fixes` group), `5_ui.md` iteration-3 notes and four new
`ui/*_3.png` screenshots. None of that is in `git diff main...HEAD` and none of
it is counted against this review. The scratch trial-status probe currently
**fails** (redirect does not fire because the working-tree test never sets
`AppModeController`/session mode before the trial-expiry flip, and it writes
`subscriptionStatus`-adjacent state directly — the committed router tests that
cover the same ruling do set both and pass); it is the in-flight stage's to
fix or delete, and `git diff main...HEAD` is not affected.

## Independently verified (re-read, not taken on trust)

* **RULES §1 scope** — every path in the diff is on the allow-list; no
  `core/`, `app/`, other feature, or `tools/screens/` edit.
* **ARCHITECTURE** — feature-first intact: `domain/` and `data/` untouched,
  one bloc per feature (`KidHomeBloc`, shared with K01/K03/K04/K05 — the
  three pin fields from iteration 2 are still the only addition, so siblings
  cannot break), DI (`kid_home_di.dart`) and routes untouched.
* **Iteration-3 product diff** — the latch-release hunk:

  ```dart
  if (mounted) {
    if (noPin != null && !noPin.pinSet) {
      context.go(KidHomeRoutePaths.home);
    } else {
      // Declined (K02-BUG-3): release the latch so a LATER no-PIN
      // state can advance again (K02-BUG-5).
      setState(() => _noPinHandled = false);
    }
  }
  ```

  This is correct and closes the stranded-spinner path from iteration-2
  finding 2 (`k02_bugs_test.dart:452-487` proves Leo→Maya→Leo advances, and
  the in-flight extension proves the same when the decline is a null child).
  Decline semantics are safe in all three cases: a PIN'd child keeps showing
  its PIN screen; a `null` child releases the latch so the *next* no-PIN
  emission re-schedules the hop; an unmounted view simply keeps the latch, but
  the state is then discarded with the route. The latch is only set inside
  the same listener that schedules the hop, so the single-flight guard still
  holds, and a released latch never causes a loop — the outer `listenWhen`
  only fires on a *new* bloc emission. The `setState` inside the post-frame
  callback is legal (mounted, outside build) and rebuilds are trivial.
* **Lifecycle** — still exactly two long-lived subscriptions in `KidHomeBloc`
  (K01's, untouched); `close()` cancels both. K02's addition adds no
  subscription. `AppSession` already owns the watch that the 10:32 hang fix
  completes with `setUpTestScope()` per pump-cycle.
* **Performance** — one `BlocBuilder` + three `listenWhen`-narrow listeners,
  `_entered` capped at 4, no `Timer`/`AnimationController` in the screen.
* **DATA OVER MOCKS / periodic rules** — no money, no dates, no `£` on this
  screen; `1234` is a DB fact pinned by `kid_home_repository_test.dart`.
* **COPY / LAYOUT** — unchanged from iteration 2's review (all elements,
  `Hi {nickname}! Enter your secret code`, `NESTLING`, `Forgot it? Just ask a
  grown-up.`, keypad grid on the shared pitch, bottom inset) — the diff
  confirms none of the geometry code moved.
* **Children's Code** — no analytics, ads, network, identifiers, `print` or
  `DateTime.now()` in the feature; unlimited retries, no lockout, no shaming
  copy.
* **ACCESSIBILITY ACTIONS** — unchanged: every control advertises
  `SemanticsAction.tap`; dots are label-only; the failure card's Pip avatar is
  the shared no-child fallback (bloc only enters `failure` when `child == null`).

## Findings

### 1. [minor] STILL OPEN from iteration 2 — `.mark` pill hard-codes `999`
instead of `NestRadii.allPill`

`app/lib/features/kid_home/presentation/views/kid_pin_view.dart:235`

`NestRadii.pill = 999` / `NestRadii.allPill` exist
(`app/lib/core/design_system/tokens/radii.dart:13`, `:23`) and every other
pill in `lib/` uses them; this is the only `circular(999)` left. (Line
shifted +6 from the K02-BUG-5 hunk.)

**Fix:** `borderRadius: NestRadii.allPill,` and update the mirroring test
predicates at `kid_pin_view_test.dart:938`, `:989`, `:1012`, `:1057` and the
assertion at `:998`.

### 2. [minor] CLOSED this iteration — `_noPinHandled` latch never released on a declined auto-advance (iteration-2 finding 2 / K02-BUG-5)

Fixed correctly in the iteration-3 product hunk
(`kid_pin_view.dart:79-87`); a regression proof for Leo→Maya→Leo is
committed and green, and the in-flight working-tree extension covers the
null-child decline. No residual issue.

### 3. [minor] STILL OPEN from iteration 2 — keys stay live while a check is in flight

`kid_pin_view.dart:38-39`, `:289-294`. `awaiting` still reaches only the dots;
`NestKeypad` keys keep their `InkWell` ripple and `Semantics(button: true,
onTap: …)` while the callbacks early-return. RULES §8: a disabled control
"passes no tap and reports `enabled: false`". One-line local mitigation:
wrap the keypad in `AbsorbPointer(absorbing: awaiting, child: …)`; the
semantics honesty needs a shared `NestKeypad(enabled: …)` (file in
`SHARED_REQUEST.md`, mirroring `NestIconButton`).

### 4. [minor] STILL OPEN from iteration 2 — `128` avatar-disc literal

`kid_pin_view.dart:213-214`. Hoist to `static const double _avatarDisc = 128;
// .k2-ava (K02-pin.html:22)` on `_KidPinBody`; if another screen wants the
same disc, request a `NestDevice`-style token in `SHARED_REQUEST.md`.

### 5. [minor] STILL OPEN from iteration 2 — `SHARED_REQUEST.md` status line stale

`docs/screens/K02/SHARED_REQUEST.md:9-11` still reads `#2 landed on main,
K02 follow-up pending` while the follow-up steps (fit.shrinkWrap call site,
Δ 0 re-measurement) are done, and item #3's call-site table points at
`kid_pin_view.dart:140` (now `:162-164`). Set to `#1 and #3 open, #2 done`
and refresh the line numbers.

### 6. [minor] STILL OPEN from iteration 1/2 — the two local type styles

`kid_pin_view.dart:242-248` (`.mark`) and `:262-269` (`.say`) hard-code
`fontFamily: 'Nunito'` + weight/size/height. Not K02-fixable (RULES §1):
`NestType.kidMark` / `kidSay` are SHARED_REQUEST #1, metric-identical local
stand-ins behind TODOs, pixels already Δ 0. Recorded for the orchestrator.

### 7. [minor] STILL OPEN from iteration 2 — K02-BUG-1's crash class is only closed for K02

`nickname.runes.first` fixed at `kid_pin_view.dart:162-164`; the other six
sites in `SHARED_REQUEST.md` #3 (`profile_tile.dart:96`,
`kid_home_view.dart:364`, `child_profile_body.dart:108`,
`kid_card_grid.dart:68`, `today_loaded_body.dart:363`, `:571`) still use
`[0]`. Shared, filed, orchestrator-owned.

## Carried-forward notes (deliberately not findings)

* The failure card's `PipAvatar(style: mochi, stage: 1, size: 140)` is a
  shared no-child fallback (bloc enters `failure` only when `child == null`);
  the PIP rule is satisfied as far as this screen can satisfy it.
* The PIN is advisory by design (`/kid-home` itself is unguarded); P17 is the
  real gate. Shared routing decision, not a K02 defect.
* Every kid route uses the same DI-singleton `KidHomeBloc`, so popping one kid
  route under another shares one bloc; pre-existing shared-router behaviour,
  K02's diff adds no new instance.
* Iteration-1/2 stage verdicts (3_test FAIL, FIXES_2, 6_bugs PASS) are
  superseded on the points fixed above.

## Verdict

No blocker and no major finding. The iteration-3 delta is a correct,
minimal, regression-tested bug fix (`kid_pin_view.dart:79-87`) for
K02-BUG-5; all iteration-2 gates still stand (format clean, `flutter analyze`
**No issues found!**, `flutter test` green — the committed K02 suite finishes
in 3 s, so the 10:32 hang mandate is met), no skips or ignores were added,
`analysis_options` and scope are clean, and the design system is reused
throughout. The six findings above are all minor: two one-line token
duplications (`999`, `128`), one disabled-control semantics honesty, and two
stale-status docs, plus two shared-owned carried items. None blocks landing.

VERDICT: PASS

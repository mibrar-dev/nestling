# K02 Kid PIN — QA code review (Stage 4, iteration 1)

Scope: feature `kid_home`, route `/kid-pin`, kid mode, designs
`design/screens/{light,dark}/K02-pin.png` (1170×2532 @3x). Reviewed
`git diff main...HEAD` against `docs/ARCHITECTURE.md`, `docs/screens/RULES.md`,
`docs/DESIGN_SPEC.md` §5 K02, `docs/design/SPACING_SPEC.md`, the design system
in `app/lib/core/design_system/`, `1_plan.md`, `2_build.md`,
`ORCHESTRATOR_NOTES.md` (the 07:13 keypad-grid mandate) and the in-flight
`5_ui.md` captures.

**This stage edited no code** — only this file. **No simulator was booted,
installed on, screenshot or driven** (SIMULATORS rule: only stage 5 may).

## Gates (run on the committed tree, `app/`)

| gate | command | result |
|---|---|---|
| format | `dart format --set-exit-if-changed --output=none .` | ⚠️ one unformatted file, `test/features/kid_home/zz_probe_test.dart` — **untracked sibling scratch, not in the K02 diff** |
| analyze | `flutter analyze` | ✅ zero issues in committed K02 files; the 14 remaining issues are all in the same untracked `zz_probe_test.dart` (process note, not a K02 finding — see §"carried, not K02's") |
| test (whole app) | `flutter test` | ✅ **`+2923 ~2: All tests passed!`** |
| test (feature) | `flutter test test/features/kid_home` | ✅ **`+373 ~1: All tests passed!`** (the `~1` skip is the pre-existing K01-BUG-7 probe skip, `skip: true` from the K01 loop, not K02) |
| skipped/suppressions | `grep` for `skip:` / `ignore_for_file` / `// ignore:` in the committed K02 test files | ✅ none (the 2 scratch files use them; see below) |
| fonts | `grep google_fonts\|GoogleFonts lib/features/kid_home test/features/kid_home` | ✅ none |
| tracking | `grep letterSpacing lib/features/kid_home` | ✅ two sites, both the known K02 `.mark` case at `kid_pin_view.dart:223` (+ the deliberate `letterSpacing: 0` on the greeting at `:239`) |
| scope | `git diff main...HEAD --name-only` | ✅ only `app/lib/features/kid_home/presentation/{bloc,views}`, `app/test/features/kid_home/**`, `docs/screens/K02/**` — no `core/`, no `app/`, no other feature, no `tools/screens/`, no `analysis_options.yaml` |

## Independently verified (measured, not taken on trust)

* **ARCHITECTURE** — feature-first. `domain/` untouched (`KidHomeRepository.verifyPin`
  and `child.pinSet` already existed). BLoC per screen, one `KidHomeBloc`;
  the three new fields are purely additive (`kid_home_state.dart:20-22`,
  threaded through every constructor and the `props` list
  (`kid_home_state.dart:305-307`).
  DI/routes untouched (`kid_home_di.dart`, `kid_home_routes.dart`).
* **RULES §1 scope** — confirmed by the name list above. ✅
* **Data layer contract** — no new repo methods, no seed/schema/DI change.
  Counts/nicknames come from the seeded stream; Maya's PIN `1234` is a
  DB-backed fact (`kid_home_repository_test.dart` K02 group), not a constant
  pasted into the view. No `DateTime.now()` in the feature; no
  `subscription_status` write. ✅
* **PERIODS / CLOCK** — n/a: this screen has no dates or quests. ✅
* **PIP rule** — no Pip slot on the main screen (avatar only). The failure
  card's `PipAvatar(style: mochi, stage: 1)` is correct: the bloc can only
  enter `failure` when `state.child == null` (`kid_home_bloc.dart:219-227`
  `_onStreamFailed` keeps the loaded state on mid-session errors), so the
  child's own Pip is unknowable there — the documented fallback, same shape
  as K03's empty-roster branch. No `pip_stage_*.svg` usage. ✅
* **BOTTOM EDGE (owner)** — no bar on this screen; the trailing
  `SizedBox(MediaQuery.viewPaddingOf(context).bottom)` paints nothing, so the
  shared `KidScope` meadow reaches the physical edge. `5_ui` measured the
  bottom-centre meadow px identical to the design in both themes. ✅
* **ALIGNMENT (owner)** — 20 px side gutters on top bar and scroll padding;
  avatar/dots/keypad/caption centred on x 195; `5_ui` measured Δ 0 for
  avatar disc (x 131–259), mark text rows, dots row (x 141–249), caption copy;
  no off-by-px element outside the keypad grid. ✅
* **COPY — character-by-character vs `design/html-source/screens/K02-pin.html`** —
  `NESTLING`, `Hi {nickname}! Enter your secret code`,
  `Forgot it? Just ask a grown-up.`, back `aria-label="Back"`,
  lock `aria-label="Grown-ups"`, delete `aria-label="Delete"`. All ASCII,
  matching the file's convention; the deliberately-invented wrong-code toast
  `That didn't work. Try again.` (straight `'`, no red, kind wording, unlimited
  retries) is kind by the Children's Code / no-shaming rule and is pinned by a
  test. UK spelling. ✅
* **FONTS** — `Nunito` is bundled; no `GoogleFonts` calls. ✅
* **LETTER SPACING** — the K02 `.mark` pill carries `letterSpacing: 1.28`
  at the call site with the shared-scale TODO; the greeting explicitly pins
  `0`. No other tracking. ✅
* **BALANCED HEADINGS** — K02's CSS has no `text-wrap: balance`;
  `NestBalancedText` correctly unused. ✅
* **CHIP ROWS** — n/a (no chip rows). ✅
* **UI CHECK MEASURES SHAPES** — the geometry test asserts the 128×128
  avatar disc rect at 131/109, four 18 px dot circles, the mark Text's
  16/ls-1.28, and 2-of-4 filled dots after two taps. Note for 5_ui: the
  pill's **background/border rect** and dot **fill colours** are not yet
  pinned by a test — only the text style and the dot circles are.
* **ACCESSIBILITY ACTIONS** — the semantics test asserts
  `hasAction(SemanticsAction.tap)` for Back / Grown-ups / Digit 0–9 / Delete,
  `performAction(tap)` on Digit 1 moves the dots label to `1 of 4 entered`
  (real state), the dots node correctly advertises **no** tap action, and the
  awaiting state wraps the dots in `Semantics(label: 'Checking your code')`
  with the inner label excluded. Keys ≥ 72, back/lock 56 ≥ kid 56 minimum. ✅
* **KID BACKGROUND** — all four states (body, `_KidLoading`, `_KidFailure`,
  `_NoActiveChild`) sit inside the shared `KidScope`; no local hills, no meadow
  overrides. ✅
* **Error handling** — repository throw in `verifyPin` maps to the wrong path
  (nonce bump, list kept, no failure card); stream failure only cards when
  there is no child; `_KidFailure` copy is verbatim K03 with fixed strings;
  a raw `error.toString()` cannot reach the child (the view renders fixed
  copy, never `state.errorMessage`). ✅
* **Children's Code** — no analytics, ads, network calls, `print`/`debugPrint`
  in `lib/features/kid_home`; the screen reads only the active child's row. ✅
* **Lifecycle / streams** — the BLoC still owns exactly one
  `StreamSubscription` (added in K01, untouched); the K02 handler guards
  re-entry (`state.pinChecking`), builds the outcome from the state at
  completion time (interleaved home-stream emission cannot swallow it —
  asserted by two pinned tests), and the view's `_awaiting` guard mirrors it
  so a double-tap of the 4th digit submits once (asserted). ✅
* **Performance** — one `BlocBuilder` + three single-flight `BlocListener`s
  with narrow `listenWhen`s; `_entered` is a 4-item local list; the keypad
  subtree is `StatelessWidget`; no rebuild storms. ✅

## Findings

### 1. [major] `docs/screens/K02/SHARED_REQUEST.md` was never created

`docs/screens/K02/` (directory listing), referenced from
`1_plan.md:147` ("SHARED_REQUESTs (file separately…)"),
`2_build.md:89`, `2b_build_ui.md:72`, and the two TODO sites in
`app/lib/features/kid_home/presentation/views/kid_pin_view.dart:215` and
`:232` — and cited by `5_ui.md` deviation 1.

Plan §(g) defined two shared needs and RULES §2 mandates they land in exactly
`docs/screens/<ID>/SHARED_REQUEST.md` ("Shared work … goes in
`docs/screens/<ID>/SHARED_REQUEST.md`"):

1. `NestType.kidSay` (Nunito 800, 20/26) and `NestType.kidMark` (Nunito 900,
   16/22, ls 1.28 stays at the K02 call site) — blocked by nothing, so the
   build carries metric-matched local styles behind TODOs;
2. `NestKeypad` pitch — now landed on `main` (`b1bfb4e`, merged via
   `9cac0c6`, documented at `7d37756`) but **not yet in this worktree**, so
   it is `NestKeypad(onKey:, onDelete:, kid: true)` + a TODO here.

The file does not exist, so the orchestrator's batch and the 2_build.md
"left for next iteration" checklist point at an artifact that isn't there.
K03 — same feature, same sibling loop — carries this exact file
(`docs/screens/K03/SHARED_REQUEST.md`, 303 lines).

**Fix:** create `docs/screens/K02/SHARED_REQUEST.md` with both items,
statuses current — #1 open (files `app/lib/core/design_system/tokens/typography.dart`),
#2 effectively "landed on main `b1bfb4e`; call-site follow-up pending"
(switch the K02 call to `fit: NestKeypadFit.shrinkWrap` once this branch
merges main, then re-run the 5_ui band table). When #1 lands, replace the two
local `TextStyle`s at `kid_pin_view.dart:218-224` and `:234-241` with
`NestType.kidMark` / `NestType.kidSay` and delete the TODOs.

### 2. [minor] Empty-child edge leaves the keypad stuck at 4 filled dots

`kid_pin_view.dart:40-47` (`_onKey`)

```dart
if (_entered.length == 4) {
  final child = context.read<KidHomeBloc>().state.child;
  if (child == null) return;        // no dispatch, no _awaiting, no feedback
  setState(() => _awaiting = true);
  context.read<KidHomeBloc>().add(...);
}
```

The 4th digit is appended first (dots show 4), so if the child is momentarily
`null` the entry stays at 4 filled dots with `_awaiting == false` and no
outcome — adding is blocked (`_entered.length >= 4`) and only a manual
`Delete` recovers. In practice `_KidPinBody` only renders while
`state.child != null` (`:105-111`), so this needs a same-frame state swap to
hit; the BLoC's own `childId` re-entry guard would also catch a stale submit.
Cheap to harden while touching the file for finding 1's follow-up.

**Fix:** if `child == null`, revert the 4th digit
(`setState(_entered.removeLast)`) so the entry stays editable, instead of
returning and leaving 4 dots.

### 3. [minor] The geometry test pins the dot circles and disc but not the pill/field shapes

`kid_pin_view_test.dart` (geometry + shapes group)

The SHAPES rule ("for every pill, chip, button, field and card, compare the
visible BACKGROUND/BORDER rect … not just where the text lands") is half-met:
the avatar disc rect and the four 18 px dot circles are pinned, but the
`NESTLING` pill's tinted background rect (and its pill radius) is only
inferred from the Text's style. The P05 lesson was exactly this class of
miss. The fix is two `tester.getRect` assertions on the mark pill's
`Container`/`DecoratedBox` (bg `lilacTint`, fully rounded) and, for the
keypad, the first-row key circles' rects once the shared pitch fix lands
(the 5_ui stage already covers it pixel-wise, but the unit pin should exist
too — K03 pins its shapes the same way).

**Fix:** assert the mark pill `DecoratedBox` rect ≈ x centred on 195,
height 26 (16 glyph + 2/2 padding), radius 999; assert each key's
`DecoratedBox`/`Material` circle is 72×72 with the kid border colour from
`context.nest`.

### 4. [minor] `_KidLoading`/`_KidFailure`/`_NoActiveChild` reserve
`NestHomeIndicator()` instead of the real inset

`kid_pin_view.dart:342` (`_KidLoading`), `:410` (`_KidFailure`),
`:460` (`_NoActiveChild`)

These three states end the Column with `const NestHomeIndicator()`, which
reserves `NestDevice.homeH` (34) only when the mock-glyph flag is off — but on
device advertising a large bottom inset (iPhone with home indicator ~34,
Android gesture inset larger), the loaded body's
`MediaQuery.viewPaddingOf(context).bottom` reserve (`:273`) and the fallback
states' fixed 34 can disagree, so the keypad/caption and the failure card's
button shift by the difference between the inset and 34 when rotating
between routes. Same shape as K03's (`kid_home_view.dart:208`), which is why
I flag it here rather than as K02-only drift — but K02 could already use the
same expression the body uses.

**Fix:** replace `const NestHomeIndicator()` with a transparent
`SizedBox` that reserves `max(MediaQuery.viewPaddingOf(context).bottom,
NestDevice.homeH)` — the same inset the loaded body uses at `:273`, with a
34 floor for devices with no bottom inset. No visual change on a standard
phone; correct on large-inset devices. (If K03 adopts the same expression,
file one SHARED_REQUEST rather than diverging the two.)

## Carried, shared-owned, deliberately NOT counted against K02

* **Keypad geometry drift** (`5_ui` deviations 1–3): app column pitch 96 vs
  design 82 (outer keys ±14 px), row pitch ~88–90 vs design 82 (R4 Δ +20),
  caption +26. Root cause is `NestKeypad`'s 24/16 gaps in this older
  worktree; the fix is on `main` (`b1bfb4e`) and is mandated for K02 per
  `ORCHESTRATOR_NOTES.md` 07:13 — this branch predates the merge, and the
  code correctly carries the `NOTE(K02)` TODO instead of re-spacing locally.
  When the loop merges main: pass `fit: NestKeypadFit.shrinkWrap` at
  `kid_pin_view.dart:261`, re-measure, and only then expect bands 4–6 of the
  compare sheet to fall under ±2.
* **The two untracked scratch probes** (`zz_k02_scratch_test.dart`,
  `zz_probe_test.dart`) are in-flight sibling work (their headers say "delete
  before finishing stage 6"). They are why `flutter analyze` prints 14
  issues and why the tree isn't `dart format`-clean. They do not appear in
  `git diff main...HEAD` and must not be committed; the committed K02 tree is
  format- and analyze-clean.
* **The pre-existing bloc lifetime quirk** — every kid route does
  `BlocProvider(create: () => GetIt.instance<KidHomeBloc>())` over the same
  DI singleton, so popping a kid route closes the bloc out from under any
  parent kid route. Routes are foundation code (RULES §1 off-limits) and
  K02's diff adds no new instance; noted for the orchestrator, not K02's.

## Verdict

Two of three review stages are green: scope, architecture, tokens, copy,
accessibility actions, error handling, Children's Code, stream lifecycle, and
the full test suite (+2923 app / +373 feature) all check out, and the code
honours the mandatory keypad-grid note. The screen itself is in good shape.

But iteration 1 of this screen does not yet satisfy RULES §2: the one shared
request K02 deliberately made (`NestType.kidSay` / `NestType.kidMark`) was
never written to `docs/screens/K02/SHARED_REQUEST.md`, and both the plan and
the code TODOs cite that file. That is a major process defect against an
explicit rule, plus three minor hardenings above. FIXES iteration 1 should:
create the SHARED_REQUEST file, revert the 4th digit when `child == null`,
pin the pill/key shadow rects in the geometry test, and swap the mock
indicator reserve for the real inset (or fold that one into a shared request
with K03).

VERDICT: FAIL

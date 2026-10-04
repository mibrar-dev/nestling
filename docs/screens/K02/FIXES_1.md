# Fix list after iteration 1

## From 3_test.md
# K02 Kid PIN — stage 3, TEST (iteration 1)

**This stage edited no product code.** Only `app/test/features/kid_home/**`
(tests) and two files in `docs/screens/K02/` (this stage file and a
`SHARED_REQUEST.md` — see "Also filed"). **No simulator was booted, installed
on, screenshot or driven** (SIMULATORS rule: only stage 5 may).

## Gates (`app/`)

| gate | command | result |
|---|---|---|
| format | `dart format --set-exit-if-changed --output=none test/features/kid_home lib/features/kid_home` | ✅ `Formatted 36 files (0 changed)` |
| analyze | `flutter analyze` | ✅ **No issues found!** |
| test (K02 files) | `flutter test test/features/kid_home/kid_pin_view_test.dart test/features/kid_home/k02_bugs_test.dart` | ✅ **+67 ~4: All tests passed!** |
| test (feature) | `flutter test test/features/kid_home` | ✅ **+418 ~5: All tests passed!** |
| test (whole app) | `flutter test` | ✅ **+2968 ~6: All tests passed!** |
| suppressed | `grep 'skip: true' test/` | 6 skips, **all parked bug proofs, no `ignore`/`ignore_for_file`/deleted tests**: 4 = `k02_bugs_test.dart` (below), 1 = `k01_bugs_test.dart:569` (K01-BUG-7, sibling feature), 1 = `p12_bugs_test.dart:321` (P12, sibling feature) |
| fonts | no `google_fonts` / `GoogleFonts` import or call | ✅ (bundled Inter/Nunito are loaded with `FontLoader` where metrics matter) |
| analysis_options | untouched | ✅ not weakened, not skipped |

## What this stage added

### `kid_home_bloc_test.dart` — 3 tests (+67 lines)

Every `KidHomePinSubmitted` path the BLoC owns, all through
`bloc_test`/`test` with a fake repository:

* **`the check passes the event's own child id to the repository`** —
  `KidHomePinSubmitted(childId: 'leo', pin: '1234')` while Maya is the loaded
  active child reaches `verifyPin(['leo', '1234'])`. Pins that the handler
  must **not** re-resolve the active child: the view is the only caller and it
  already holds the tapped row.
* **`a wrong attempt never turns the failure card into a loaded screen`** —
  on a failed load (`status == failure`) a submit bumps `pinWrongNonce`,
  leaves `pinPassed`/`pinChecking` false and does **not** clear `status`, so
  the retry card survives a wrong code.
* **`a submit before the load lands still resolves its outcome`** — the check
  never depends on `status == loaded`: `status` stays `initial` while
  `pinPassed` flips true.

### `kid_pin_view_test.dart` — 24 tests in 5 groups (+832 lines)

All on the in-memory Drift DB (`setUpTestScope()` → `Seed.demo`, and
`setUpTestScope(seedDemo: false)` + `Seed.empty` for the empty family), with
the bundled Inter/Nunito loaded so text metrics match a device run. Every
pump ends with `disposeApp(tester)` (RULES §7).

| group | covers |
|---|---|
| **K02 tap targets** | digits / Delete / Back / lock all ≥ **56 px** (kid minimum, not the 44 px parent one — `.lock-btn.lg`/`.nav-back.lg` are 56 in the CSS); key discs 72×72 (`.keypad button`); Choose/Try again keep the kid minimum; the keypad's blank slot is **not** announced as a control |
| **K02 every tap reaches its route** | Back by tap **and** by VoiceOver `performAction(tap)` both land on `/who-is-playing`; Back pops a K02 that K01 pushed; the lock opens the parental gate **and keeps the typed code**; a rapid lock double-tap pushes exactly one gate; the lock works in the loading state too; an accepted code leaves `/kid-pin` for good |
| **K02 entry announcements and limits** | the dots count up `1…4 of 4 entered`, then announce `Checking your code` while in flight and the dots expose **no** tap action; a wrong attempt re-arms the keypad (dots back to 0, toast shown, retry works); a `verifyPin` **error** nudges like a wrong code and never shows the failure card; a no-PIN child auto-advances with **zero** `verifyPin` calls |
| **K02 layout invariants** | keys centred on x 195, evenly pitched, inside the 20 px gutters; headings / pill / dots / caption share the same 20 px gutters (ALIGNMENT owner rule); **the pill and key discs pinned as SHAPES** — background/border rects, not just where the text lands (the P05 lesson; this was review finding 3); dark mode keeps the light geometry and flips the tokens; filled/empty dot + disc tones follow the theme; no bottom bar so the shared meadow reaches the physical edge (BOTTOM EDGE owner rule); the failure card uses `PipAvatar`, never a v1 `pip_stage_*.svg` |
| **K02 design-copy parity** | `NESTLING` / `Hi Maya! Enter your secret code` / `Forgot it? Just ask a grown-up.` are the design's bytes vs `design/html-source/screens/K02-pin.html`; the icon-button labels are the design's `aria-label`s (`Back`, `Grown-ups`, `Delete`); `.mark` carries `letterSpacing: 1.28` (LETTER SPACING rule) |

Pre-existing coverage this stage verified still holds (not re-written):
the **12-combination layout matrix** (light + dark × 320/390/430 × text scale
1.0 and 1.3, asserting no exception, all three strings present and no `£` on
a kid screen), the 390/light geometry pin (avatar disc 128×128 at 131/109,
four 18 px dots, 2-of-4 filled after two taps), the **semantics** group
(every control a labelled tap target, dots not), the **PIN flow** group
(correct PIN → `/kid-home`; wrong PIN toasts + clears + retry; a 5th digit is
ignored and Delete on empty is a no-op; back-to-back 4th-digit taps submit
once) and the **states + modes** group (Leo no-PIN auto-advance, no active
child → chooser, hanging stream → PIN loading / failed stream → retry card
that recovers, `Seed.empty` family → chooser and no keypad).

**Repo (DB-backed, `Seed.demo`)**: `kid_home_repository_test.dart` already pins
that Maya's PIN is `1234` in the database — the view's happy path is a
DB-backed fact, not a constant pasted into the widget.

## Bugs found — 4 confirmed, screen NOT patched

All four reproduce. They are parked with `skip: true` in
`app/test/features/kid_home/k02_bugs_test.dart` (in-flight sibling work from
the stage-6 bug hunt; the proofs run with):

```
flutter test test/features/kid_home/k02_bugs_test.dart --run-skipped --plain-name "K02-BUG"
```

Verified myself: **+0 -4: Some tests failed.**

### K02-BUG-1 [major] — an emoji-leading nickname throws and the screen never builds

* **Site:** `app/lib/features/kid_home/presentation/views/kid_pin_view.dart:140`
  `final initial = nickname.isEmpty ? '?' : nickname[0].toUpperCase();`
* **Repro:** set Maya's nickname to `🐝 Bee` (`test/…/k02_bugs_test.dart:327`).
  `nickname[0]` indexes UTF-16 *code units*, so it returns the unpaired high
  surrogate `U+D83D`; `.toUpperCase()` then throws.
* **Observed:** `Expected: null / Actual: ArgumentError:<Invalid argument(s):
  string is not well-formed UTF-16>`.
* **Impact:** the whole `/kid-pin` frame fails — no screen at all, not a
  degraded one. Reachable with no validation in the way: there is **no**
  `inputFormatters`, `maxLength` or nickname validation anywhere in
  `app/lib/`, so P05 accepts an emoji-leading name.
* **Not K02-only.** The same `[0].toUpperCase()` initial appears at
  `kid_home_view.dart:364` and `widgets/profile_tile.dart:96` (same feature)
  and at `features/family/presentation/widgets/child_profile_body.dart:108`,
  `features/family/presentation/widgets/kid_card_grid.dart:68`,
  `features/today/presentation/widgets/today_loaded_body.dart:363,571`.
  The fix belongs in the design system as one grapheme-safe initial helper
  (`characters`/`runes`), reused everywhere — a local patch here would leave
  six sites broken. **Orchestrator: SHARED_REQUEST item.**

### K02-BUG-2 [minor] — the greeting silently drops its tail at 320 px + 1.3 scale

* **Site:** `kid_pin_view.dart:228-242` (`maxLines: 2`, `fontSize: 20`,
  `height: 26/20`).
* **Repro:** nickname `Maximilian-Alexander`, width 320, `textScale` 1.3
  (`test/…/k02_bugs_test.dart:357`).
* **Observed:** `RenderParagraph.didExceedMaxLines == true` — the greeting
  needs three lines, so "…your secret **code**" is cut. It raises **no**
  overflow error (that is why the matrix test at 320×1.3 passes today), so a
  child just sees a truncated sentence.
* **Note:** this is an accessibility-scale copy defect, not a layout one —
  `maxLines: 2` is a hard cap that the 1.3 scale can always beat.

### K02-BUG-3 [minor, security-relevant] — the no-PIN auto-advance can bypass a PIN

* **Site:** `kid_pin_view.dart:57-70` — the no-PIN listener schedules
  `WidgetsBinding.instance.addPostFrameCallback((_) { context.go('/kid-home'); })`
  and the callback navigates **unconditionally**, with no re-check of the
  child.
* **Repro:** emit a no-PIN child (Leo) and then a PIN'd child (Maya) in one
  event-loop turn (`test/…/k02_bugs_test.dart:383`, a controllable broadcast
  stream — the same shape Drift delivers on two rapid `setActiveChild`
  writes).
* **Observed:** `Expected: '/kid-pin' / Actual: '/kid-home'` — Maya's PIN is
  never asked for.
* **Why minor and not major:** the window is the single frame between the
  post-frame callback being scheduled and firing. In production it needs the
  active child to change from a no-PIN child to a PIN'd child inside that one
  frame (e.g. a parent switching the playing child on another device while the
  route is mounted). Low probability — but it is a **PIN bypass on a kid
  screen**, so it deserves the one-line fix rather than a backlog item:
  re-read `context.read<KidHomeBloc>().state.child?.pinSet` inside the
  callback, or drop the post-frame hop and assert the state at navigation
  time.

### K02-BUG-4 [minor] — the wrong-code toast outlives a successful retry

* **Sites:** `kid_pin_view.dart:85` `showNestToast(context, …)` and
  `app/lib/core/design_system/components/nest_toast.dart:39-56`, which uses
  the **root** `ScaffoldMessenger.of(context)` and a 3 s duration.
* **Repro:** enter `9999` (wrong), then `1234` (correct)
  (`test/…/k02_bugs_test.dart:409`).
* **Observed:** on `/kid-home` the SnackBar
  `That didn't work. Try again.` is still on screen for its remaining ~2.8 s.
* **Why it matters beyond tidiness:** this screen is under the Children's Code
  no-shaming rule — telling a child their code failed while showing them the
  home screen they were not let into is both confusing and unkind. Fix is
  local: `ScaffoldMessenger.of(context).hideCurrentSnackBar()` before
  `context.go(home)`.

## Verdict

`flutter analyze` is clean and the whole suite passes — but **four real bugs
in the screen are proven by these tests**, and the rule for this stage is
explicit: PASS only if all tests pass **and** no bugs were found. Two are
K02-local one-liners (`kid_pin_view.dart:85`, `:140`), one needs a shared
design-system helper across seven sites in four features, and one is a
PIN-bypass race at `:57-70`. Per the brief the screen was **not** patched —
all four are recorded here with file:line and a repro for the FIXES iteration.

Stage 6 reached the same four findings independently and with the same
severities (`6_bugs.md`), which is corroboration rather than a new result.

## Also filed

`docs/screens/K02/SHARED_REQUEST.md` — created this stage. `4_review.md`
filed its absence as a **major** process defect against RULES §2 (the plan,
`2_build.md`, `2b_build_ui.md` and two live `TODO(K02)` comments all cite a
file that did not exist). Three items:

1. **`NestType.kidSay` / `NestType.kidMark`** — open; the metrics K02 currently
   hard-codes locally behind TODOs, with `.mark`'s `1.28` tracking to stay at
   the call site per the LETTER SPACING rule.
2. **`NestKeypad` pitch** — landed on `main` (`b1bfb4e`, merged `9cac0c6`);
   the K02 follow-up is to re-shoot `/kid-pin` after the loop merges `main` and
   confirm bands 4–6 of the compare sheet fall under ±2. This is the sole
   reason `5_ui` returned FAIL; K02 must not re-space keys locally.
3. **Grapheme-safe avatar initial** — new, from **K02-BUG-1** below: one shared
   helper replacing `nickname[0].toUpperCase()` at **seven sites across four
   features**, which K02 is not allowed to fix alone.

## Carried, not this stage's

* `k02_bugs_test.dart` (868 lines, untracked) and `6_bugs.md` are **stage-6
  work**, in flight alongside this stage. Left untouched. Its four `skip: true`
  proofs are the bug evidence cited above; I re-ran them to confirm each still
  fails and did not edit the file.
* `5_ui.md` FAIL (keypad pitch/caption) and `4_review.md` findings 2–4 —
  other stages' verdicts, recorded here only for the FIXES iteration's benefit.
* The shared bloc-lifetime quirk (every kid route does
  `BlocProvider(create: () => GetIt.instance<KidHomeBloc>())` over the same
  DI singleton) is foundation code, off-limits per RULES §1, and K02's diff
  adds no new instance — so it is not a K02 finding.


## From 4_review.md
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


## From 5_ui.md
# K02 Kid PIN (`/kid-pin`) — 5_ui (iteration 1)

Shots (simulator BC440E48-B3A3-43BC-971B-0EF5DB621874, `demo kid maya`):
- `docs/screens/K02/ui/app_light_1.png` (1170×2532, = 390×844 @3x)
- `docs/screens/K02/ui/app_dark_1.png` (1170×2532)

Compare output:
- Light: `mean diff: 5.33%`; bands 0: 1.60 (0–105), 1: 0.19 (105–211), 2: 2.07 (211–316), 3: 3.07 (316–422), 4: 11.09 (422–527), 5: 12.82 (527–633), 6: 8.79 (633–738), 7: 3.07 (738–844).
- Dark: `mean diff: 5.06%`; bands 0: 1.57, 1: 0.21, 2: 1.97, 3: 2.97, 4: 10.76, 5: 11.99, 6: 7.96, 7: 3.09.
- Bands 4–6 (keypad zone) carry the diff; bands 0–1 (top bar/avatar) are ~0–1.6% (status-bar chrome + font raster only).

Method: logical px = PNG px ÷ 3. Dark-ink row/column projections on design vs app (light pair; dark pair is geometrically identical per the compare sheets).

Measured Y (logical px, design vs app, Δ = app − design):
- `NESTLING` mark text rows: ~265–270 vs ~265–270 → Δ 0.
- Say title `Hi Maya! Enter your secret code`: rows ~292–305 both → Δ 0.
- PIN dots block: 331–365, dots 340–358 both; x-segments identical 141–159 / 171–189 / 201–219 / 231–249 (18 px dots, 12 px gap, total x 141–249) → Δ 0.
- Keypad row tops: R1 393–395 vs 393–395 (Δ 0); R2 ~473–475 vs ~483–485 (Δ +10); R3 ~558–560 vs ~568–570 (Δ +10); R4 ~638–640 vs ~658–660 (Δ +20). R4 bottom ~710–715 vs ~725–730 (Δ +15–18).
- Key columns, row-1 left edges: design 77 / 159 / 241 (pitch 82, grid x 77–313, w 236) vs app 63 / 159 / 255 (pitch 96, grid x 63–327, w 264). Centre column aligned; outer keys Δ −14 (left) / +14 (right).
- Key size 72 circle both (mid-slice chord ~70 in both — circle curvature, not a size change).
- Caption `Forgot it? Just ask a grown-up.`: top ~737 (rows 740/745) vs ~763 (rows 765/770) → Δ +26.
- Avatar disc: lilac span x 131–259 (128) identical both. Lock-button row white segments identical. Bottom-centre meadow px identical `[204, 237, 192]`.

## Deviations

1. Keypad column pitch (SHARED — `NestKeypad`, fix on `shared/keypad_grid`, do not fix in K02). Design: col pitch 82, grid x 77–313. App: col pitch 96, grid x 63–327. Outer keys ±14 px off (e.g. left key left edge 77 vs 63). Exceeds ±2. Fix: shared keypad grid gap 24 → design 10 (ORCHESTRATOR_NOTES mandatory item; plan SHARED_REQUEST #2). K02 takes the component as-is.
2. Keypad row pitch (same SHARED root cause). Design row pitch 82 (R1 393, R2 ~473, R3 ~558, R4 ~638). App pitch ~88–90 (R1 393, R2 ~483, R3 ~568, R4 ~658): R2 Δ +10, R3 Δ +10, R4 Δ +20, R4 bottom Δ +15–18. Exceeds ±2. Fix: shared row gap 16 → design 10; re-shot after main lands it.
3. Caption vertical position (downstream of #2, no local fix). Design top ~737, app top ~763 (Δ +26) — the taller keypad pushes the 20 px-gap caption down. Resolves with the shared keypad fix; K02 layout (gap 20, scroll pad 32) already matches the HTML.
4. Home-indicator mock pill: design draws the 134×5 mock pill (y 825–829, x 128–262); simctl app shot shows none (transparent bottom spacer per plan §9; the OS draws the real indicator). Chrome difference, not a product defect — no fix.
5. Status-bar time/glyphs (07:46 + simulator icons vs 9:41 mock): ignored per STATUS BAR orchestrator rule — no fix.

Not deviations (checked, passing):
- Presence/order: back, lock, avatar, mark pill, greeting, dots, 10 digit keys + blank + delete, caption — all present, in design order.
- Copy (vs HTML source char-by-char): `NESTLING`, `Hi Maya! Enter your secret code` (no trailing period, as in source line 38), `Forgot it? Just ask a grown-up.` (period) — exact in both themes.
- Dots fill: design shows 2 filled (illustrative mid-entry mock, aria `Two of four digits entered`); app shows 0 filled = correct empty initial state. Position identical; state difference is correct behaviour, not a defect.
- Avatar/mark/say/dots/top-bar/meadow geometry: Δ 0 (see table). Key shape/size, 3 px kid borders, kid shadows, pill radii, lock 56×r18 surface + line border — match.
- Alignment: 20 px side gutters, centred avatar/dots/keypad/caption — no off-by-px element outside the keypad grid.
- Bottom edge (owner rule): no bottom bar on this screen; meadow runs to the physical edge in both themes, no strip — PASS.
- Dark mode: same geometry as light; colours correct (dark sky, dark-navy keys with light borders, empty dots light-bordered, lilac disc dark tint + lavender M, caption ink-2). No dark-only deviation.
- No `£`, no Pip slot on this screen (avatar only — PIP rule N/A), no chip rows (N/A), no balanced heading in K02 CSS (N/A).

UI VERDICT RULE audit: keypad rows/cols (up to ±14 col, +20 row) and caption (+26) exceed ±2 px — including as a uniform keypad-block shift. FAIL.


## From 6_bugs.md
# K02 · Kid PIN — Stage 6 bug hunt (iteration 1)

Adversarial pass over `/kid-pin` on the iteration-1 build (`7435738`, main
merged at `e01420a`). Every proof lives in
`app/test/features/kid_home/k02_bugs_test.dart` and runs against the real
in-memory Drift database (Seed.demo), the real repository, or a
feature-local fake. No screen code was changed by this stage; no simulator
was used (SIMULATORS rule).

```
flutter test test/features/kid_home/k02_bugs_test.dart
  → +21 ~4: All tests passed!        (K02-BUG-1..4 parked, skipped)

flutter test --run-skipped test/features/kid_home/k02_bugs_test.dart \
  --plain-name K02-BUG
  → 4 deterministic failures: K02-BUG-1, K02-BUG-2, K02-BUG-3, K02-BUG-4

flutter test test/features/kid_home/
  → +418 ~5: All tests passed!      (the 4 parked proofs + K01-BUG-7)
```

## Findings

| # | Severity | Status |
|---|---|---|
| K02-BUG-1 | major | **OPEN** — an emoji-leading nickname throws during avatar render |
| K02-BUG-2 | minor | **OPEN** — the greeting clips at 320 px + 1.3 scale |
| K02-BUG-3 | minor (latent) | **OPEN** — the no-PIN auto-advance can skip a PIN |
| K02-BUG-4 | minor | **OPEN** — the wrong-code toast outlives a successful retry |

---

### K02-BUG-1 — major — a nickname starting with an emoji breaks the avatar

**Mechanism.** `kid_pin_view.dart:140` builds the avatar initial with
`nickname[0].toUpperCase()`. For a non-BMP first character (any emoji, e.g.
🐝 = U+1F41D) `[0]` slices the UTF-16 surrogate pair and returns an unpaired
high surrogate. Flutter's text layout then throws
`Invalid argument(s): string is not well-formed UTF-16` while laying out
`NestAvatar`'s `Text`, so the avatar disc renders broken and the error
surfaces as a framework exception (debug: error paint; release: dropped
text plus a console error).

**Repro.** P05 accepts any non-empty nickname ≤24 characters
(`family_bloc.dart:78-85`) and applies no character filter, so a parent can
save "🐝 Bee". Deep-linking `/kid-pin` with that child active (and, once the
picker has the same fix, tapping their tile) renders K02 with the exception.
The failing proof seeds `nickname = '🐝 Bee'` on Maya and pumps `/kid-pin`;
it asserts `NestAvatar.initial == '🐝'` and `takeException() == null`.

**Failing test.** `K02-BUG-1: a nickname starting with an emoji throws in
the avatar initial` (skipped; bug id in the test description).

**Suggested fix (small).** Take the first *rune* instead of the first code
unit:

```dart
final initial = nickname.isEmpty
    ? '?'
    : String.fromCharCode(nickname.runes.first).toUpperCase();
```

(`nickname.characters.first` is the fuller grapheme fix, but `characters` is
not a direct dependency yet.) The same `nickname[0]` expression exists at
`profile_tile.dart:96`, `kid_home_view.dart:364`, `kid_card_grid.dart:68`
and `child_profile_body.dart:108` — a shared `kidInitial()` helper
(SHARED_REQUEST) closes the whole class; the K02 fix alone stops this
screen's exception.

---

### K02-BUG-2 — minor — the greeting clips at 320 px + 1.3 scale

**Mechanism.** The greeting is
`Text('Hi $nickname! Enter your secret code', maxLines: 2)` with no
ellipsis. At 320 px content width (280) and text scale 1.3 (26 px Nunito
800), a 20-character nickname (P05's limit is 24) needs a third line;
`RenderParagraph.didExceedMaxLines` is true and the tail of the sentence is
silently dropped mid-glyph.

**Repro.** Nickname `Maximilian-Alexander`, width 320, scale 1.3:
`didExceedMaxLines == true`. The same name fits at 390/1.0, 390/1.3 and
320/1.0 — those combinations are green probes in the same file.

**Failing test.** `K02-BUG-2: a 20-char nickname clips the greeting at
320 px + 1.3 scale` (skipped; bug id in the test description).

**Suggested fix (small).** Let the say line grow with the accessibility
scale (e.g. `maxLines: 3` when
`MediaQuery.textScalerOf(context).scale(20) > 20`, or drop `maxLines` —
the ListView scrolls), or at minimum `overflow: TextOverflow.ellipsis` so
the cut is legible. Keep the design's single-line break for short names.

---

### K02-BUG-3 — minor (latent) — the no-PIN auto-advance can bypass a PIN

**Mechanism.** The first `BlocListener` (`kid_pin_view.dart:57-70`)
navigates when a loaded no-PIN child arrives, but the actual
`context.go(home)` runs in a post-frame callback and never re-checks the
child. If a second home emission replaces the no-PIN child with a
PIN-protected one before that callback runs, K02 still navigates home —
the PIN is skipped.

**Repro (deterministic fake).** `_StreamPairRepo` emits
`Leo (pinSet: false)` and then `Maya (pinSet: true)` in one event-loop
turn; after settling, the path is `/kid-home` and Maya's PIN screen never
rendered.

**Reachability.** No shipped flow writes `app_state.active_child_id` twice
inside one frame (K01 writes once, before pushing, and routes no-PIN
children straight to `/kid-home`), so this is a latent hardening hole like
K01-BUG-7 rather than a user-visible defect today — hence minor, not major.

**Failing test.** `K02-BUG-3: a no-PIN child followed by a PIN child in one
stream turn navigates home without the PIN` (skipped; bug id in the test
description).

**Suggested fix (small).** In the post-frame callback, read the bloc state
again and only `go(home)` when the current child is still non-null and
`!pinSet`; or navigate directly in the listener (it fires outside build, so
the post-frame hop is unnecessary).

---

### K02-BUG-4 — minor — the wrong-code toast outlives a successful retry

**Mechanism.** `showNestToast` uses the root `ScaffoldMessenger` (3 s
duration). A wrong attempt followed by a correct one within that window
navigates to `/kid-home` with "That didn't work. Try again." still on
screen — telling the child the code failed after it succeeded.

**Repro.** Enter `9999`, pump 200 ms (toast visible), enter `1234`, settle:
`currentPath == /kid-home` and the toast text is still found.

**Failing test.** `K02-BUG-4: the wrong-code toast is still visible on
/kid-home after a correct retry` (skipped; bug id in the test description).

**Suggested fix (small).** `ScaffoldMessenger.of(context)
.hideCurrentSnackBar()` in the pass listener before `context.go`, or hide
it when a new digit is pressed.

---

## Checked clean (probes — all green)

| Category | Probe | Result |
|---|---|---|
| data edges | 0 children (Seed.empty): chooser + `Choose` tap action → K01; 1 child; 6 children (active child only, no roster leak); £0.00 / £999.99 / 9999 coins never render; no `£` on the screen | pass |
| long names | `Maximilian-Alexander` fits at 390/1.0, 390/1.3 and 320/1.0 | pass (320/1.3 = K02-BUG-2) |
| rapid double taps | 4th-digit double tap submits once (`kid_pin_view_test.dart`); Back double-tap returns once; Back-then-lock burst cannot stack a gate; lock double-tap opens exactly one gate | pass |
| back nav + deep links | deep-link Back → picker; a passed PIN cannot be popped back to; a pushed route pops to the picker | pass |
| restart persistence | wrong attempt + restart: dots reset, toast gone, PIN still enforced | pass |
| mode guards | lock from loaded and failure states → P17 gate; parent-mode `/kid-pin` renders and Back → picker (observed; matches K01/K03 notes); kid mode → parent-only is router-guarded | pass |
| dark contrast | greeting ≥3.0; caption over hill-front and meadow ≥4.5; mark pill, keypad key, avatar initial, dot border ≥4.5/3.0 | pass |
| 320 px + 1.3 | loaded screen + wrong-PIN toast, failure card, chooser: no overflow exceptions | pass |
| async gaps | pop while the PIN check hangs: no exception, no stale navigation (emit-after-close is a no-op in bloc 9.2.1) | pass |
| BST/GMT + money | whole visible text tree byte-identical across a BST→GMT clock change; no dates, no `£` | pass |
| accessibility | digits / Delete / Back / lock expose `SemanticsAction.tap` and `performAction` drives the real state (`kid_pin_view_test.dart`); dots have no tap; failure `Try again` and chooser `Choose` expose tap and drive the real outcome; the awaiting label is present and non-interactive | pass |

## Observations (not defects)

1. **Keypad pitch** — this worktree still has `NestKeypad`'s 24 px columns /
   16 px rows; the design CSS `.keypad` is 10/10. This is the known shared
   deviation tracked by SHARED_REQUEST #2 and ORCHESTRATOR_NOTES (07:13);
   the UI stage owns it, not this hunt.
2. **Awaiting label merge** — `Semantics(label: 'Checking your code')` is a
   label-only node, so it merges into the screen's text node instead of
   replacing the dots node. The phrase is exposed and non-interactive;
   `container: true` would give it a distinct node if wanted.
3. **Parent-mode kid routes** — a parent-mode deep link to `/kid-pin`
   renders the kid screen (same as the K01/K03 notes); the boundary guarded
   today is the opposite direction (kid mode → parent-only stops at the
   gate).
4. **Rules N/A on K02** — no chip rows (`NestChipWrap`), no
   `text-wrap: balance` heading (`NestBalancedText`), no Pip on the screen
   (avatar initial only); the failure-card `PipAvatar(mochi, stage 1)` is
   K03's shared no-child fallback. Bottom-edge rule: no bottom bar on K02,
   the shared meadow runs to the edge.

## Verdict

One major (K02-BUG-1) and three minor open bugs. All four proofs are
deterministic under `--run-skipped`; the plain suite stays green with them
parked. A screen with a crash-class defect cannot pass the bug stage.


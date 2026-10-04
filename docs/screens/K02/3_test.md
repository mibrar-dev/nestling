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

VERDICT: FAIL

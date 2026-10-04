# 3 TEST (iteration 1) — K02 Kid PIN (`kid_home`, `/kid-pin`)

Stage scope: `app/test/features/kid_home/**` (RULES §1). **This stage changed
no product code** — only tests in `app/test/features/kid_home/` and this file.
**No simulator was booted, installed on, screenshot or driven** (SIMULATORS
rule: only stage 5 may).

Test posture when this stage started: 22 widget tests
(`kid_pin_view_test.dart`) and 10 K02 bloc/state tests
(`kid_home_bloc_test.dart`). The matrix, the geometry anchors and the PIN
outcomes were already covered; the gaps this stage closed were accessibility
**tap targets**, **every-tap navigation**, the **loading/chooser/empty**
control set, the **shape** pins (UI CHECK MEASURES SHAPES), **design-copy
parity read from the HTML source**, and — after the loop merged main —
**pixel-exact design anchors for the keypad grid**.

Final counts: `kid_pin_view_test.dart` 22 → **47**, K02 bloc group 10 → **13**,
`test/features/kid_home` **+423 ~1**, whole app **+2978 ~2**.

## Tests added

### `app/test/features/kid_home/kid_pin_view_test.dart`

Same harness as before (`_loadBundledFonts` + `setUpTestScope` +
the `_WrappingRepo`/`_PinStub` seam), so every new test runs against the real
in-memory Drift database and the real `KidHomeRepository`.

| Group | Test | What it pins |
|---|---|---|
| K02 states + modes | `an empty family (Seed.empty) shows the chooser, not a keypad` | `Seed.empty` (onboarded parent, no children) renders `_NoActiveChild`; no keypad and no dots leak into the empty state |
| K02 tap targets | `digits, Delete, Back and the lock are all >= 56 px` | every control ≥ `NestDevice.tapKid` (56) — RULES §8 kid minimum; the two design controls (`NestIconButton`, `NestLockButton`) match 56 exactly |
| | `the key discs are 72 px squares (design .keypad button)` | all 11 keypad cells are 72×72 (`.keypad button`, `components.css`) |
| | `the chooser and retry buttons keep the kid minimum` | `Choose` and `Try again` (the fallback-state buttons) clear 56 too, and the button box is larger than its label |
| | `the keypad blank slot is not announced as a control` | the decorative 12th cell is excluded from semantics: exactly 11 announced keypad controls, none unnamed (no dead button for VoiceOver) |
| K02 every tap reaches its route | `Back by tap and by VoiceOver both land on the picker` | `performAction(SemanticsAction.tap)` on `Back` (not only a pointer tap) drives the deep-link-safe fallback → `/who-is-playing` |
| | `Back pops a K02 that K01 pushed` | K01 → K02 → Back returns to the picker (real `setActiveChild` write drained with `runAsync`, the K01-BUG-3 harness note) |
| | `the lock opens the grown-up gate and keeps the typed code` | `Grown-ups` → `/parental-gate` by semantics action, and a half-typed code survives the gate detour |
| | `a rapid lock double tap pushes exactly one gate` | the `_GateLockButton` guard: one pop lands back on `/kid-pin`, so no second gate is stacked |
| | `the lock works in the loading state too` | the fallback states keep a working grown-up route while the load hangs |
| | `the accepted code leaves the PIN screen for good` | a correct code replaces the stack — `KidPinView` is no longer in the tree, so Back cannot return to the PIN |
| K02 entry announcements and limits | `the dots count up, then announce the in-flight check` | dots announce `1…3 of 4 entered`; the 4th digit starts exactly one `verifyPin`; mid-check the dots announce `Checking your code` and the counting label is gone; keys are inert, so the code cannot exceed 4 |
| | `a wrong attempt re-arms the keypad for a fresh code` | after a nudge the dots reset to 0 and a fresh code goes through (unlimited retries) |
| | `a verifyPin error nudges like a wrong code, never the card` | a repository throw stays on `/kid-pin` with the toast (no `Oh no! Pip got lost.`), the toast node is a **live region**, and the next attempt still navigates |
| | `a no-PIN child auto-advances without any verify call` | Leo auto-advances to `/kid-home` with `verifyCalls == 0` (the repository auto-passes; the view never dispatches) |
| K02 layout invariants | `the screen lands on the 1_plan.md design anchors (390/1.0)` | pixel-exact against the design HTML: key columns x 77/159/241, key rows 393/475/557/639, `Delete` row 639, caption 731, greeting 285, dots 331, back/lock 47 (all ±2). This is the proof that the shared keypad-grid fix (`main b1bfb4e`, ORCHESTRATOR_NOTES 07:13) plus `fit: NestKeypadFit.shrinkWrap` restored the design pitch — the deviation recorded in `5_ui.md` is gone |
| | `keys are centred, evenly pitched and inside the gutters` | at 320/390/430: the grid is centred on the column, no key crosses the 20 px gutter, row and column pitches are uniform (row 4 shares the column pitch) — width-independent, so it guards every device size |
| | `headings, pill, dots and caption share the 20 px gutters` | greeting, `NESTLING` pill, dots, caption and keypad are centred on x 195 and inside the gutters (ALIGNMENT owner rule) |
| | `the pill and the key discs are pinned as SHAPES` | the `.mark` pill's **background** = `tokens.lilacTint`, radius 999, width = text + 2×12 padding; every key `Ink` decoration is a 72 circle, `surface` fill, kid ink border at `context.nestKid.borderWidth` |
| | `dark mode keeps the light geometry and flips the tokens` | 7 measured rects (back, lock, say, pill, dots, keypad, caption) are **identical** light↔dark — tones differ, geometry does not |
| | `the filled/empty dot and disc tones follow the theme` | filled dot = `tokens.ink`, empty = `tokens.surface`, 128 disc = `tokens.lilacTint`, in **both** themes (and the test proves the theme really switched) |
| | `no bottom bar: the shared meadow reaches the physical edge` | `NestMeadow` is 390×136 with `bottom == 844`, the body `Scaffold` is transparent and there is no `NestBottomCta` — no coloured strip can appear (BOTTOM EDGE owner rule) |
| | `the failure card shows PipAvatar, never a v1 illustration` | the failure card renders `PipAvatar` (PIP rule) and the K02 view source contains no `pip_stage_`, no `google_fonts`, no `GoogleFonts` |
| K02 design-copy parity | `mark, greeting and caption are the design bytes` | `.mark`, `.say` and `.kcap` are **read out of `design/html-source/screens/K02-pin.html`** (regex + entity decode, never transcribed), the greeting's name is the DB nickname (DATA OVER MOCKS), every rendered string is pure ASCII like the design, and the source contains no error copy (the nudge is app-only) |
| | `the icon-button labels are the design aria-labels` | `Back`, `Grown-ups`, `Delete` exist as `aria-label`s in the source **and** as the app's semantics labels |

### `app/test/features/kid_home/kid_home_bloc_test.dart` (K02 group: 10 → 13)

| Test | What it pins |
|---|---|
| `the check passes the event's own child id to the repository` (blocTest) | `verifyPin` receives the `childId` on the event (the handler must not re-resolve the active child); `checking → passed` |
| `a wrong attempt never turns the failure card into a loaded screen` | with `failLoad`, a wrong code bumps `pinWrongNonce`, leaves `pinPassed`/`pinChecking` false and does **not** clear `status` — the retry card survives |
| `a submit before the load lands still resolves its outcome` | the handler needs no loaded child: `pinPassed` lands while `status` is still `initial` (the view dispatches from the row it already holds) |

Still green from the build stage (K02 group, recorded for completeness):
correct PIN `checking → pinPassed`; wrong PIN nonce bump with the list kept;
two identical wrong attempts both surface; correct retry after a wrong one; a
`verifyPin` throw reads as the wrong path; the re-entry guard while a check is
in flight; an interleaved home-stream emission cannot swallow the outcome; the
next home emission consumes `pinPassed` but not the nonce; `copyWith` /
`withCompletion*` / `copyWithProfiles*` / `copyWithSelection` /
`copyWithLoaded` all carry the three PIN fields with the documented
preserve/consume rules; `KidHomePinSubmitted` equality.

## Coverage against the stage brief

| Required | Where |
|---|---|
| bloc_test for every event/state path | 13 in the K02 bloc group (3 new) + the field-threading and equality paths |
| light + dark | matrix (2 themes) + dark-geometry parity + the tone-flip test |
| widths 320 / 390 / 430 | matrix + the key-gutter test |
| text scale 1.0 and 1.3 | matrix (all 12 combinations) |
| empty / loading / error states | `_KidLoading` (hanging stream), `_KidFailure` (broken stream + `Try again` recovery), `_NoActiveChild` (null child **and** `Seed.empty`) |
| every tap navigates to the right route | Back (tap + semantics action, deep link + pushed), lock (single/double tap, loaded + loading), `Choose` → `/who-is-playing`, `Try again`, accepted PIN → `/kid-home` |
| semantics labels on icon buttons | `Back`, `Grown-ups`, `Delete`, `Digit 0-9` labelled + `hasAction(tap)` + `performAction` drives real state/navigation; the dots node is label-only |
| tap targets ≥ 44 parent / ≥ 56 kid | keypad 72, Back/lock 56 (exact token), `Choose`/`Try again` ≥ 56 |
| in-memory Drift DB, `Seed.demo` / `Seed.empty` | every widget test; the real repository except where a script must hang or throw |

## Gates (re-run at the end of the stage, `app/`)

```
dart format --set-exit-if-changed --output=none test/features/kid_home lib/features/kid_home
Formatted 36 files (0 changed) in 0.24 seconds.

flutter analyze
Analyzing app...
No issues found! (ran in 6.9s)

flutter test test/features/kid_home/kid_pin_view_test.dart
00:03 +47: All tests passed!

flutter test test/features/kid_home/kid_home_bloc_test.dart
00:04 +51: All tests passed!

flutter test test/features/kid_home
00:13 +423 ~1: All tests passed!

flutter test                       (whole app)
02:02 +2978 ~2: All tests passed!
```

The single `~1` skip in the feature directory is the pre-existing
K01-BUG-7 probe from the sibling K01 loop; no skip was added by this stage.

**One environmental note, for honesty about two earlier runs:** two whole-app
runs failed mid-flight with `ArgumentError: Couldn't resolve native function
'sqlite3_initialize' … Failed to load dynamic library
'…/app/build/native_assets/macos/libsqlite3.dylib' (no such file)` in
unrelated features (`test/app/routes_smoke_test.dart`,
`test/features/auth/create_account_view_test.dart`,
`test/features/onboarding/value_tour_view_test.dart`). That is the shared
`build/` directory being rewritten by a concurrent build in this same
worktree (the sibling FIXES/UI stages), not a test or product defect: the very
same command passed on re-run, and the affected files are not K02's. Log kept
at `/tmp` equivalent path `…/k02_full_suite.txt`. Nothing was "fixed" in
response to it.

## Bugs

**Open bugs: none.** No test written by this stage exposed a defect in
`kid_pin_view.dart`, `kid_home_bloc.dart` or `kid_home_state.dart`.

Four bugs were found in this iteration by the sibling bug hunt
(`6_bugs.md`, `app/test/features/kid_home/k02_bugs_test.dart`) and **fixed
during this same iteration** by the concurrent FIXES stage; this stage
re-verified the result rather than patching anything:

| id | severity | fix (in `kid_pin_view.dart`) | proof now |
|---|---|---|---|
| K02-BUG-1 | major | `kid_pin_view.dart:156` avatar initial now takes `nickname.runes.first`, so an emoji-leading nickname (`🐝 Bee`) no longer slices a surrogate pair and throws during layout | un-skipped, green |
| K02-BUG-2 | minor | `kid_pin_view.dart:249` greeting `maxLines: 3`, so a 20-character nickname is not cut at 320 px + scale 1.3 | un-skipped, green |
| K02-BUG-3 | minor (latent) | `kid_pin_view.dart:76-84` the no-PIN post-frame auto-advance re-reads the bloc state and only navigates while the current child is still PIN-free | un-skipped, green |
| K02-BUG-4 | minor | `kid_pin_view.dart:88` the pass listener hides the current snack bar before `go(home)`, so the wrong-code nudge cannot outlive a successful retry | un-skipped, green |

`4_review.md`'s findings are likewise closed: #3 (pin the pill/key **shapes**,
not only the text) by this stage's `the pill and the key discs are pinned as
SHAPES`; #2 (revert the 4th digit when `child == null`) and #4 (mock home
indicator vs the real inset → `_BottomInset`) by the FIXES stage; #1
(`SHARED_REQUEST.md` was never written) by `docs/screens/K02/SHARED_REQUEST.md`,
which now exists.

## Notes for the next iteration

1. **The keypad deviation is closed.** With `main` merged (`c094fd5`) and
   `fit: NestKeypadFit.shrinkWrap` at the call site, K02 measures key columns
   x 77/159/241, rows 393/475/557/639 and caption 731 — exactly the design.
   `5_ui.md`'s deviations 1–3 (column pitch 96 vs 82, row pitch ~88 vs 82,
   caption +26) should be re-measured and closed; the unit-level proof is now
   `the screen lands on the 1_plan.md design anchors (390/1.0)`.
2. **The width-independent key tests were deliberate.** `keys are centred,
   evenly pitched and inside the gutters` asserts invariants rather than a
   pixel grid so it stays valid at 320/390/430; the anchor test above is the
   390/1.0 design proof. Keep both if the pitch is ever touched again.
3. **Semantics finders need `RegExp` for the dots and the toast.**
   `find.bySemanticsLabel` reads `renderObject.debugSemantics.label`, and the
   dots/toast nodes merge into the screen's text node, so their label is a
   concatenation. An exact-string lookup silently reports `findsNothing` even
   though the label is present — worth knowing before anyone "fixes" one of
   these assertions.
4. **The fallback states are now pinned too**: a working lock, ≥56 tap targets
   on `Choose`/`Try again`, and no overflow at 320 px / scale 1.3.
5. **Hygiene**: no test skipped, no `ignore_for_file`, no `// ignore:` added by
   this stage; `analysis_options.yaml` untouched; no simulator used.

VERDICT: PASS
# K02 Kid PIN — QA code review (Stage 4, iteration 4)

Scope: feature `kid_home`, route `/kid-pin`, kid mode, designs
`design/screens/{light,dark}/K02-pin.png` (1170×2532 @3x). Reviewed
`git diff main...HEAD` (7 lib files, 5 test files, `docs/screens/K02/**`)
against `docs/ARCHITECTURE.md`, `docs/screens/RULES.md`,
`docs/DESIGN_SPEC.md` §5 K02, `docs/design/SPACING_SPEC.md`, the design
system in `app/lib/core/design_system/`, `1_plan.md`,
`ORCHESTRATOR_NOTES.md` (07:13 keypad, 10:32 hang, 12:00 avatar initial),
`SHARED_REQUEST.md` and the stage notes 1→6 of all four iterations.

**This stage edited no product code** — only this file. **No simulator was
booted, installed on, screenshot or driven** (SIMULATORS rule: only stage 5
may). The design PNGs and the iteration-4 app shots were read with the file
reader only.

## What changed in iteration 4 (verified with `git diff 9a1f16d..HEAD`)

* `presentation/widgets/kid_style_helpers.dart` — new grapheme-safe
  `kidAvatarInitial(String, {String fallback = '?'})`.
* `presentation/views/kid_home_view.dart:364` and
  `presentation/widgets/profile_tile.dart:94` — the two remaining
  `nickname[0].toUpperCase()` sites routed through it (K02-TEST-BUG-A closed
  for `kid_home`).
* `presentation/views/kid_pin_view.dart` (30 lines) — the `.mark` pill's
  hard-coded `circular(999)` → `NestRadii.allPill` (`:239`), the bare `128`
  hoisted to `_KidPinBody.avatarDisc` with its `.k2-ava` provenance (`:162`),
  and the rationale/TODO block for the reverted `AbsorbPointer` experiment
  (`:289-306`).
* Tests — the P17-gate exit harness (`_leaveGate` in
  `kid_pin_view_test.dart:76`, the same two-line pattern in
  `k02_bugs_test.dart:804-806`), the five mirroring predicates moved to
  `NestRadii.allPill`, and two new render proofs for an emoji-leading
  nickname (`kid_pin_view_test.dart:1521`, `kid_home_view_test.dart:2314`).
* No change to the bloc (the iteration-1 `KidHomePinSubmitted` contract still
  holds — re-verified below), to `domain/`, `data/`, DI or routes.

## Gates (run in `app/`, every test run with `--timeout 120s`)

| gate | result |
|---|---|
| `flutter analyze` | ✅ 3 infos, **all three in the untracked in-flight file** `test/features/kid_home/kid_avatar_initial_test.dart` (cascade, tear-off, missing EOL). The committed set: clean |
| `dart format --set-exit-if-changed --output=none lib/features/kid_home test/features/kid_home` | ✅ 36 committed files 0 changed (the 1 "changed" is the untracked in-flight file) |
| `flutter test --timeout 120s` over the six committed feature files | ✅ `00:08 +258 ~1: All tests passed!` (the `~1` is K01's pre-existing `K01-BUG-7` park at `k01_bugs_test.dart:569`) |
| `flutter test --timeout 120s test/features/kid_home` | ⚠️ `+449 ~1 -2` — **both failures are in the untracked in-flight file only**, see §In-flight work |
| scope | ✅ `git diff main...HEAD --name-only` touches only `app/lib/features/kid_home/presentation/**`, `app/test/features/kid_home/**`, `docs/screens/K02/**`. No `core/`, no `app/`, no other feature, no `tools/screens/`, no `analysis_options.yaml` |
| suppressed | ✅ no `skip: true`, no `@Skip`, no `ignore_for_file` / `// ignore:` in the five K02 test files (only the prose mention at `k02_bugs_test.dart:6`) |
| fonts / clock / trial | ✅ no `google_fonts`/`GoogleFonts`, no `DateTime.now()` in the view, bloc or K02 tests, no `subscription_status` write, no new ids |

## Independently verified (re-read, not taken on trust)

* **ARCHITECTURE** — feature-first intact: `domain/` and `data/` are
  untouched (`KidHomeRepository.verifyPin` already exists on `main`, so the
  iteration-1 code never needed a data edit); one bloc per feature as
  `ARCHITECTURE.md:85` and the route table at `:140` (`/kid-pin` →
  `KidHomeBloc`) prescribe; DI (`kid_home_di.dart`) and routes untouched. K02
  adds one event + one handler + three state fields to the shared feature
  bloc rather than a new `KidPinBloc` — that is the foundation's shape
  (`kidHomeRoute` builds `GetIt.instance<KidHomeBloc>()`), so the screen
  cannot deviate without editing shared files RULES §1 forbids.
* **One-shot correctness (re-derived, not assumed)** — `copyWithLoaded`
  builds through the **constructor** (`kid_home_state.dart:227-240`), whose
  default clears `pinPassed`, while `pinChecking`/`pinWrongNonce` are carried
  explicitly; so a home-stream emission mid-check neither swallows the outcome
  nor double-fires the navigation. `_onPinSubmitted` guards re-entry with
  `state.pinChecking`, builds its outcome from the state at completion time,
  and the route-level `BlocProvider(create: …)` gives every `/kid-pin` mount a
  fresh bloc, so a stale `pinPassed` cannot survive into a later visit. All
  three properties are pinned by the 13 bloc tests in the K02 group.
* **Error handling / Children's Code** — a `verifyPin` throw reads as the
  wrong-PIN path (never the failure card, never `status: failure`) and the
  roster stays usable; `_KidFailure`'s `Try again` restarts the load through
  the `_homeSub` single-flight guard, so a burst cannot stack subscriptions.
  The view never renders `state.errorMessage`, so no raw `toString()` of an
  exception can reach a child's screen. No lockout, no attempt counter copy,
  no shaming: unlimited retries and `Forgot it? Just ask a grown-up.` — the
  right register for this age group.
* **No analytics / ads / network / identifiers** — `grep` over
  `lib/features/kid_home/` finds no `print`, `debugPrint`, `dart:io`, `http`
  or analytics call. No `£` and no dates render on this screen (DATA OVER
  MOCKS / PERIODS rules N/A; the only DB fact it shows is the child's
  nickname, and 1234 is pinned by the DB-backed repository test).
* **Performance** — the view holds no `StreamSubscription`,
  `Timer` or `AnimationController`; the only async hop is one post-frame
  callback. The bloc's two long-lived subscriptions (`_homeSub`,
  `_profilesSub`) are cancelled in `close()` (`:289-296`) and K02 adds no
  third. No rebuild storm: on `/kid-pin` nothing writes to the DB, so the home
  stream does not tick while the screen is up, and the three
  `listenWhen`-narrowed listeners cost nothing per frame. `_entered` is capped
  at 4. Const usage is right: the whole fallback subtree (`_KidLoading`,
  `_KidFailure`, `_NoActiveChild`, `_BottomInset`) is const-constructible, and
  the loaded body is the one part that cannot be.
* **Design system** — no invented component and no hard-coded colour: every
  colour comes from `context.nest`, spacing from `NestSpacing`, radii from
  `NestRadii`, metrics from `NestDevice`. The only shape literal introduced
  this iteration is `avatarDisc = 128`, and it is a named `static const` with
  its `.k2-ava` CSS provenance rather than a bare number. `NestKeypad(fit:
  NestKeypadFit.shrinkWrap)`, `NestPinDots`, `NestIconButton`, `NestLockButton`,
  `NestAvatar`, `NestKidButton`, `KidScope`, `NestStatusBar` and
  `showNestToast` are all reused, not re-implemented.
* **Copy — character-by-character against `K02-pin.html`** — `NESTILING`
  (`:37`), `Hi Maya! Enter your secret code` with **no** trailing full stop
  (`:38`), `Forgot it? Just ask a grown-up.` with one (`:42`), `aria-label`
  `Back` / `Grown-ups` (`:32`) and `Delete` (`:41`) → `Digit N`. The two
  states the design does not draw are also right: `"Let's try again."` and
  `"That didn't work. Try again."` use the **straight** apostrophe, which is
  what the design source itself uses (`K03-kid-home.html:50`,
  `design-system.html:126`) — no curly/ASCII mismatch. The `Hi $nickname!`
  interpolation reproduces `Hi Maya!` from the DB row.
* **Accessibility** — every interactive node advertises
  `SemanticsAction.tap`: `Back` (`NestIconButton`), `Grown-ups`
  (`NestLockButton`), each digit and `Delete` (`Semantics(button: true,
  onTap:)` in `nest_keypad.dart:199`), and the fallback `Try again` /
  `Choose`. The PIN dots stay label-only and non-interactive, and while a
  check is in flight the label becomes `Checking your code`
  (`ExcludeSemantics` around `NestPinDots`). `NestAvatar` returns
  `ExcludeSemantics` when no `semanticLabel` is passed, so the initial letter
  is not read as a stray "M" and the name is announced by the greeting below
  it. 13 `SemanticsAction.tap` assertions across the two K02 test files, and
  `performAction` drives real state/DB transitions.
* **BOTTOM EDGE / ALIGNMENT / KID BACKGROUND** — verified on the iteration-4
  shots read this stage (`ui/app_light_4.png`, `ui/app_dark_4.png`) against
  both design PNGs: the shared meadow runs to the physical edge with no
  coloured strip under it (K02 paints no bar), 20 px gutters on both sides,
  the centred column, the lock at the right edge aligned with the keypad
  grid's right edge, and the dark pair geometrically identical to the light
  pair. `KidScope` supplies the sky + hills; no local meadow. The only
  differences are the ones the rules exclude: the OS-drawn status bar, the
  design's 2-filled dot mock (the app correctly starts empty), and the
  design's home-indicator pill (the OS draws the real one).
* **BOTTOM-EDGE inset asymmetry — checked** — the loaded body reserves only
  `MediaQuery.viewPaddingOf(context).bottom` while the three fallbacks use
  `max(viewPadding.bottom, NestDevice.homeH)` (`_BottomInset`). That is
  deliberate and correct (the fallbacks centre their content, so the design's
  34 px floor keeps the block off the home indicator on a device that reports
  no inset), and the loaded path is a `ListView` whose last item scrolls under
  the indicator only as content demands.

## Findings

### 1. [minor] `kidAvatarInitial` is now a feature-local duplicate of the shared helper that has landed on `main`

`app/lib/features/kid_home/presentation/widgets/kid_style_helpers.dart:48-68`
(calls at `kid_pin_view.dart:168`, `kid_home_view.dart:364`,
`profile_tile.dart:94`).

`main` now carries
`app/lib/core/design_system/components/nest_avatar_initial.dart`
(`nestAvatarInitial`) merged in `9eea253` ("grapheme-safe avatar initials"),
and it has **already migrated `kid_home`** — `main:…/kid_home_view.dart:364`
and `main:…/profile_tile.dart:94` both call `nestAvatarInitial`. The two
contracts already differ: the shared one trims and returns `fallback` for a
whitespace-only name, the local one returns the raw first code point
(`kidAvatarInitial('  Bee') == ' '`). `ORCHESTRATOR_NOTES.md` (12:00)
anticipated exactly this — "keep your own fix; switch to `nestAvatarInitial`
once it is on main" — so the interim state was sanctioned and the code is
correct today; the duplication is the finding, not the behaviour.

**Fix.** Delete `kidAvatarInitial` and its two `TODO(K02)` blocks
(`:59-64`), call `nestAvatarInitial(nickname)` at the three sites (the two
K01/K03 sites will resolve automatically once the loop merges `main`),
and update the interim contract probe that pins the local behaviour
(`kid_avatar_initial_test.dart:74`, `expect(kidAvatarInitial('  Bee'), ' ')`
→ `'B'`), or drop layer 1 of that file entirely once
`core/design_system/avatar_initial_test.dart` (on `main`) covers the contract.
Keep the two render proofs — they are behaviour, not implementation.
`SHARED_REQUEST.md` #3's `kid_home` rows then become "✅ shared".

### 2. [minor] The `NestKeypad(enabled:)` ask cites the wrong SHARED_REQUEST item, so it never reaches the orchestrator

`app/lib/features/kid_home/presentation/views/kid_pin_view.dart:303-306`.

The `TODO(K02)` says "SHARED_REQUEST #1 — a shared `NestKeypad(enabled: …)`
(as `NestIconButton` has)", but `SHARED_REQUEST.md` **#1** is
*`NestType.kidSay` / `NestType.kidMark`*. Grepping the file for `enabled`
finds nothing: the ask lives only in a code comment, which no orchestrator
batch reads. Finding 3 below is therefore both unresolved *and* invisible.

**Fix.** Correct the reference (`SHARED_REQUEST #4`) and add the item to
`docs/screens/K02/SHARED_REQUEST.md` in the RULES §2 shape: need = a
disabled keypad must report `enabled: false` and drop the ripple while every
key keeps its own semantics node (the `AbsorbPointer` experiment and why it
was reverted); files = `app/lib/core/design_system/components/nest_keypad.dart`
+ a design-system test; blocks = no.

### 3. [minor] Carried from iteration 2 — keys keep advertising `tap` (and rippling) while a check is in flight

`kid_pin_view.dart:293-312`.

RULES §8: "a disabled control passes no tap and reports `enabled: false`".
`awaiting` reaches only the dots; `NestKeypad` keeps `InkWell` + `Semantics(
button: true, onTap:)` and the callbacks early-return. The behaviour is safe
— a pointer tap *and* a VoiceOver/TalkBack activation both change nothing, and
four digits can never be submitted mid-check — and the iteration-4 rationale
for rejecting `AbsorbPointer` (it deletes the keys' semantics nodes, which
would break the opposite half of RULES §8 and the mid-check `Digit 9` probe)
is correct and now documented in the code. It stays open only because the
honest fix is `NestKeypad(enabled: …)` in `core/`, which RULES §1 puts out of
this screen's reach. Not an accessibility blocker; a disabled-*looking*
control. Re-file per finding 2.

### 4. [minor] `context.read` runs before the `mounted` guard in the no-PIN post-frame callback

`kid_pin_view.dart:75-89` — `:78` reads the bloc, `:80` checks `mounted`.

`addPostFrameCallback` fires after the frame; if the route is popped inside
that same frame the element is deactivated and `context.read` throws
"Looking up a deactivated widget's ancestor is unsafe", which turns a
harmless navigation race into a red frame. No shipped flow reproduces it
today (`6_bugs.md` records the same observation), but the guard is already
there — it is just in the wrong order.

**Fix.** Move the check first:

```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (!mounted) return;
  final current = context.read<KidHomeBloc>().state;
  if (current.child != null && !current.child!.pinSet) {
    context.go(KidHomeRoutePaths.home);
  } else {
    setState(() => _noPinHandled = false);
  }
});
```

### 5. [minor] Carried from iteration 1/2 — the two local type styles

`kid_pin_view.dart:246-252` (`.mark`) and `:266-273` (`.say`) hard-code
`fontFamily: 'Nunito'` + weight/size/height. Both are metric-identical
stand-ins for `NestType.kidMark` / `NestType.kidSay`, which do not exist in
the shared token file and which `core/` is the only place to add — SHARED_REQUEST
#1, still open, deliberately not patched locally. `.mark`'s
`letterSpacing: 1.28` is correctly applied at the call site per the LETTER
SPACING rule, and `.say`'s explicit `letterSpacing: 0` documents the
post-`fd92d95` default rather than re-adding Material tracking. Pixels are
Δ 0 (measured this iteration: all bands within ±1 px).

## Carried-forward notes (deliberately not findings)

* The failure card's `PipAvatar(style: mochi, stage: 1, size: 140)` is the
  shared no-child fallback: `_onStreamFailed` only sets `failure` when
  `state.child == null`, and `_onProfilesFailed` only when profiles **and**
  child are both empty, so on this screen there is never a child row whose
  `pip_style`/`skin`/`accessory`/`stage` could be used. The PIP rule is
  satisfied as far as the screen can satisfy it; the 140 px size matches the
  same fallback in K01/K03/`today`, so it is a shared-token candidate rather
  than a K02 literal.
* The PIN is advisory: `/kid-home` itself carries no guard, so P17 (the
  parental gate) is the real boundary. Shared routing decision, unchanged by
  this diff.
* No `NestChipWrap` row and no `text-wrap: balance` heading on K02 — the
  design's CSS has neither, so both rules are correctly N/A rather than
  skipped.
* `NestKeypad` pitch is shared-owned and already merged; K02 opts in with
  `fit: shrinkWrap` and re-spaces nothing locally, per ORCHESTRATOR_NOTES
  07:13. The iteration-4 shots hold the iteration-3 bands (mean diff 0.95%
  light / 1.03% dark, every band unchanged except the OS status bar).

## In-flight work observed (process — not findings against this diff)

While this stage ran, a sibling stage wrote into the same worktree. None of
it is in `git diff main...HEAD`, and none of it is counted against the
verdict (PROCESS rule), but the loop should know before the next build/test
gate:

* **Untracked `app/test/features/kid_home/kid_avatar_initial_test.dart` is red
  (2 failures) and unformatted.** (a) *K01 profile tile renders a non-BMP
  nickname…* fails with `Bad state: GetIt: Object/factory with type
  ThemeModeController is not registered inside GetIt` — the file imports
  `../../test_scope.dart` but never calls `setUpTestScope()`. (b) *no call site
  indexes a name with [0]* fails on its own helper: the regex matches the
  doc comment `` `nickname[0]` indexes UTF-16 **code units** `` at
  `kid_style_helpers.dart:50`. Either exclude comments or reword that line.
  The file also produces the 3 `flutter analyze` infos and the one
  `dart format` diff above.
* `app/test/features/kid_home/k02_bugs_test.dart` and `docs/screens/K02/5_ui.md`
  have uncommitted edits; `ui/app_{light,dark}_4.png` and the two iteration-4
  compare sheets are new and untracked. The `5_ui` diff only retitles the file
  to iteration 4 and restates the bands (0.95% / 1.03%, all bands equal to
  iteration 3 except band 0), which matches the shots I read.
* `main` has moved past this branch (`b1e9a7f`, `9eea253`); merging it is the
  loop's job and is what finding 1 waits on.

## Verdict

No blocker and no major finding. The iteration-4 delta is small, in-scope and
correct: the emoji-initial crash class is closed for the whole `kid_home`
feature, the last two token duplications in the K02 view are gone, and the
two token-dependent test predicates still bite. Re-verified independently on
this iteration: gates clean on every committed file (`+258 ~1` green over the
six feature files), scope clean, `analysis_options.yaml` untouched, no skips
or ignores, the design system reused throughout with no invented colours or
sizes, copy character-exact against `K02-pin.html`, every control operable
by VoiceOver/TalkBack, no analytics/ads/network/clock/trial violations, and
the iteration-4 light and dark shots matching both design PNGs with the meadow
running to the physical edge and no misalignment. All five findings are
minor: a shared-helper duplicate that has landed on `main`, one mistyped
cross-reference hiding a real shared ask, the carried disabled-keypad
semantics honesty, a one-line `mounted`-ordering hardening, and the two
shared typography tokens. None blocks landing.

VERDICT: PASS
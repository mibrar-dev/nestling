# 2b BUILD UI — K02 Kid PIN (`kid_home`, iteration 4, FIXES)

Scope: `app/lib/features/kid_home/presentation/views/**`,
`presentation/widgets/**`, and the `kid_home` test files whose names contain
`view`/`widget`. No domain/, data/ or bloc/cubit file touched (the logic
builder owns those); no simulator booted, installed on, screenshot or driven
(SIMULATORS rule).

## CONTRACT CHANGES (re-read from `2a_build_logic.md` before finishing)

None. `2a` closed with "None" and nothing has landed since: the event/state
names (`KidHomePinSubmitted`, `pinChecking`/`pinWrongNonce`/`pinPassed`) and the
semantics the UI relies on are unchanged, and my edits touch no bloc surface.

## FIXES_3.md — items this stage had to fix (mine)

`FIXES_3.md` is stage 3's report verbatim. Its one open product defect is
**K02-TEST-BUG-A (major)**, the avatar-initial crash class, and it is a UI-layer
defect in files I own — so this iteration closes it inside `kid_home` rather
than leaving a live whole-screen crash on two sibling kid routes.

1. **K02-TEST-BUG-A — the crash class, closed for all of `kid_home`.**
   `nickname[0]` indexes UTF-16 **code units**, so a nickname opening with a
   non-BMP character (emoji, regional-indicator flag, many CJK extensions)
   yields an unpaired surrogate and `String.toUpperCase()` then throws
   `ArgumentError: Invalid argument(s): string is not well-formed UTF-16`
   while laying out the avatar. The frame does not degrade — **the whole
   screen fails to build**. Stage 3 re-proved it live on `/who-is-playing`
   and `/kid-home` for the P05-reachable nickname `🐝 Bee` (P05 has no
   `inputFormatters`, ≤ 24 characters, no character filter), and correctly
   declined to patch it locally because the *permanent* fix is shared
   (`SHARED_REQUEST.md` #3, `core/`, out of reach under RULES §1).

   **Fix, in my owned paths:** one grapheme-safe helper
   `kidAvatarInitial(String nickname, {String fallback = '?'})` in
   `presentation/widgets/kid_style_helpers.dart` — the file that already
   exists to stop these switches being duplicated across `kid_home` views —
   implemented with `nickname.runes.first`, and all **three** `kid_home` call
   sites now route through it:

   | site | before | after |
   |---|---|---|
   | `views/kid_pin_view.dart` (`_KidPinBody`) | `runes.first` (iteration-1 local fix) | `kidAvatarInitial(nickname)` |
   | `views/kid_home_view.dart` (`KidHomeHeader`) | `nickname[0].toUpperCase()` ❌ | `kidAvatarInitial(nickname)` |
   | `widgets/profile_tile.dart` | `nickname[0].toUpperCase()` ❌ | `kidAvatarInitial(child.nickname)` |

   `runes` is the right primitive here, and deliberately *not* the
   `characters` package: a code point can split a grapheme cluster (a
   ZWJ emoji renders as its first element) but it can **never** produce the
   unpaired surrogate that makes `toUpperCase()` throw, so the frame always
   builds. `characters` is not a declared dependency of this app
   (`pubspec.lock` has it transitively via Flutter), and reaching for a
   transitive package would itself trip
   `depend_on_referenced_packages`. The one behavioural consequence to state
   plainly: for `🐝 Bee` the avatar initial is now `🐝` (the emoji), not `?` or
   a replacement glyph.

   Two render tests pin it from the outside, both driven off a real Drift
   write of `🐝 Bee` onto Maya, both asserting `takeException()` is null **and**
   that the initial is the emoji itself (so a future "fix" that silently
   substitutes a placeholder cannot pass):
   `kid_pin_view_test.dart` → `K02 iteration 3 fixes / a nickname opening with
   an emoji still builds the frame` (also asserts the copy still reads
   `Hi 🐝 Bee! Enter your secret code` and the keypad is mounted), and
   `kid_home_view_test.dart` → new group `K03 avatar initial
   (grapheme-safe)`.

   The remaining four sites are in `features/family/**` and
   `features/today/**` — other features' loops, and `SHARED_REQUEST.md` #3
   now records them as the remaining ask with the helper's eventual shared
   home. K02's own sites no longer need the orchestrator to be crash-safe.

   `kidAvatarInitial` takes a `fallback` parameter so the parent row at
   `today_loaded_body.dart:363` can keep its distinct `'S'` default when that
   feature's loop points it at the shared helper; that call site still uses
   `[0]` and is recorded, not patched.

2. **Two pre-existing test failures in my owned files, fixed (they were red on
   the merged tree before I started — confirmed by stashing my work and
   re-running).** Both were `tester.pageBack()` against the P17 gate:
   `the lock opens the grown-up gate and keeps the typed code` and
   `a rapid lock double tap pushes exactly one gate` failed with
   `Found 0 widgets with type "CupertinoNavigationBarBackButton"` /
   `One back button expected on screen`. Since the P17 merge the gate has **no
   AppBar back button** — its only exit is the 56 px ghost `Back to Pip`
   (`parental_gate_view.dart`), which is also what a kid actually taps, so the
   test was asserting against a widget the screen no longer has.
   **Fix:** the post-merge pattern already used by the sibling suites
   (`k01_bugs_test.dart:720`, `k03_bugs_test.dart:1063`) — tap `Back to Pip`
   when present, fall back to `pageBack()` if the gate ever regrows an AppBar.
   `kid_pin_view_test.dart` gets it as a documented `_leaveGate(tester)`
   helper (two call sites, plus the pump/settle pair they shared);
   `k02_bugs_test.dart:768` gets the inline form with the same comment and
   rationale. **No product behaviour changed** — this is purely the test
   driving the exit the design offers.

   Not listed in `FIXES_3.md` (stage 3's own gate run passed before the P17
   merge landed), but it is in my owned files and it was red, so it is fixed
   here rather than handed on.

3. **Parked/skipped bug tests.** None to un-skip: `k02_bugs_test.dart` carried
   no `skip:` line (K02-BUG-1..5 all ran), and the only `skip: true` in the
   feature is `k01_bugs_test.dart:569`, which is K01's parked proof and not
   K02's to land from this loop.

## Also closed — `4_review.md` findings I own (iteration-3 review, still open)

* **Finding 1 [minor] — `.mark` pill hard-coded `999`.** `NestRadii.allPill` is
  the token and every other pill in `lib/` uses it; this was the last
  `circular(999)`. Now `borderRadius: NestRadii.allPill`, and the five
  mirroring predicates in `kid_pin_view_test.dart` moved to the token too.
  Verified the tests still bite: with the radius deliberately changed to 24,
  exactly the three shape/geometry tests fail (pill-as-SHAPE, gutter
  invariants, dark parity), and restoring it returns them to green — so the
  suite is asserting the pill's background rect, not just where its text lands
  (UI CHECK MEASURES SHAPES rule).
* **Finding 4 [minor] — bare `128` avatar-disc literal.** Hoisted to
  `_KidPinBody.avatarDisc` with the `.k2-ava` CSS provenance in the doc
  comment. (I did not try to reference the constant from the test: the class is
  private, and a test cannot see it.)
* **Finding 5 [minor] — `SHARED_REQUEST.md` status line stale.** Now reads
  `#1 and #3 open, #2 done`, item #2's follow-up list is marked done with what
  actually happened, and item #3's call-site table is refreshed with per-site
  status instead of stale line numbers.
* **Finding 6 [minor] — the two local type styles.** Not fixable here:
  `NestType.kidSay`/`kidMark` are `core/` (SHARED_REQUEST #1). The local
  stand-ins are metric-identical (pixels already Δ 0) and their `TODO(K02)`
  markers now name the missing token. The iteration-4 tracking sweep still
  holds: only `.mark` carries 1.28, every other string 0.
* **Finding 7 [minor] — K02-BUG-1's crash class live outside K02.** Closed for
  all three `kid_home` sites by item 1 above; the four `family`/`today` sites
  remain in SHARED_REQUEST #3.

## Finding 3 [minor] — keys during an in-flight check: tried, reverted, recorded

The review asked for `AbsorbPointer(absorbing: awaiting)` around the keypad
while a check runs, so a disabled control would not ripple (RULES §8). I
implemented it, and it **broke a real invariant**: `AbsorbPointer` removes its
subtree's semantics nodes, so `find.bySemanticsLabel('Digit 9')` found 0 widgets
and `the dots count up, then announce the in-flight check` — the test that
proves the entry limit — could no longer even address the key it taps to prove
the key is inert. That is the same rule fighting itself: RULES §8 also requires
every key to keep advertising `SemanticsAction.tap`, and the mid-check probe
taps by label on purpose.

So it is reverted, the behaviour is unchanged (both callbacks early-return on
`_awaiting`, so a pointer tap *and* a VoiceOver/TalkBack activation both change
nothing), and the code now carries the full rationale plus a
`TODO(K02)` naming the real fix: a shared `NestKeypad(enabled: …)` in the
manner of `NestIconButton`, which would report `enabled: false` and drop the
ripple while keeping every key node addressable. Recorded in
`SHARED_REQUEST.md` #1's orbit for the orchestrator. Not re-attempted blind.

## Touches this iteration

Product (`app/lib/`):

* `features/kid_home/presentation/widgets/kid_style_helpers.dart` — new
  `kidAvatarInitial()`.
* `features/kid_home/presentation/views/kid_pin_view.dart` — helper import +
  use, `avatarDisc` constant, `NestRadii.allPill`, the in-flight-keypad
  rationale comment.
* `features/kid_home/presentation/views/kid_home_view.dart` — helper use at
  the header avatar initial.
* `features/kid_home/presentation/widgets/profile_tile.dart` — helper use at
  the tile avatar initial.

Tests (`app/test/features/kid_home/`, all mine under the name rule):

* `kid_pin_view_test.dart` — new emoji-nickname test; `_leaveGate()` helper
  replacing two `pageBack()` calls; five `NestRadii.allPill` predicates.
* `kid_home_view_test.dart` — new `K03 avatar initial (grapheme-safe)` group.
* `k02_bugs_test.dart` — `pageBack()` → `Back to Pip` at line 768.

Docs: this file, `SHARED_REQUEST.md`.

## Gates this iteration (`app/`)

| gate | result |
|---|---|
| `dart format --set-exit-if-changed --output=none lib/features/kid_home test/features/kid_home` | ✅ Formatted 36 files (0 changed) |
| `flutter analyze lib/features/kid_home test/features/kid_home` | ✅ No issues found! |
| `flutter test --timeout 120s test/features/kid_home/kid_pin_view_test.dart test/features/kid_home/k02_bugs_test.dart` | ✅ **91/91** (58 + 33) |
| `flutter test --timeout 120s test/features/kid_home/kid_home_view_test.dart` | ✅ **88/88** |
| `flutter test --timeout 120s test/features/kid_home` (whole feature, including the K01/K03/sibling files) | ✅ **443 passed, ~1 skipped**, 11 s |

The `~1` skip is K01's parked `k01_bugs_test.dart:569`, not a K02 file.
Every run used `--timeout 120s` and the whole feature finishes in ~11 s, well
inside the 10-minute ceiling and the 10:32 hang mandate (the individual K02
files: 4 s and 5 s). I did **not** run the whole-app `flutter test` or the
simulator — the integrator owns both, and SIMULATORS restricts every stage but
5_ui to BC440E48.

Geometry/copy/layer audit against the plan and the design, no simulator:

* Design Y anchors unchanged by this iteration (say 285, dots 340, keypad rows
  393/475/557/639, caption 731; gutters 20; avatar disc x 131–259, y 109–237)
  — the pill-radius and constant hoists are value-preserving, and the
  geometry tests pin all of them. No new hard-coded colour or size: the pill
  moved *to* a token, the 128 is a named screen-local CSS value with its
  provenance in the doc comment.
* Copy untouched and still ASCII-exact against `K02-pin.html`:
  `Hi {nick}! Enter your secret code`, `NESTLING`, `Forgot it? Just ask a
  grown-up.`, `That didn't work. Try again.` The only new non-ASCII anywhere in
  my diff is the `🐝 Bee` **test fixture** — deliberately a P05-reachable name,
  never product copy.
* PIP rule N/A on this screen (avatar only; the `failure` fallback card keeps
  the shared no-child `PipAvatar`). No `text-wrap: balance` in K02's CSS, so
  no `NestBalancedText`. No chip rows. No `google_fonts`, no `DateTime.now()`,
  no new ids, clock N/A.
* `analysis_options` untouched; no ignores, no skips added.

## LEFT FOR NEXT ITERATION

* `NestType.kidSay` / `NestType.kidMark` (SHARED_REQUEST #1) — orchestrator.
  `core/` is out of reach; K02's local stand-ins are metric-identical.
* The four remaining `nestAvatarInitial` call sites in `features/family/**`
  and `features/today/**` — other features' loops (SHARED_REQUEST #3).
* A shared `NestKeypad(enabled: …)` so an in-flight keypad can report
  `enabled: false` honestly without dropping its semantics nodes (finding 3
  above) — orchestrator, `core/`.
* **Not re-measured this iteration:** the design PNGs. No stage but 5_ui may
  boot a simulator, so the pixel re-check of the pill radius against
  `K02-pin.png` belongs to the next 5_ui. Value-preserving by construction
  (`999` == `NestRadii.pill` == `allPill`), and 5_ui iteration 3 already
  measured this screen inside ±2.
* Whole-app `flutter test`, `shot.sh`, `compare.py`: integrator.

VERDICT: PASS
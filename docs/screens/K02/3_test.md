# 3 TEST (iteration 3) — K02 Kid PIN (`kid_home`, `/kid-pin`)

Scope: `app/test/features/kid_home/**` + this file (RULES §1). **No product
code was touched by this stage.** No simulator was booted, installed on,
screenshot or driven (SIMULATORS rule).

The iteration-3 build (`2_build.md`) changed exactly one behaviour: K02-BUG-5's
fix released the no-PIN auto-advance latch on the *declined* path with a
`setState(() => _noPinHandled = false)` inside the post-frame callback
(`kid_pin_view.dart`). Everything else was already-covered territory, so this
stage (a) pinned that new statement from an independent harness and (b) kept
the earlier suites honest after the `main` merge.

## Tests added — `kid_pin_view_test.dart` (54 → **57**)

Group `K02 iteration 3 fixes`, driven by a scripted `_PairRepo` (a
`KidHomeRepository` whose `watchHome`/`watchActiveChild` share one broadcast
controller, so a test can push two children inside a single turn — the only way
to reproduce a *declined* auto-advance; real awaited writes cannot land two
children in one frame). Fixtures are the real seeded rows, read from the live
repository before the fake takes its place, so "Maya has a PIN, Leo does not"
stays a database fact rather than a literal.

| Test | What it pins |
|---|---|
| `a declined auto-advance leaves a live PIN screen` | Leo (no PIN) → Maya (PIN) in one turn declines the navigation (K02-BUG-3's protection). Then: the screen stays on `/kid-pin` with the greeting **and a keypad**, it stays there for 600 ms more (**the released latch must not become a PIN bypass**), and it is fully interactive — a wrong code nudges, the right code (`1234`) reaches `/kid-home` |
| `the released latch advances the returning no-PIN child` | the fix's own promise: decline, then Leo comes back → `/kid-home`, and K02's own fallback loader (`Loading your secret code`) is gone from the tree |
| `repeated alternation never advances a PIN child` | three Leo→Maya alternations keep `/kid-pin` every time; only the final Leo advances — an over-released latch would leak home mid-sequence |

Helpers added: `_settleK02` (two pump/advance rounds — `pumpAndSettle` cannot
be used because the destination screens carry an infinite
`CircularProgressIndicator`), `_seededRoster`, `_useRepo`, `_PairRepo`.

**Why two settle rounds** (found by a real failure here, worth recording): with
one round, `expect(find.bySemanticsLabel('Loading your secret code'),
findsNothing)` failed right after `currentPath == '/kid-home'` — the outgoing
K02 route is still mounted for the length of its page transition, and the
no-PIN branch renders `_KidLoading`. The path assertion is not evidence that
the previous screen has left the tree; the settle has to outlast the
transition. Same trap the iteration-2 build hit when it retargeted that
assertion from a spinner to K02's own label.

Carried from iterations 1–2 and re-verified unchanged after the merge: the
matrix (light/dark × 320/390/430 × scale 1.0/1.3), copy parity read from
`K02-pin.html`, tap targets ≥ 56, every-tap navigation, the design-anchor
geometry (key columns 77/159/241, rows 393/475/557/639, caption 731, say 285,
dots 331, back/lock 47 ±2), the tracking sweep, the three fallback-state inset
tests and the long-nickname matrix.

No new bloc test: `2a_build_logic.md` records that FIXES_2 needed no
logic-layer change, and the bloc contract this screen depends on is already
pinned end to end — `KidHomePinSubmitted` paths (13 tests in the K02 group of
`kid_home_bloc_test.dart`) plus the DB-backed `Leo has no PIN so any code
auto-passes` in `kid_home_repository_test.dart`, which is the rule that makes
the no-PIN auto-advance legitimate.

## Gates

```
dart format --set-exit-if-changed --output=none test/features/kid_home lib/features/kid_home
Formatted 36 files (0 changed) in 0.20 seconds.

flutter analyze
Analyzing app...
No issues found! (ran in 3.0s)

flutter test --timeout 120s test/features/kid_home/kid_pin_view_test.dart
00:04 +57: All tests passed!

flutter test --timeout 120s test/features/kid_home/kid_pin_view_test.dart --plain-name "K02 iteration 3 fixes"
00:01 +3: All tests passed!

flutter test --timeout 120s test/features/kid_home
00:16 +441 ~1: All tests passed!

flutter test --timeout 120s                    (whole app)
01:37 +3242 ~2: All tests passed!
```

Every run used `--timeout 120s` (TEST TIMEOUTS rule). No K02 file comes close to
it: the whole feature directory is 16 s, the largest K02 file 4 s. The `~2`
skips are the sibling parks (`K01-BUG-7`, P12) — `k02_bugs_test.dart` carries
none.

**One in-flight sibling failure, resolved before the gates closed.**
`k02_bugs_test.dart: kid mode + expired trial: /kid-pin lands on the gate`
failed for two of my runs while that file was being edited by the bugs stage
(mtime within seconds of each run; it contained `SCRATCH` debug prints). I did
not touch it. Instead I verified the behaviour **independently** with a
throwaway probe (since deleted): expiring the trial through `AppSession` before
pumping gives `status=expired`, `trialExpired=true`, and `/kid-pin` correctly
lands on `/parental-gate` with no exception — so the **TRIAL** guard and the
router redirect in `lib/app/router.dart:126-133` are sound, and the red was the
sibling harness's own ordering, not a product defect. After their edit landed,
the test is green.

## Bugs

### Still open — carried from iteration 2, re-verified after this merge

**K02-TEST-BUG-A — major — the K02-BUG-1 crash class is still live on K01 and
K03.** `app/lib/features/kid_home/presentation/widgets/profile_tile.dart:96`
and `app/lib/features/kid_home/presentation/views/kid_home_view.dart:364` still
index UTF-16 code units (`nickname[0].toUpperCase()`). Re-probed this stage
after the `main` merge: `/who-is-playing` and `/kid-home` both throw
`ArgumentError: Invalid argument(s): string is not well-formed UTF-16` while
laying out the avatar initial for the seeded nickname `🐝 Bee`, which P05
accepts (no `inputFormatters`, ≤ 24 characters, no character filter). K02's own
site is fixed (`kid_pin_view.dart:164`, `nickname.runes.first`).

Still filed as `docs/screens/K02/SHARED_REQUEST.md` **#3** (seven sites, four
features) and still owned by the orchestrator: the fix is a
grapheme-safe `nestAvatarInitial()` helper in `app/lib/core/design_system/**`,
which RULES §1 puts out of reach for any screen agent, and the two live
`kid_home` files belong to the K01/K03 loops. Not patched here — recorded, as
the brief requires.

### Verified fixed by this iteration's build

K02-BUG-5 (latch released on decline) — now pinned three ways from my harness
(§Tests added), and the bugs file's own proof runs un-skipped.

### Harness note (cost me one 10-minute hang — the rule from iteration 2)

Two `await tester.runAsync(…)` cycles inside a single `testWidgets` deadlock
the binding, even with `disposeApp` in between. I reproduced it in a throwaway
probe this iteration before splitting it into two single-cycle tests. The rule
is already written into `ORCHESTRATOR_NOTES.md` (10:32), the file header of
`k02_bugs_test.dart` and §5 of my iteration-2 notes — keep honouring it in any
new probe, and prefer one cycle per test over a loop of cycles.

## Notes for the next iteration

1. **K02 is behaviourally complete and fully covered**: 57 tests in the view
   suite, 13 in the bloc suite, 31 in the bugs suite, design geometry pinned at
   unit level *and* verified pixel-wise by 5_ui. Further test work should go to
   the shared items, not to this screen.
2. **The only outstanding defects on this screen's feature are shared-file
   ones** (`nestAvatarInitial`, `NestType.kidSay`/`kidMark`). Both need an
   orchestrator decision, not a screen edit.
3. When a route-change assertion matters, settle past the page transition
   (`_settleK02`), and remember a path assertion is not proof the previous
   route left the tree.
4. `find.bySemanticsLabel` still needs a `RegExp` for merged nodes (dots, toast).

VERDICT: FAIL
# 2 BUILD (INTEGRATE) — K02 Kid PIN (`kid_home`, iteration 4)

Merge of the two FIXES_3 builders on top of the iteration-3 checkpoint
(`01865c9`) with `main` already merged (`9a1f16d`). The halves compiled,
analysed and passed as merged, so the only work was running the gates and
re-checking the merge for regressions. **No integration fix was required.**

## Summary of 2a (logic) — no code change

`presentation/bloc/**`, `domain/**`, `data/**` untouched; the iteration-1
contract (`KidHomePinSubmitted`, `pinChecking`/`pinWrongNonce`/`pinPassed`)
still holds and no new contract was needed.

FIXES_3 triage found **no logic-layer defect**: K02-BUG-5 was already closed
by the iteration-3 UI build and its behaviour is pinned end to end by the 13
`KidHomePinSubmitted` bloc tests plus the DB-backed no-PIN rule (no new bloc
test needed); K02-TEST-BUG-A's remaining sites are UI-builder-owned paths
whose permanent fix is SHARED_REQUEST #3 (`core/`, orchestrator); the
`k02_bugs_test.dart` churn was a view-layer test file owned by that stage.

## Summary of 2b (UI) — FIXES_3 + the open 4_review items it also closed

Product:

1. **K02-TEST-BUG-A [major] — the avatar-initial crash class, closed for all
   of `kid_home`.** One new grapheme-safe helper
   `kidAvatarInitial(String, {String fallback = '?'})` in the existing
   `presentation/widgets/kid_style_helpers.dart` (the file that already
   exists to stop these switches being duplicated), implemented with
   `nickname.runes.first`, and **all three** `kid_home` call sites routed
   through it: `kid_pin_view.dart` (`_KidPinBody`), `kid_home_view.dart`
   (`_KidHomeBody` header) and `widgets/profile_tile.dart`. A nickname opening
   with a non-BMP character (`🐝 Bee`, accepted by P05) previously threw
   `ArgumentError: string is not well-formed UTF-16` and the **whole frame
   failed to build** on `/who-is-playing` and `/kid-home`, not just the
   avatar. Two render tests now pin it from the outside (real Drift write,
   `takeException() == null` **and** the initial is the emoji itself, so a
   placeholder substitution cannot pass): `kid_pin_view_test.dart`
   (`K02 iteration 3 fixes / a nickname opening with an emoji still builds the
   frame`) and a new `K03 avatar initial (grapheme-safe)` group in
   `kid_home_view_test.dart`.
2. **Two pre-existing red tests fixed** (`the lock opens the grown-up gate and
   keeps the typed code`, `a rapid lock double tap pushes exactly one gate`):
   they used `tester.pageBack()`, which needs a Material/Cupertino back button,
   but since the P17 merge the gate's only exit is the 56 px ghost
   `Back to Pip`. Now they drive that button (the post-merge pattern already
   used by `k01_bugs_test.dart:720` / `k03_bugs_test.dart:1063`) with a
   `pageBack()` fallback so the harness stays honest if the gate regrows an
   AppBar. No product behaviour changed.
3. **4_review findings it owns closed**: the `.mark` pill's hard-coded
   `999` → `NestRadii.allPill` (value-preserving: `NestRadii.pill = 999`,
   `radii.dart:13`), with the five mirroring test predicates moved to the
   token — the suite was verified to still bite (breaking the radius fails
   exactly the three shape/geometry tests); the bare `128` avatar-disc literal
   hoisted to `_KidPinBody.avatarDisc` with its `.k2-ava` CSS provenance; the
   stale `SHARED_REQUEST.md` status line refreshed.
4. **Finding 3 (in-flight keypad) tried, reverted, recorded**: an
   `AbsorbPointer(absorbing: awaiting)` wrapper was implemented and reverted —
   it removes the keys' semantics nodes, which contradicts RULES §8's
   "every key must keep advertising `SemanticsAction.tap`" and breaks the
   entry-limit probe that taps `Digit 9` mid-check by label. Behaviour is
   unchanged (both callbacks early-return on `_awaiting`, so a pointer tap
   *and* a VoiceOver/TalkBack tap change nothing), and the rationale plus a
   `TODO(K02)` for a shared `NestKeypad(enabled: …)` now live in the code.

## FIXES_3 / review items — done / left

| item | owner | status |
|---|---|---|
| K02-TEST-BUG-A avatar-initial crash (`kid_home`'s 3 sites) | 2b | **done** (helper + 3 sites + 2 render tests) |
| `pageBack()` vs the AppBar-less P17 gate (2 tests) | 2b | **done** (drive `Back to Pip`, `pageBack()` fallback) |
| K02-BUG-5 | 2b (iteration 3) | **done**, behaviour already pinned by the bloc tests |
| 4_review finding 1 `.mark` hard-coded `999` | 2b | **done** (`NestRadii.allPill`, tests still bite) |
| 4_review finding 4 bare `128` | 2b | **done** (`_KidPinBody.avatarDisc` + provenance) |
| 4_review finding 5 stale SHARED_REQUEST status | 2b | **done** |
| 4_review finding 7 crash class outside K02 | 2b (kid_home) | **done for `kid_home`**; the 4 `family`/`today` sites remain shared |
| 4_review finding 3 in-flight keypad | 2b | **left (shared)** — needs `NestKeypad(enabled:)` in `core/`; behaviour is already correct and recorded |
| 4_review finding 6 local `.say`/`.mark` styles | orchestrator | **left (open, shared)** — SHARED_REQUEST #1, `NestType.kidSay`/`kidMark` in `core/` |
| `nestAvatarInitial` for `features/family/**` + `features/today/**` (4 sites) | other loops | **left (shared)** — SHARED_REQUEST #3; the helper carries `fallback` so `today_loaded_body.dart`'s `'S'` default survives |

Nothing was left for this stage, and nothing was left for the integrator.

## Integration check (beyond the gates)

- **TEST TIMEOUTS rule** — every run used `--timeout 120s`; whole suite 1 m
  38 s wall, feature 12 s, no file anywhere near the ceiling. The 10:32 hang
  mandate still holds (`k02_bugs_test.dart` 5 s).
- **No contract mismatch across the halves**: 2b's edits touch no bloc
  surface; `kidAvatarInitial` is a pure view-layer helper in the feature's own
  widget file (RULES §1 scope), imported by exactly the three call sites.
- **No new skips, no ignores, no weakened assertions** — the only executable
  `skip: true` lines in the whole app are the two pre-existing sibling parks
  (`k01_bugs_test.dart:569`, `p12_bugs_test.dart:321`), matching the `~2`;
  `rg ignore_for_file|// ignore:` in `lib|test/features/kid_home` → none;
  `analysis_options.yaml` untouched. K02 test counts only grew: 91 in the two
  K02 files (was 91 at iteration 3 → 58+33 with the two new emoji proofs net of
  the refactors), 88 in `kid_home_view_test.dart`, 443 in the feature.
- **Geometry preserved** — `999` → `NestRadii.allPill` is the same value
  (`radii.dart:13`), the `128` hoist is a named constant, and the
  design-anchor test (grid x 77–313 pitch 82, rows 393/475/557/639, caption
  731, say 285, dots 331) still passes, so no vertical or horizontal drift was
  introduced for the next 5_ui to re-measure.
- **Rule spot-checks on the merged diff**: no `GoogleFonts`; no
  `DateTime.now()`; no `subscription_status` write; no new ids (IDS rule N/A);
  no `pip_stage_*.svg`; no local hills/meadow; copy untouched and still
  ASCII-exact vs `K02-pin.html` (the only new non-ASCII in the diff is the
  `🐝 Bee` **test fixture**); the pill moved *to* a token, nothing new
  hard-coded; PIP rule still N/A on the main screen (avatar only; the failure
  card keeps the shared no-child `PipAvatar`).
- **Scope**: `app/lib/features/kid_home/presentation/{views,widgets}/**`,
  `app/test/features/kid_home/**`, `docs/screens/K02/**`. No `core/`, no
  `app/`, no other feature, no `tools/screens/`. **No simulator was booted,
  installed on, screenshot or driven by this stage.**

## Gates (`app/`)

`dart format .`

```
Formatted 546 files (0 changed) in 1.79 seconds.
```

`flutter analyze`

```
Analyzing app...
No issues found! (ran in 4.1s)
```

`flutter test --timeout 120s` (whole app)

```
01:34 +3360 ~2: .../value_tour_view_test.dart: P02 value tour — owner rule: alignment dark 390dp: 20px gutters on every edge
01:34 +3361 ~2: ... P02 value tour — owner rule: alignment dark 430dp: 20px gutters on every edge
01:34 +3362 ~2: ... P02 value tour — owner rule: alignment card content shares one inner left edge
01:34 +3364 ~2: All tests passed!
```

3364 pass, 2 skipped (the pre-existing sibling parks), 0 failures, 1 m 38 s wall.

`flutter test --timeout 120s test/features/kid_home`

```
00:12 +443 ~1: All tests passed!
```

(the `~1` is K01's parked `k01_bugs_test.dart:569`)

`flutter test --timeout 120s` on the two K02 files, and on the K03 file 2b
also touched

```
00:05 +91: All tests passed!     (kid_pin_view_test.dart 58 + k02_bugs_test.dart 33)
00:05 +88: All tests passed!     (kid_home_view_test.dart)
```

**Integration fixes required: none.** The merged halves compiled, analysed
clean and passed together as delivered.

VERDICT: PASS
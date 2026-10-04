# 2 BUILD (INTEGRATE) — K02 Kid PIN (`kid_home`, iteration 2)

Merge of the two FIXES builders on top of the iteration-1 checkpoint
(`6d9d559`) with `main` already merged (`c094fd5`, which brought the shared
keypad grid `b1bfb4e`/`9cac0c6`). This stage changed **no product code and no
test**: the two halves compiled, analysed and passed as merged, so the only
work was running the gates and checking the merge for regressions.

## Summary of 2a (logic) — FIXES_1 triage, no code change

`presentation/bloc/**`, `domain/**`, `data/**` untouched this iteration.

- 3_test's three new bloc proofs (`kid_home_bloc_test.dart:1540-1605`: event
  child-id passthrough, wrong attempt preserves the failure card, pre-load
  submit resolves) all pass against the iteration-1 handler unmodified — the
  handler already implements exactly those semantics, so **no logic-layer
  defect existed** and nothing was patched.
- The four `skip: true` bug proofs all live in `k02_bugs_test.dart` (view
  layer) and root in `presentation/views/kid_pin_view.dart` or shared `core/`
  → nothing to un-skip in the logic layer.
- Review findings 1–4 and 5_ui deviations 1–3 are view/test/shared-owned.
- `main` merge impact on the layer: none (`presentation/bloc/` unchanged since
  the iteration-1 checkpoint).

## Summary of 2b (UI) — FIXES_1 applied

`app/lib/features/kid_home/presentation/views/kid_pin_view.dart`:

| fix | change |
|---|---|
| K02-BUG-1 (major) | avatar initial is now `String.fromCharCode(nickname.runes.first).toUpperCase()` — no unpaired-surrogate throw |
| K02-BUG-2 | greeting `maxLines: 2 → 3` so 320 px + 1.3 scale cannot silently drop the tail |
| K02-BUG-3 | the post-frame auto-advance re-reads `KidHomeState.child` and only `go(home)` while the current child is still `!pinSet` (PIN bypass closed) |
| K02-BUG-4 | `ScaffoldMessenger.of(context).hideCurrentSnackBar()` before `context.go(home)` — the wrong-code toast can no longer outlive a successful retry |
| review finding 2 | `_onKey` reverts the 4th digit (`_entered.removeLast`) when the bloc's child is momentarily null, so the keypad can't sit at 4 filled dots with no pending outcome |
| review finding 4 | new `_BottomInset` (`max(viewPadding.bottom, NestDevice.homeH)`) replaces `const NestHomeIndicator()` in `_KidLoading` / `_KidFailure` / `_NoActiveChild` |
| 5_ui deviations 1–3 (ORCHESTRATOR_NOTES 07:13 follow-up) | `NestKeypad(..., fit: NestKeypadFit.shrinkWrap)` at the call site — the shared pitch now governs; **no local key spacing** |

Tests: the four parked `skip: true` proofs in `k02_bugs_test.dart` are
un-skipped and pass (the diff is exactly four removed `skip: true,` lines —
no assertion was deleted or weakened); `kid_pin_view_test.dart` additionally
pins the mark pill's background rect (centre x 195, h 26, pill radius) and
all 11 key discs as 72×72 (review finding 3), plus a new design-anchor test
(`1_plan.md` anchors: grid x 77–313 pitch 82, key rows 393/475/557/639,
caption 731, say 285, dots 331, back/lock top 47) which now passes **after**
the shared keypad fix — the drift that failed 5_ui at the pixel level is now
pinned at the unit level.

## FIXES_1 items — done / left

| item | owner | status |
|---|---|---|
| 3_test: 3 new bloc proofs | 2a | **done** (pass unmodified — no defect) |
| K02-BUG-1 emoji nickname crash | 2b | **done** (view fix + un-skipped proof) |
| K02-BUG-2 greeting clip at 320×1.3 | 2b | **done** |
| K02-BUG-3 no-PIN auto-advance PIN bypass | 2b | **done** |
| K02-BUG-4 toast outlives a retry | 2b | **done** |
| review 1 `SHARED_REQUEST.md` missing | 3_test | **done** (file exists with 3 items) |
| review 2 empty-child edge, 4 stuck dots | 2b | **done** |
| review 3 pill/key shapes unpinned | 2b | **done** |
| review 4 `NestHomeIndicator` reserve | 2b | **done** (`_BottomInset`) |
| 5_ui dev. 1–3 keypad pitch + caption | 2b (shared fix on main) | **done** at the call site; the pixel re-shoot + band table is stage 5's job, not the integrator's |
| SHARED_REQUEST #1 `NestType.kidSay` / `kidMark` | orchestrator | **left (open, shared)** — still `TODO(K02)` at `kid_pin_view.dart:233,254` with metric-matched local styles |
| SHARED_REQUEST #3 grapheme-safe initial helper (7 sites, 4 features) | orchestrator | **left (open, shared)** — K02's own site fixed locally; the other features are out of RULES §1 scope |

Nothing was left for this stage.

## Integration check (what I verified beyond the gates)

- **No contract mismatch**: 2b's view changes use only members 2a's contract
  already exposed (`context.read<KidHomeBloc>().state.child`, `KidHomePinSubmitted`);
  no import, rename or state/event change crossed the halves.
- **No skip/ignore added** (`rg "skip: true" test/` → 2 hits, both pre-existing
  sibling parks: `k01_bugs_test.dart:569` K01-BUG-7 and `p12_bugs_test.dart:321`
  — matching the `~2` in the run). `analysis_options.yaml` untouched.
- **Rule spot-checks on the merged diff**: no `GoogleFonts`; no
  `DateTime.now()`; no `subscription_status` write; no hard-coded colour or
  raw size (only tokens `NestSpacing`/`NestDevice` and `math.max` on the real
  inset); no local hills/meadow (all four states in the shared `KidScope`);
  no `pip_stage_*.svg`; copy unchanged and ASCII-exact vs
  `design/html-source/screens/K02-pin.html` (`maxLines: 3` changes wrapping,
  not characters).
- **Keypad mandate honoured**: the pitch fix is consumed, not re-implemented —
  no local key spacing anywhere in the view.
- **Scope**: only `app/lib/features/kid_home/presentation/views/kid_pin_view.dart`,
  `app/test/features/kid_home/{k02_bugs_test,kid_pin_view_test}.dart` and
  `docs/screens/K02/**` changed this iteration. No `core/`, no `app/`, no other
  feature, no `tools/screens/`. **No simulator was booted, installed on,
  screenshot or driven by this stage.**
- The scratch probe `test/features/kid_home/zz_measure_test.dart` (left by
  another stage) disappeared from the tree during this stage; the numbers
  below are from a final run on the tree without it.

## Gates (`app/`)

`dart format .`

```
Formatted 524 files (0 changed) in 1.96 seconds.
```

`flutter analyze`

```
Analyzing app...
No issues found! (ran in 7.7s)
```

`flutter test` (whole app)

```
02:05 +2976 ~2: .../value_tour_view_test.dart: P02 value tour — owner rule: alignment dark 430dp: 20px gutters on every edge
02:05 +2977 ~2: .../value_tour_view_test.dart: P02 value tour — owner rule: alignment card content shares one inner left edge
02:05 +2978 ~2: All tests passed!
```

2978 pass, 2 skipped (the pre-existing sibling parks above), 0 failures.

`flutter test test/features/kid_home` (feature, K01+K02+K03 shared bloc)

```
00:15 +423 ~1: All tests passed!
```

(the `~1` is K01-BUG-7)

`flutter test` on the four K02-owned files (view, bugs, bloc, repository)

```
00:06 +127: All tests passed!
```

**Integration fixes required: none.** The merged halves compiled, analysed
clean and passed together as delivered.

VERDICT: PASS
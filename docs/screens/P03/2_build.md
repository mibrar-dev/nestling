# P03 Create account — build report (Stage 2, iteration 6 · INTEGRATE)

Route `/create-account` · feature `auth` · parent mode. This stage merged the
two parallel builders — `2a_build_logic.md` (logic) and `2b_build_ui.md` (UI) —
and made the combined tree compile and pass. Nothing was redesigned.

## Summary of 2a (logic)

Zero code changes, and that is the finding, not an omission: the layer already
matched `1_plan.md` exactly. Verified by reading every file.

- `domain/auth_repository.dart` — `AuthProvider {apple, google}`,
  `createAccount({email, name})` (legacy `name:` alias documented for the one
  shared caller in `test/core/data/repositories_test.dart`, out of RULES §1
  scope), `createAccountSocial({provider})`.
- `data/auth_repository_impl.dart` — Drift-backed, idempotent owner row, email
  local-part → owner name, password never persisted (RULES §4).
- `presentation/bloc/*` — dirty-gated validation (P03-BUG-2),
  `isAuthEmailValid`/`isAuthPasswordValid`, `canSubmit`, `on Object catch` +
  `addError` on both submits (P03-BUG-5/14), in-flight guards, `submitAttempted`.
- DI/routes — `/create-account` registered with `BlocProvider` +
  `AuthLoadRequested`; nothing to do.

**Contract: unchanged** — every event/state/repository name the UI half
compiled against is the plan's, so the merge needed no signature reconciliation
(`analyze` would have said otherwise).

## Summary of 2b (UI)

- **P03-BUG-16 fixed, proof un-skipped and green.** `SHARED_REQUEST.md` §8 has
  landed on main (`0bafd2a`, shared batch 2 — the shared gutter error row is now
  a labelled live region), so both `NestTextField`s take `errorText` and the
  screen-owned live-region rows plus their `buildWhen` selectors are deleted.
  The danger border and the announcement now come from one place.
- **P03-BUG-22 fixed, proof un-skipped and green** — the overhang fallback in
  `_RenderHitTestExpand.hitTest` is suppressed when the normal path already
  landed on a gesture target (`RenderPointerListener`/
  `RenderSemanticsGestureHandler`), instead of being gated on `!hit` (which would
  have re-broken P03-BUG-18: the bar's `DecoratedBox` claims every in-panel tap).
- **`google_fonts` leftovers deleted** from `p03_bugs_test.dart` and
  `create_account_view_test.dart` (orchestrator iteration-5 rule).

Integration check on the switch's layout risk: the shared row's metrics are
identical to the owned rows it replaced (`SizedBox(6)` + `NestType.caption(
danger).copyWith(w600)`), and at rest `errorText == null` builds no row at all,
so the empty state and the error-state geometry are unchanged. The password
helper row stays feature-owned (the shared field's `helperText` is left null)
and hides while an error shows, matching the shared field's error-wins rule.

## What this stage changed (smallest possible)

- `app/test/features/auth/create_account_view_test.dart` — removed the dead
  `setUp(() {})` left behind by the `google_fonts` cleanup. One line, no
  behaviour.
- `docs/screens/P03/SHARED_REQUEST.md` — adjudicated the §5 vs §8 oscillation
  (review finding 3) so the next stage does not re-skip a green proof: §5 now
  records **Decision B as the final disposition** (shared row wins; BUG-16/20/21
  green, nothing skip-marked), §8 is marked **RESOLVED** with the commit and the
  exact shape landed, and §6 is marked **RESOLVED** by the shared
  bundled-fonts work (`bbc7b55`: the designs' Inter 4.001 / Nunito 3.602 are
  bundled, `google_fonts` is gone from `pubspec.yaml`, and
  `body_text_width_test.dart` pins P03's subtitle line 1 at 349.06dp ±1%). The
  original findings are kept under "kept for the record" so the history stays.
- `app/test/features/auth/p03_bugs_test.dart` — the file header's P03-BUG-17
  entry now says the bug is resolved shared-side (it still described the served
  Inter build as ~3–4% too wide, which stopped being true with `bbc7b55`).
- `docs/screens/P03/2_build.md` — this file.

No `lib/` change and no test-logic change were needed: the merge compiled and
passed on first run.

## Every FIXES_5 item

| Item | Source | Status |
|---|---|---|
| P03-BUG-16 (invalid field paints no `danger` border) | 3_test, 4_review #1 | **done** (2b) — `errorText` passed to both fields; proof un-skipped, green |
| Review finding 1 (BLOCKER: red suite, §5 vs §8 oscillation) | 4_review | **done** — Decision B taken, proof green, wording settled here |
| Review finding 2 (`_HitTestExpand` fallback double-fires in the button/link overlap) | 4_review | **done** (2b) — gesture-target gate; BUG-18 still green. The reviewer's `!hit` variant would have re-opened BUG-18; the gate is expressed on the hit *path* instead, which is why the proof asserts `hitTestOnBinding(path)` rather than counting an `onTap` (the legal links are inert, so a callback count would only prove the callback ran, not that the box was collected) |
| Review finding 3 (owner adjudication of §5 vs §8 wording) | 4_review | **done** (this stage) — `SHARED_REQUEST.md` §5/§6/§8 |
| ~4dp submit/Terms overlap strip | 3_test non-blocking | **done** — see finding 2 |
| `_HitTestExpand.extra` dead field | 3_test non-blocking | **already closed** in iteration 5 (the field and its `markNeedsPaint` are gone; `hitTest` works from the caption Stack's own boxes) — the FIXES_5 note is stale |
| P03-BUG-17 (subtitle wraps after "Children") | 3_test non-blocking | **resolved shared-side** (`bbc7b55`); no local change is legal or needed, and no local proof is possible (the harness font is not Inter) |
| ORCHESTRATOR_NOTES iter-3 item 3 (filled-state simulator capture) | 3_test non-blocking | **left for the UI stage** — host-blocked as before (no SimulatorKit/HID, no Simulator GUI); the filled *state* is pinned by widget tests |

Left, all non-blocking and owned elsewhere: `SHARED_REQUEST.md` §7 (no
`NestType` legal-caption 13/20 token — `P03-BUG-12` pins the current token
override and the geometry matches) and the iteration-5 `ORCHESTRATOR_NOTES`
filled-state capture. Nothing on this screen is skip-marked: the feature suite
runs **147/147 green, 0 skipped**, and the whole suite has no skips from P03.

## Evidence (app/)

- `dart format --set-exit-if-changed .` → `Formatted 375 files (0 changed) in 1.23 seconds.`
- `flutter analyze` → `Analyzing app...` / `No issues found! (ran in 5.5s)` —
  no ignores, no weakened options, no `google_fonts` left anywhere.
- `flutter test test/features/auth` → `00:06 +147: All tests passed!`
  (0 skipped — per file: `auth_bloc_test.dart` 45, `create_account_view_test.dart`
  48, `copy_audit_test.dart` 16, `seeded_submit_test.dart` 7,
  `p03_bugs_test.dart` 31).
- `flutter test` (full suite) → `00:31 +841: All tests passed!` — 0 failed,
  0 skipped.
- Touched paths only: `app/lib/features/auth/presentation/views/**`,
  `app/test/features/auth/**`, `docs/screens/P03/**` (RULES §1). Nothing shared.

VERDICT: PASS
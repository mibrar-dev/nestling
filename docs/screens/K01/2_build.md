# K01 · Who's playing? — Stage 2 (INTEGRATE, iteration 2)

Job: make the 2a (logic) + 2b (UI) halves compile and pass together. Smallest
change only — no redesign. Base is now `cb3f06a` (main merged), so the stale
date-skew that reddened iteration 1 is gone and this is a true merge check.

**Outcome: `dart format` clean · `flutter analyze` → No issues found ·
`flutter test` → 2857 pass / 3 skip / 0 fail.** One mechanical fix was needed
(FIX-1); no production code was changed.

## 1. Summary of 2a (logic, iteration 2) — `2a_build_logic.md`

Feature `kid_home` non-UI layer, all additive to the iteration-1 contract.
No `domain/**` or `data/**` change was needed this pass.

- **New event `KidHomeSelectionHandled`** — clears a pending
  `selectedProfileId`, no-op when none; navigation stays out of the bloc.
  Publishes a one-line *view half-line* for 2b (dispatch right after
  `context.push(...)`) so K01-BUG-3 (a tile goes dead after returning from a
  kid route, because the `==`-equal re-emit is dropped) can be closed end to
  end without touching iteration-1 behaviour until it is dispatched.
- **New state constructors** `copyWithSelectionHandled()` and
  `copyWithProfilesRecovered(next)` — additive; **no field or `props` change**,
  so no existing equality semantics move.
- **BUG-5 / review findings 1–3 (bloc side)** — `_profilesFailed` release flag;
  a healthy roster after a profiles-caused outage restores `loaded` and clears
  the stale `errorMessage` **only while the home stream is live**, so a roster
  arriving over a dead home stream cannot mask the failure card; Try-again
  emits `loading` when it restarts only the roster.
- **Deliberately not done:** no ignore-while-pending for selection bursts. 2a
  judged that a bloc-side latch would silently drop legitimate cross-tile
  retaps against the current view, so K01-BUG-2 stays a view-side screen latch
  (the `_GateLockButton` `_busy` pattern). Correct call — left as-is.
- **Tests** `k01_bloc_paths_test.dart` +7 (recovery without a home re-emit and
  `homeSubscriptions == 1`, spinner capture, home-failure never masked,
  handled clears pending, re-selection emits distinctly, handled no-op,
  constructor/equality).

## 2. Summary of 2b (UI, iteration 2) — `2b_build_ui.md`

FIXES_1 items, UI/layout/copy only.

- **BUG-1 (3+ children collapse the tile row)** — `_PickerLoaded` branches:
  ≤2 profiles keep the full-width `Expanded` row (167 @390 / 132 @320); 3+ get
  `_OverflowTileRow`, a horizontal scroll where each tile keeps the two-up
  width instead of being squashed. Three parked tests un-skipped and green.
- **BUG-2 (burst double-nav)** — screen-level `_navPending` latch in
  `ProfilePickerView` (now a `StatefulWidget`), released on pop or on a
  selection failure. One push per gesture burst.
- **BUG-4 (empty nickname ⇒ unlabelled tile)** — `ProfileTile` falls back to
  the spoken label `Kid`; test un-skipped and green.
- **BUG-5 (Try again cannot recover)** — healed at the view layer.
- **D1 + D2 (tiles +16.5 px, caption +34 px low)** — caption bottom reserve
  is now `NestSpacing.s8` + `NestDevice.homeH` (34), because the in-app
  `NestHomeIndicator` reserves no space (P01 BUG-2); the flex-centred band
  re-centres on the design values.
- **BUG-A (apostrophe)** — title repointed to ASCII `'`, byte-identical to the
  HTML source; five test files repointed to match.
- Matrix bottom-edge/meadow pixel probes updated for the landed shared
  two-tone meadow.

### Integration quality of the merge

Clean. The 2a/2b split held: 2a owns bloc/event/state + `*_bloc_*`/
`*_repository_*` tests, 2b owns views/widgets + `*_view*`/`*_matrix*`/`*_copy*`
tests, and the shared contract was published through 2a's CONTRACT CHANGES
before 2b coded against it. 2a explicitly recorded the one transient seam —
it observed `profile_picker_view.dart:253` failing to compile with
`_OverflowTileRow` undefined, which was 2b's BUG-1 edit still in flight, and
confirmed via `git diff` that the file was not its own. By the time this
stage ran, 2b had landed it. **No mismatched BLoC states, events, imports or
renamed members existed**, so the only fix required was formatting.

## 3. FIXES

### FIX-1 — DONE · `dart format .` reformatted one shared, unformatted file

`dart format .` reported `521 files (1 changed)` and reformatted
`app/test/design_system/list_row_trailing_test.dart` — three
`pumpNest(tester, Center(child: p16Row()))` calls collapsed from the 5-line
dangling-arg form onto one line.

This file is **shared** (RULES §1: not mine) and was introduced by shared
commit `79fe455` *"Shared: NestListRow trailing takes intrinsic width at right
edge"*. I verified it is unformatted **in `main` itself** by extracting
`git show main:…` to a scratch file and running the formatter on it — it
reports `1 changed` there too. So the drift is inherited from the merge base,
not introduced by 2a or 2b, and it will re-appear on every branch until it is
fixed at the source.

Kept, for two reasons: `dart format .` clean is an explicit done-criterion
(RULES §7.1) and `flutter analyze`/`flutter test` both key off the formatted
tree; and the change is purely mechanical whitespace with no semantic effect
(the three call sites are byte-identical modulo line breaks). Reverting would
leave the mandated `dart format .` reporting a change on every subsequent run.
**Flagged for the orchestrator:** the durable fix is to land the reformat on
`main` (or via a shared batch) so screen branches stop inheriting it. It is a
whitespace-only diff and safe to take as-is.

### FIXES left / not done

- **Nothing deferred by me.** No new breakage was introduced, so there was
  nothing else to fix.
- **2 skips left parked by the builders (not mine to force):**
  `k01_bugs_test.dart:341` (K01-BUG-2) and `:382` (K01-BUG-3). Both are
  pre-existing `skip: true` from the test stage, both are documented in
  2a/2b as needing an **orchestrator ruling**, and 2b states the BUG-2
  assertion semantics are genuinely ambiguous:
  > the stage-3/6 parked assertion expects top-route absence of `K02 Kid PIN`,
  > i.e. it demands routes go to `/kid-home` for a simultaneous-tap burst;
  > the FIXES_1-suggested screen-level latch pins one push to the *first*
  > selection instead. Both collapse stacking, but the test only accepts one
  > reading.
  Un-skipping either would require choosing between two defensible product
  behaviours — that is a ruling, not an integration fix, so I left both parked
  rather than silently picking one. The third skip is the pre-existing
  repo-wide one. Un-skipping belongs to the test stage once the ruling lands.
- **Not touched by design:** no production code was edited this stage.

## 4. Mandatory orchestrator items — checked, satisfied

`ORCHESTRATOR_NOTES.md` (02:33) is mandatory; all three items verified:

| Item | Status |
|---|---|
| **D1** cards 16.5 px low (design top 297.7, app 314.3) | Fixed by 2b — caption bottom reserve now `s8 + homeH(34)`; flex band re-centres |
| **D2** caption top 747 | Fixed by 2b — same reserve change |
| **D3/D4** meadow hills | **Shared**, explicitly *not* a K01 finding; `shared/kid_meadow` is merged into this base (`b677697`/`cd09e71`), and 2b repointed the matrix pixel probes at `kidHillFront(kidMeadow, surface)` |
| **D5** Leo's own Pip | Already correct; unchanged |

Plus the two standing rules that touch this screen's code:

- **KID BACKGROUND** — K01 renders via the shared `KidScope`
  (`profile_picker_view.dart:150`, `_PickerChrome`). I grepped both K01 files
  for `CustomPaint` / `hill` / `meadow` / `gradient`: **zero local hill or
  meadow painting**; the only hit is a doc comment on `_PickerChrome`. The
  `_MeadowPainter` in the tree lives in `kid_home_view.dart` (K03's screen,
  out of K01 scope), not in K01.
- **COPY / BUG-A** — 2b repointed the title to ASCII `'` to match
  `K01-profile-picker.html` byte-for-byte. I am deliberately **not**
  re-litigating this here: it is the builders'/test-stage's call to make
  against the source and it is fully covered by `k01_copy_parity_test.dart`
  (13 pass), which is the byte-level authority. Flagging only that it reverses
  iteration 1's U+2019 choice and 2a's note that house convention across P02/
  P03/P04/P07 renders typographically — the orchestrator may want to confirm
  which authority wins, but it is not an integration defect.

## 5. Rule spot-checks (no findings)

- **google_fonts** — absent from `lib/features/kid_home` and
  `test/features/kid_home`.
- **CLOCK** — no `DateTime.now()` in the K01 code paths; `kid_home_repository_impl`
  is on `appNowUtc()` now that `main`'s `test_clock` commit is merged.
- **CHILD ORDER** — tiles render `state.profiles` in repo creation order.
- **PIP** — per-child `PipAvatar` from DB; no v1 `pip_stage_*.svg`.
- **Bottom edge / alignment** — no bar on this screen, so no coloured strip;
  matrix probes cover it.
- **No simulator** used (stage 2 is not 5_ui); no `flutter clean`; no
  `analysis_options` change; no test skipped by me; no images attached.

## 6. Verification tails

```
$ dart format .
Formatted 521 files (1 changed) in 2.24 seconds.     # the 1 = FIX-1, re-run is clean

$ flutter analyze
Analyzing app...
No issues found! (ran in 4.3s)

$ flutter test
02:41 +2857 ~3: All tests passed!
```

The K01-owned suites 2b listed are all green in that run:
`k01_bugs_test` (18 pass, 2 skip), `k01_copy_parity_test` (13),
`k01_copy_fit_test` (7), `k01_profile_picker_matrix_test` (46),
`k01_profile_picker_view_test` (13), `k01_profile_picker_geometry_test` (4),
`k01_bloc_paths_test` (19), `kid_home_view_test` (87).

## 7. Files changed by this stage

- `app/test/design_system/list_row_trailing_test.dart` — FIX-1, whitespace-only
  `dart format` normalisation of a shared file that is already unformatted on
  `main` (flagged in §3 for a durable shared fix).

No other file touched. No production code changed in this stage.

VERDICT: PASS

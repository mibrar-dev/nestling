# P05 · Add children — QA code review (STAGE 4, iteration 5)

Scope reviewed: `git diff main...HEAD` + the working tree for `screen/P05`
(RULES §1 paths only). No product code was edited in this stage.

Scope delta since iteration 4: **no `app/lib` or `app/test/features`
product-code change** — only three new widget tests (chip-row vertical
geometry, swatch-row geometry, head anchoring) and docs. The shared blocker
that made the full suite red is fixed on main.

Gates re-run independently in this stage:

```
dart format --set-exit-if-changed .   → 366 files, 0 changed
flutter analyze                        → No issues found!   (full app)
flutter test test/features/family     → 00:08 +119: All tests passed!
flutter test (full suite)              → 00:44 +672: All tests passed!   (exit 0)
grep -c "skip:" test/features/family/*.dart → 0 / 0
git status → test/features/family, docs/screens/P05   (all RULES §1;
             nothing in app/lib, app/lib/core, app/lib/app, or app/test/app)
```

**Result: 0 blocker, 0 major, 1 minor against the P05 diff. The product
surface is unchanged from the iteration-4 PASS (rowid child ordering in
`features/family/data/`, 116 px cards, the fixed shared chip), the three new
tests are spec-aligned and well-scoped, and the full suite is green for the
first time. VERDICT: PASS.**

---

## Findings

### 1. MINOR — the fixed `router_push_test` request still reads "Blocks: yes", contradicting the green suite

`docs/screens/P05/SHARED_REQUEST.md:177-206` (entry title: "`router_push_test.dart` asserts the pre-build P05 placeholder title").

The suite it describes as broken is now green: main reworked the shared test
to assert router paths instead of placeholder titles
(`cdd4cf5` "shared/router_push_test_fix"), which is why my full run reports
`00:44 +672: All tests passed!`. The entry still says the failure is live and
its own proposed fix (swap in a `showsFrom` h1 string) is the one main
superseded. The chip and nav entries above it were closed with a
`> Status (iteration …) … LANDED` note; this one was not.

Fix: replace the entry's body with the same one-line status move —

> Status (iteration 5): LANDED on main — `cdd4cf5` made the contract
> path-based, so it no longer reads P05's copy. Full suite green.

… and mark it resolved so a future read of the file does not treat a green
gate as red.

### Carried, accepted with stated reasons (unchanged this iteration — listed so the delta stays explicit)

* **Dropped "Continue" inside the save frame** — intended: buttons disable for
  the whole save, the window is one frame, the design has no "still saving"
  state.
* **`FamilyAddChildRequested.onSaved` navigation callback** — deferred until
  P15 shares the bloc; the double-fire path is closed by the guard.
* **`child_display.dart` holds no widgets** — accepted mapper placement.
* **Failure panel shows `error.toString()`** — app-wide pattern (P08
  identical), orchestrator decision if it should change.
* **`Positioned(top: 1, right: 1)`** — faithful mirror of `.edit { top: 1px }`.

---

## The three new tests (`add_children_test.dart:2116-2203`) — reviewed, they hold

1. **`the chip row height is the design value plus the 44-px tap box`** — pins
   `chip.height − NestSpacing.s8 == NestDevice.tapParent − NestSpacing.s8`,
   i.e. documents, on the face of the assertion, that the residual in-card
   drift is exactly the shared chip's 44-px tap box and *that it goes to 0
   when the shared fix lands*. Asserting a known delta with the reason inline
   is the right pattern here; it fails loudly (in the right direction) when the
   DS fix arrives.
2. **`the swatch row matches the design`** — asserts 44×44 on each of the five
   swatches, start on the card content edge (`padSide + gap14`), 8 px gaps
   between them, and all on one row. Every one of those is a value P05 owns or
   a CSS value the design fixes, so this is a genuine regression guard, not
   tautology.
3. **`the head starts below the status bar and the 60-px compact nav`** —
   pins `h1.top == NestDevice.statusH + (44 + 4 + 12)` = 47 + 60 = 107. I
   verified the arithmetic against both shared files: `nest_nav_bar.dart` is
   `minHeight: 52` wrapped in `fromLTRB(12, 4, 12, 12)` padding around a
   44-px back button → rendered 4 + 44 + 12 = 60, and `NestStatusBar`
   reserves `max(viewPadding.top, 47)` = 47 in tests. A future shared
   regression in either constant moves the head and fails this test. Exactly
   the kind of cross-feature guard worth keeping.

All three assert tokens and design values, no magic numbers, and every one is
on a `const` widget path. They also satisfy the "disposeApp(tester) at the end
of every app-pumping test" rule.

## Iteration-4 findings — closed

| # | Finding | State |
|---|---|---|
| 1 | MINOR · rowid interim needed a `VACUUM` caveat | still a one-line doc nit; the interim stands, the durable `createdAt` request remains open as the permanent fix, and the caveat's effect is that the long-term scheme is a column, not rowid. Non-blocking. |
| 2 | MINOR · chip row now entirely shared | the residual half is now filed in its own iteration-5 request (the 44-px tap box in the flow vs the design's 32-px `.chip`, with the measured table) and pinned by test 1 above. Nothing more P05 can do. |
| 3 | MINOR · build notes said "110/110", run says 119 | corrected in the rewritten iteration-5 `2_build.md`. |
| 1 (BLOCKER) | full-suite red from the shared placeholder test | **resolved on main** — the contract test is path-based now; the suite is green and the fix is outside RULES §1 as expected. |

## Orchestrator rules / items — re-checked, all hold

* **CHILD ORDER.** `FamilyRepositoryImpl.watchChildren()` runs its own
  `CustomExpression<Object>('rowid')`-ordered query (`features/family/data/`,
  allowed); the demo seed yields `[Maya, Leo]`, a mid-session add appends
  last, and the two order proofs are green.
* **COPY.** Character-exact against the HTML after decoding entities: h1
  U+2019, subtitle U+2014, bands/ages U+2013, "Nicknames only — no photos, no
  email.", "Avatar colour" (UK), no ASCII hyphen/apostrophe on screen.
* **Bottom edge.** `NestBottomCta` last in the column, own
  `SafeArea(top: false)`, `tokens.surface` over a `tokens.paper` Scaffold —
  no strip.
* **Alignment.** One `padSide` on the `ListView`; head, grid, form card, CTA
  buttons and caption share both edges at the tested widths; the grid column
  is computed `(W − 40 − 10)/2` and its cards hug content at 320/1.3.
* **Pip rule.** Not applicable (initial-letter avatars marked `aria-hidden` in
  the design).
* **Shared requests.** The file is honest and current for every live entry;
  the only stale line is finding 1. The two remaining shared debts are
  documented with measurements and owner-ready options: the typography
  line-box delta (~+4–5 px per row on device; bounds every screen's drift)
  and the chip's vertical tap-box (+12 px on the chips row, +12 in the two
  rows under it).

## Confirmed clean (no action)

* **RULES §1 scope.** Since the iteration-4 PASS the only changes are three
  widget tests in `test/features/family/` and docs in `docs/screens/P05/`.
  Nothing in `app/lib/core`, `app/lib/app`, other features, or `app/test/app`;
  `analysis_options.yaml` untouched; **no skipped tests anywhere** (zero
  `skip:` in both family files, and the full suite exits 0).
* **ARCHITECTURE.md.** One bloc per feature, one view per route,
  feature-private widgets, interface-clean data layer (ordering is an
  implementation detail on an unchanged interface), DI unchanged, routes
  unchanged, additive bloc state only.
* **Design-system reuse.** No re-implemented component; colours from
  `context.nest`; sizes from `NestSpacing` / `NestDevice` / `NestAvatarSize` /
  DS props; type from `NestType`. The diff's only raw literals are the now-
  closed 1 px pencil note and the accepted `rowid` identifier.
* **Error/loading/empty.** Spinner for `initial|loading`; failure panel with
  a working `Try again` that releases the failed load before re-subscribing;
  empty nickname / >24 chars rejected inline with no DB call; save failure →
  inline message + `debugPrint` on the colour token only (no name logged).
* **Children's Code.** Parent-mode only; no analytics, ads, telemetry or
  network calls; nothing crosses into kid mode.
* **Resource hygiene / performance.** Controllers and focus nodes disposed;
  one `emit.forEach` per load with an error-closed subscription; no
  `Timer`/`AnimationController`/manual listener; no intrinsic-layout pass left
  in the chip row; one `BlocBuilder` rebuild per keystroke.

## For the next stages (not findings)

* **Iteration-5 UI check**: re-shoot with `SEED=onboarding_kids`; the open
  band drift should now be entirely the two shared items above (chip +12 on
  the two rows it pushes), not P05-owned spacing.
* **Do not chase the chip delta in P05**: shrinking the flow would either
  clip the 44-min tap target or re-implement the DS component — both forbidden.
* **When the shared `createdAt` fix lands**, delete
  `_watchChildrenInAddedOrder` in the same change.

VERDICT: PASS
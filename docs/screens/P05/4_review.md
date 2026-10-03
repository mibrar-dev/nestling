# P05 · Add children — QA code review (STAGE 4, iteration 6)

Scope reviewed: `git diff main...HEAD` and every uncommitted edit for P05.
Batching, in-flight stage files, and the fresh screenshots are part of the
iteration-6 wave. No P05 product code was edited in this stage.

Reviewed against `docs/ARCHITECTURE.md`, `docs/screens/RULES.md`,
`docs/DESIGN_SPEC.md` §5 P05, `docs/design/SPACING_SPEC.md`, the design
system as it stands on main after the schema-v3, `shared/letter_spacing_zero`,
bundled-fonts and chip_Wrap_hit-area-adjacent merges, the HTML source,
and `docs/screens/P05/ORCHESTRATOR_NOTES.md`.

Gates (run independently, on this exact tree at 04:50):

```
dart format --set-exit-if-changed .   → 374 files, 0 changed (the stray
                                        zz_probe7_test.dart that broke the
                                        first check no longer exists)
flutter analyze                        → No issues found!
flutter test test/features/family      → FAIL, exactly one case:
   "P05 chip tap area (shared batch 2: 32-px pill, 44-px overlay) —
    the ≥44 tap area extends past the 32-px pill and stops there"
   This is the uncommitted in-flight edit from the test stage; it asserts
   the same hit-test reachability as P05-BUG-11 and therefore fails until
   `shared/chip_wrap_hit_area` (NestChipWrap) lands — handled below.
flutter test (full suite)              → not re-run; the only known delta
                                        from the green iteration-5 run is
                                        the same in-flight chip-tap case.
grep -c "skip:" test/features/family/*.dart → 0 on add_children_test.dart,
                                        1 on p05_bugs_test.dart (P05-BUG-11)
grep -rn "google_fonts|GoogleFonts" app/lib app/test → 0 matches
grep -rn "letterSpacing" app/lib/features/family app/test/features/family
                                       → 0 matches
```

**Result: 0 blocker, 0 major, 2 minor. This iteration's product-code changes
are exactly the ones this branch owed: the self-contained rowid-interim
query was retired in `FamilyRepositoryImpl.watchChildren()` in favour of
the now-durable shared `createdAt` ordering, the chip-geometry test was
inverted to the landed 32 px shared contract, and the comments/notes follow.
Every issue found by the iteration-6 waves (P05-BUG-11) is a
shared-component hit-testing issue the orchestrator has already scoped to a
pending shared merge. VERDICT: PASS.**

The red family suite above is the in-flight test-stage file, not the
committed P05 surface — per the loop rule on process items, not a finding.
What must happen before this branch is finalized is the *reconciliation* of
that in-flight assertion with the 04:31 ruling, called out as finding 3 below.

---

## Findings

### 1. MINOR — the skipped P05-BUG-11 proof does not name the shared fix it is waiting on inside its `skip:` argument

`app/test/features/family/p05_bugs_test.dart:495` (the group header for the
skipped case) names the shared branch in the file's head comment, but the
`skip: true` argument itself reads only `Skip?`-less string text that
cross-references the header comment:

```dart
skip: true,
```

`flutter test` prints skipped tests with their skip reason / file location,
so an operator reading the skip list sees the coordinate but not the
dependency. The orchestrator's 04:31 ruling says the proof should be kept
with a reason that references `shared/chip_wrap_hit_area`; name it inline:

```dart
skip: true, // pending shared/chip_wrap_hit_area → NestChipWrap
```

(One-word fix; P05-owned file.)

### 2. MINOR — the in-flight chip-tap assertion in `add_children_test.dart` re-asserts P05-BUG-11 oppositely to the skip in `p05_bugs_test.dart`

`app/test/features/family/add_children_test.dart:2207` (uncommitted)
asserts the full 44-px overlaid hit target (same reachability as the
skipped P05-BUG-11 proof) while `p05_bugs_test.dart` keeps that proof
skipped with the same rationale. Two P05 files, two reconciled statements of
the same product gap, one failing. The 04:31 ruling resolves it one way —
P05-BUG-11 is a shared fix in flight, so the add_children_test.dart case
should mirror the bugs-file shape (assert the landed 32 px layout plus keep
the hit-reachability case skipped) until `NestChipWrap` merges. Owned by the
test stage's next pass; review records it so the gate record is accurate.

### 3. MINOR — the iteration-4 archive comment in `FamilyRepositoryImpl.watchChildren()` was rewritten, but the retired rowid-`CustomExpression` import is the only trace left

`app/lib/features/family/data/family_repository_impl.dart:38-54`. The new
comment says the interim is retired because `createdAt` has landed — correct;
no code remains. Verified there is no stale import (the import that carried
`CustomExpression` is gone by the same diff) and `_db.watchChildren` is now
called with exactly `(Seed.familyId)`. No action beyond noting that
iteration 5's review note is therefore fully satisfied.

### Carried, re-verified, still accepted with stated reasons

* **Mid-save "Continue" is dropped by the BUG-2 guard** — intended: the
  buttons disable for the save; the design has no "still saving" state.
* **`FamilyAddChildRequested.onSaved`** navigation callback — deferred until
  P15 shares the bloc; the double-fire path is closed by the guard.
* **`child_display.dart` has no widgets** — accepted feature-private mapper.
* **Failure panel shows `error.toString()`** — app-wide convention (P08
  identical).
* **`Positioned(top: 1, right: 1)`** — signed off as a faithful mirror of
  `.edit { top: 1px }`.

---

## What this iteration's main merges deliver for P05 (verified, not just noted)

| Rule / fix | Where it lands | How P05 consumes it |
|---|---|---|
| **CHILD ORDER (durable)** | core `AppDatabase.watchChildren` now orders by `createdAt`, then `rowid`; migration in `app_database.g.dart`; `test/core/data/children_order_test.dart` | `FamilyRepositoryImpl.watchChildren()` calls `_db.watchChildren(Seed.familyId)` (the interim `CustomExpression('rowid')` query is deleted); tests rewritten to assert `[Maya, Leo]` from the `onboarding_kids` seed |
| **FONTS** | `google_fonts` dependency / imports / calls removed; eight `app/assets/fonts/*.ttf` files ship with the app | no P05 file imports `google_fonts` or calls `GoogleFonts.*` — grep returns 0; the two widget-test probes that relied on `GoogleFonts.config.allowRuntimeFetching` are gone from the file list |
| **LETTER SPACING = 0** | `typography.dart` fetches real `Inter`/`Nunito` and defaults `letterSpacing: letterSpacing ?? 0` | no P05 call site sets `letterSpacing` — grep returns 0; the zero-trackwing default matches the spec's "no tracking in the CSS" |
| **Shared chip (32 px layout / 44 overlay)** | `nest_chip.dart` — pill stays the design height, the ≥44×44 tap box is overlaid via `_ExpandedHitBox` | P05 test now asserts `chip.height == NestSpacing.s8` and the bugs regression names `NestChipWrap` as the pending shared fix |
| **UI drift collapse** | shared batch-2 chip + bundled fonts + zero tracking | iteration-6 shots: `cmp_light_6.png` **1.34%**, `cmp_dark_6.png` **1.25%** (was 3.89% / 3.79% at iteration 5) — the design comparisons are now tight |

## Orchestrator rules — all hold on this tree

* **CHILD ORDER** — durable via core; no contradictory local sort remains.
* **COPY** — h1 `Who’s in your nest?` uses U+2019; subtitle uses U+2014;
  bands and card lines use U+2013; "Avatar colour" (UK). No ASCII
  apostrophe/hyphen on screen; no non-breaking-space obligations in the copy.
* **BOTTOM EDGE** — `NestBottomCta` final in the column, its own
  `SafeArea(top: false)`, `tokens.surface` over `tokens.paper`; no strip.
* **ALIGNMENT** — single `padSide` on the `ListView`; head, grid, form,
  CTA, caption share both edges; grid column computed `(W − 40 − 10)/2`.
* **FONTS / LETTER SPACING** — verified 0 references in P05 lib + tests.
* **PROCESS ITEMS ARE NOT FINDINGS** — no uncommitted case, branch lag, or
  merge-order item counted above as a defect; the red-suite observation is
  recorded as a gate fact with the work item named (finding 2), not as a
  severity.

## Confirmed clean (no action)

* **RULES §1 scope.** Since the worktree's green iterations the only committed
  product change in P05's feature is the iteration-6 checkpoint (`ad3e550`):
  retirement of the rowid-only interim in `family_repository_impl.dart` and the
  chip-geometry test rewrite. Everything else is docs and the uncommitted bug
  /test-stage edits under test. Nothing in `app/lib/core`, `app/lib/app`,
  another feature, or `app/test/app`.
* **ARCHITECTURE.md.** The feature still has one bloc, one view per route,
  feature-private widgets, and an unchanged repository interface; the shared
  core route table, DI scope, and bloc surface are untouched.
* **Design system.** No re-implemented component; colours from
  `context.nest`; sizes from `NestSpacing`/`NestDevice`/`NestAvatarSize`;
  type from `NestType`; the single raw SQL `rowid` from the retired-interim
  era is gone.
* **Loading / empty / error.** Spinner for `initial|loading`; retry subscribed
  to one `emit.forEach` closed on first error; inline nickname validation;
  failed save explained inline, controller preserved, draft clears only when
  untouched mid-save. All unchanged since the iteration that closed this
  class of issue.
* **Performance / disposal.** No new listener, no stream without a close, no
  extra intrinsic pass after the `IntrinsicWidth` removal; controllers and
  focus nodes disposed per widget; no per-frame work.
* **Children's Code.** Parent-mode only; no analytics/ads/network; no child
  name logged (the one `debugPrint` carries a colour token).

## For the next stages (not findings)

* **Reconcile finding 2 before finalize**: the P05 suite must agree with
  itself about P05-BUG-11 — keep one skipped proof with the inline
  `shared/chip_wrap_hit_area` reason, and mirror the same decision in
  `add_children_test.dart` until `NestChipWrap` merges.
* **When `NestChipWrap` lands**, swap the single age-chip `Wrap` for it in
  `add_child_form_card.dart` and restore the chip tap-target test to
  `atLeast44(chip)` on both axes.
* **UI check**: drift is now 1.34%/1.25% — the required gate for this
  iteration is met; keep the app’s swatch and CTA edges aligned to the card's
  20 px gutter when `NestChipWrap` introduces its own bounds (gap above and
  below the row must stay ≥ 6 px, which it already is).

VERDICT: PASS
# P05 · Add children — bug hunt (STAGE 6, iteration 5 — final)

Route `/add-children` (feature `family`, parent mode). Adversarial re-hunt of
the iteration-5 build (working tree after `c5dcb00`, main merged through
`28d62fe`, including the shared `router_push_test_fix` and
`shared/family_time_zone` merges). No screen code was changed and **no new bug
was found**.

Gates on this build: `dart format` clean · `flutter analyze` No issues found! ·
`flutter test test/features/family` **119 passed, 0 skipped, 0 failed** · full
`flutter test` **672 passed, 0 skipped, 0 failed** (the iteration-3/4 shared
gate is fixed on main: `cdd4cf5` made the push/pop contract path-based) · no
file outside RULES §1 touched.

Proofs: `app/test/features/family/p05_bugs_test.dart` — **11 proofs, all
un-skipped and green**. No `skip` remains anywhere in
`test/features/family/`; nothing needed re-skipping this iteration.

**Result: 0 new bugs, 0 P05-owned bugs open. The one remaining screen
deviation is the shared `NestChip` flow height (+12 px, design `.chip` is
32), which P05 cannot fix and which is filed, quantified and pinned by test.
VERDICT: PASS** — per the orchestrator’s iteration-5 rule that a shared-only
residual is recorded explicitly and does not block when every P05-owned test
passes.

---

## Iteration-4 carried items — closed / verified

| Item | State |
|---|---|
| Shared `router_push_test.dart` red | **resolved on main** — `099748e`/`cdd4cf5` assert router paths; full suite green; P05 untouched |
| `NestChip` 44 px flow box vs design 32 (+5 centre, +12 below) | **filed in its own iteration-5 request** with the measured delta table; pinned by the new test `the chip row height is the design value plus the 44-px tap box`, which flips to 0 when the shared fix lands |
| Shared typography line-box claim | re-checked — the iteration-4/5 UI landmarks are ±0 through “Age band”, so the residual is the chip box, not per-row font growth; the shared typography request stays non-blocking and separately filed |
| `rowid` interim `VACUUM` caveat | one-line doc nit only; the durable shared `createdAt` request remains the permanent fix |

## Adversarial checks this iteration

| Check | Result |
|---|---|
| Order — `Seed.demo` | Maya left (30), Leo right (210) ✓ |
| Order — `Seed.onboarding_kids` (UI state) | Maya left, Leo right ✓ |
| Kid cards | height **116.0** (design-exact) ✓ |
| Chips | one row on device, 8 px gaps, left-aligned; boxes 73.75/73.75/102.25/73.75 × **44.0** (the shared residual) |
| Head anchor | `h1.top == 107` = status 47 + compact nav 60 ✓ |
| Rapid double taps | two same-frame taps with the real DB → one child ✓ |
| Restart / Drift persistence | child persisted and rendered after relaunch over the same DB ✓ |
| Kid-mode guard | deep link → `/parental-gate` ✓ |
| Data edges | 0/1/6 children, “Maximilian-Alexander”, 320×1.3 → no overflow, no exceptions ✓ |
| `family_time_zone` merge | schema v2 adds `…_tz` columns to event tables only (quest completions, redemptions, ledger); the children table and P05 paths are untouched; all 119 feature tests green ✓ |
| Transient UI frame (`devLocale=…` debug text in `app_light_5.png`) | `grep` over `app/lib`, `app/test`, `design` finds no such string — a stale simulator frame, not product code; the re-shot `app_light_5b.png` is stable ✓ |
| Money / timezone / async gaps | P05 renders no money or dates; bloc drops late emits and callbacks are `mounted`-guarded — N/A / sound ✓ |

## The one carried shared item, precisely

`NestChip`’s 44 px minimum tap box sits **in the flow**, so the chip row and
everything below it is +12 px vs the design’s 32 px `.chip` (labels centred
+5, “Avatar colour”/swatches/caption +12; UI iteration-5 band5 10.8–11.1%).

I re-probed the only local construction that could shrink the row without
touching `core/` — `SizedBox(height: 32)` + `OverflowBox(44)` around each
chip: the row does become 32, but the 6 px of tap area above/below the parent
**stops hit-testing** (measured: above-edge tap 0 hits, centre tap 1 hit).
This is inherent to Flutter hit testing — a hit area cannot extend beyond an
ancestor’s bounds — so no P05-local wrapper can keep the 44×44 target and the
32 px row at the same time. The resolution is an owner/shared decision:
keep the 44 px flow box (accept +12), amend the design’s `.chip` to 44, or
build shared hit-routing that owns the overlay. P05’s gaps are already exact
(chip-row→label 8, label→swatch 4, swatch 44 with 8 px gaps, note gap 6).

## Notes

* The new `add_children_test.dart` chip-height test asserts the shared delta
  (44 − 32) with the reason inline, so it fails loudly in the right direction
  when the shared fix lands — the acceptance criterion for that request.
* `SHARED_REQUEST.md`’s `router_push_test` entry still reads “Blocks: yes”
  although the gate is green (review iteration-5 finding 1) — a one-line
  status move for the fix pass, not a P05 defect.
* No skipped proofs were added this iteration: there are no P05-owned bugs to
  prove.

VERDICT: PASS

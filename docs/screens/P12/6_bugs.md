# P12 · Money (ledger) — Stage 6 bug hunt (iteration 3)

Re-audit of the iteration-2 review findings (one major + three minors) after
their iteration-3 fixes, plus a fresh adversarial pass over the changed code
(status-band pinning, sheet `errorText`, pending-write confirmations,
same-second tie rule) and the shared `NestSegmented` semantics change that
merged into main.

Method: widget/pure probes on the in-memory and file-backed Drift databases,
including a pixel sample of the pinned status band after scrolling, a gated
repository for the pre-emission write states, and both input orders for the
owed-math tie. **No simulator was used** (stage rule; only stage 5_ui may).
No screen code was edited (stage rule).

Guards: `app/test/features/pocket_money/p12_bugs_test.dart` (23 tests — 22
active, 1 skipped: P12-BUG-04). `flutter test --run-skipped` proves BUG-04 is
still the only unresolved item (42.0 px segment width at 320 dp).

Hand-off state: `dart format` clean, `flutter analyze` → No issues found,
`flutter test` → **1914 passed / 1 skipped / 0 failed**.

---

## Findings status

| # | Severity | Status | Verified by |
|---|---|---|---|
| P12-BUG-01 | major | **FIXED** (it 2) | unbounded amount → parser cap, no overflow (active test) |
| P12-BUG-02 | major | **FIXED** (it 2) | `1,50` rejected, never £150.00 (active test) |
| P12-BUG-03 | minor | **FIXED** (it 2) | `1.005` rejected, integer-pence maths (active test) |
| P12-BUG-04 | minor | **OPEN** — shared `NestSegmented`, `SHARED_REQUEST.md` §3 | skipped test still fails at 42.0 px |
| P12-BUG-05 | major | **FIXED** (it 2) | geometry anchors ±1 px (active test) |
| P12-BUG-06 | major | **FIXED** (it 3) | status band pinned — see below |
| P12-BUG-07 | minor | **FIXED** (it 3) | sheet error attaches to Amount + live region |
| P12-BUG-08 | minor | **FIXED** (it 3) | write confirmation carries its child id |
| P12-BUG-09 | minor | **FIXED** (it 3) | `summarise()` same-second tie order-independent |

### P12-BUG-06 — status-bar band scrolled away with the ledger (major) — FIXED

**Repro (before):** scroll `/money` down; the 47 px reserve (and the title)
scrolled out because `NestStatusBar` was `ListView` child 0, so the white
history cards painted under the OS clock.
**Fix (iteration 3):** both bodies are `Column[NestStatusBar,
Expanded(ListView)]` — the band is the scroller's preceding sibling, as the
HTML/CSS defines and P05/P06/K03 already did.
**Verification:** `money_ledger_geometry_test.dart`'s new scrolled-state
guard, plus my independent probes: after a full fling to the end (light and
dark) the band rect is `(0, 0, 390, 47)`, the scroller top is 47, and a pixel
sample at (195, 24) equals `tokens.paper` — never the `tokens.surface` of a
card scrolled underneath. The empty body stays pinned at 47 through a drag.
No exception at 320 dp × 1.3.

### P12-BUG-07 — sheet error detached from the field it describes (minor) — FIXED

**Repro (before):** the inline rejection rendered as a hand-rolled block
under the *Note* field instead of the Amount field that was rejected.
**Fix:** `NestTextField.errorText` (shared invalid state: 2 px danger border
+ gutter-aligned error row below Amount, its own live region, inner text
excluded).
**Verification:** error top 532 < Note label top 566 at 390 dp; exactly one
`Enter an amount like £1.00` node with `isLiveRegion` true; clears on change
and the write then succeeds; 320 dp × 1.3 sheet keeps the CTA on screen
(Rect 20, 658 → 300, 710) with no exception.

### P12-BUG-08 — write confirmation lost/misattributed across a child switch (minor) — FIXED

**Fix:** the single pending tuple became `List<_PendingWrite>` carrying
`childId`; the listener retires entries belonging to a child the parent left
and fires on selection changes.
**Verification:** the view-test gated scenario (switch to Leo before the
round-trip → no stale Maya toast, later Leo write names Leo), plus my probe
with **two writes held before the first emission**: both rows land and both
confirmations are announced in turn (`Added £1.00 for Maya` 0–4 s, then
`Added £2.00 for Maya` from 4.25 s — the SnackBar queue loses neither).

### P12-BUG-09 — `summarise()` same-second tie (minor) — FIXED

**Fix:** the latest payout instant is located first, then `weekly_base` +
`quest_bonus` rows at/after it are summed (order-independent); the test
fallback mirrors the rule.
**Verification:** a payout and a quest bonus inserted at the same instant for
Leo give `base 0 / quests 25 / total 25` in both list orders, and the live
`watchLedgerData` stream reports the same 25.

## Shared change verified for P12

main's `shared/segmented_semantics` (`excludeSemantics: true` + `onTap` on
each `NestSegmented` option) merged into the picker P12 renders:

- exactly one semantics node per option (`find.semantics.byLabel('Leo')`
  matches once);
- it keeps `SemanticsAction.tap`, and `performAction(tap)` selects Leo and
  re-renders the hero (`Leo is owed`), announcing `selected` state.

## Fresh adversarial probes (iteration 3) — all hold

- Status band pinned after scroll, light + dark, layout + pixel (above).
- Empty body band pinned through a drag.
- Sheet error attach, live region, clear-and-write, 320 × 1.3 layout.
- Two held writes before the first emission: both rows land, both
  confirmations queue in order.
- Same-second payout/bonus tie in both orders and through the stream.
- Segmented semantics after the shared change: one node, tap works.
- Regression re-runs: parser boundary matrix, `£1,000,000` cap, geometry
  anchors, double-tap single writes, deep links, restart persistence, BST and
  Dubai zone labels, dark contrast, 320 × 1.3, empty/single-child, back from
  `/payout` — all still green in the feature suite (321 pass / 1 skip).

## No new bugs found

No blocker or major finding this iteration. The only open finding is
P12-BUG-04 at minor severity (shared control, already filed). The remaining
carried review items (`.ptitle` shared component, `next_payout.dart`
placement, retained raw error suffix, P13 `state.items` hand-off, `setup`
coupling) are documented architecture/hand-off decisions, not user-facing
bugs, and are not re-reported.

**Environment note (not a finding):** two full-suite runs failed on
`Failed to load dynamic library ... build/native_assets/macos/libsqlite3.dylib`
while a concurrent stage was rebuilding; the immediate re-runs passed
(321/1 feature, 1914/1 full). Toolchain race, not P12.

VERDICT: PASS

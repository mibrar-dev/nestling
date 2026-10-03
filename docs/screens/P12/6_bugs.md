# P12 · Money (ledger) — Stage 6 bug hunt (iteration 2)

Re-audit of iteration 1's five findings against the iteration-2 build, plus a
fresh adversarial pass over the changed code (amount parser, write-
confirmation toasts, geometry, history-row layout).

Method: the same widget/pure-test probes as iteration 1 on the in-memory and
file-backed Drift databases, with extra boundary matrices for the new parser
and the new toast confirmation flow. **No simulator was used** (stage rule;
only stage 5_ui may). No screen code was edited (stage rule).

Reproducers/guards: `app/test/features/pocket_money/p12_bugs_test.dart`
(23 tests — 22 active, 1 skipped: P12-BUG-04, the known minor cross-screen
item). `flutter test --run-skipped` proves BUG-04 is still the only
unresolved one, and that it fails exactly at the 42 px segment width.

Hand-off state: `dart format` clean, `flutter analyze` → No issues found,
`flutter test` → **1900 passed / 1 skipped / 0 failed**.

---

## Iteration-1 findings — status

| # | Severity | Status | Verified by |
|---|---|---|---|
| P12-BUG-01 | major | **FIXED** | `P12-BUG-01: an unbounded amount is clamped to int64 and overflows the history row` (now active, green) |
| P12-BUG-02 | major | **FIXED** | `P12-BUG-02: "1,50" is silently recorded as £150.00 (100x)` (now active, green) |
| P12-BUG-03 | minor | **FIXED** | `P12-BUG-03: "1.005" silently stores £1.00 (half-penny dropped)` (now active, green) |
| P12-BUG-04 | minor | **OPEN** — shared `NestSegmented`, tracked in `SHARED_REQUEST.md` §3 | `P12-BUG-04: six children at 320dp collapse the segment below the 44px tap target` (still `skip: true`; fails at 42.0 px when run) |
| P12-BUG-05 | major | **FIXED** | `P12-BUG-05: the whole stack sits 15-21px below the design` (now active, green) |

### P12-BUG-01 — unbounded amount (major) — FIXED, independently verified

`_parsePence` now validates `^\s*£?\s*(?:\d{1,9}(?:\.\d{1,2})?|\.\d{1,2})\s*$`
and caps at `maxPence = 100,000,000` (£1,000,000.00); the history row's
trailing amount is additionally bounded to `maxWidth − 64`. Probes:

- 23-digit mash → inline error, nothing written, no `RenderFlex` exception,
  no `92233720368547760` anywhere.
- `1000000` and `1000000.00` → exactly `100000000p`, rendered
  `+£1000000.00`, toast once, no overflow at 320 dp and at 320 dp × 1.3.
- `1000000.01`, `999999999.99`, `1000000000`, `10000000000` → rejected.

### P12-BUG-02 — separator stripping (major) — FIXED, independently verified

The parser no longer strips: `1,50`, `1,000`, `5 5`, `1\u00a0000`, `+5`,
`-5`, `5e3` are all rejected with `Enter an amount like £1.00` and never
reach the bloc (comma-decimal keyboards can no longer record 10–100× the
typed amount). Accepted double-checked: `£5`, `.5`, `0.01`, `1.15`, `999.99`,
`  £ 5.50 `.

### P12-BUG-03 — half-penny float rounding (minor) — FIXED, independently verified

Integer-only maths (`whole * 100 + int.parse(fraction.padRight(2, '0'))`):
`.05` → 5p, `0005.6` → 560p; `1.005` and `1.234` are rejected (no float
multiply anywhere).

### P12-BUG-04 — six children at 320 dp (minor) — OPEN (shared)

Still 42.0 × 44.0 px per option at 320 dp with six children; remains
`skip: true` by design because P12 must not fork the shared control. Fix
requested in `SHARED_REQUEST.md` §3 (44 px floor / horizontal scroll in
`core/design_system/components/nest_segmented.dart`). No P12-local workaround
is appropriate; not a blocker.

### P12-BUG-05 — geometry stack (major) — FIXED, independently verified

The extra 16 px spacer is gone from both the loaded and empty bodies; the
real-font probe now measures title top **55** (centre 72), segmented **105**,
owed card **173**, goal card **400**, history card **504** — all within ±1 px
of `ORCHESTRATOR_NOTES.md`, matching stage 5's iteration-2 table (Δ 0/+1 px)
and `money_ledger_geometry_test.dart` (10/10 green).

---

## Fresh adversarial probes (iteration 2) — all hold

- **Parser boundary matrix**: 8 accepted forms exact to the penny; 16
  malformed/rejected forms (`1000000.01`, `1,000`, `1,50`, `5.`, `+5`,
  `-5`, `5e3`, `£`, `1.234`, `.`, `..5`, `5 5`, NBSP, 10-digit wholes)
  all show the inline error and write nothing. `5.` is now rejected rather
  than silently read as £5.00 — that is the intended strict-validation
  behaviour, not a regression.
- **Rejected write** (repo throws on `addMoney`): only the error toast
  (`We couldn’t save that: …`, U+2019) appears; no `Added £5.00 for Maya`
  toast.
- **Stale confirmation**: after a rejected write, an unrelated ledger-stream
  emission does not pop the pending success toast (`_pendingWrite` is
  cleared).
- **Payout double-tap**: two same-frame taps on `Payout time` render one
  `/payout` page, not two.
- **Rapid writes**: three sequential add-money submissions each land exactly
  once, one toast each.
- **Regression re-runs**: every iteration-1 "attack that holds" stays green —
  double-tap add/save single write, six children in creation order at 390,
  long UK name at 320 × 1.3, empty ledger child, single child, £999.99,
  rapid child switching, back from `/payout`, kid-mode gate, `Seed.fresh`
  → `/welcome`, empty-state semantics tap, dark-mode contrast ≥ 4.5:1,
  Europe/London + BST labels, `Asia/Dubai` zone switch, file-backed restart
  persistence of gift/spend rows.
- **No `ledgerDataFallback` (or other test helper) in `app/lib/`** — the
  iteration-2 move stayed test-side; `grep` is clean.

## No new bugs found

No new blocker, major or minor finding survived reproduction this iteration.
Deferred review-level items (`next_payout.dart` placement, the
`MoneyLedgerData.setup` coupling, the P13 `state.items` hand-off) are
architecture notes explicitly accepted by the loop, not user-facing bugs, and
are not re-reported here. P12-BUG-04 above is the only open finding, at
minor severity.

VERDICT: PASS

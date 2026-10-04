# P17 Parental gate — 2a build logic (iteration 4)

Scope: non-UI layer only — `domain/**`, `data/**`,
`presentation/bloc/**`, plus unit/bloc tests whose names contain
`bloc`/`repository`/`data`. No view/widget edits; no DI/route edits;
no simulator use.

## CONTRACT CHANGES

None. Events, state fields, helpers, `copyWith(clearError)` and the
London-day `challengeFor` are exactly what iteration 2 shipped.

## Files changed

None in `app/lib/**` or `app/test/**` this iteration. Deliberately
so — see triage.

## FIXES_3 triage — no item in my layer

FIXES_3 carries only the 2_build section this iteration, and every
item in it is view, shared, or out-of-layer:

- The 8 remaining whole-app reds are all `kid_home` tests asserting the
  v1 scaffold title / `pageBack()` (request #1) — RULES §1 forbids P17
  from touching them, and neither can be "fixed" in the gate view
  (placeholder copy is not design copy; an AppBar back button breaks
  all 11 geometry pins).
- P17-BUG-1 (shared router loop): request #2, honestly skip-marked.
- In-feature suite is 106 pass · 1 skip · 0 red; ORCHESTRATOR_NOTES
  2–6 + scrim pins 11/11 green; requests #3 closable.

## Merge regression check (the iteration's actual work)

The `main` merge since iteration 3 touched shared core my layer
depends on (`app_database` v6→v7 + `watchMembers`, `family_time` zone
aliases, `seed` owner email, new `ids.dart`). Reviewed each diff:
all additive, no signature change to `toFamilyZone` /
`defaultFamilyZoneId` / `appNowUtc` / `Seed.demo|empty`. The new IDS
rule (`newId(prefix)`) does not apply — this layer creates no rows.
Re-ran everything anyway:

- `flutter analyze lib/features/parental_gate` + my two test files →
  No issues found!
- bloc + repository files → +38, all pass (25 + 13).
- `p17_bugs_test.dart` P17-BUG-2 / P17-BUG-3 proofs by `--plain-name`
  → +1 / +1, all pass (widget tests in that file not run — view
  territory).
- No `google_fonts`, no letterSpacing, no `DateTime.now()` in lib, no
  simulator.

## LEFT FOR NEXT ITERATION

- Nothing in this layer. Standing notes (unchanged): midnight re-key
  needs a timer the plan's Drift-only contract does not provide;
  4_review finding 2 contradicts `1_plan.md` §(b) and would need a
  joint iteration with the UI builder if ever mandated.

VERDICT: PASS

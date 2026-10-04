# P16 Settings — Stage 2 INTEGRATE (iteration 4)

Job: make the two parallel halves (`2a_build_logic.md` + `2b_build_ui.md`)
compile and pass together. Smallest change, no redesign.

**Outcome: PASS on the gates — analyze clean, full suite green, no integration
breakage, and I changed no product code and no test.**

The thing to read is not a build failure: the orchestrator appended a new
mandatory `ORCHESTRATOR_NOTES` block **two minutes after both builders' briefs
were generated**, so its three "LAST pass" items never reached either builder.
All three are still open. Timestamps and evidence below, because two of the
three need an orchestrator decision rather than another build pass.

## Gates (this worktree, `app/`)

```
$ dart format .
Formatted 537 files (0 changed) in 1.50 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 4.0s)

$ flutter test
01:20 +3025 ~3: All tests passed!
```

Zero failures. The `~3` is **one** P16 skip (B09), K01's
`k01_bugs_test.dart:566` (new — arrived with `Merge screen/K01`, not P16's)
and P12's pre-existing one. P16's own skip count is unchanged at 1.

## Summary of the two halves

**2a — logic: no changes, again.** I verified rather than trusted: no touched
path under `settings/domain`, `settings/data`, `settings/presentation/bloc` or
`settings_di.dart`. Contract changes: **none.** Every open FIXES_3 item was
audited for a logic-layer hook and none has one (B11 is wrapper geometry in
views, B10 is a view tap handler, B09 is the shared tz helper). Its 39 tests
pass; CLOCK re-verified clean.

**2b — UI: two fixes, both with live proofs.**

1. **P16-B11 (major, switches 34.5 px off the right edge) — FIXED.** The T02
   wrapper became `SizedBox(width: 51, height: 44, Center(NestToggle(…)))` on
   all three switch rows, so it no longer stretches to the row's 120 px
   trailing cap and the track sits flush with the row's 16 px right inset
   (x 303–354 at 390; 233–284 at 320). Proof live and green.
2. **P16-B10 (minor, the guard missed the delete and invite rows) — FIXED.**
   Both `onTap`s now route through `P16TransientGuard.run` like every other
   navigational row. Proof live: a double-tap on Cancel no longer re-opens the
   dialog, and a picker double-tap landing on the delete row no longer opens it.
3. **P16-B09 — still not fixed, correctly.** Shared `isKnownZoneId` root
   cause; `SHARED_REQUEST` §5.

**2b also found a real harness coupling while fixing B10** — worth recording
because it is exactly the class of thing an integrator should catch:
`settings_view_test.dart` pumps a raw `SettingsView` without the route harness,
so it never went through `P16TransientGuard.reset()`, and fencing the delete
row broke its modal-open test on a stale 300 ms guard window. Reset added to
that file's pump helper too.

## Independent verification

| claim | how I checked | result |
|---|---|---|
| 2a changed no logic file | `git status` filtered for domain/data/bloc/DI paths | empty — confirmed |
| B11 + B10 + T02 + B08 really live | each proof name present in the passing run; **0** `[E]` markers for any of them | confirmed |
| only one P16 skip remains | whole tree has exactly 3 `skip: true`; the non-P16 two are K01's (from main) and P12's | confirmed |
| guard reset covers every pumping path | `pumpSettingsApp` is defined once in `p16_test_support.dart` and calls `_resetTransientGuard()`; all 38 pump sites in a11y/navigation/responsive go through it, and `settings_view_test.dart` resets in its own helper | confirmed, no coverage hole |
| T02 survived the B11 wrapper change | T02 proof still live and green with `width: 51` added — both findings pinned on one layout | confirmed |
| CLOCK rule | 0 hits for `DateTime.now()` in the feature; the guard uses `clock.now()` | confirmed |
| nothing outside the allowed paths | all changed paths are under `lib/features/settings/**`, `test/features/settings/**`, `docs/screens/P16/**` | confirmed |

## The 08:12 "LAST pass" mandate: 0 of 3 items reached the builders

`ORCHESTRATOR_NOTES.md` was modified at **08:10**. Both builders' briefs were
generated at **08:08**. Their notes were written at 08:08 and 08:14. The
mandate therefore post-dates the briefs by two minutes, and neither builder
could have read it — which is the whole explanation for what follows. This is
not one of the three ignorable process items (uncommitted work / behind `main`
/ merge order); it is a dispatch-order gap, and it is fixable by regenerating
briefs after touching `ORCHESTRATOR_NOTES.md`, or by having the builder re-read
that file at start-up.

| mandate item | state |
|---|---|
| **1** — fix B11, fix B09 + B10, un-skip all four proofs | **partially met by the FIXES_3 work the builders did see**: B11 ✓, B10 ✓, T02 and B08 still live ✓. **B09 remains the one skipped proof** (shared §5) |
| **2** — parent email from the DB, "the seed holds that value" | **not met, and unsatisfiable as written** — the premise is false; see below |
| **3** — un-fork `_P16Sect`, the subcard and `SettingsRow`; keep the shared components | **not met** — all three forks still present (`_P16Sect` ×9 refs, the local `p16_subcard` container, `SettingsRow` ×6) |

### Item 2's premise is false — measured, not assumed

The ruling says the parent's email must come from the DB because "the seed
holds that value". It does not:

- `grep -i email` over `app_database.g.dart` **and** `lib/core/data/*.dart`
  returns **0 hits**. No table in the schema has an email column.
- The omission is deliberate and already documented by the auth feature:
  `auth_repository_impl.dart:38` — *"the members table has no email/password
  columns"*; `:41` uses the submitted email **only** to derive the owner
  display name (which is how the name `Sarah` exists at all);
  `auth_repository.dart:9-17` repeats it and asks the orchestrator to migrate
  the shared test.
- `sarah@example.co.uk` appears in `lib/` in exactly two places: P16's
  hard-coded subtitle (`settings_view.dart:468`) and the design-system gallery
  as a form `hintText` (`gallery_forms.dart:21`) — placeholder copy in both.

So there is nothing to read and no seed value to surface. The ruling's own
fallback ("if the DB lacks a field, write SHARED_REQUEST.md") is what applies,
and I sharpened **§4** with this evidence plus the two ways to close it
(role-derived subtitle = no schema change; or persist the email, which is free
at signup because the value is already in hand — only the schema and the auth
contract change). Four P16 tests assert that literal, so they follow whichever
way it is decided.

### Item 3 is now unambiguous, and it overrides my iteration-3 reasoning

Last iteration I declined to force the reverts, reasoning that the shared fix
should land first. The 08:12 note settles it: *"If they really differ from the
design, record the numbers in `SHARED_REQUEST.md` and **keep the shared
ones**. Do not fork."* The numbers are already recorded (§2 line box ~15.7 vs
18 px; §3 radius 16 vs 24, plus the `Material` loss), so the sequence the
orchestrator wants is: revert to the shared components **now**, accept the
re-measured drift, and let the shared batch close the gap. 2b has not done it
and could not have been asked. I did not do it either — reverting three
components changes the rendered geometry of the whole screen and invalidates
the geometry tests that pin today's numbers, which is a redesign, not an
integration fix. It needs a build stage with the mandate actually in the brief.

## FIXES accounting

| item | severity | status |
|---|---|---|
| P16-B11 switches 34.5 px off the right edge | major | **DONE** (2b) — proof live |
| P16-B10 guard missed delete + invite rows | minor | **DONE** (2b) — proof live |
| P16-B09 linked IANA ids | minor | **LEFT — correctly shared-blocked**, §5 |
| P16-T02 switch 44 px target | major | **still fixed and proved** (iteration 3), survives the B11 wrapper change |
| P16-B08 modal-close double tap | minor | **still fixed and proved** (iteration 3) |
| P16-T01 delete-confirm navigator | blocker | closed in iteration 2, proofs green |
| B01–B06 (iteration 1) | — | all still closed, no regression |
| obs 1 dialog Cancel wraps at 320 @1.3 | cosmetic | **LEFT** — shared `NestButton` padding |
| obs 2 subcard ripple behind the card | cosmetic | **LEFT** — now a symptom of the fork; §3 |
| obs 3 T02 write-up "~36 px" vs 51×31 | doc | harmless |
| 3_test §4.4 #2 Family list announces as one node | minor | **LEFT — shared** (`NestListRow` no-`onTap` branch); 2b's local attempt broke the tappable-node contract |
| hard-coded `sarah@example.co.uk` | minor | **LEFT — now measured as unsatisfiable**; §4 rewritten |
| `_P16Sect` per-build `TextPainter` | perf | accepted and documented by 2b |

## Left for the next stage

1. **Dispatch order** — regenerate briefs when `ORCHESTRATOR_NOTES.md` changes,
   or have the builder re-read it at start-up. Three mandatory items were lost
   to a 2-minute gap this iteration.
2. **Orchestrator: item 2** — the seed does not hold an email; choose the
   role-derived subtitle (cheap) or authorise the schema change (§4).
3. **Orchestrator: item 3** — the reverts are wanted *before* the shared fix,
   not after; they need a build stage whose brief carries the mandate.
4. **P16-B09** waits on `SHARED_REQUEST` §5.
5. **Stage 5 owns a remeasure** — `ui=PASS` predates B10/B11, and B11 changed
   the toggle's horizontal geometry, which the alignment/UI verdict rules care
   about.
6. No simulator was booted, installed on, screenshotted or driven.

## Code changed by this stage

**None** — no `lib/**` change, no test edit, no lint weakened, no `// ignore:`,
no test skipped, `analysis_options.yaml` untouched, no shared file touched.

Docs only: rewrote `SHARED_REQUEST.md` §4 with the iteration-4 measurement that
the 08:12 email ruling rests on a false premise, and the two ways to close it.

---

# Appendix — iterations 1-3 in one line each

- **Iteration 1:** built from `1_plan.md`; fixed the one integration breakage
  (`today_view_test.dart` anchoring on the deleted placeholder `P16 Settings` →
  `pushedPath`) and proved the combination green on `main` (`+2741 ~1`).
- **Iteration 2:** integrated clean, zero code changed; proved the remaining
  skip was honest rather than hiding a green test; filed `SHARED_REQUEST.md`
  §1-§4 for four "LEFT" items with no carrier.
- **Iteration 3:** integrated clean, zero code changed; T02 + B08 closed with
  live proofs; flagged that the 06:58 un-fork mandate was unactioned and
  argued for shared-fix-first sequencing (the 08:12 note overrode that
  reasoning — see item 3 above).

VERDICT: PASS
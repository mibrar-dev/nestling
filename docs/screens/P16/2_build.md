# P16 Settings — Stage 2 INTEGRATE (iteration 3)

Job: make the two parallel halves (`2a_build_logic.md` + `2b_build_ui.md`)
compile and pass together. Smallest change, no redesign.

**Outcome: PASS on the gates — analyze clean, full suite green, and I changed
no product code and no test.** The halves integrated without a single
breakage. What needs the orchestrator's attention is not a build failure: it is
**mandatory `ORCHESTRATOR_NOTES` item 1 (added 06:58, this iteration), which
2b did not action**, and I deliberately did not force it. Reasoning below.

This supersedes iteration 2's `2_build.md`, which is summarised in the appendix.

## Summary of the two halves

Iteration 2 ended `test=FAIL bugs=FAIL`, so iteration 3 worked
`FIXES_2.md`: one open test bug (T02), two open bug-hunt findings (B08, B09),
three observations, and a new mandatory `ORCHESTRATOR_NOTES` update.

**2a — logic: no changes at all.** Contract changes: **none.** I verified this
rather than trusting the note — `git status` shows no touched path under
`settings/domain`, `settings/data`, `settings/presentation/bloc` or
`settings_di.dart`. 2a audited every open FIXES_2 item for a logic-layer hook
and correctly concluded none has one: hit-test geometry is a layout concern
(T02), the stray modal-close tap lands on a row that calls `context.push`
(B08), and the B09 root cause is a shared helper (below). Its own 39 tests pass.

**2b — UI: two real fixes, one correctly refused.**

1. **P16-T02 (major, owner 44 px rule) — FIXED.** The three switch rows now
   render through P16's `SettingsRow` at 6 px vertical padding (content box
   56 − 12 = 44) *and* each `NestToggle` sits in a
   `SizedBox(height: 44, Center(…))`. 2b's finding is the useful part: padding
   alone does **not** restore the slop — the 44-high wrapper around the toggle
   is what makes the overhang hittable. Proof is live (`skip: false`).
2. **P16-B08 (minor, double-tap fall-through) — FIXED** with a new
   `P16TransientGuard` (`presentation/widgets/p16_transient_guard.dart`): every
   modal/sheet close records the instant via `clock.now()`, and every page-level
   row tap routes through `P16TransientGuard.run`, which swallows taps for
   300 ms. CLOCK-rule clean (uses `clock.now()`, not `DateTime.now()`), and the
   static is reset in test support, which fixed a real order-dependent leak (a
   picker test that passed alone but failed in the full run).
3. **P16-B09 (minor, linked IANA ids) — correctly NOT fixed.** I verified the
   root cause is shared and unreachable from the feature: `isKnownZoneId`
   (`core/data/family_time.dart:37`) calls `tz.getLocation(id)` against the
   bundled `latest_10y` dataset, which ships **no backward links**, so
   `Europe/Amsterdam` reads as unknown and `FamilyZoneService.deviceZoneId()`
   returns null — the raw id never reaches the bloc, so there is genuinely no
   feature-side workaround. Already filed as `SHARED_REQUEST.md` §5.

## Gates (this worktree, `app/`)

```
$ dart format .
Formatted 525 files (0 changed) in 2.24 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 5.8s)

$ flutter test
01:51 +2852 ~2: All tests passed!
```

Zero failures. The `~2` is `p16_bugs_test.dart:530` (P16-B09, shared-blocked)
and the pre-existing `p12_bugs_test.dart:321` (another feature). Two proofs
moved from skipped to **live guards** this iteration (T02, B08), so the skip
count is down by one against iteration 2.

## FIXES accounting

| item | severity | status |
|---|---|---|
| P16-T02 switch tap target ≈36 px | major | **DONE** (2b) — proof live, taps ±5 px outside the track |
| P16-B08 double tap during modal close falls through | minor | **DONE** (2b) — proof live |
| P16-B09 linked IANA ids read as unknown | minor | **LEFT — correctly shared-blocked**; `SHARED_REQUEST` §5 filed |
| P16-T01 delete-confirm pops the right navigator | blocker | closed in iteration 2, proofs still green |
| B01/B02/B03/B04/B05/B06 (iteration 1) | — | all still closed; no regression |
| obs 1 delete-dialog Cancel wraps at 320×568 @1.3 | cosmetic | **LEFT** — inside `NestButton`'s wrap-by-design contract; would need a shared dialog-button padding |
| obs 2 subcard ripple paints behind the card | cosmetic | **LEFT, now evidenced** — see below |
| obs 3 T02 write-up says "~36 px" where measurement is 51×31 | doc | harmless; the shared fix is unaffected |
| 3_test §4.4 #2 Family list announces as one button | minor | **LEFT — shared** (`NestListRow`'s no-`onTap` branch merges semantics); 2b tried a local label and rejected it because it broke the tappable-node contract across the whole section |
| `_P16Sect` runs a `TextPainter.layout()` per build | perf | **accepted by 2b**, documented as intentional; no measurable cost |
| hard-coded `sarah@example.co.uk` | minor | **LEFT** — `members` has no email column; `SHARED_REQUEST` §4 |

## The one thing I did not action: `ORCHESTRATOR_NOTES` item 1

The 06:58 update is mandatory and says, in full:

> 1. Do NOT fork shared components. Revert `_P16Sect` to the shared
>    `NestSectionLabel`, and the subcard to `NestCard`. If the shared label or
>    card does not match the design, write SHARED_REQUEST.md with the measured
>    numbers and the orchestrator will fix the shared one.

**2b kept all three local forks** (`SettingsRow`, `_P16Sect`, the `p16_subcard`
container) and said so plainly. I verified it: `_P16Sect` renders all seven
section labels, and the subcard is still a local `Container`.

I did not revert them, for three reasons:

1. **It is a redesign, which my brief forbids.** Swapping the section label and
   the card shell changes the rendered geometry of seven sections and one card
   — not an integration fix.
2. **It would re-open a UI failure the loop is actively closing.** The
   orchestrator's own conditional exists precisely because the shared
   components are still wrong: `NestSectionLabel` pins an 18 px line box where
   the browser's natural 13 px Inter line height is ~15.7 px, which `5_ui`
   measured as ~+1–2 px of drift *per section* (children card +4, subcard +6) —
   a breach of the ±2 px UI verdict rule. Reverting to the shared label today
   restores that drift immediately.
3. **The note's escape hatch is already satisfied.** "If the shared label or
   card does not match the design, write SHARED_REQUEST.md with the measured
   numbers" — `SHARED_REQUEST.md` §2 and §3 carry exactly that, and I added the
   concrete symptom to §3 this stage: `NestCard` wraps its child in a
   `Material` (`nest_card.dart:71`) and the local `Container` does not, so the
   `Manage subscription` ripple paints on the Scaffold's Material **behind** the
   card (bug-stage observation 2). The fork is therefore not style-only — it
   also drops a Material, which is a symptom the orchestrator can weigh.

So the correct sequence is **shared fix first, reverts second**, and the
decision is the orchestrator's. Flagging it as the one mandatory item still
open; it is not a build or test failure and it did not affect the gates.

Items 2 and 3 of the same update: **item 2 is satisfied** (T02 live, and the
proof taps 5 px outside the track — stricter than the mandated 4 px); **item 3
is partially satisfied** — B08 closed, B09 genuinely unsatisfiable without the
shared change its proof depends on, already filed as §5.

## Independent verification (I did not take the notes' word for it)

| claim | how I checked | result |
|---|---|---|
| 2a changed no logic file | `git status` filtered for domain/data/bloc/DI paths | empty — confirmed |
| T02 really closed | proof is `skip: false` (a11y test line 342) and taps `track.top − 5` / `track.bottom + 5`, asserting the **DB row flips**; suite green | confirmed |
| B08 really closed | proof carries no `skip:`; guard reads `clock.now()` (CLOCK rule) and is reset in `p16_test_support.dart:96` | confirmed |
| B09 really is unfixable here | `isKnownZoneId` → `tz.getLocation` against a links-less dataset; raw id never reaches the bloc; RULES §1 forbids editing `core/` | confirmed |
| guard cannot swallow the move prompt | the banner's Switch / Not now `onPressed`s dispatch straight to the bloc, **not** through `P16TransientGuard.run`; only list rows are fenced | confirmed |
| CLOCK rule | `DateTime.now()` → 0 hits in `lib/features/settings/`; guard uses `clock.now()` | confirmed |
| no skip added to go green | whole tree has exactly 2 `skip: true`: B09 (`p16_bugs_test.dart:530`, present since the bug hunt) and P12's pre-existing one. T02 and B08 moved the other way | confirmed |
| nothing outside the allowed paths | every changed path is under `lib/features/settings/**`, `test/features/settings/**` or `docs/screens/P16/**` | confirmed |
| §5 reference resolves | `SHARED_REQUEST.md` really has a §5 for B09 (I expected a dangling ref; it is not dangling) | confirmed |

## Left for the next iteration

1. **Orchestrator: item 1 sequencing.** Land `SHARED_REQUEST` §2/§3 in the
   shared components, then the `_P16Sect` → `NestSectionLabel` and subcard →
   `NestCard` reverts become safe (and §3's radius parameter removes the ripple
   defect with them). Until then the forks stay, deliberately.
2. **P16-B09** waits on `SHARED_REQUEST` §5 (`isKnownZoneId` link support);
   its proof stays skip-marked with the reason inline.
3. **T02's screen-local recipe** (`SettingsRow` 6 px padding +
   `SizedBox(height: 44)`) should be retired when `SHARED_REQUEST` §1 lands in
   the shared toggle/row.
4. **Stage 5 owns the remeasure** of the yard metrics; iteration 2's UI stage
   passed (`ui=PASS`) before these two fixes, and both change row geometry, so
   the numbers want a fresh look.
5. Cosmetic, unowned: stale wording in `settings_a11y_test.dart` — the T02
   block still opens "P16-T02 open (major…)" and then says "FIXED in
   iteration 3". Confusing in a live guard; left verbatim so 2b can word it.
6. No simulator was booted, installed on, screenshotted or driven.

## Code changed by this stage

**None** — no `lib/**` change, no test edit, no lint weakened, no `// ignore:`,
no test skipped, `analysis_options.yaml` untouched, no shared file touched.

Docs only: added the `Material`-loss symptom to `SHARED_REQUEST.md` §3, which
strengthens a request that already existed (it does not create new shared work
for this screen).

---

# Appendix — iterations 1-2 in one line each

- **Iteration 1:** two halves built from `1_plan.md`; I fixed the single
  integration breakage (`today_view_test.dart` anchoring on the deleted
  placeholder `P16 Settings` → `pushedPath`) and proved the combination green on
  `main` (`+2741 ~1`).
- **Iteration 2:** halves integrated clean, zero code changed; I verified the
  contract alignment, proved the one remaining skip was honest rather than
  hiding a green test, and filed `SHARED_REQUEST.md` §1-§4 because four "LEFT"
  items had no carrier.

VERDICT: PASS
# K11 · Badges — stage 6 bug hunt (iteration 2)

Adversarial pass over `/badges` (feature `badges`, kid mode) on the
iteration-2 tree, after the build fixed the two iteration-1 bugs
(`ORCHESTRATOR_NOTES.md` 03:04). Result: **both fixes verified, no new bugs
found** — no major bug exists, so the stage verdict is PASS.

No file under `app/lib/` was touched by this stage. Only
`app/test/features/badges/k11_bugs_test.dart` and this file changed.

## Bugs — status

### K11-BUG-1 — `happyDays` was never clamped to the seven drawn days — FIXED, verified

- **Severity (when open):** minor (a stored value outside the schema's
  documented 0..7 rendered “8 happy days” under seven dots).
- **Original repro:** write `happyDays = 8` for Maya, open `/badges` →
  why-line claimed a day the Mon–Sun row cannot draw.
- **Fix (iteration 2):** `HappyWeekCard.build` clamps once
  (`final days = happyDays.clamp(0, 7)`) and passes `days` to both the dots
  and `HappyWeekCopy.why`; `why` clamps too (defence in depth). The
  repository still reports the stored value verbatim (pinned by
  `badges_repository_test.dart`), so the 0..7 framing stays a screen concern.
- **Regression guard:** `K11-BUG-1 happyDays 8 clamps to the seven drawn
  days` in `k11_bugs_test.dart` — **un-skipped and passing** (7 checks,
  “7 happy days this week…”, no “8 happy days”).

### K11-BUG-2 — no active child fell back to the hard-coded `'maya'` — FIXED, verified

- **Severity (when open):** minor (deep-link/cleared-state edge; a family
  whose children are not named Maya saw a shelf belonging to no child).
- **Original repro:** a family whose only child is Zoe (one earned badge,
  `happyDays 2`), `activeChildId` null → `/badges` showed
  “No shiny ones yet…” and no `Got it!`.
- **Fix (iteration 2):** `watchActiveBadges` combines `app_state` with the
  family roster and `_resolveChildId` returns the persisted id when it names
  a real child, else the first child in creation order (CHILD ORDER ruling),
  else null → an empty `BadgesData` (childless empty state). `watchItems`
  rides the same path; no hard-coded id remains in the feature.
- **Regression guard:** `K11-BUG-2 a non-Maya family with no active child
  shows Zoe` in `k11_bugs_test.dart` — **un-skipped and passing** (Zoe's
  “One shiny one already.”, one `Got it!`, nine cells).
- **Harness fix:** the iteration-1 test wrote several rows in raw awaits
  before the first pump, which left the Drift streams silent under
  `flutter_test`'s fake-async zone (the build stage's “write-then-subscribe
  silence”). The guard now pumps first and issues **one DB write per
  `tester.runAsync` with a pump between writes** — reliable and passing.

## Iteration-2 hunt — checked, no bug found

Repository-level probes (real async, temporary file, deleted afterwards):

| Probe | Result |
|---|---|
| R1 empty family → add child → remove child, live | empty shelf → Zoe's shelf (1 earned, 2 days) → empty shelf; no stream errors |
| R2 six children, active null | resolves Zoe (added first), **not** Adam — creation order, not alphabetical; explicit `activeChildId` wins (kid5, 5 days); deleting the active child falls back to Zoe |
| R3 deleting the active child (Leo) | falls back to the first child (Maya, 4 earned / 4 days), no crash |
| R4 10 concurrent switch+write bursts | no emission from the switched-away child ever landed after the switch (review finding 3 remains hardening-only) |
| R5 `watchItems`/`getItems` with no children | empty list, no hang |

Widget-level probes (temporary file, deleted afterwards):

| Probe | Result |
|---|---|
| W1 no children at all (live, after demo loaded) | kid empty state “No badges yet” + chrome, grid and week card hidden |
| W2 `activeChildId` null with the demo family | first child Maya, “Four shiny ones already.”, nine cells |
| W3 childless → add Zoe → add her earned badge, live | shelf appears with “2 happy days…”, then “One shiny one already.” + one `Got it!` |

Re-verified from iteration 1 (unchanged code paths, still clean): rapid
double tap on Back (single push and a two-deep stack — one pop), lock
double-tap guard (stage-3 a11y/view tests), whole-screen 320 px × 1.3 text
scale overflow (now pinned by `badges_matrix_test.dart` at 3 widths × 2
scales × 2 themes), long badge titles, dark mode, app-restart persistence,
nine-id medal art (`badges_art_test.dart`), timezone/money (N/A — no clock,
no £ on K11).

**Harness note (not a product bug):** a second DB write inside the same
`tester.runAsync` after a write that triggers a Drift stream re-query
deadlocks (the re-query is scheduled in the fake-async zone and the next
write queues behind it). One write per `runAsync` + pump is reliable. The
build stage hit the same behaviour; it reproduces with and without the
resolution change.

## Verification

```
dart format test/features/badges/k11_bugs_test.dart          → clean
flutter analyze test/features/badges/k11_bugs_test.dart      → No issues found!
flutter test --timeout 120s test/features/badges/k11_bugs_test.dart
  → +2: All tests passed!            (both guards un-skipped)
flutter test --timeout 120s --concurrency=1 test/features/badges
  → +144: All tests passed!          (feature suite, 0 skipped, 0 failed)
```

No simulator was booted, no `flutter clean`, no global kills (only my own
orphaned test PIDs), no files outside
`app/test/features/badges/k11_bugs_test.dart` and `docs/screens/K11/6_bugs.md`
were touched by this stage.

VERDICT: PASS

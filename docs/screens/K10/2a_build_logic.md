# K10 · Payout day — 2a BUILD (logic chunk, iteration 2)

Iteration 1 built the layer (`1_plan.md` §b/§f.1/§f.2 — see this file's
iteration-1 revision in git history). This iteration fixes every `FIXES_1.md`
item in the logic layer and un-skips its proofs.

## CONTRACT CHANGES

None. No event/state shape changed (the UI builder's plan contract stands):

- `goalPercent` keeps its signature; only the VALUE is fixed (clamped,
  K10-BUG-2). Demo/seeded readings are unchanged (62 / 66); only overshoots
  move (142 → 100).
- The close guard is a private `_closing` flag — invisible outside the bloc.
- `KidJarPayoutRequested / KidJarPayoutReceived / KidJarState.payout /
  copyWithPayout / watchLatestPayout` all unchanged.

## Files changed

- `app/lib/features/kid_jar/domain/entities/payout_celebration.dart`:
  **K10-BUG-2** — `goalPercent` is now `(goalFraction * 100).round()` (the
  clamped fraction, K09 `JarGoalCard.percent` precedent) instead of dividing
  the raw saved amount. Saved 3550/2499 reads `100% there!` under the full
  bar with `£0.00 to go`, never `142% there!`.
- `app/lib/features/kid_jar/presentation/bloc/kid_jar_bloc.dart`:
  **K10-BUG-1** — same-tick close guard on BOTH `_onPayoutRequested` and
  `_onLoadRequested` (the K09-BUG-7 shape, applied to both handlers per the
  fix note). The guard checks a private `_closing` flag set synchronously
  as the first line of `close()` — deliberately NOT `isClosed`: `isClosed`
  flips only when the state controller closes, which is the LAST step of
  `Bloc.close()` (bloc 9.2.1 `src/bloc.dart:313`), so it is still false
  while a same-tick queued load runs during close (verified: the first
  `isClosed`-only attempt still leaked, `live=1`). `add()` delivers
  asynchronously, so no queued handler can run before the flag is set.
- `app/test/features/kid_jar/kid_jar_bloc_test.dart`: K10-BUG-1 regression
  (payout request + close → 0 live subs, leftover emit is a no-op) + the jar
  handler's twin (K09-BUG-7 shape, since that handler was touched too).
- `app/test/features/kid_jar/payout_celebration_test.dart`: K10-BUG-2
  regression at entity level (`goalPercent == 100` on overshoot) and repo
  level (`recordPayout(2000, move 2000)` → saved 3550, `£0.00 to go`, full
  bar, `100% there!`).
- `app/test/features/kid_jar/k10_bugs_test.dart`: un-skipped the three
  logic-layer proofs the stage prompt instructs to un-skip (K10-BUG-1,
  K10-BUG-1b, K10-BUG-2 — `skip:` removed, plus a two-line header note).
  Nothing else in that file touched; the `avoid_escaping_inner_quotes`
  lint the test stage saw there is gone (`flutter analyze` clean).

## Items done

- K10-BUG-1 (minor, latent): fixed + proven live (bugs-stage proofs pass:
  `--run-skipped --plain-name 'K10-BUG-1'` → +2 green).
- K10-BUG-2 (minor): fixed + proven live (`--plain-name 'K10-BUG-2'` → +1,
  `100% there!` on screen).
- Verified: `dart format` clean; `flutter analyze` clean on lib feature +
  all touched test files; `test/features/kid_jar` → **+265 ~6, All tests
  passed!** (remaining skips: K10-BUG-3's matrix proof + pre-existing K09
  skips). No simulator booted/driven; pinned clock; no `DateTime.now()`;
  no `google_fonts`.

## Deliberately NOT changed (out of this layer, per stage scope)

- **K10-BUG-3** (major, 320 px / 1.3× truncation): the two sites are
  `presentation/widgets/payout_note.dart` + `payout_fund_card.dart` — UI
  builder's layer. Its matrix proof stays skipped for them to un-skip.
- Review finding 1 (truncated doc comment) + finding 2 (write-only
  `message` param): both in `payout_day_view.dart` — UI builder's layer.
- Review finding 3 (stale `errorMessage` during payout reload): kept the
  K03/K09 precedent — a loading retry keeps the error until a healthy
  emission clears it, pinned by my `kid_jar_bloc_test` retry tests AND the
  K09 equivalents. Clearing only the payout half would fork the two
  handlers' contract for an invisible state. Revisit only if both handlers
  change together.
- Review finding 4 (newest- vs oldest-match companion move): kept the
  plan-specified semantics (`1_plan.md` §b: first/newest `Jar → …` at/after
  the payout instant). The bugs stage explicitly did not file it
  ("hardening, not a defect in the demo path"); changing match order would
  fork the plan both builders code against.
- No `SHARED_REQUEST` (nothing shared touched; plan §g still holds).

## LEFT FOR NEXT ITERATION

Nothing in the logic layer. Not run (integrator's job): whole-app
`flutter test`, `shot.sh`/simulator UI check (only stage 5_ui may use a
simulator).

VERDICT: PASS

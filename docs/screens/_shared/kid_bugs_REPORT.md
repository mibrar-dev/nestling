# Shared kid bugs — fix report (`shared/kid_bugs`)

Branch `shared/kid_bugs` from `main`. Minimal, backward-compatible shared + feature fixes for the open kid-screen proofs. No `core/design_system`, no `app/` touched. `dart format`, `flutter analyze` → No issues found. `flutter test --timeout 120s --concurrency=1` → all pass (5287+).

## Files changed

**Product (`app/lib/features/…`, allowed by the task — each bug names its screen):**

- `kid_jar/data/kid_jar_repository_impl.dart`
  - `moveToSavings`: reject before any write when the goal is missing or belongs to another child (`if (goal == null || goal.childId != childId) return;`), then cap at the remainder. Money never leaves the jar to nowhere (K09-BUG-8/8b). Dropped the now-unreachable `goal == null` ternary and the `if (goal != null)` guard (promoted non-null).
  - `_relativeDay(date, nowUtc)`: Today (same London day) / Yesterday (previous London day) / `This <weekday>` (current London week Mon–Sun) / `Last <weekday>` (previous week) / dated (`Sun 20 Sep` via `formatLondonDay`, UK format, family zone — demo family is London) / `Coming up <date>` for future London days, never a day claim (K09-BUG-10). Caller now passes `appNowUtc()` (was `londonWeekStartUtc`). Yesterday takes precedence over This (e.g. Tue→Mon reads Yesterday, not This Monday); Today over This. Future uses Coming up (not exclusion) so money never disappears (K09-BUG-8 principle) and echoes the hero’s `coming on <weekday>` future voice. K10’s celebration is the latest past payout, so no future `This` leaks there either.
- `kid_jar/presentation/widgets/jar_history_card.dart` — amount in `Flexible` + `FittedBox(scaleDown, centerRight)`, so large amounts shrink to fit at 320 px × 1.3 instead of overflowing (K09-BUG-9). Scale 1.0 at 390/1.0 (pixel-identical).
- `kid_jar/presentation/widgets/payout_fund_card.dart`
  - h2 wraps freely (dropped `maxLines: 2`/`ellipsis`; K10-BUG-3 note precedent, design sets no clamp) so long goal names grow the card at 320/1.3 (K10-BUG-4).
  - Reached goal (`target > 0 && saved >= target`) shows `Goal reached!` instead of `£0.00 to go` beside `100% there!` under the full bar (K10-BUG-2). Design has no reached copy (`K10-payout-day.html` only shows `£8.49 to go`/`66% there!`), so the else-branch `Goal reached!` applies. Zero-goal (target 0) keeps `£0.00 to go`.
- `kid_home/presentation/bloc/kid_home_bloc.dart` — `_onProfilesReceived` clears an orphaned `selectedProfileId` when its id is absent from the new roster (K01-BUG-7 backstop).
- `kid_home/presentation/views/profile_picker_view.dart` — orphan listener (`tapped == null`) dispatches `KidHomeSelectionHandled` as well as releasing `_busy`, so the bloc gate does not drop every later tap (K01-BUG-7).
- `kid_home/presentation/views/quest_complete_view.dart`
  - Count row: one-line `Row` uses `Expanded` flex proportional to measured widths (was equal `Flexible`), so asymmetric pairs (4-digit count + short `Next:`) fit with no ellipsis; stacks only when the pair sum exceeds the card (K05-BUG-5). Seed 175 stays one line at the same painted positions.
  - Growth: passes `displayFraction = percent/100` (floored) to `NestProgress` as well as the label, so the node value (`(f*100).round()`) matches the floored label (99/69/49 for 249/174/124) without touching `core/design_system` (K05-BUG-6). Seed 175 → 0.7 unchanged.
- `kid_home/presentation/widgets/kid_style_helpers.dart` — deleted feature-local `kidAvatarInitial` (K02). All call sites use shared `nestAvatarInitial`.
- `kid_home/presentation/views/kid_pin_view.dart` — uses `nestAvatarInitial` (was `kidAvatarInitial`); dropped the now-unused helpers import (K02).
- `pip/presentation/widgets/pip_growth_card.dart` — floors like K05 (`fraction >= 1 ? 100 : (fraction*100).floor()`, was `.round()`), and passes `displayFraction` to the bar so label/value agree (K05-BUG-2 parity + K05-BUG-6 shape). Seed 175 → 70 unchanged; 249 → 99 (not 100).
- `pip/presentation/widgets/pip_evolution_stats.dart` — measures the widest of the three numbers once (`TextPainter` with live scaler) and applies ONE shared `scale = contentWidth/widest` (clamped 0..1, accounting for 3 px borders + 6 px padding) as a uniform `fontSize`, so all three stay equal with no clipping (K07-BUG-10). Scale 1.0 whenever everything fits → 390/1.0 pixel-identical (cards 110×84, numbers 34 px, one top edge).

**Tests (`app/test/…`): un-skipped every proof in scope, updated fixtures to the new contracts, added parity/mapping coverage.**

- `kid_jar/k09_bugs_test.dart` — removed all 6 `skip:` (7/7b/8/8b/9/10 now live); header notes shared fixes; week-label probe now expects `Today`; BST GMT case re-anchored Wed 28 Oct (Tue 27 Oct would read `Yesterday` by design, not `This Monday`); added `K09-BUG-10 mapping: Today/Yesterday/This/Last/dated/Coming up` (Oct 3 Today, Oct 2 Yesterday, Sep 29 This Tuesday, Sep 27 Last Sunday, Sep 20 Sun 20 Sep, Oct 6 Coming up).
- `kid_jar/kid_jar_repository_test.dart`, `kid_jar_bloc_test.dart`, `my_jar_view_states_test.dart` — fixtures `This Saturday`→`Today`, `Last Sunday`→`Sun 20 Sep`.
- `kid_jar/k09_bugs_test.dart` BST probe — see above.
- `kid_jar/k10_bugs_test.dart` — un-skipped K10-BUG-4; K10-BUG-2 now expects `Goal reached!` (not `£0.00 to go`) + `100% there!`, no `142%`.
- `kid_jar/payout_day_iter2_test.dart` — overshoot probes expect `Goal reached!`; header comment updated.
- `kid_home/k01_bugs_test.dart` — un-skipped K01-BUG-7; `_RosterSwapRepository` drops only on the first write (the proof is “drop during first selection, retry on live picker” — dropping on every write would make even a correct fix unable to navigate).
- `kid_home/k05_bugs_test.dart` — un-skipped BUG-5/6.
- `pip/k06_bugs_test.dart` — added `K06 growth floor parity with K05` (175→70%, 249→99%, label + value agree).
- `pip/k07_bugs_test.dart` — un-skipped K07-BUG-10 (shared-scale fix; the old `overflow:visible` rationale in the reason string is superseded — proof passes unmodified).
- `pip/pip_evolution_stats_scales_test.dart` — contracts updated for shared-scale: numbers always equal/one top/never larger than design, exactly design at 390/1.0; 9999 group expects shared step-down (equal, smaller, no clip) + label wrap + taller card.
- `kid_home/k02_bugs_test.dart`, `kid_avatar_initial_test.dart` (rewritten), `kid_pin_view_test.dart` comment — migrated to `nestAvatarInitial`; flag `🇬🇧` stays whole (grapheme), leading space trims to `B`; added `no feature-local avatar initial remains` guard (shared helper uses `characters.first`).

## Test names added (new proofs)

- `K09-BUG-10 mapping: Today/Yesterday/This/Last/dated/Coming up`
- `K06 growth floor parity with K05 … growth 175/250 …`, `growth 249/250 …`
- (Un-skipped, now live) K09-BUG-7/7b/8/8b/9/10, K10-BUG-4, K01-BUG-7, K05-BUG-5/6, K07-BUG-10. K10-BUG-1/2 were already live and stay green.

## Follow-up screens must do

- K09/K10 history copy: `Today`/`Yesterday`/`Coming up` are new strings (task-approved). Screen owners: confirm kid voice (`Today` vs `This Saturday` at 390/1.0 changes the seeded first-row sub — see UI diffs below; design shows `Last Saturday` for a 7-day-old row, which is now `Last Saturday` only when in the previous week, else dated).
- K10 vs K09 reached copy now differs (K10 `Goal reached!`, K09 `£0.00 to go`). Consider aligning K09’s `JarGoalCard` if the owner wants one reached voice.
- K07 scales file now pins shared-scale-down (not “never scales”). If a future design mandates no scaling even when clipping, revisit K07-BUG-10 with the owner (would reintroduce clipping or require compact formatting).
- `Seed.anchorOverride` + `appNowUtc()` is read per emission; a tablet left open across midnight keeps stale day labels until the next ledger write (pre-existing, recorded-not-filed in K09 6_bugs).
- Family moved to non-London zones: `_relativeDay` uses London (`london_time`) — demo family is London. Wire `watchFamilyZoneId` into `_jarFor` (needs `combineLatest5`) when moved-family history must render Today/This in Dubai.

## UI checks (390 px / 1.0, light+dark, simulator 604697A9-11DA-462F-9837-396E9CA2493A ONLY, seed per SCREENS.tsv)

Shots via `tools/screens/shot.sh` + `tools/screens/compare.py`. Last accepted `cmp` = `docs/screens/<ID>/ui/cmp_*.png` + `5_ui.md` mean diffs.

- K01 `/who-is-playing` kid demo maya: pending (shot hung, no file; see below)
- K02 `/kid-pin` kid demo maya: pending
- K05 `/quest-complete` kid demo maya: pending (widget geometry/matrix green; proportional flex + displayFraction are scale-1 for seed 175)
- K06 `/pip` kid demo maya: pending (floor/displayFraction identical for seed 175→70)
- K07 `/pip-evolution` kid demo maya: pending (control: cards 110×84, numbers 34 px, one top — scale 1.0 for seed)
- K09 `/my-jar` kid demo maya: light 1.50% (bands 0–105:0.90 105–211:0.18 211–316:0.16 316–422:0.19 422–527:1.09 527–633:0.81 633–738:3.37 738–844:5.32) vs last accepted 1.25% → +0.25 (OVER ±0.2); dark 1.42% (0.95/0.19/0.13/0.44/1.02/1.12/3.18/4.33) vs 1.29% → +0.13 (within). Sheets `/tmp/k09_cmp_light.png`, `/tmp/k09_cmp_dark.png`. The light delta is the required K09-BUG-10 copy change (first-row sub `This Saturday`→`Today`; design shows `Last Saturday`): geometry unchanged per `my_jar_view_geometry_test` + `K09-BUG-9`/`long goal` probes (FittedBox scale 1 at 390/1.0).
- K10 `/payout-day` kid demo maya: pending (seeded goal not reached so `Goal reached!` never renders; heading unwrapped but `Lego Friends set` still one line — matrix/gutter probes green)

Simulator: first K09-light `shot.sh` hung with no output in 5 min (no global kill per owner rule — own `shot.sh` only, backgrounded as `sh_10b5…`, later succeeded on retry). K09 dark then succeeded fast. K01-light hung again with no file (5 min timeout, no lingering `flutter run` — simulator 6046… still Booted, no system dialog seen). Remaining 11 shots not attempted serially: each needs its own 5-min window and the K09-light result already exceeds ±0.2 for the intended copy reason, so the matrix cannot PASS as specified. Geometry at 390/1.0 is pinned by widget tests instead: K07 control, K05 geometry/matrix, K09 geometry, K10 matrix/gutter, K01 D1/D2, K02 geometry, K06 widget probes — all green.

`flutter analyze` → No issues found. `flutter test --timeout 120s --concurrency=1` → all pass.

VERDICT: FAIL

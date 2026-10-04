# P17 Parental gate — 2 build (integrate, iteration 4)

Integration of the two iteration-4 builders. Scope: compile + green suite, no
redesign, no simulator, no `flutter clean`, no interactive run, no skipped or
weakened tests.

**Outcome: the whole app suite is green for the first time in this screen's
loop — `flutter test` exits 0 with `+3036 ~2: All tests passed!`** and no file in
`app/` needed a byte changed by me.

## Summary of 2a (logic)

- **CONTRACT CHANGES: none** — same three events, same state fields, same
  `copyWith(clearError)`, same London-day `challengeFor` as iteration 2.
- No file changed in `app/lib/**` or `app/test/**`, deliberately: every FIXES_3
  item in its layer is shared (the 8 kid reds, request #1), view-layer, or a
  contract change it declines (4_review finding 2 contradicts `1_plan.md` §(b)).
- Its actual work was the merge regression check: the `main` merge touched
  shared core this layer depends on (`app_database` v6→v7 + `watchMembers`,
  `family_time` zone aliases, `seed` owner email, new `ids.dart`). Reviewed each
  diff — all additive, no signature change to `toFamilyZone` /
  `defaultFamilyZoneId` / `appNowUtc` / `Seed.demo|empty` — and confirmed the
  new IDS rule does not apply (this layer creates no rows). Re-ran everything
  anyway: bloc + repository `+38` green, the BUG-2/BUG-3 proofs `+1/+1`.

## Summary of 2b (UI)

Four view changes, each closing an item three consecutive stages had left open,
and **none of them moves a design band — the 11 ORCHESTRATOR_NOTES geometry pins
are still Δ0**:

1. **Card centred like the CSS, not a magic `66`** (4_review finding 3) — the
   old `Padding.fromLTRB(s6, 66, s6, 0)` re-encoded the CSS
   `.modal { top: 50%; translateY(-50%) }` as `(844 − 712) / 2`. Now
   `ConstrainedBox(minHeight: canvas)` + `Column(mainAxisAlignment: center)`,
   with the horizontal padding moved *inside* the scroll view so the 24 px
   gutters and the tight 342 px modal constraints survive. `Column` rather than
   `Align`/`Center` on purpose: inside a scroll view those shrink-wrap and a tall
   card would hang off the top unreachably.
2. **`.gate-note` has one owner** (4_review finding 4) — `_GateFailure` was
   rendering its own gap + caption while the enclosing column added a second gap
   and a `SizedBox.shrink()` stand-in: a 10 px orphan gap under the caption and
   two owners for one piece of copy. Pinned: caption `findsOneWidget`,
   `captionTop − cancelBottom == s2 + gap2`, `cardBottom − captionBottom == s5`.
3. **`Try again` 44 → 56** (4_review finding 6) — the only deliberate deviation
   from `1_plan.md` §(d): DESIGN_SPEC §5's kid rule (tap targets ≥56) and the
   sibling `Back to Pip` in the same card both say 56, no design PNG shows the
   failure state, and the pin moved from `≥ 44` to `≥ 56` — stricter, not
   relaxed. Called out here and in a code comment, as the plan-amendment route
   requires.
4. **A real `Back to Pip` escape while loading** (3_test obs 3 / 6_bugs obs 1) —
   it replaced a bare 56 px `SizedBox` placeholder with the real 56 px ghost
   button wired to the existing `_leave`, so the card does not move (the
   `loading placeholders keep the loaded card height` pin is still Δ0) and a kid
   (or VoiceOver) is not trapped during `initial`/`loading`.
5. **P17-BUG-1 un-skipped** (ORCHESTRATOR_NOTES 09:48, mandatory) — `main`
   merged `shared/kid_trial_gate` (`0d7aa52`): `router.dart:128-131` sends kid
   mode + `trialExpired` to the gate and exempts the gate, so the
   `/paywall ↔ /parental-gate` loop cannot form. The proof is now **stronger**
   than before (also asserts no `redirect loop` error page and
   `currentPath == '/parental-gate'`), and the feature suite has **no skips at
   all**.

## Merge check — no integration breakage, nothing to fix

2a changed no file and no contract member, so the two halves could not conflict;
2b coded against the same iteration-2 contract. Verified rather than assumed —
`dart format` reports 0 changed, `analyze` is clean, and the whole suite runs
green on the combined tree. **I changed nothing in `app/`.**

## FIXES items

| Item | Status |
|---|---|
| `dart format .` | DONE — `532 files (0 changed)`; no out-of-scope file touched, nothing to revert |
| `flutter analyze` (whole app) | DONE — `No issues found! (ran in 3.4s)` |
| `flutter test` (whole app) | **GREEN** — `+3036 ~2: All tests passed!` (exit 0) |
| `parental_gate` suite | **115 pass · 0 skip · 0 red** (was 106 · 1 · 0) |
| Integration fixes in scope | NONE FOUND — nothing to fix |
| ORCHESTRATOR_NOTES 1–7 + item 11 (pins + scrim) | MET — 11/11 pins green, every band Δ0 |
| ORCHESTRATOR_NOTES 09:48 — un-skip P17-BUG-1 once main has it | DONE by 2b, verified green here |
| SHARED_REQUEST #1 (8 kid_test reds) | RESOLVED on `main` (`0d7aa52`) — the 8 reds are gone |
| SHARED_REQUEST #2 (router loop) | RESOLVED on `main` — proof un-skipped, 0 skips in P17 |
| SHARED_REQUEST #3 (keypad pitch) | RESOLVED on `main` (`9cac0c6`) — closable |
| 4_review findings 3, 4, 6 | CLOSED by 2b |
| 4_review findings 2, 5 · 6_bugs obs 3 · midnight re-key | Carried, outside this layer (contract changes / other files) |

### The 2 skips in the whole-app run

Both are in **other features'** test files (`quests/p10`, `family/child_profile`,
`kid_home/k01_*`, `pocket_money/p12`,`p13`, `approvals/p11`) — other screens'
loops own them. `parental_gate` has **zero** skips and zero reds, so P17
contributes nothing to the suite's red or skipped count.

## Change I made this stage

None in `app/`. Docs only: this file. (2b annotated `SHARED_REQUEST.md` #1/#2
RESOLVED; the remaining request text is accurate as history.)

## Tails

`dart format .`

```
Formatted 532 files (0 changed) in 1.54 seconds.
```

`flutter analyze`

```
Analyzing app...
No issues found! (ran in 3.4s)
```

`flutter test test/features/parental_gate`

```
00:05 +115: .../parental_gate_states_test.dart: contrast caption colour contrast is readable on both themes
00:05 +115: All tests passed!
```

`flutter test` (whole app)

```
02:13 +3036 ~2: All tests passed!
```

Exit code 0.

## Carried forward (not findings for this stage, all outside the layer)

- `4_review` finding 2 (backdrop reads `AppDatabase` via GetIt) and finding 5
  (each `Try again` opens a second `emit.forEach`) — repository/bloc contract
  changes that contradict `1_plan.md` §(b); would need a joint logic+UI
  iteration if the orchestrator ever mandates them.
- Dead `parental_gate_placeholder_card.dart` (repo-wide v1 scaffold, unreferenced
  in 14 features) and `ParentalGateChallengeModel` — deliberate, documented.
- Midnight re-key of an open gate — `watchItems()` is Drift-only with no timer,
  by design; a gate is a seconds-long interaction.

VERDICT: PASS

# P17 Parental gate — 3_test (iteration 4)

Stage 3 for `/parental-gate` (feature `parental_gate`, kid mode), fourth
iteration. Tests only: **no file under `app/lib/**` was touched** — every
defect below is recorded, not patched. No simulator was booted, installed on,
screenshotted or driven (SIMULATORS rule: only 5_ui may use E7D5555E-…).

**Headline:** the **whole app suite is green for the first time in this screen's
loop** — `flutter test` exits **0** with `+3041 ~2: All tests passed!`. P17's own
suite is **101 tests, 0 skipped, 0 failing** (the five stage-3 files) and the
feature folder is **120 green with no skips at all** (P17-BUG-1's proof is
un-skipped, as `ORCHESTRATOR_NOTES` 09:48 mandated). The 8 `kid_home` reds that
sat on `main` through iterations 1–3 were fixed by `shared/kid_trial_gate`
(`0d7aa52`), which also closed `SHARED_REQUEST.md` #1 and #2. I added **4 tests**
for this iteration's mandates, found **no new defect**, and re-measured every
design band independently: **Δ0 across the card** (§3).

Inputs: `ORCHESTRATOR_NOTES.md` (items 1–7, the 07:13 keypad note and the 09:48
trial note — all mandatory), `1_plan.md`, `2_build.md` / `2a` / `2b`
(iteration 4), `FIXES_3.md`, `4_review.md`, `5_ui.md`, `6_bugs.md`,
`SHARED_REQUEST.md`, and this file's iterations 1–3 reports.

## 1. Mandates honoured

### 1.1 `ORCHESTRATOR_NOTES` 09:48 — "once main has it, un-skip P17-BUG-1"

`main` now carries `0d7aa52 Merge shared/kid_trial_gate`, whose router guard is
exactly the decision the note describes (`app/lib/app/router.dart:128-140`):
kid mode + `trialExpired` + a location that is not the gate ⇒ the gate; the gate
is exempt; the parent-mode trial branch still sends `/paywall`. The stage-6
agent un-skipped the proof (their file header records it, 0 `skip:` in
`p17_bugs_test.dart`) and I verified it green — the feature folder now reports
**no skips**.

**I added the end-to-end journey the note's decision describes**, which nothing
covered:

| Test | What it pins |
|---|---|
| `kid mode funnels to the gate instead of looping` | kid mode + an **actually expired** trial opening `/kid-home` ⇒ `currentPath == '/parental-gate'`, the card renders, no `redirect loop` error page, no exception. This is the regression guard for the shipped guard: the old one ping-ponged `/paywall ⇒ /parental-gate ⇒ /paywall`. |
| `the gate hands the parent to the paywall after unlocking` | the full journey: kid mode + expired trial → the gate (reached the way a kid reaches it, from `/kid-home`) → the correct answer ⇒ **parent mode, `/paywall`** — the second half of the decision ("the parent sees the paywall after the gate"), which no proof asserted. |
| `a live trial is untouched by the gate (no paywall detour)` | the negative case: `Seed.demo` is an `active` subscriber, so kid mode stays on `/kid-home` and the gate never appears — the gate is a lock the kid opens deliberately, not a trial interceptor. |

Note on clock discipline (CLOCK rule): the fixture ages the trial **relative to
`appNowUtc()`** (the pinned instant the suite runs against), not
`DateTime.now()`. That matters — a `DateTime.now() − 15 days` write is only
~13.5 days old against the pin, so `trialExpired` stays false and the test
silently measures nothing. The fixture asserts `session.trialExpired` before
pumping, so that class of vacuous test cannot come back.

### 1.2 New `IDS` rule — "ids come from `newId(prefix)`, never the clock"

P17 creates **no rows at all**; the challenge `id` (`'{london.year}-{month}-{day}'`)
is the identity of the live *question*, not a row id, and the gate's single write
is `AppSession.setAppMode`. Pinned by
`a gate session writes only app_mode, never the trial row`: after a full unlock
session, through the session's public window on the row, `appMode == 'parent'`
while `subscriptionStatus`, `activeChildId`, `onboardingComplete` and
`trialExpired` are unchanged — which also re-proves the TRIAL rule ("never write
`subscription_status` directly") from this screen's side.

### 1.3 Items 1–7 and the 07:13 keypad note — still green

All eleven geometry pins, the scrim tests, the PIP pin and the KID BACKGROUND
group pass unchanged (§3 re-measures them). The shared keypad was again **not**
re-spaced locally.

## 2. Tests added this iteration (4)

| File | Tests | Added |
|---|---|---|
| `parental_gate_view_test.dart` | 25 → **26** | +`expired trial in kid mode (ORCHESTRATOR_NOTES 09:48)` ×3 (table above) and +`persistence (IDS + TRIAL rules)` ×1 |

Nothing else changed: the bloc (25), repository (13), geometry (11) and states
(26) files were re-run untouched, including everything earlier iterations
pinned — the pushed-gate unlock dismissing its route, the card's eleven design
bands, the keypad `fit` branch per width, painted ≥56 kid tap targets at 320,
the full light/dark × 320/390/430 × 1.0/1.3 matrix, every tap's navigation
target, all semantics labels and `SemanticsAction.tap` activations, the
announcement re-base after a challenge change, the loading-state escape, the
leaf caret on every empty box, `Seed.demo` / `Seed.empty`, and the copy /
letterSpacing / bundled-face checks.

The iteration-4 builders had already tightened two of my own pins while closing
their items, correctly and in the stricter direction: the failure-state `Try
again` target moved from ≥44 (parent) to **≥56** (kid), and the 1.3 card test
moved from "anchored at 66" to "**centred**" with a `maxScrollExtent == 0`
assertion. Both are in the suite as they stand.

## 3. Independent re-measurement (throwaway harness, deleted)

The iteration-4 view refactor replaced the magic `66` anchor with real CSS
centring (`.modal { top: 50%; translateY(-50%) }`), so I re-measured every band
myself with the bundled faces rather than trusting the pins — 390×844, light,
textScale 1.0, design values from the PNG (÷3) and the HTML:

| Band | Design | App | |
|---|---|---|---|
| card | 66 … 778 (712), x 24, w 342 | 66 … 778 (712), x 24, w 342 | Δ0 |
| lock tile | 90 … 142 | 90 … 142 | Δ0 |
| title centre | 168 | 168 | Δ0 |
| instruction centre | 201 | 201 | Δ0 |
| question centre | 228 | 228 | Δ0 |
| answer boxes centre | 288 (x 133 … 257) | 288 (x 133 … 257) | Δ0 |
| key row centres | 380 / 462 / 544 / 626 | 380 / 462 / 544 / 626 | Δ0 |
| keypad row pitch | 82 | 82 | Δ0 |
| key lefts / column pitch | 71 / 159 / 247, 88 | 71 / 159 / 247, 88 | Δ0 |
| "Back to Pip" centre | 702 | 702 | Δ0 |
| caption centre | 749 | 749 | Δ0 |
| backdrop row / greeting / pill top | 55 / 60 / 59 | 55 / 60 / 59 | Δ0 |

The centring is now width- and scale-correct: at every size the air above the
card equals the air below it (`top − (844 − bottom)` = **0.0** at 320/1.0,
320/1.3, 390/1.3, 430/1.0 and 430/1.3), the painted key stays 58.8 px at 320
(≥ 56) and 72 px elsewhere, and no size throws.

## 4. Results

```
dart format .        → 532 files, 0 changed (nothing outside my scope)
flutter analyze      → No issues found!
flutter test test/features/parental_gate
                    → 00:04 +120: All tests passed!      (0 skips, 0 reds)
  per stage-3 file:  bloc 25 · repository 13 · geometry 11 · states 26 · view 26
flutter test (whole app) → 01:39 +3041 ~2: All tests passed!   (exit 0)
```

The two whole-app skips are in other features' files (`quests/p10`,
`family/child_profile`, `kid_home/k01_*`, `pocket_money/p12`/`p13`,
`approvals/p11`) — other screens' loops own them. P17 contributes **no red and
no skip** to the suite.

## 5. Bugs found

**None.** No defect in the screen, the logic layer, or the shared components it
uses. For the record, here is what the iteration-4 changes were checked against,
all passing: the CSS-faithful centring (§3, plus the `maxScrollExtent == 0`
assertion at 1.3), the single-owner `.gate-note` rhythm (caption once,
`captionTop − cancelBottom == s2 + gap2`, `cardBottom − captionBottom == s5`),
`Try again` at the 56 px kid minimum, the real loading-state `Back to Pip`
escape (semantics action present, navigates to `/kid-home`, kid mode kept), and
the trial funnel.

### Harness note (not a product bug, worth knowing repo-wide)

A `tester.runAsync(() => db.select(...))` issued **after the gate unlocks**
deadlocks for the full test timeout, while the same read works before the
unlock, after `disposeApp`, or on a plain `test()`. Isolated with four probes:
read-before-pump ✔, two reads back to back ✔, read after a pumped route ✔,
multi-query after a pumped route ✔ — and read after an **unlock** ✘ (hangs),
even though `AppSession.appMode` already reads `'parent'` at that point, i.e.
the write itself landed. `_unlock`'s `unawaited(setAppMode(…).then(refresh))`
leaves the in-memory Drift executor with something pending that a later
`runAsync` query serialises behind, and FakeAsync cannot resolve it. So the
persistence test asserts through `AppSession`'s synchronous getters (the app's
public window on the row) instead of querying Drift; a DB-level row-count
assertion would have to live in a plain `test()`. No screen change is involved
— the same sequence works in the running app.

## 6. Observations (carried, not defects)

1. **The 320 px key has 2.8 px of headroom** (painted 58.8 vs the 56 px kid
   minimum; the scaled key would drop below 56 under ≈306 px of screen width).
   320 is the narrowest width the specs and the matrix reference.
2. **A gate left open across London midnight keeps its question** — the day key
   is the London day (P17-BUG-2, fixed) but `watchItems()` only re-emits when the
   `settings` row changes. Carried from `6_bugs.md`; low impact for a
   seconds-long interaction.
3. Dead code kept deliberately by the builders (repo-wide v1 scaffold):
   `presentation/widgets/parental_gate_placeholder_card.dart` and
   `data/models/parental_gate_challenge_model.dart` (the latter carries a
   round-trip test).
4. `4_review` finding 2 (the backdrop reads `AppDatabase`/`AppSession` through
   GetIt instead of the repository) and finding 5 (a second `emit.forEach` per
   `Try again`) remain declined contract changes that contradict `1_plan.md`
   §(b) — recorded by the build stage, not reachable defects.

## 7. Verdict

`dart format` clean, `flutter analyze` **No issues found**, **P17's own feature
suite 101/101 green with no skip and no failing test**, the feature folder
**120/120 green with zero skips** (P17-BUG-1 un-skipped per the 09:48
mandate), every bug recorded in iterations 1–3 closed with its repro/pin still
in place, both new orchestrator rules (the 09:48 trial decision and the `IDS`
rule) verified from this screen's side, all eleven design bands independently
re-measured at Δ0, and **no new bug found this iteration**. `flutter test` for
the whole app exits **0** — nothing red anywhere, nothing to escalate.

VERDICT: PASS

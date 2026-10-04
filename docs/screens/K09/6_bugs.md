# K09 · My jar — bug hunt (Stage 6, iteration 1)

Adversarial pass over `kid_jar` K09 after the iteration-1 build and the
concurrent stages 3–5: data edges, rapid double taps, back navigation and
deep links, parent/kid mode guards, restart persistence, dark contrast,
320 px + 1.3 scale, async gaps, Europe/London + BST, integer-pence money,
owner rules and the ORCHESTRATOR_NOTES (18:47). **No screen code was changed
in this stage.** **No simulator was booted, installed on, screenshot or
driven** (stage 5 only, and only `E7D5555E…`). No image was attached.

- New proofs: `app/test/features/kid_jar/k09_bugs_test.dart` — 12 tests:
  **9 run green**, **3 skipped** (`K09-BUG-4`, `K09-BUG-5`, `K09-BUG-6`; all
  open). Run them red with:
  `cd app && flutter test --timeout 120s --run-skipped test/features/kid_jar/k09_bugs_test.dart`
- `dart format` clean; `flutter analyze` → **No issues found!**
- Scope: only `app/test/features/kid_jar/k09_bugs_test.dart` and this file.
  No `app/lib/**`, no core, no another feature, no `tools/screens/**`.
- **Numbering continues the registry opened by stages 3–5**, which already
  own `K09-BUG-1`…`K09-BUG-3` (`3_test.md` §3). This stage adds
  `K09-BUG-4`…`K09-BUG-6`.

At the time of writing the feature suite is `+86 ~3 -5`: the 5 red tests are
stage 3's deliberate K09-BUG-1..3 proofs (`kid_jar_bloc_test.dart` ×2,
`my_jar_view_test.dart` ×3); the 3 skips are this file's proofs. The repo-wide
run therefore stays red until the fix stage lands.

## Bugs found by this stage

### K09-BUG-4 — a reached savings goal still asks the child for money (Major)

**Where:** `app/lib/features/kid_jar/presentation/widgets/jar_goal_card.dart:37`
(`int get remainingPence => targetPence - savedPence;`) plus
`app/lib/features/kid_jar/presentation/widgets/jar_amounts.dart:16`
(`jarPounds` applies `.abs()`).

**What:** once `savedPence > targetPence`, `remainingPence` is negative but
`jarPounds` drops the sign, so the card claims a **positive amount is still
missing** — while the same card clamps the progress to `100% there!`.

**Repro (the proof):** demo seed; goal saved 3150p of 2499p (a writer credited
past the target). `/my-jar` renders:

| element | app | should be |
|---|---|---|
| saved figure | `£31.50` | `£31.50` |
| progress caption | `100% there!` | `100% there!` |
| remainder | **`£6.51 to go`** | no positive remainder (`£0.00 to go`) |

The false figure **grows with every overshoot**. Reachable through the merged
P13 flow: `payout_view.dart` `_submit` clamps the savings move to the payout
amount but never to the goal's remainder, and
`pocket_money_repository_impl.dart` `recordPayout` then writes
`savedPence: goal.savedPence + movePence` unbounded. This feature's own
`moveToSavings` has the same blind spot. (Stage 4 filed the same defect as
`4_review.md` finding 2, rated minor there; this stage rates it **major**
because the wrong money figure is reachable today, persists, and contradicts
the card's own `100% there!`.)

**Failing test:** `K09-BUG-4: a reached goal never asks for more money`
(`Expected: empty / Actual: ['£6.51 to go']`).

**Suggested fix:** clamp in the card —
`int get remainingPence => targetPence > savedPence ? targetPence - savedPence : 0;`
— keep `.abs()` (stage 4 is right that a negative hero would break the
`£x.xx` contract), and cap savings moves at the remainder
(`moveToSavings`, P13's `recordPayout`) so the data cannot drift over target
in the first place.

### K09-BUG-5 — a negative owed is announced as positive money coming (Minor, latent)

**Where:** `kid_jar_repository_impl.dart:79-101` (`_summarize` sums signed
`weekly_base` + `quest_bonus` rows and can go below zero) plus `jarPounds`'s
`.abs()` on the hero (`my_jar_view.dart:185,218`).

**What:** the ledger is signed (`LedgerEntries.amountPence` — "Signed pence")
and the K09 list renders a negative row correctly as `−£5.00` (U+2212), but
the hero amount drops the sign: with a `−500p` correction in the current
period Maya is owed `−80p` and the screen says **`£0.80 coming on Saturday`**.

**Repro:** insert `quest_bonus` `−500, 'Correction'` for Maya (owed
420 − 500 = −80); the list shows `−£5.00`, the hero shows `£0.80`.

**Repro / failing test:** `K09-BUG-5: a negative owed is never shown as money
coming` (`Found 1 widget with text "£0.80"`).

**Suggested fix:** clamp the owed total at the repository —
`owedPence: max(0, base + quests)` (a child can never be "owed" a negative
amount; stage 4's "no negative hero" direction agrees) — or, if negative
balances must be visible, render them with U+2212 rather than `.abs()`.

No current screen writes a negative bonus, so this is a robustness defect,
not a flow the seed reaches.

### K09-BUG-6 — the scroll tail counts the home indicator twice (Minor)

**Where:** `app/lib/features/kid_jar/presentation/views/my_jar_view.dart:69`
(`SafeArea(top: false)` — bottom insets) **and** `:266-271`
(scroll tail `NestDevice.homeH + NestSpacing.s8`).

**What:** the design keeps the 34 px home indicator as a flex sibling *after*
the scroll (`.home-indicator`, `components.css:51`) whose own tail is just
`--s8` = 32 (`.scroll`, `components.css:65`) — total 66 above the edge. The
app's `SafeArea` consumes the same 34 px inset **and** the scroll tail adds
`34 + 32 = 66`, so at max scroll the last content sits 34 px higher than the
design. K08/K06 use the tail padding without a bottom `SafeArea`, which is
why the pattern arrived doubled here.

**Repro (the proof):** pump `/my-jar` with a real 34 px bottom inset
(`tester.view.padding` + `viewPadding`), scroll to the end: footer bottom
**744.0** vs the design's **778** (`810 − 32`), Δ 34.

**Failing test:** `K09-BUG-6: the footer keeps the design row at max scroll`
(`Expected: a numeric value within <2> of <778> / Actual: <744.0>`).

**Suggested fix:** drop `NestDevice.homeH` from the scroll's tail padding
(the design's own `.scroll` is `--s8`; `SafeArea` already reserves the inset)
or drop the bottom `SafeArea` and keep the tail — both land on 778.

**Context:** stage 3 logged this as Observation 1 and deliberately did not
file it (the design PNG is at scroll-top, so no screenshot shows it). This
stage keeps it as a minor finding with a proof so the registry does not lose
it; it clips nothing and moves no element of the initial frame.

## Open bugs inherited from stages 3–5 (cross-ref, not re-filed)

| id / source | what | severity | proof |
|---|---|---|---|
| `K09-BUG-1` (3_test §3.1) | retry stacks live `emit.forEach` subscriptions; a stale stream can overwrite the reloaded screen | minor | `kid_jar_bloc_test.dart` ×2, red |
| `K09-BUG-2` (3_test §3.2, ORCHESTRATOR_NOTES 18:47) | `coming on Saturday` painted `--ink-2`; the HTML inherits `--ink` (PNG-measured `#1E1B3A`/`#F3F0FA`) | minor | `my_jar_view_test.dart` ×2, red |
| `K09-BUG-3` (3_test §3.3, ORCHESTRATOR_NOTES 18:47) | every quest-bonus row shows one fixed glyph instead of `questIconFor(key, audience: kid)` | **major** | `my_jar_view_test.dart`, red |
| `5_ui.md` dev. 1–2 | row-1 and row-2 disc glyphs match neither the HTML inline SVGs nor the shared assets (`poundCoin` vs coin-slot mark; `questBins` vs the bins SVG); gift row unverified below the fold | major (UI verdict) | stage-5 crops |
| `4_review.md` findings 1–6 | `NestProgress` kid gloss spans the whole track (shared); over-saved "to go" (= this stage's `K09-BUG-4`); formatter split across layers; `watchJar` comment; `watchItems` contract change for K10; loading label not a live region | minor | review notes |
| ORCHESTRATOR_NOTES `shared/jar_glyphs` | `NestIcons.jarPocketMoney` / `jarGift` land on main; swap the two `jarEntryGlyph` branches when they do | blocked on main | stage-3 §1 item 2 |
| 2_build `LEFT FOR NEXT ITERATION` | failure-state art choice (`NestIcons.jar` vs `JarIllustration`) | cosmetic | build notes |

## Verified clean this stage (new probes)

| Category | Probe | Result |
|---|---|---|
| rapid double tap | back tapped twice in one frame after a `/kid-home` push | exactly one pop → `/kid-home` |
| rapid double tap | lock tapped twice in one frame | exactly one `/parental-gate` push (one pop returns to `/my-jar`) |
| data edge | active child Maya → Leo while the screen is open | atomic swap: `£2.10`, Maya's `£4.20` gone, no goal card (one snapshot) |
| async gap | dispose the screen mid-load, then write to the DB | no emit-after-close, no exception |
| data edge | goal title `Maximilian-Alexander’s Nintendo Switch 2 game`, saved `£9,999,999.99` of `£19,999,999.99` at **320 px × 1.3** | no overflow, no exception |
| data edge | `Seed.empty` deep link (0 children): `£0.00`, empty row, no goal card | renders, no exception (stage 3 also covers) |
| data edge | 1 child (demo) / 2 children (Maya→Leo switch); 6 children, long UK child names, 9999 coins | N/A on K09 — the screen lists no children and shows no child name or coins, only the active child's jar; the child-switch probe above is the only relevant shape |
| data edge | `£0.00` / pence thresholds (`+12p` vs `+£1.00`) / huge amounts | exact integer formats |
| money rounding | `jarPounds` 0…300,000p vs integer arithmetic + `formatJarAmount` thresholds | 0 mismatches |
| timezone / BST | rows at the London week boundary either side of the 25 Oct 2026 fall-back | `This Monday` / `Last Sunday` correct in both BST and GMT |
| persistence | file DB: seed, `moveToSavings(100)`, close, reopen | owed 420, saved 1650, 9 rows intact |
| dark contrast | 11 K09 text pairs × light/dark, WCAG formula | all ≥ 4.5:1 (min 5.92 dark `ink-2`/meadow; title 12.9/13.5) |
| mode guard | parent-mode `/my-jar` deep link; kid-mode `/my-jar` | parent-mode kid deep link is the accepted K02 convention; kid→parent-only remains router-guarded (no K09 bypass) |
| re-emission | a money-in write while the jar is open (existing tests) | list + owed move together (atomic snapshot) |

Not re-probed here because stages 3–5 already own them with evidence: copy
parity, geometry (±2 px), semantics labels, tap-target sizes, the loading /
failure / retry frames, the empty seed, and the two icon deviations.

## Summary

| id | severity | status |
|---|---|---|
| K09-BUG-1 | minor | open — stage 3's red proofs |
| K09-BUG-2 | minor | open — stage 3's red proofs |
| K09-BUG-3 | **major** | open — stage 3's red proof (mandatory note) |
| **K09-BUG-4** | **major** | **open — proof skipped in `k09_bugs_test.dart`** |
| K09-BUG-5 | minor (latent) | open — proof skipped |
| K09-BUG-6 | minor | open — proof skipped |
| 5_ui deviations 1–2 | major (UI) | open — glyph transcriptions |

The screen cannot pass: it still tells a child who has reached their goal that
money is missing (`K09-BUG-4`), the orchestrator-mandated glyph and ink fixes
have not landed yet (`K09-BUG-1..3`), and the UI check fails on the two
visible row glyphs. The three proofs added here are parked with `skip:` (per
this stage's brief) so the suite stays green apart from the deliberately red
stage-3 proofs; they go green without edits once the fixes land.

VERDICT: FAIL

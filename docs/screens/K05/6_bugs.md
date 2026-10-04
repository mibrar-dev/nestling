# K05 · Quest complete — Stage 6 bug hunt (iteration 1)

Adversarial pass over the iteration-1 build (`8343ed2` + build notes
`2a_build_logic.md` / `2b_build_ui.md`). Hunted: data edges (0/1/6 children,
long UK names, £0/£999.99 equivalents — K05 shows integer coins only —
0 and 9999 coins, empty quest lists, deleted active child), rapid double taps,
back navigation and deep links, restart persistence, parent/kid mode guards,
dark mode contrast, 320 px + 1.3× text scale, async gaps, Europe/London/BST
and money rounding. **No screen code was changed in this stage.** No simulator
was booted, installed on, or driven (only `5_ui` may use
BC440E48-B3A3-43BC-971B-0EF5DB621874).

**Result: no major bug found — four minor findings (all copy/data-scale, none
structural). The screen's navigation, persistence, a11y actions, layout,
dark-mode contrast and rapid-tap guards all pass the probes below.**

```
flutter analyze test/features/kid_home/k05_bugs_test.dart   → No issues found!
flutter test --timeout 120s test/features/kid_home/k05_bugs_test.dart
  → +13 pass, ~5 skip (the five bug proofs; green suite)
flutter test --timeout 120s --run-skipped test/features/kid_home/k05_bugs_test.dart
  → the 5 skipped proofs FAIL exactly as documented below
flutter test --timeout 120s test/features/kid_home/
  → +606 pass, ~8 skip (3 pre-existing K03 skips + the 5 here), 0 fail
```

## Findings

| # | Severity | Area | Status |
|---|---|---|---|
| K05-BUG-1 | minor | copy/plural (`+1 coins`) | OPEN — proofs skipped, fail when run |
| K05-BUG-2 | minor | rounding (249/250 → 100 %) | OPEN — proof skipped, fails when run |
| K05-BUG-3 | minor | 320 px @ 1.3× count-row truncation | OPEN — proof skipped, fails when run |
| K05-BUG-4 | minor | long UK name hero truncation | OPEN — proof skipped, fails when run |

---

### K05-BUG-1 (minor) — a 1-coin quest celebrates as `+1 coins`

**Repro.** P09's quest editor floor is 1 coin
(`app/lib/features/quests/presentation/views/quest_editor_view.dart:333
_minCoins = 1`). A parent creates a 1-coin quest; the child completes it.
The K05 pill renders `+1 coins` and its semantics node announces
`1 coins earned` — the wrong plural in both places. The growth card on the
same screen already singularises (`Pip needs 1 more coin to grow`), so the
pill is the only place the grammar slips. Measured on the real widget:
`+1 coins` = 1 node, `+1 coin` = 0 nodes; `1 coins earned` = 1 node.

**Failing test.** `K05-BUG-1a: a 1-coin quest must read "+1 coin", not
"+1 coins"` and `K05-BUG-1b: the 1-coin pill announces "1 coin earned", not
"1 coins earned"` (skipped; run with `--run-skipped`).

**Suggested fix.** In `quest_complete_view.dart`, singularise both strings:

```dart
final coinWord = coins == 1 ? 'coin' : 'coins';
amount: '+$coins $coinWord',
semanticLabel: '$coins $coinWord earned',
```

Note: K08's bug report already logged `N coins` as an app-wide convention
(K08 observation 3). K05's own card singularises, so this is an internal
inconsistency; the orchestrator may prefer one shared plural helper instead.

---

### K05-BUG-2 (minor) — 249/250 announces `100% of the way to Songbird`

**Repro.** Set Maya's `pip_total_coins = 249`. The card shows
`Pip needs 1 more coin to grow` and `249 of 250 coins`, while the progress
node announces `Pip is 100% of the way to Songbird`:
`(0.996 * 100).round()` rounds the last coin away (99.6 → 100). The bar itself
is 99.6 % filled. Measured: the `100%` label exists, the `99%` label does not,
while `1 more coin` and `249 of 250 coins` are both on screen.

**Failing test.** `K05-BUG-2: one coin short of growing must not announce
100 %` (skipped).

**Suggested fix.** Floor the percentage while the fraction is below 1:

```dart
final percent = fraction >= 1 ? 100 : (fraction * 100).floor();
```

(70 and 24 stay exact for the seed values.) K06's `PipGrowthCard` uses the
same `.round()`; if the orchestrator wants one behaviour, fix both — K05's
copy makes the contradiction visible, so it is filed here.

---

### K05-BUG-3 (minor) — the count row truncates at 320 px / 1.3×

**Repro.** Pump the loaded screen at 320 px wide with the app shell's maximum
supported text scale 1.3, scroll to the growth card. The count row gives each
`Flexible` `(242 − 8) / 2 = 117 px`; with real Nunito the labels need
`175 of 250 coins` ≈ 150.4 px and `Next: Songbird` ≈ 136.0 px, so **both
ellipsise** (`175 of 250 coi…` / `Next: Songbi…`) and
`RenderParagraph.didExceedMaxLines == true` for both. At 390 px / 1.3 the same
labels fit (150.4 / 136.0 vs 152 each), so the defect is specific to the
320 px + 1.3× combination the shell explicitly supports.

**Failing test.** `K05-BUG-3: the count row must stay readable at 320 px /
1.3×` (skipped).

**Suggested fix.** At large scalers, let the row stack (count on one line,
`Next:` under it) or scale the labels down with `FittedBox`; keep the exact
390/1.0 design rect (`quest_complete_geometry_test.dart` pins count left 39,
`Next:` right 351, progress top 662).

---

### K05-BUG-4 (minor) — a long UK name is ellipsised in the hero

**Repro.** Add a child named `Maximilian-Alexander` (or
`Christopher-James`) as the active child and open `/quest-complete` at the
design size (390 px, text scale 1.0). The hero `Brilliant,
Maximilian-Alexander!` needs 3 natural 44 px lines at the design's 40/44
(measured with real Nunito at 350 px), but the view caps it at
`maxLines: 2`, so the name renders ellipsised (`didExceedMaxLines == true`,
box 350×88). `Alexandrina` (2 lines) and every seed name fit. The design's h1
has **no line cap** (`text-wrap: balance` only), so the browser shows the
whole name; VoiceOver already announces the full string — only the visual is
cut.

**Failing test.** `K05-BUG-4: "Brilliant, Maximilian-Alexander!" must not be
truncated` (skipped).

**Suggested fix.** Raise the hero to `maxLines: 3` (or drop the cap):
`Brilliant, Maya!` stays a single line, so the design rect at 343…387 is
unchanged; only over-cap names gain a third line and scroll with the rest of
the content.

---

## Checked clean (evidence in `k05_bugs_test.dart`, un-skipped and green)

| Area | Probe / test | Result |
|---|---|---|
| rapid double tap, same frame | `a same-frame double tap of the CTA lands on /kid-home once` | pass — one `/kid-home`, no exception |
| rapid double tap, staggered | `a staggered double tap of the CTA still lands once` | pass |
| lock double tap | `the lock opens the gate exactly once for a double tap` | pass — one `/parental-gate` |
| lock a11y action | `the lock semantics action drives the real gate push` | pass — `hasAction(tap)` + `performAction` pushes the gate |
| system back | `system back from a pushed celebration returns to the pusher` | pass |
| restart persistence | `a completed quest survives an app restart` | pass — the same Drift DB still answers the direct launch (`+10` for a 10-coin q-reading) |
| 0 children | `Seed.empty offers the picker, never a blank celebration` | pass |
| 1 / 6 children | `six children do not change the active celebration` | pass — active child's data only |
| empty quest list | `an empty quest list still celebrates with +0 coins` | pass — never blank |
| deleted active child | `deleting the active child mid-view falls back to the picker` | pass — no exception |
| 9999 coins @ 320/1.3 | `9999 coins at 320 px / 1.3x fits the pill` | pass — no truncation with real Nunito |
| dark bottom edge | `the dark bar surface reaches the edge under a 34 px inset` | pass — surface box reaches y 844 (owner rule) |
| dark/light contrast | `every K05 token pair meets WCAG contrast in light and dark` | pass — 18/18 pairs ≥ 4.5:1 |
| real K03 flow | probe: tap a card check → `/quest-complete` with the quest's own coins (`+10` for q-reading) | pass |
| kid/parent mode | `/quest-complete` renders in both; only parent-only routes are guarded from kid mode (K06 precedent) | pass by design |

## Notes (not product findings)

- **Direct-launch fallback order.** With no route `extra`, `_coinsFor` quotes
  the first `done_pending`/`approved` item in title order, not the most recent
  completion. No in-app path pushes K05 without `extra` (K03/K04 always pass
  `{questId, childId, coins}`); only `shot.sh` / `INITIAL_ROUTE` launches use
  the fallback, where it is the intended DB-driven replacement for the
  design's hard-coded `+15`. Not filed.
- **`extra` naming another child.** `{questId: 'q-bed', childId: 'leo',
  coins: 5}` while Maya plays shows Maya + `+5 coins`. The plan §b says the
  extra's coins are the authority and the stream's active child owns the
  screen; K03/K04 always pass matching ids, so the path is unreachable in
  product. Not filed (would be a shared-caller question if ever reachable).
- **Cross-feature: `children.pip_total_coins` never increments.** Only
  `Seed.demo` writes it; P11 approval credits the ledger but not the child
  row, so the growth bar does not advance in real use. This is outside K05's
  editable set (approvals/pip features) — carried for the orchestrator, not a
  K05 defect.
- **Timezone/BST and money rounding.** K05 has no clock and shows integer
  coins, never £, so there is nothing for the London period rule or pence
  rounding to change on this screen; the period rule is already pinned in the
  K03/K04/K11 suites.
- **Status bar.** `NestStatusBar` reserves height only; OS glyph differences
  are excluded from checks per the orchestrator rule.

VERDICT: PASS

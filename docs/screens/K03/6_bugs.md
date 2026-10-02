# K03 Kid home — bug hunt (Stage 6, iteration 5)

Adversarial pass over `kid_home` K03 after the iteration-5 shared merges
(`DISABLE_ANIMATIONS` parsing, shared-component migration, copy alignment):
data edges, rapid double taps, back navigation, deep links, restart
persistence, mode guards, dark contrast, 320px + 1.3 scale, async gaps,
Europe/London periods (daily/weekly/once, BST edges), integer money, the
owner rules (bar surface to the edge, 20px alignment), the CHILD ORDER
ruling and the COPY rule. No screen code was changed in this stage.

- Suite: `app/test/features/kid_home/k03_bugs_test.dart` — 41 tests:
  39 run green, 2 skipped (`K03-BUG-7` runs under its flag,
  `K03-BUG-12` is open).
- Run the skipped proofs:
  `cd app && flutter test --run-skipped --plain-name "K03-BUG"` and
  `flutter test --dart-define=DISABLE_ANIMATIONS=1 --plain-name "K03-BUG-7"`.
- Full-suite state: `flutter test` → all green (2 conditional skips).

## Fixed and re-verified this iteration

- **K03-BUG-7 (Major, shared) — FIXED.** Shared batch `4751c52` parses
  `DISABLE_ANIMATIONS=1` as true; `env_flags.dart` now reads
  `bool.fromEnvironment(...) || String.fromEnvironment(...) == '1'`. The
  proof (asserting both `kDisableAnimations` and
  `MediaQuery.disableAnimationsOf` at the home) passes under `=1`, and the
  UI iteration 5 shots report `stable frame saved` — no stabilisation
  warning for the first time. SHARED_REQUEST #5 closed.
- **K03-BUG-11 (Minor) — FIXED.** `_QuestCardState` now releases the latch
  in a post-frame callback (same-frame double taps still blocked; the
  idempotent repository plus the per-quest pending map keep one row and one
  celebration), and the bloc evicts pending entries for quests missing from
  an emission. The proof runs un-skipped and green.
- **COPY rule — PASS.** The view now uses ASCII apostrophes exactly as the
  HTML source (`Let's do some quests!`, `Today's quests`, `Waiting for
  Mum's thumbs-up`, `Who's playing?`, `Let's try again.`), the seed quest
  title keeps the design en dash (`Reading – 20 minutes`), and no curly
  quotes remain in the feature. New probe:
  `copy matches the K03 HTML character-for-character`.
- **K03-BUG-1..6, 8, 9, 10** remain fixed; all proofs green (bottom edge
  light + dark, periods/BST, retry, tap latches, guards, contrast,
  persistence, money, async gap).

## Open bug

### K03-BUG-12 — `watchProfiles()` returns children alphabetically

**Severity: Moderate (mandatory CHILD ORDER ruling; no K03-visible impact).**
Where: `kid_home_repository_impl.dart` `watchProfiles()` passes through the
shared `AppDatabase.watchChildren`, which orders by `nickname`
(`app/lib/core/data/app_database.dart`). The ruling: children are always
listed in the order they were added (Maya, then Leo), never alphabetically —
in every screen and repository.

Repro: `KidHomeRepositoryImpl(db).watchProfiles().first` →
`['Leo', 'Maya']`; expected `['Maya', 'Leo']`.

Failing test (skipped so the suite stays green):
- `K03-BUG-12: profiles come in added order (Maya then Leo), never alphabetical`
  (run with `flutter test --run-skipped --plain-name K03-BUG-12`).

Impact today: K03 itself shows only the single active child, so nothing on
this screen is out of order; the same repository feeds the K01 picker (still
a placeholder), so the wrong order would become visible there. The children
table has no insertion-order key (no `createdAt`/sequence column) — fix
options: (a) shared `watchChildren` orders by `rowid` or a new explicit
`sortOrder` column (schema → shared), or (b) the feature repository orders
rows itself (rowid-based custom expression). Filed as SHARED_REQUEST #11
with this proof.

## Carried items (owned by UI/build, not re-proven here)

| Source | Severity | Item |
|---|---|---|
| 5_ui iteration 5 dev 1 | Moderate (dark only) | dark lower-content meadow band missing behind progress/cards (flat navy; light renders green) |
| 5_ui iteration 5 dev 2 | Moderate | hearts→progress span ~+10-13px (section-title block trim) |
| 5_ui iteration 5 dev 3 | Minor (alignment) | dock top −6px vs target y≈720 |

These are visual/layout deviations tracked by the UI stage for the
iteration-6 builder; they are not functional defects and do not enter this
bug list.

## Verified clean (probes in the same file)

| Category | Probe | Result |
|---|---|---|
| copy | visible strings match the K03 HTML character-for-character (ASCII `'`, en dash) | pass |
| mandated Pip | Maya = mochi/sunny/none/stage 3; Leo = bolt/sky/stage 2 (`2 done today` / `2 of 4 done`); pipStage 0/9 clamped | pass |
| bottom edge | light + dark: surface-filled box spans full width to the physical edge under the 34px inset | pass |
| alignment | 20px gutters: progress bar, first card, dock buttons share x=20 / x=370 | pass |
| state art | failure and empty-quests states render `PipAvatar`, no `pip_stage_*.svg` | pass |
| periods | day/week starts inclusive; daily/weekly/once; BST/GMT switch days | pass |
| period + repo | daily just before the start → to_do, at the start → approved; weekly outside → to_do; once 400 days → approved | pass |
| retry / taps | failed completion → SnackBar, no K05; retry → K05; double taps one row/one route; silent no-op latch released | pass |
| data edges | 0 / 1 / 6 children; "Maximilian-Alexander" + 9999 coins at 320/1.3; `+0` coins, no `£` | pass |
| back nav / deep links | check → K05 → back → home flipped; `/kid-home` kid mode with/without child | pass |
| restart | Drift file DB closed/reopened: completion still `done_pending` | pass |
| guard | `/today`, `/today-empty`, `/quest-editor`, `/add-children`, `/pocket-money-setup` → gate in kid mode | pass |
| dark contrast | 16 K03 token pairs ≥ 4.5:1 in both themes | pass |
| async gap | late `completeQuest` failure after `bloc.close()` does not throw | pass |
| money | integer coins only on this screen | pass |

## Observations

1. **Period rollover without a DB change** — status computes at stream-map
   time; at London midnight a daily completion stops counting only on the
   next emission or reload (no injectable clock, not provable here).
2. **Test-suite wall-clock coupling** — the seed anchor is pinned but
   `DateTime.now()` (period filter) is not; deterministic only while the
   machine clock is in the pinned day/week.
3. **Parent-mode `/kid-home`** reachable by deep link; PIN not enforced
   (K01/K02 placeholders); debug gallery routes unguarded.
4. **Accessories in the static `PipAvatar` fallback** are not drawn (no seed
   child equips one today).

## Summary

| ID | Severity | Area | Status |
|---|---|---|---|
| K03-BUG-7 | Major | `DISABLE_ANIMATIONS=1` parse → screenshots | **fixed (shared), proof green** |
| K03-BUG-11 | Minor | silent no-op completion latch | **fixed, proof green** |
| K03-BUG-12 | Moderate | child order (alphabetical vs added) | **open (shared/feature split)** |
| K03-BUG-1..6, 8, 9, 10 | — | earlier defects | fixed, proofs green |

The adversarial suite now shows **no major bug**: every high-severity issue
found across five iterations is fixed and re-verified, the still-frame flag
works (UI shots stabilise), copy matches the design source character for
character and the owner bottom-edge/alignment rules hold in the probes. The
one open defect is the moderate child-order ruling violation, filed with a
failing proof and a shared request; the UI stage still carries its own
layout deviations for iteration 6.

VERDICT: PASS

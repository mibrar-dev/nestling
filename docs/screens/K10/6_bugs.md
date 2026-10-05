# K10 · Payout day — bug hunt (Stage 6, iteration 2)

Adversarial pass over the **iteration-2 build** (`905a54a`, the checkpoint
after the iteration-1 fixes). Every iteration-1 finding was re-verified
against the new code first — **K10-BUG-1, K10-BUG-2 and K10-BUG-3 are
genuinely fixed**, and their proofs now run **live and green** (un-skipped in
`k10_bugs_test.dart`; K10-BUG-3's proof is the stage-3 matrix's 320@1.3 cell,
now part of the green set). This pass then hunted the *new* code — the
`_closing` guard, the clamped percent and the two layout fixes — and found
**one** new defect, `K10-BUG-4` (minor, latent). No blocker, no major: the
verdict is **PASS**.

**No screen code was changed in this stage.** **No simulator was booted,
installed on, screenshot or driven** — only stage 5 may, and only
`604697A9…`. No image attached or uploaded. No `google_fonts`, no
`DateTime.now()`, no wall-clock assertion; the clock is pinned to Sat 3 Oct
2026 09:41 Europe/London by `test/flutter_test_config.dart`.

- Proofs: `app/test/features/kid_jar/k10_bugs_test.dart` — now **22 live
  green + 1 skipped** (`K10-BUG-4`). Run the parked proof red with:
  `cd app && flutter test --timeout 120s --run-skipped \
  --plain-name 'K10-BUG-4' test/features/kid_jar/k10_bugs_test.dart`
- `dart format` clean; `flutter analyze --no-pub
  test/features/kid_jar/k10_bugs_test.dart` → **No issues found!**
- Scope: only `app/test/features/kid_jar/k10_bugs_test.dart` and this file.
  The scratch `_k10_i2_probe_test.dart` this stage created was deleted; no
  other stage's file was edited.

## Iteration-1 findings, re-verified against the iteration-2 build

| id | iteration-1 symptom | iteration-2 evidence | status |
|---|---|---|---|
| `K10-BUG-1` | `add(KidJarPayoutRequested)` + same-tick `close()` leaked a live subscription and threw on its first emission | `_closing` is set synchronously on `close()`'s first line (`kid_jar_bloc.dart:34-40, 147-159`) and re-checked before every emit/subscribe in both handlers (`:51-70, :118-137`); the two proofs **run live and green**: `liveSubscriptions == 0` after add+close, and an emission into any leftover is a no-op. Five new race probes (emission / error / reload / six same-tick requests / close-twice) all clean | **fixed** |
| `K10-BUG-2` | a goal saved past target read `142% there!` under a full bar | `goalPercent` now rounds the CLAMPED fraction (`payout_celebration.dart:61-67`); the live proof shows `£35.50`, `£0.00 to go`, `[100% there!]`. The build added repo-level assertions (`payout_celebration_test`) | **fixed** |
| `K10-BUG-3` | 320 px / 1.3× ellipsized the seeded note-2 title and `£9.49 to go` mid-word | note title is unclamped (`payout_note.dart` — design sets no max-lines); each amount sits in `FittedBox(scaleDown)` (`payout_fund_card.dart`). The stage-3 matrix's `(320, 1.3)` cell is now in the green copy-fit set (live); this pass measured independently with bundled Nunito: `didExceedMaxLines == false` for both strings, money child 121.4 → slot 117.0 (**scale 0.963, whole**), and **identity at 390/1.0** (93.4 == 93.4) | **fixed** |

The iteration-2 UI fixes also resolved `4_review.md` findings 1 (comment) and
2 (dead `message` param). Findings 3–4 (stale `errorMessage` during a reload;
companion-move newest-vs-oldest hardening) are untouched and remain open
minors in that registry — not re-filed here.

## Bugs found by this stage

### K10-BUG-4 — the fund-card h2 still clamps a long goal name at 320 px / 1.3× (Minor, latent)

**Where:** `app/lib/features/kid_jar/presentation/widgets/payout_fund_card.dart`
(the h2 `Text` with `maxLines: 2, overflow: TextOverflow.ellipsis`).

**What.** The K10-BUG-3 fix freed the **note** title (`payout_note.dart`
dropped its 2-line cap) but the **fund card** h2 kept its cap. The design sets
no `max-lines`/`line-clamp` anywhere on this screen — the exact rationale that
made K10-BUG-3 a bug — so the goal name is the one string still clamped
against the design's box model. A plausible UK wishlist name —
`Maximilian-Alexander’s Nintendo Switch 2 game`, the same fixture K09's clean
probe uses — needs **three** lines in the 242 px card at 320/1.3, and the
goal name loses its tail.

**Repro (the proof), measured with the bundled Nunito:**

| cell | `didExceedMaxLines` |
|---|---|
| **320 × 1.3** | **true** (h2 box 242×68 — two clamped lines) |
| 320 × 1.0 | false |
| 390 × 1.3 | false |
| 390 × 1.0 | false |

**Latent:** savings goals have no writer in `lib/` today — only `Seed.demo`
inserts them; `recordPayout`/`moveToSavings` update `savedPence` only, and P15
deletes goals with a child — so this needs a future goal editor or imported
data. It is minor for that reason (the seeded `Lego Friends set` is whole at
every supported cell), and the fix is the same one the sibling note title
already got.

**Failing test:** `K10-BUG-4: a long goal name is never clamped in the fund
card` — `Expected: false / Actual: <true>` (the h2's `didExceedMaxLines`).

**Suggested fix:** drop `maxLines: 2`/`overflow: ellipsis` from the h2 (the
note title's K10-BUG-3 fix), or raise the cap to 3 — the card grows with
content like the CSS `.k10-fund`. One string, no geometry change at the
design cell (the seeded title still takes 2 lines, so the recorded bands hold).

## Cross-screen effect: K09-BUG-7 / 7b are fixed too

The new `_closing` guard was added to **both** handlers in the shared
`kid_jar_bloc.dart`, including K09's `_onLoadRequested`. K09's two parked
proofs (`k09_bugs_test.dart`, `skip: true`) now **pass**:

```
flutter test --timeout 120s --run-skipped --plain-name 'K09-BUG-7' \
  test/features/kid_jar/k09_bugs_test.dart
# → +2: All tests passed!   (K09-BUG-7 and K09-BUG-7b)
```

`k09_bugs_test.dart` / `docs/screens/K09/**` were deliberately **not**
edited — that screen's loop owns its registry, and its `3_test`-era coverage
of the shared guard already exists as a **live** test in
`kid_jar_bloc_test.dart` ("the jar handler has the same same-tick close
guard"). The orchestrator may want to flip K09's two skipped markers and
update K09's note.

## Verified clean this stage (new probes, stay green)

| Category | Probe | Result |
|---|---|---|
| async gap | an emission racing `close()` (event added, then close in the same turn) | subscription released, no exception |
| async gap | a stream **error** racing `close()` | subscription released, no exception |
| async gap | a **reload** paused in `previous.cancel()` when close lands | old sub cancelled, no second watch, live 0 |
| rapid events | **six** same-tick payout requests, then close | `watchLatestPayout()` was never called (`watches == 0`) — every queued handler saw `_closing` |
| async gap | `close()` called twice after an emission | idempotent, live 0 |
| layout (fixed) | seeded note title + `£9.49 to go` at 320 × 1.3 with bundled Nunito | `didExceedMaxLines == false` for both |
| layout (fixed) | amount slot at 390 × 1.0 vs 320 × 1.3 | identity at 390 (93.4 == 93.4); scaled at 320/1.3 (117.0/121.4 = 0.963, above 0.9) |
| layout (fixed) | unbroken 34-char goal word at 320 × 1.3 | wraps **by character** inside the card (max line right 238.1 ≤ 242) — removing the ellipsis did not trade truncation for paint overflow |
| layout (fixed) | overshoot goal in the UI | caption reads `100% there!`; the progress semantics (`100% of the … saved`) follows the same clamped percent |
| data edge | seeded goal title at 320 × 1.3 | whole (the matrix's green cell) |

Kept from iteration 1 (all still green): double taps (Thanks Mum!/lock),
longest UK nickname + 7-figure amounts, Pip look clamping, active-child
switch, companion-move instant boundary, file-DB restart, integer pence,
WCAG contrast pairs, dispose-mid-load, parent-mode deep link, back nav.

## Recorded, not filed

1. **The matrix's `didExceedMaxLines` is now vacuous for the money strings.**
   The K10-BUG-3 fix lays each amount out inside the FittedBox with unbounded
   width, so the paragraph can never exceed a line and the assertion passes by
   construction. A future regression to ellipsis/`maxLines` would not be
   caught by that check — asserting the FittedBox's **box/child scale** (as
   the new `k10_bugs_test.dart` probe does) would keep it honest. Test-quality
   note only; the fix itself is correct.
2. **Review findings 3–4 still open** (stale `errorMessage` kept during a
   payout reload; companion-move attribution hardening) — untouched by
   iteration 2, unchanged minors, owned by their registry.
3. **The torn frame on `recordPayout`** (per-source `combineLatest3`
   emission) remains recorded-not-filed from iteration 1: unreachable as a
   visible frame on one device.
4. **No in-product entry point to `/payout-day`** — recorded in iteration 1
   and still true (P13's caption promises the celebration; the wiring is
   cross-feature and orchestrator-owned).

## Open registry

| id | severity | status |
|---|---|---|
| `K10-BUG-1` | minor (latent) | **fixed in iteration 2** — proof live and green |
| `K10-BUG-2` | minor | **fixed in iteration 2** — proof live and green |
| `K10-BUG-3` | major | **fixed in iteration 2** — matrix 320@1.3 cell live; independently measured here |
| **`K10-BUG-4`** | **minor (latent)** | **open** — fund h2 clamps a long goal name at 320/1.3; 1 skipped proof |
| `4_review.md` findings 1–2 | minor | fixed in iteration 2 |
| `4_review.md` findings 3–4 | minor | open, unchanged, not K10-BUG-4 duplicates |
| `K09-BUG-7` / `7b` | minor (latent) | **fixed by this build** — K09's markers left to its loop (see above) |

## Process items (loop-owned, explicitly NOT findings)

- A concurrent iteration-2 stage left `payout_day_iter2_test.dart` (untracked)
  in `app/test/features/kid_jar/` while this stage ran; it is not this stage's
  file and was not touched or reported.
- The uncommitted briefs and other stages' notes are the loop's to commit;
  branch/merge order is the orchestrator's.

## Verdict

All three iteration-1 findings are verifiably fixed and their proofs now run
live: the close-leak guard (with five new race probes clean), the clamped
percent, and the 320 × 1.3 copy fit (independently measured, identity at the
design cell). The only new defect this pass found is `K10-BUG-4`, **minor and
latent** — a long goal name is clamped in the fund h2 at the narrowest cell,
with no goal editor in the product yet and a one-line fix. No blocker, no
major: **PASS**, with K10-BUG-4 as the single item for the next build.

VERDICT: PASS

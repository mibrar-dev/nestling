# K10 · Payout day — bug hunt (Stage 6, iteration 1)

Adversarial pass over the `/payout-day` screen, its BLoC and its repository
path (`watchLatestPayout`), against the demo seed. **No screen code was
changed in this stage.** No simulator was booted, installed on, screenshot or
driven (only stage 5 may, and only `604697A9…`). No image was attached or
uploaded; the design PNGs were only read with the file reader. No
`google_fonts`, no `DateTime.now()`, no wall-clock assertion — the clock is
pinned to Sat 3 Oct 2026 09:41 Europe/London by `test/flutter_test_config.dart`.

**This stage found two new defects and independently confirmed a third:**

| id | severity | status | proof |
|---|---|---|---|
| `K10-BUG-1` | minor (latent) | **open** | 2 skipped proofs, red |
| `K10-BUG-2` | minor | **open** | 1 skipped proof, red |
| `K10-BUG-3` | **major** | **open** — owned by the concurrent `3_test` stage | its proof re-run red; independently reproduced |

Verdict is **FAIL**: `K10-BUG-3` is a major, deterministic truncation of the
seeded money copy at a supported device cell (320 px / 1.3×), and it is
present in this build. The two new findings are one-line fixes for the next
build.

- New proofs: `app/test/features/kid_jar/k10_bugs_test.dart` — **11 green,
  3 skipped** (`K10-BUG-1`, `1b`, `2`). Run them red with:
  `cd app && flutter test --timeout 120s --run-skipped \
  --plain-name 'K10-BUG' test/features/kid_jar/k10_bugs_test.dart`
- `dart format` clean; `flutter analyze --no-pub
  test/features/kid_jar/k10_bugs_test.dart` → **No issues found!**
- K10-BUG-3's proof lives in the stage-3 matrix file (its registry, its id);
  this stage re-ran it and reproduced both measurements with an independent
  scratch probe (since deleted).
- Scope: only `app/test/features/kid_jar/k10_bugs_test.dart` and this file.
  No `app/lib/**`, no core, no other feature, no `tools/screens/**` touched.
  The scratch `_k10_verify_bug3_test.dart` this stage created was deleted; no
  other stage's files were edited.

## Bugs found by this stage

### K10-BUG-1 — a payout request + `close()` in the same tick leaks a live subscription and throws on its first emission (Minor, latent — the K09-BUG-7 defect's exact twin)

**Where:** `app/lib/features/kid_jar/presentation/bloc/kid_jar_bloc.dart:88-105`
(`_onPayoutRequested`). The `await previous?.cancel()` at line 94, the
subscription at 96, the `add` at 97.

**What.** The handler opens with `await previous?.cancel()`. Even with
`previous == null` (the first load) that await suspends the handler for a
microtask, so a `close()` landing in the window finds `_payoutSub` still
`null` and cancels nothing; the handler then subscribes to
`watchLatestPayout()` **after the bloc is closed**. The subscription is never
cancelled, and the first emission calls
`add(KidJarPayoutReceived(…))` on the closed bloc, which throws
`Bad state: Cannot add new events after calling close` from inside the stream
callback (an unhandled async error).

This is the same defect K09 registered as `K09-BUG-7` for the jar half of
this bloc; the payout half (`_onPayoutRequested`) never received the guard.
Both handlers live in the same file, so one fix covers both.

**Repro (the proofs):**

```dart
final repo = _CountingPayoutRepository();
final bloc = KidJarBloc(repository: repo)
  ..add(const KidJarPayoutRequested());
await bloc.close();
await Future<void>.delayed(const Duration(milliseconds: 20));
// K10-BUG-1  → Expected: <0>  Actual: <1>        (live payout subscriptions)
// then emit on the leaked controller:
// K10-BUG-1b → Bad state: Cannot add new events after calling close
```

| | expected | app |
|---|---|---|
| live subscriptions after `add` + `close` | 0 | **1** (leaked, never cancelled) |
| first emission on the leak | dropped | **throws** from `kid_jar_bloc.dart 97:24` |

**Latent:** no user gesture can unmount the route inside the microtask window
(the first frame must render before any control exists), so only programmatic
same-tick teardown — a future caller or a test harness — reaches it. That is
exactly why it is minor, like K09-BUG-7.

**Failing tests:** `K10-BUG-1: a payout request then close releases the
subscription` (`Expected: <0> / Actual: <1>`) and `K10-BUG-1b: the leaked
payout subscription cannot emit after close` (`Bad state: Cannot add new
events after calling close`).

**Suggested fix** (the K09-BUG-7 shape — apply to both handlers):
```dart
await previous?.cancel();
if (isClosed) return;
final sub = _repository.watchLatestPayout().listen(…);
if (isClosed) { unawaited(sub.cancel()); return; }
_payoutSub = sub;
```

### K10-BUG-2 — a goal saved past its target reads "142% there!" beside a full bar and "£0.00 to go" (Minor)

**Where:** `app/lib/features/kid_jar/domain/entities/payout_celebration.dart:61-64`
(`goalPercent`), consumed by `payout_fund_card.dart:84` (progress semantics)
and `:102` (the caption).

**What.** `goalFraction` is clamped to 0…1 (the bar is honest) and
`goalRemainingPence` is clamped at 0 (`£0.00 to go`), but `goalPercent`
divides the **raw** saved amount:

```dart
return ((goalSavedPence * 100) / goalTargetPence).round();
```

Saved past the target therefore renders a percent over 100 — "142% there!"
under a 100%-full progress bar, next to "£0.00 to go" — and the same figure is
announced by the progress semantics ("142% of the Lego Friends set saved").
K09's sibling card clamps first (`JarGoalCard.percent` is
`(fraction * 100).round()` with `fraction` clamped), so the same data reads
"100% there!" there.

**Reachable through the real product API:** `PocketMoneyRepositoryImpl.recordPayout`
caps the move at the payout but never at the goal's remainder — it writes
`savedPence: Value(goal.savedPence + movePence)` unbounded
(`pocket_money_repository_impl.dart:381-389`), the same hole K09-BUG-4 fixed
in `moveToSavings`. The proof uses exactly that API.

**Repro (the proof):** demo seed; then
`recordPayout(childId: 'maya', amountPence: 2000, savingsMovePence: 2000,
goalId: 'goal-lego')`.

| | expected | app |
|---|---|---|
| saved figure | £35.50 | £35.50 |
| "to go" | £0.00 to go | £0.00 to go (clamped) |
| percent caption | ≤ `100% there!` | **`142% there!`** |
| progress bar | full | full (clamped) |

**Failing test:** `K10-BUG-2: a goal saved past its target never reads over
100% there` (`Expected: empty / Actual: WhereIterable<String>:['142%
there!']`).

**Suggested fix** (exactly K09's clamp):
```dart
int get goalPercent {
  if (goalTargetPence <= 0) return 0;
  return (goalFraction * 100).round();
}
```

## K10-BUG-3 (major) — confirmed: 320 px / 1.3× truncates the seeded money copy

Owned by the concurrent `3_test` stage (`3_test.md` §3, proof parked in
`payout_day_matrix_test.dart`, `skip: true`). **Verified independently by this
stage**, not re-filed:

- Re-ran the stage-3 proof:
  `flutter test --timeout 120s --run-skipped --plain-name 'K10-BUG-3'
  test/features/kid_jar/payout_day_matrix_test.dart` → **`+1: All tests
  passed!`** (the defect is present).
- Independent scratch probe (deleted after) pumped the seed at 320 px / 1.3×
  and read the real `RenderParagraph`s:

| string | paragraph box | `didExceedMaxLines` |
|---|---|---|
| `£5.50 went into your Lego Friends set` | 200.0 × 58.0 | **true** |
| `£9.49 to go` | 117.0 × 30.0 | **true** |

The money string is ellipsized mid-word (`£9.49 to g…`) and the savings note
loses the goal's last word. Both are deterministic with the demo seed at a
supported cell (the app intentionally clamps text scale to 1.0–1.3). The fix
is the two `maxLines`/amount-row layout sites the stage-3 note names
(`payout_note.dart:62-68`, `payout_fund_card.dart:96-119`); this stage hands
that to the next build and does not duplicate the id.

## Verified clean this stage (new probes, stay green)

| Category | Probe | Result |
|---|---|---|
| rapid double tap | `Thanks Mum!` tapped twice in one frame | one `/kid-home`, no exception |
| rapid double tap | lock tapped twice in one frame | exactly one `/parental-gate` push; one pop returns to `/payout-day` |
| data edge | longest UK nickname + 7-figure goal + £9,999,999.99 payout at **320 × 1.3** | no overflow, no crash (copy truncation at this cell is K10-BUG-3, above) |
| data edge | Pip look out of range (`stage 9`, bogus style/skin/accessory) | stage clamps to 4, style→mochi, skin→sunny, accessory→none, no crash |
| data edge | active-child switch Maya → Leo while the screen is open | the whole celebration swaps atomically; note 2 hidden; no Maya string survives |
| data edge | no-payout child / `Seed.empty` | empty frame (owned by the stage-3 matrix, re-checked in passing) |
| timezone / instant | companion `Jar →` move 1 s **before** vs **at** the payout instant | before → `movedPence` null; at → attributed (P13 writes both rows with one `now`) |
| persistence | file DB: `recordPayout(420, move 100)`, close, reopen | paid 420, moved 100, saved 1650, nickname Maya |
| money rounding | `jarPounds` 0…300,000 plus 99,999,999 | exact integer-pence strings, no float drift |
| dark contrast | 10 K10 text pairs × light/dark, WCAG formula | all ≥ 4.5:1 (incl. `ink2`/`coinTint`, `ink`/`lilacTint`, `onLeaf`/`leaf`) |
| async gap | dispose the screen mid-load, then write payout + goal | no emit after close, no exception |
| mode guard | `/payout-day` deep link in **parent** mode | renders (kid routes are deliberately not mode-guarded — the K02 convention; the router's parent-only redirect in kid mode is the guard that matters) |
| back nav | deep-linked back (`canPop() == false`) | falls through to `/kid-home` (the pushed-route branch is the stage-3 matrix's) |

Not re-probed because stages 3–5 already own them with evidence: copy bytes,
geometry ±2 px in both themes, semantics labels, tap-target floor, loading /
failure / retry frames, dark token paints, the bottom-edge raster, the KidScope
sky/meadow mount.

## Recorded, not filed

1. **No in-product entry point reaches `/payout-day`.** `grep` over `app/lib`
   finds no navigation to `KidJarRoutePaths.payoutDay` (only the route
   definition; `kid_home` imports the feature for its `My jar` button only).
   DESIGN_SPEC's kid flow lists K10 after K09, and P13's own caption promises
   "Your children will see a payout celebration next time they open
   Nestling." — but there is no unseen-payout concept in the schema and no
   screen that navigates to K10, so the celebration is currently reachable
   only by deep link (which is how the loop screenshots it). This is a
   cross-screen integration gap: the fix touches `kid_home`/`pocket_money`
   and possibly the schema, all outside K10's editable scope (RULES §1). Left
   for the orchestrator / a SHARED_REQUEST rather than a K10 bug id.
2. **A torn frame can pair a new payout note with the old goal figure.** The
   `combineLatest3` stream re-emits per changed table, so the first emission
   after `recordPayout`'s transaction can carry the new ledger rows with the
   old goal figure — already acknowledged and drained in
   `payout_celebration_test.dart`. Unreachable as a visible frame on one
   device (the parent records in parent mode; the child's K10 run starts
   fresh), so recorded, not filed. Same behaviour as K09's accepted
   per-source emission.
3. **The concurrent stage-4 review findings 1–4** (`_PayoutPip` comment
   truncation, the write-only `_PayoutFailure.message`, the stale
   `errorMessage` during a payout reload, and the
   newest-vs-oldest companion-move hardening) are **not re-filed**: none is
   reachable today and none is a K10-BUG-1/2/3 duplicate. Finding 3 is the
   only one a next build might sweep up in the same edit as K10-BUG-1.

## Open registry

| id | severity | status |
|---|---|---|
| **`K10-BUG-1`** | minor (latent) | **open** — same-tick payout request + close leaks a subscription; 2 skipped proofs |
| **`K10-BUG-2`** | minor | **open** — overshoot goal reads "142% there!" under a full bar; 1 skipped proof |
| **`K10-BUG-3`** | **major** | **open** — 320 × 1.3 truncates the money string and the goal name; owned by `3_test`, confirmed here |
| `4_review.md` findings 1–4 | minor | open; cosmetic/invisible/hardening (see above) |
| `5_ui.md` D1–D5 | — | PASS, all DB-driven or owner-rule (no fix) |

## Process items (loop-owned, explicitly NOT findings)

- The concurrent `3_test` / `4_review` / `5_ui` stages were writing and
  running in this worktree while this stage ran. Two early suite reds were
  theirs, not K10's: the combined run that flashed
  `k10_probe_tmp_test.dart` `(setUpAll)` (a scratch file that appeared and
  was deleted mid-run — the file no longer exists) and a transient
  `No space left on device` during one compile. `payout_day_matrix_test.dart`
  alone is green (`+76 ~1`), and this stage's file is green (`+11 ~3`).
- The untracked `payout_day_matrix_test.dart` and the `3_test`/`4_review`/
  `5_ui` notes are other stages' work-in-flight; the loop owns committing
  them and the branch/merge order.
- `dart format` on this stage's file: clean; `flutter analyze
  test/features/kid_jar/k10_bugs_test.dart`: No issues found.

## Verdict

Two minor defects are new (`K10-BUG-1`, the payout handler's missing
same-tick close guard — the twin of K09-BUG-7; `K10-BUG-2`, the unclamped
`goalPercent`), and the stage-3 **major** truncation at 320 × 1.3 is
independently reproduced here. Per the stage rule — PASS only when no major
bugs — the verdict is **FAIL**, and the next build should fix all three:
guard both `*Requested` handlers against close, clamp `goalPercent` to the
clamped fraction, and let the note title / amounts row render whole at
320 × 1.3 (the stage-3 fix note names the two sites). Everything else this
stage probed is clean.

VERDICT: FAIL

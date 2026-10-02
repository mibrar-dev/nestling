# P04 · Privacy consent — bug hunt (Stage 6, iteration 3)

Route `/privacy` · feature `privacy_consent` · parent mode · seeds `demo` and
first-run (empty DB). **No screen code was changed.** Re-hunted the
iteration-3 tree after the P04-8 / null-title fixes and before the shared
batch (`ic_trash`, themed shield) lands.

`app/test/features/privacy_consent/p04_bugs_test.dart` now has **16 proofs:
12 green + 4 skipped** (P04-2/P04-4/P04-7 open, P04-9 new). Run the skipped
ones with:

```
flutter test --run-skipped test/features/privacy_consent/p04_bugs_test.dart
→ 12 passed, 4 failed (the four open defects, by design)
```

Method: re-read the two iteration-3 production changes, the new copy test and
the review; re-ran every previous proof; probed the untested edges with
throwaway tests (first-run upsert overlap at repository and widget level,
same-frame vs one-frame double taps, guard/deep-link/persistence/async-gap
re-checks); re-measured the iteration-3 shots against the design. Every claim
below has a committed proof.

**New finding this iteration: P04-9 (minor) — the first-run upsert is not
atomic.** P04-8 is fixed and pinned; four defects remain open (P04-2/P04-4
majors, P04-7/P04-9 minors). The screen still cannot pass: `VERDICT: FAIL`.

## Iteration state

| Id | Sev | Finding | Status |
|---|---|---|---|
| P04-1 | major | first-run opt-in silently dropped | **FIXED** — upsert (it. 2); proof green |
| P04-2 | major | row 4 empty peach tile (no trash glyph) | **OPEN — shared batch** (orchestrator 13:42 UPDATE: deferred; flip instructions ready) |
| P04-3 | major | compact nav bar 16 px short | **FIXED** — shared merge (it. 2); proof green |
| P04-4 | major | real 1 px dividers inflate the list by 3 px | **OPEN — now fixable in scope** per review it.-3 finding 1 (below); shared §6 stays for the component |
| P04-5 | minor | rapid double-tap wrote the same value twice | **FIXED** — optimistic emit (it. 2); proof green |
| P04-6 | major | failed OFF write claimed "it stays off" | **FIXED** — state-aware caption (it. 2); proof green |
| P04-7 | minor | dark mode renders the light-baked shield | **OPEN — shared batch** (themed shield queued) |
| P04-8 | minor | failed toggle reverted to an unpersisted value | **FIXED** (it. 3) — `_crashFrom(state.items)`; proof un-skipped and green, re-verified here |
| P04-9 | minor | overlapping first-run writes keep the earlier value | **NEW** (below) |

## New finding

### P04-9 — the first-run upsert is a read-then-write pair, not an atomic write — MINOR

- **Where:** `app/lib/features/privacy_consent/data/privacy_consent_repository_impl.dart:72-86`
  — `UPDATE … ; if (changed == 0) INSERT … InsertMode.insertOrIgnore`.
  (Also raised by the iteration-3 review, finding 2.)
- **Why:** two overlapping `setCrashConsent` calls both execute their UPDATE
  before either INSERT, so both see the empty `settings` table; the first
  INSERT wins and the second is silently ignored. On a first-run database —
  exactly P04's first visit, before the row exists — the parent's **later**
  tap can be dropped, and the `watchItems` re-emit then reconciles the switch
  to that earlier value. If the earlier value is ON, the opt-in silently
  survives the parent's last attempt to switch it off.
- **Repro (proof, deterministic — 5/5 runs):** `--run-skipped … --plain-name
  '[P04-9]'` — `Seed.fresh(db)`, then issue
  `setCrashConsent(true)` and `setCrashConsent(false)` without awaiting
  between them, `await Future.wait` both → expected stored `false`, actual
  `true` (one row). A widget-level same-frame double tap shows the same, but
  that variant is dominated by the pre-rebuild stale value, so the
  repository-level proof is the one committed.
- **Reachability:** only when the two writes overlap (rapid double tap /
  slow DB). With a frame between taps the repository serialises in practice —
  my iteration-2 guard ("first run: a double tap persists the last tap") is
  still green — but the non-atomic pair is the real defect behind it.
- **Failing test:** `[P04-9] overlapping first-run writes keep the last value`.
- **Fix (feature-local, one of):**
  1. wrap UPDATE + conditional INSERT in `_db.transaction(() async { … })`
     so the pair is atomic and the second call sees the committed row; or
  2. serialise writes in the bloc with a `Future<void> _writes =
     Future<void>.value(); _writes = _writes.then(…)` chain (keeps the
     optimistic emit and error handling unchanged).
  Option 1 is the better home; the same pattern can later be shared with
  P16's `SettingsRepositoryImpl._write`.

## Open defects

### P04-4 — list 3 px too tall; fixable in P04 scope — MAJOR

- **Where:** `privacy_consent_view.dart:94-127` (four rows as four children of
  shared `NestList`, which injects real `Divider(height: 1)`s).
- **Current evidence:** iteration-3 shots: list card 289→512 vs design
  289→509; tile tops 295 / 352 / 409 / 466 (57 px apart) vs 295 / 351 / 407 /
  463 (56 apart); opt card 530 vs 527; `compare.py` bands 3–5 remain the worst
  (7.86 / 7.31 / 6.52 % light). `[P04-4]` fails with list = rows + 3.
- **Fix (review it.-3 finding 1, do this next build):** pass the four rows as
  a **single** child of `NestList` (a `Column`), so no dividers are injected
  and the card chrome (surface, r16, shadow) is unchanged; give
  `_PromiseRow` a `showDivider` flag and wrap its content in a `Stack` with
  one non-layout `Positioned(top: 0, left: 72, right: 0, height: 1, child:
  Divider(height: 1, thickness: 1, color: context.nest.line))` for rows 2–4.
  The Stack sizes to its non-positioned child, so the separator adds zero
  height and the line is pixel-identical to the design's `::before`. Keep
  `SHARED_REQUEST` §6 filed — the shared component is still wrong for every
  other `NestList` screen — but it no longer blocks P04.

### P04-2 — row 4 empty peach tile — MAJOR (shared batch)

- Deferred by the orchestrator's 13:42 UPDATE. `app/assets/icons/ic_trash.svg`
  and `NestlingIcons.trash` are still absent from this worktree; row 4 keeps
  the reserved 40×40 tile + `TODO(P04)`. When the batch merges: add
  `leadingAsset: NestIcons.trash`, delete the TODO, un-skip `[P04-2]`, flip
  the contract test's `findsNothing` to `findsOneWidget`. Evidence: the
  iteration-3 shot still shows a continuous `#FFEDE4` tile at x=52,
  y 466–505.7 (design has rust glyph pixels in 463–502.7).

### P04-7 — dark shield artwork — MINOR (shared batch)

- The themed shield is named in the same shared batch. Current probes on
  `ui/app_dark_3.png`: disc `#E6EFFE` vs design `#1A2A4A`; body `#FFFFFF`
  vs `#1F1C2E`. Flip `[P04-7]` when the themed asset lands.

## Verified this iteration (passing proofs and probes)

- **P04-8 fix:** the double-failure revert now restores the stored value; my
  `[P04-8]` proof is un-skipped and green, and the direct bloc test added by
  stage 3 covers the same path. No regression in either failure direction
  (P04-6 proof still green).
- **Null-title nav:** the `title: ''` workaround removal changes nothing
  visually (iteration-3 probes: chevron 66–80, h1 113–138, list top 289 — Δ0
  vs both the design and iteration 2) and the new widget test pins the 60 px
  bar with no empty `Text` node.
- **Copy rule:** the new `privacy_consent_copy_test.dart` reads the HTML
  source, decodes entities and compares every rendered string; the review
  independently decoded the same strings code point by code point. No drift
  found; typographic characters are exact.
- **Same-frame double tap:** two taps inside one frame send `true` twice (the
  widget has not rebuilt), which is a harness artefact — a human double tap
  spans frames, and the one-frame-apart behaviour is correct and pinned
  (`[P04-5]`, and the first-run last-write guard). Not reported as a bug;
  the genuine overlap defect is P04-9 at the repository level.
- **Re-run green:** kid-mode guard (`/parental-gate`), deep-link back
  (`/create-account`), restart persistence (demo + first-run), async-gap
  after leaving the screen, single-dialog double tap, 320 px / scale 1.3
  matrix, dark contrast, 20 px gutters, CTA surface to the physical edge.
- **N/A:** children/long names/coins/£ values (no such data on P04), timezone
  and money rounding (no dates or money), child-order rule (no children).

## Mandatory notes status

| Item | Status |
|---|---|
| 1 — row-4 bin glyph + all-four-glyph test | Deferred to the shared batch by the 13:42 UPDATE; P04 side ready (`TODO`, reserved tile, proof + flip instructions) |
| 2 — header 16 px offset | **Met** (shared merge; probes Δ0) |
| 3 — row heights/dividers → opt card ≈528 | Rows/tiles/indent exact; residual +3 px is P04-4, **fixable in scope** per review it.-3 finding 1 — not closed this iteration |
| 4 — bottom edge + alignment | **Met** (both themes, gutters 20 px, header exact; the only misalignment is P04-4) |
| COPY / CHILD ORDER | Copy **met** (new test + independent review decode); child order N/A |

## Suite state at hand-off

- `dart format --set-exit-if-changed .` → 358 files, 0 changed.
- `flutter analyze` → No issues found.
- `flutter test test/features/privacy_consent/` → **105 passed, 4 skipped,
  0 failed**.
- `flutter test` (whole app) → **592 passed, 4 skipped, 0 failed**.
- `--run-skipped` on the bug file → 12 passed, **4 failed** (P04-2, P04-4,
  P04-7, P04-9), each with its repro above.

## Verdict

All iteration-1/2 bugs are fixed and pinned, the iteration-3 changes (P04-8
revert, null-title nav) are verified with no regression, and the copy rule is
locked by a test. Two majors remain open on this screen: P04-4 (the +3 px
divider drift — now proven fixable inside RULES §1, review finding 1) and
P04-2 (empty row-4 tile, deferred to the shared batch). Plus P04-7 (shared
batch) and the new P04-9 (non-atomic first-run upsert). "All tests pass" does
not mean "no defects open".

VERDICT: FAIL

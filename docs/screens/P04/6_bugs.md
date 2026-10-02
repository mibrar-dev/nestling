# P04 · Privacy consent — bug hunt (Stage 6, iteration 2)

Route `/privacy` · feature `privacy_consent` · parent mode · seeds `demo` and
first-run (empty DB). **No screen code was changed.** Re-hunted the
iteration-2 tree after the build fixes and the shared compact-nav merge
(`main` `fc981bc` via `b93ad6d`/`bccbde8`).

`app/test/features/privacy_consent/p04_bugs_test.dart` now has **15 proofs:
11 green + 4 skipped** (P04-2/P04-4/P04-7 shared-blocked, P04-8 new). Run the
skipped ones with:

```
flutter test --run-skipped test/features/privacy_consent/p04_bugs_test.dart
→ 11 passed, 4 failed (the four open defects, by design)
```

Method: re-read the iteration-2 view/bloc/repository plus the shared component
diffs; measured the new simulator shots (`ui/app_{light,dark}_2.png`) against
the design PNGs with pixel probes; probed every edge class in the brief with
throwaway tests before writing anything (first-run upsert races, rapid
double/triple taps, interleaved write failures, async gaps, guards,
persistence); every claim below is reproduced by a committed test.

**New finding this iteration: P04-8 (minor).** Four iteration-1 findings are
fixed and pinned; two majors and one minor remain open, all shared-owned.
The screen still cannot pass: `VERDICT: FAIL`.

## Iteration-1 findings — disposition

| Id | Sev | Finding | Status |
|---|---|---|---|
| P04-1 | major | first-run opt-in silently dropped | **FIXED** — upsert in `setCrashConsent` (`data/privacy_consent_repository_impl.dart:63-87`); `[P04-1]` green; two new first-run guards below |
| P04-2 | major | row 4 empty peach tile (no trash glyph) | **OPEN — shared** (`ic_trash.svg` + `NestIcons.trash` still absent; `SHARED_REQUEST` §1) |
| P04-3 | major | compact nav bar 16 px short | **FIXED by the shared merge** — 60 px bar, chevron centre 69→73, h1 91→107; `[P04-3]` green |
| P04-4 | major | real 1 px dividers inflate the list by 3 px | **OPEN — shared** (`NestList` draws layout-height `Divider`s; §6) |
| P04-5 | minor | rapid double-tap wrote the same value twice | **FIXED** — optimistic emit; `[P04-5]` green |
| P04-6 | major | failed OFF write claimed "it stays off" | **FIXED** — state-aware caption; `[P04-6]` green |
| P04-7 | minor | dark mode renders the light-baked shield | **OPEN — shared asset** (§2) |
| P04-8 | minor | double-failed rapid toggle reverts to an unpersisted value | **NEW** (below) |

## New finding

### P04-8 — a double-failed rapid toggle reverts to a value that was never persisted — MINOR

- **Where:** `app/lib/features/privacy_consent/presentation/bloc/privacy_consent_bloc.dart:52`
  (`final previous = state.crashConsent;`) + `:60` (`crashConsent: previous`).
  With the iteration-2 optimistic emit, `state.crashConsent` can be another
  event's **in-flight optimistic** value, not the stored one. (Also flagged by
  the iteration-2 review, finding 4.)
- **Why it matters:** interleaving ON → OFF with both writes failing, the
  first failure reverts to the stored OFF, then the second failure reverts to
  the first tap's optimistic ON: nothing was persisted, yet the switch shows
  ON, the caption says "Crash reports are still on", and `status == failure`
  disables the toggle, so the parent cannot correct it without leaving the
  screen. A never-persisted consent being announced as ON is the wrong
  direction for this control (same root cause can strand other orderings,
  e.g. a failed first tap after a later successful tap).
- **Repro (test):** `--run-skipped … --plain-name '[P04-8]'` — fake repository
  whose ON write fails at 10 ms and OFF write at 50 ms (items stream never
  re-emits); tap twice → expected `NestToggle.value == false` and no "still
  on" caption, actual `true` + caption. Bloc-level probe confirmed
  `state.crashConsent == true`, `status == failure`, stored value `false`.
- **Failing test:** `[P04-8] a double-failed rapid toggle reverts to the
  stored value`.
- **Fix (one line, feature-local):** revert to the stored value the state
  already carries — `final previous = _crashFrom(state.items);` (the existing
  static helper; `items` mirrors the database) instead of
  `state.crashConsent` — or expose a `storedCrashConsent` getter. Review
  finding 4 has the same fix.

## Remaining defects — all shared-owned, none fixable in RULES §1

| Id | Sev | Defect | Evidence (iteration-2 shots) | Action needed |
|---|---|---|---|---|
| P04-2 | major | row 4 "Delete everything anytime" renders an empty peach tile; the design draws the trash glyph | `ui/app_light_2.png` x=52: peach tile 466–505.7 continuous `#FFEDE4` (no glyph pixels); design 463–502.7 with rust glyph | add `app/assets/icons/ic_trash.svg` (path `M4 7h16M9.5 7V5h5v2M6.5 7l1 13h9l1-13`, 24×24, `currentColor`, 2 px, round caps) + `NestlingIcons.trash`/`NestIcons.trash`; then P04 adds `leadingAsset: NestIcons.trash` and `[P04-2]` goes green (one line) |
| P04-4 | major | `NestList`'s real 1 px `Divider`s make the list 227 px instead of 224; every row after the first drifts 1 px and everything below +3 px | app tile tops **295 / 352 / 409 / 466** (57 px apart) vs design **295 / 351 / 407 / 463** (56 px apart); opt card top 530 vs 527; `compare.py` bands 3–5 stay the worst (7.86 / 7.31 / 6.52 % light) | one shared change in `nest_list_row.dart`: paint the separator over the row boundary (Stack/overlay/negative offset) keeping `indent: 72` + `line`; then `[P04-4]` goes green |
| P04-7 | minor | dark mode shows `#E6EFFE` disc + `#FFFFFF` shield body instead of the design's `#1A2A4A` + `#1F1C2E` | dark shot probes: disc `(165,229)` design `#1A2A4A` vs app `#E6EFFE`; body `(195,250)` design `#1F1C2E` vs app `#FFFFFF` | themed shield asset (light + dark variant or token-coloured layers); then `[P04-7]` asserts the dark artwork |

**Mandatory `ORCHESTRATOR_NOTES.md` status:** item 1 **unmet** (P04-2,
blocked on the shared asset); item 2 **met** (shared merge, probes Δ0);
item 3 **partly met** (row heights/indent exact, residual is the 3 divider
px — P04-4); item 4 **met** (bottom panel to the edge both themes, 20 px
gutters, header/CTA aligned).

## Adversarial checks this iteration (cleared, proofs in the file)

- **First-run upsert races — clean.** An ON→OFF double tap on an empty DB
  persists the last tap (`false`) across 5 consecutive runs, so the
  `insertOrIgnore` fallback does not drop the later overlapping write in
  practice; pinned as a new guard test. A first-run opt-in also survives a
  route close/reopen (new guard). Single-tap upsert was already P04-1.
- **Interleaved write outcomes — only the double-failure ordering is wrong.**
  First-fails-then-second-succeeds and first-succeeds-then-second-fails both
  settle on the last successful write's value; captured as P04-8.
- **Async gap:** unchanged — a write failing after the parent leaves the
  screen is caught (bloc 9.2 drops emits after close); proof still green.
- **Guard / deep link:** kid mode still redirects `/privacy` →
  `/parental-gate`; back with no history still lands on `/create-account`.
- **Visual owner rules on the iteration-2 shots:** gutters 20 px on headline,
  list, opt card and CTA; bottom CTA surface runs to the physical edge in both
  themes (`#FFFFFF` / `#1F1C2E` at y 838); header and CTA are pixel-exact
  (h1 113–138, chevron 66–80, Continue 690). The three shared deviations are
  the only visual gaps.
- **Unchanged / N/A for this screen:** text scale 1.3 at 320 px (matrix still
  green), dark contrast on token pairs, Pip rule (no Pip), children/money/
  timezone edge classes (P04 reads no child, quest or ledger data, no dates).
- **New cleanup obligations only (not defects):** the contract test still pins
  row 4's *missing* glyph (`findsNothing`) — flip it with P04-2; the view's
  `title: ''` + obsolete `TODO(P04)` should be dropped now that `NestNavBar`
  handles a null title (review finding 3); `2_build.md` has three stale
  sentences (review finding 5). The next build stage owns these.

## Suite state at hand-off

- `dart format --set-exit-if-changed .` → 357 files, 0 changed.
- `flutter analyze` → No issues found.
- `flutter test test/features/privacy_consent/` → **97 passed, 4 skipped,
  0 failed**.
- `flutter test` (whole app) → **584 passed, 4 skipped, 0 failed**.
- `--run-skipped` on the bug file → 11 passed, **4 failed** (P04-2/P04-4/
  P04-7 shared-blocked, P04-8 new), each with its own repro above.

## Verdict

The iteration-1 in-scope bugs are fixed and pinned, the shared nav fix closed
the header offset, and the first-run upsert holds under overlap probes. But
two majors remain visibly open on this screen — the empty row-4 tile (P04-2)
and the +3 px list/row drift (P04-4) — plus the dark shield artwork (P04-7)
and the new double-failure revert (P04-8, minor). The three visual defects are
owned by `lib/core`/assets and need orchestrator action (items 1 and 3 of the
mandatory notes are not met); "all tests pass" must not be read as "no
defects open".

VERDICT: FAIL

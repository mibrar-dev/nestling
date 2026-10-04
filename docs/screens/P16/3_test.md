# P16 Settings — Stage 3 TEST (iteration 5)

Job: re-prove the screen after the iteration-5 un-fork, and serve the two new
mandatory rules in this brief (AVATAR INITIALS, TEST TIMEOUTS).

**Outcome: FAIL — every gate is green, the screen now has **zero** skip-marked
tests in its own file except the one I added this stage, and iteration 5's
un-fork is verified metric-preserving by my existing tests. One minor defect
remains open (P16-T04: the two hand-rolled avatar initials), and it is a
**mandatory rule the tree cannot apply yet** — not a choice.**

Numbers: **+2 tests** (141 in `test/features/settings`, 1 of them a skip-marked
proof), **0 new failures**, **1 new minor bug**, **the iteration-4 finding and
mandate items 1–3 all closed by the build**.

---

## 1. What iteration 5 changed (the shared-request arc closed)

Shared batch 6 landed on this branch and made every previously-blocked item
buildable, so this build is mostly consumption:

| shared batch 6 item | what it unblocked |
|---|---|
| `NestListRow._TrailingSlop` + `_RowSlopForwarder` | T02 / T03 **without** local wrappers |
| section label line box 13/16 | `_P16Sect` revert |
| `members.email` (schema v7, nullable) + seeded | DATA OVER MOCKS owner row |
| `NestCard(radius:)` parameter | subcard revert |
| IANA backward links resolved | P16-B09 |

1. **All three forks are gone** — `NestSectionLabel` ×7, `NestCard` ×2, plain
   `NestListRow` for the switch and picker rows, every `SizedBox` wrapper
   deleted. `SettingsRow` survives narrowed to the five rows the shared row
   still cannot express (owner, co-parent, two children, the danger row).
2. **DATA OVER MOCKS is real** — the owner subtitle reads
   `SettingsMemberEntry.email` ← `members.email`; `sarah@example.co.uk` is gone
   from the view; a NULL e-mail falls back to the role-derived `Owner`.
3. **T03 and B09 un-skipped and green** — so, with my T02 proof from iteration 3
   and the B11 proof from iteration 3, **every tap-target and zone finding of
   the last three iterations is closed with a live guard**.
4. Token literals replaced (`gap2`, `gap14`, `NestType.chipLabel`).
5. The build corrected its own iteration-4 finding: "the seed holds that parent
   email" is true *now* — the ruling described the destination and the integrator
   measured the tree it was written against.

## 2. What I verified this iteration (no new test needed — the old ones did it)

The build claims the reverts are "metric-preserving". My geometry and design
tests, written against the forks in iterations 2–4, now pass against the shared
components — which is the verification:

| contract | assertion (which file) | measured now |
|---|---|---|
| section label line box | typography + scaling, both themes/scales (`settings_responsive_test.dart`) | **16 px** at scale 1.0, 21 px at 1.3 — identical to the fork |
| subcard radius / padding | `subscriptionCard()` decoration (`settings_responsive_test.dart`) | **16 px** radius, **16 × 14** padding, `surface` + `sh-1` |
| switch track flush right | B11 proof, 320/390/430 × light/dark | track **303–354** at 390 (= 370 − 16) |
| 44 px target | T02 proof: content box ≥ 44 + taps ±5 px flip the DB | content box **44** (row padding box 56 − 12) |
| 4 px horizontal slop | T03 proof: taps 4 px left AND right of the track | both flip |
| gutter / ALIGNMENT | full sweep at three widths × two scales × two themes | one 20 px gutter everywhere |

**One number I re-pinned because it was only ever a prediction:** iteration 4
measured that un-forking `SettingsRow` → `NestListRow` *without* batch 6 would
grow the switch rows 56 → **64 px** (+8 × 3 rows). Batch 6's `_TrailingSlop` is
what prevents it, so "the reverts are metric-preserving" was a claim until now.
The T02 proof now asserts the row is **56 px** — like every other row on the
page — so the claim is testable rather than trusted.

## 3. Tests added (2) — the new AVATAR INITIALS rule

`nestAvatarInitial(name)` lives on `main` but is **absent from this worktree**
(the branch is 25 commits behind `main`), so importing it here would break
`flutter analyze`. Both P16 call sites
(`settings_view.dart`, member row and child row) still hand-roll
`characters.first` — which is grapheme-safe and so does **not** violate the
rule's actual prohibition (`name[0]`), but also does not do two of the things
the shared helper does.

- **Live: an emoji nickname yields ONE grapheme.** `'🌟Zoe'` renders initial
  `'🌟'`, whole, with no exception — the guard against anyone "simplifying" the
  call site back to `name[0]`, which would throw on an unpaired surrogate and
  take the frame with it. Addressed through *the row's own* avatar: my first
  draft asserted "some avatar contains '🌟'", which a different child could
  satisfy — the same false-pass shape the loop's rules warn about, caught by
  tightening it.
- **Skip-marked `[P16-T04]`: the initial trims and falls back.** The helper
  trims first and returns its `fallback` (`'?'`) for empty or whitespace-only
  names; the hand-rolled version does neither. Measured: a nickname of
  `' Maya'` renders a **space** as its avatar initial, and `'   '` also renders
  a space instead of `'?'` — a blank avatar where a parent expects a letter.
  Unfixable in this tree (the helper does not exist here); the fix is the two
  one-line swaps the integrator already identified.

Also satisfied this stage: **TEST TIMEOUTS** — every run above used
`--timeout 120s`, foreground, none over 10 minutes. **IDS** — the screen mints
no ids, nothing to check.

## 4. Results

```
$ dart format .
Formatted 553 files (0 changed) in 3.21 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 14.2s)

$ flutter test test/features/settings --timeout 120s
00:31 +141 ~1: All tests passed!

$ flutter test --timeout 120s
02:29 +3278 ~3: All tests passed!
```

Zero failures. The full suite's `~3` is **one** P16 skip (my T04), K01's
`k01_bugs_test.dart` skip (from `Merge screen/K09`/main) and P12's pre-existing
one. P16's own skip count went 2 (iteration 4) → 1 (this stage).

**Skip honesty.** `flutter test test/features/settings --run-skipped --timeout
120s` fails on exactly the one open proof:

```
settings_a11y_test.dart  [P16-T04] the initial trims a leading space and falls
                                   back to "?" for a whitespace-only name
        Expected: 'M'   Actual: ' '     (nickname <space>Maya)
```

## 5. Bugs

### Closed this iteration (build, verified by my tests)
P16-T03 (4 px horizontal slop), P16-B09 (linked IANA ids), P16-B11 (switch
alignment), P16-B10 (guard coverage), and — via the un-fork and batch 6 — the
three mandatory `ORCHESTRATOR_NOTES` items 1 and 3, plus item 2 (DATA OVER
MOCKS). Nothing regressed: T02 and B11 still pass on the new layout.

### Open — P16-T04 (minor) — mine

`app/lib/features/settings/presentation/views/settings_view.dart` — the member
row and the child row build their `NestAvatar` initial from
`name.characters.first.toUpperCase()` (with an `isEmpty ? '?'` guard) instead of
`nestAvatarInitial(name)`. Effect: a leading space or a whitespace-only
nickname renders a space (or nothing) in the avatar; the shared helper would
render `M` and `?`.

**Repro:** real app at `/settings`, rename a child to `' Maya'` → the Children
row's avatar shows a blank where `M` belongs. Proof:
`flutter test test/features/settings --run-skipped --timeout 120s`.

**Blocked here:** the helper is on `main`, absent from this branch (25 commits
behind); importing it fails `flutter analyze`. Fix after the merge: two
one-line swaps. `SHARED_REQUEST.md` already carries the rest of the arc; this
one needs no schema or shared work, only the merge.

## 6. Observations (not bugs)

1. **The email tripwire did its job and was correctly flipped.** My iteration-4
   tripwire asserted "no `email` column exists"; when batch 6 landed it failed,
   which is exactly what it was for. The builders replaced it with the positive
   form (column present, row reads it) plus a NULL-fallback case — the right
   resolution, and a good demonstration of why a tripwire is worth writing when
   a ruling cannot yet be honoured.
2. **The Family list still announces as one node.** Its two static rows (Sarah,
   James) have no semantics node of their own, so a screen reader announces
   `"Sarah — you / … / James — co-parent / … / Invite co-parent"` as a single
   button. Unchanged across five iterations; the shared `NestListRow`'s
   no-`onTap` branch is where it lives, and the integrator records that a local
   label broke the tappable-node contract for the whole section.
3. **The shared `Semantics(label:) > InkWheel` wart** — blast radius still
   pinned by `settings_a11y_test.dart`: the only unlabelled tappable nodes are
   the three switch tracks.
4. `.ptitle` declares no `text-wrap: balance`, so the plain `Text` with
   `NestType.h1` is correct by the CSS as written.
5. **A fenced tap ripples but does nothing** (the 300 ms guard) — defensible,
   but a silent dead tap if the window is ever widened.
6. The dialog Cancel still wraps at 320 × 1.3 (shared `NestButton` padding).

## 7. Harness notes

- **A row's type is not stable across a fork/revert.** `NestAvatar` lives under
  `NestListRow` for some rows and under P16's `SettingsRow` for the member and
  child rows; after the un-fork the child rows are `SettingsRow`. Address rows
  with `find.byWidgetPredicate((w) => w is SettingsRow || w is NestListRow)` so
  a proof survives either shape — the same reasoning that made the T02 proof
  shell-agnostic.
- **"Some element contains X" is a weak assertion** when the tree holds several
  similar nodes: my first avatar draft passed for the wrong reason (another
  child's `M`). Address the node's own row and read that row's value.
- Unchanged from iterations 1–4: Drift streams need `settleSettings`
  (`runAsync`); `bloc.close()` must be `unawaited` in a widget test;
  `scrollUntilVisible` walks down only (`scrollSettingsUpTo` walks up); a
  semantics-tree walk misses un-passed nodes (`getSemantics` does not);
  `testWidgets(skip: …)` takes a bool; never settle before asserting a
  time-windowed guard; `PRAGMA table_info(t)` reads the live schema.

---

VERDICT: FAIL
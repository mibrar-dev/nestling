# P09 — stage 3 · TEST (iteration 6)

Scope: `app/test/features/quests/**` only. No screen code, no shared code and
no `tools/` touched; `flutter clean` never run; no simulator booted, installed
on, screenshotted or driven; no `skip:` added, no test weakened, no
`analysis_options.yaml` change; `google_fonts` appears nowhere.

Iteration 6 landed the **IDS rule** (`newId(prefix)`, never a clock) and the
P09-TEST-9 centring fix. Both are shape-level changes to a tap target that the
previous two rounds had already broken once, so this stage's work was to prove
the new shapes hold everywhere the app can be, not only on the design frame.

## 1. Gates

```
$ dart format --set-exit-if-changed .
Formatted 539 files (0 changed) in 3.34 seconds.          (exit 0)

$ flutter analyze
Analyzing app...
No issues found! (ran in 5.0s)

$ flutter test test/features/quests/
00:30 +419: All tests passed!          # 419 tests, zero skipped

$ flutter test
02:40 +3129 ~2: All tests passed!
```

Per file: states 23, coin-rules 15, data-integrity 23, toggle-hit-area 7,
robustness 22, copy 8, a11y 15, bloc 7, view 42, view-geometry 9, bugs 32. The
`~2` are the repo's pre-existing skips (P12's and K01's); this feature has none.

## 2. Review of stage 2's forced test changes

| File | Change | Verdict |
|---|---|---|
| `quest_editor_states_test.dart` — my CLOCK test | retitled *'the new id comes from `newId`, never from a clock'*; the assertion moved from "equals `q-<appNowUtc ms>`" to a **uuid v4 shape regex**, with both former clock shapes rejected explicitly | correct and a genuine **strengthening**: the old assertion could not tell a uuid from a timestamp, and the reason is now legible in the failure |
| `quest_editor_view_test.dart` | two hard-coded toggle assertions (`center.dy == approval.top + 36`, `top == approval.top + 20.5`) replaced by the centring contract | correct — those were measurements of the bug P09-TEST-9 fixed; the contract is the stricter property |
| `p09_bugs_test.dart` BUG-P09-14 | un-skipped and **extended**: both creates persist, the editor is not stranded, no `UNIQUE constraint failed` text reaches the parent, and the two ids are distinct | correct; this is the mandatory 09:27 item's proof |

## 3. Tests added (4 new) and strengthened (5)

### 3.1 The centring contract, now asserted at every surface (5 strengthened)

Iteration 5 added a placement matrix (320/390/430 × 1.0, plus 320/390 at scale
1.3) that could only assert *containment* — the switch never covered the
sub-line and never left the card's 16 px box — because the code then pinned
`Positioned(top: 20.5)`, the design frame's centred offset, and any centring
assertion would have failed. Now that the offset derives from the card's own
height, those same five tests assert the real rule on top of the old
invariants:

```
track.center.dy  ≈  (title.top + sub.bottom) / 2      ± 1 px
track.center.dy  ≈  card.center.dy                    ± 1 px
```

At 390/1.0 that is exactly the design rect (track 303 / 620.5 / 51 / 31); at the
other four metrics it is what stops the switch riding 20–43.5 px high. This is
the assertion P09-TEST-9's fix should have had from the start, and it now
guards the fix rather than the symptom.

### 3.2 The hit slop on every surface (3 new)

`quest_editor_toggle_hit_area_test.dart` grew from one proof at 390/1.0 to
**four** (390 and 320, at scale 1.0 and 1.3), still on the real bundled faces.
The code comment at the toggle's call site records why this matters: while
centring the track, `RenderBox.hitTest` bounds-checks *every* ancestor box, so a
tight `Positioned.fill` + `Padding` region silently ate the 2 px-right tap and a
tight vertical inset ate both 5 px taps — six attempts to find a shape that
satisfies both BUG-P09-10 (slop) and P09-TEST-9 (centring). That class of
regression only shows where the card is taller than the design's 72, so the
proof now runs at 320 dp and at scale 1.3, where it is. All four pass.

### 3.3 Id uniqueness, generalised from two creates to three (1 new)

Stage 6's BUG-P09-14 proof creates two quests and checks both survive. This
adds a third in the same session and asserts the stronger property: three rows,
**three distinct ids**, each matching `^q-<uuid v4>$`. A mint that reused a
suffix, or that fell back to a counter seeded from the clock, would pass a
two-row check and fail this one.

## 4. Bugs found

**None.** No test in this stage exposed a new defect in the screen: the two
open items from iteration 5 are now closed by the code, and the third is
recorded below as still open by decision.

### Carried over, deliberately open

- **P09-TEST-8 (major)** — a non-`ArgumentError` save failure still reaches the
  parent verbatim: `QuestsBloc._editorError` maps only `ArgumentError`, so any
  other error becomes `error.toString()`. Iteration 5 measured the raw
  `SqliteException(1555): … UNIQUE constraint failed: quests.id …` in a toast.
  Stage 2 left it open with sound reasoning (`2_build.md` §1): mapping
  everything unknown to generic copy would break the offline/disk-full
  passthrough that `quest_editor_states_test.dart` pins, and mapping one more
  concrete Drift type is whack-a-mole; it needs orchestrator copy plus a
  cross-stage test change. The one *reachable* producer of a raw-SQL toast was
  the id collision, which died with BUG-P09-14. **Still a real leak for a
  storage failure**, so it stays on the books — but it is not a P09-local
  decision and this stage's tests neither pin nor contradict it.

### Observations (not findings)

- **An intermittent failure in another feature's suite.** One full-suite run
  reported `+3126 ~2 -4`, all four in
  `test/features/family/child_profile_copy_test.dart` (P15's file, "quest
  counting against the real database"). That file passes in isolation (21/21,
  and the whole `test/features/family` directory passes at 283/283), and two
  subsequent full-suite runs of the same tree were green
  (`+3129 ~2: All tests passed!` twice). It is an order/parallelism-dependent
  flake in another feature's tests, not something this screen's diff can cause
  (my changes are additive test cases in `test/features/quests/**`), and not
  reproducible on demand. Flagged for visibility so the orchestrator does not
  read a red gate as a P09 regression if it sees one.
- **Still deliberately untested:** `buildWhen` (review 7) and the
  `ValueListenableBuilder` (review 4) — performance properties with no
  observable contract.
- **Still-unreachable observation:** `QuestEditorView.didChangeDependencies`
  fetches `?id=` once, so `/quest-editor?id=a` → `?id=b` on the same `State`
  would keep showing `a`. Every in-app path pushes a new page.
- Optional DS note 2b raised (a `NestToggle` variant that insets its track
  inside its own 59×44 box would delete the whole `Positioned`-compensation
  class from every screen) is untouched by this stage and not mine.

## 5. Handover

- This feature's suite is green and, for the first time in six iterations,
  carries **zero** parked proofs. Two of the three iteration-5 findings are
  closed at the source with a regression guard; the third (P09-TEST-8) needs
  orchestrator copy, not a screen fix.
- The two fragile shapes from this iteration are now guarded at 320/390 ×
  scale 1.0/1.3, so a future change to the approval card has a contract to
  break rather than a screenshot to eyeball.
- Every widget test ends with `disposeApp(tester)`, and every semantics handle
  is disposed **inside** the test body.

VERDICT: PASS
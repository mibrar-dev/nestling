# Fix list after iteration 4

## From 3_test.md
# P16 Settings — Stage 3 TEST (iteration 4)

Job: re-prove the screen after iteration 4's build, serve the three new
mandatory `ORCHESTRATOR_NOTES` items (08:12 "LAST pass") from the test side,
and audit the fixes this build landed.

**Outcome: FAIL — all gates green, both of iteration 3's findings are closed
and proved, and I found one new (minor) defect that iteration 4's own fix
introduced. P16-B09 also remains open, and two of the three mandatory items
are still unmet — one of them unsatisfiable as written.**

Numbers: **+3 tests** (137 in `test/features/settings`, 2 of them skip-marked
proofs), **0 new failures**, **1 new minor bug (P16-T03)**, **2 findings closed
and proved**.

---

## 1. What iteration 4 changed

| change | where | test consequence |
|---|---|---|
| **P16-B11 fixed** — switch wrapper `SizedBox(width: 51, height: 44, …)` | `settings_view.dart:296-303` and twice more | my widened B11 proof un-skipped; the T02 proof had to survive the change |
| **P16-B10 fixed** — the delete row and the Invite row now route through `P16TransientGuard.run` | `settings_view.dart:185`, `:377` | covered by the bug stage's proofs |
| `P16TransientGuard.reset()` added to the raw-pump helper in `settings_view_test.dart` | `settings_view_test.dart` | harness gap the integrator caught; nothing for me to add |
| B09 still not fixed (shared) | — | unchanged, skip-marked |
| **`ORCHESTRATOR_NOTES` (08:12) — three new mandatory items** | `ORCHESTRATOR_NOTES.md` | see §4; one is unsatisfiable as written, two are open |

Baseline at the start of this stage: `test/features/settings` `+134 ~1`, full
suite `+2852 ~2`. Now: **+137 ~2** and **+3028 ~4**.

## 2. Tests added (3) and how the fixes were proved

### 2.1 `[P16-T03]` — the new minor defect iteration 4 introduced (skip-marked)

The B11 fix pinned the switch wrapper to **`width: 51`** — exactly the track
width. `NestToggle` promises a **59 × 44** hit box
(`_ToggleHitSlop(minWidth: 59, minHeight: 44)`, mirroring the design's
`.toggle::before { left/right: -4px; top/bottom: -7px }`), so a 51-wide wrapper
clips the horizontal half of the slop:

| | wrapper | track | slop available |
|---|---|---|---|
| vertical | 122.0–166.0 (**44**) | 128.5–159.5 (31) | 6.5 px above/below ✓ |
| horizontal | 303.0–354.0 (**51**) | 303.0–354.0 (51) | **0 px** of the 4 px ✗ |

Measured: a tap 4 px left of the track's left edge (x 299) and 4 px right of its
right edge (x 358) **do not flip the switch**; the track centre and both
vertical ±5 px probes do.

**Severity is deliberately minor, and the proof says why:** the owner rule
(≥ 44 px parent target) is still met — the effective target is 51 × 44 — and
P16-T02's vertical proof still passes. What is lost is the shared component's
4 px of horizontal forgiveness, which `ORCHESTRATOR_NOTES` (08:12) item 1 asks
for by name ("using the shared NestToggle as-is"; item 2: "prove taps 4 px
outside the track toggle it"). Fix is one line and keeps B11: make the wrapper
the slop's width and right-align it —
`SizedBox(width: 59, height: 44, child: Align(alignment: Alignment.centerRight, child: toggle))`
— so the track stays flush at x 354 while the 4 px has room (the row's 12 px
left padding keeps it inside the content box).

Beside it, a **live** companion test holds the part that does hold: the
effective target clears 44 px in *both* axes, so no future wrapper change can
quietly shrink it.

### 2.2 DATA OVER MOCKS — the parent's e-mail (mandate item 2), 2 tests

The ruling says the parent's e-mail must come from the database and asserts
"the seed holds that value". **It does not** — the integrator measured that no
table in the schema has an e-mail column (`auth_repository_impl.dart:38`
documents the omission), and my own probe agreed. The ruling's own fallback
("if the DB lacks a field, write SHARED_REQUEST.md") is what applies, and
`SHARED_REQUEST.md` §4 already carries it.

What the test stage can do without patching the screen is make the gap
**impossible to ignore**:

- **`TRIPWIRE: `members` still has no e-mail column`** — reads the live schema
  (`PRAGMA table_info(members)`) and fails the moment a column appears, with a
  message that says what to do then (read `members.email` for the owner row and
  update the four tests that assert the literal). It also pins that the rest of
  the owner row stays database-driven (`id`, `family_id`, `name`, `role`,
  `invite_status`). Writing it made me check the real column names — they are
  snake_case in SQL, which the first draft of my assertion got wrong.
- **the owner row follows the seeded NAME** — rename Sarah to Sam in the
  database and the row reads `Sam — you`, i.e. the part DATA OVER MOCKS covers
  is genuinely live, while the subtitle beside it is the documented exception.

I did **not** weaken the four tests that assert `sarah@example.co.uk`: they
describe the screen as built, and they are the tests that have to change when
§4 lands.

## 3. Existing tests hardened (3)

1. **The T02 proof is now shell-agnostic.** It used to assert
   `find.byType(SettingsRow)`, its exact 6 px padding and a
   `SizedBox(height: 44)` — i.e. the *fork*. `ORCHESTRATOR_NOTES` (08:12) item
   3 orders that fork reverted to the shared `NestListRow`, and a proof that
   names the fork would fail on the revert with "no SettingsRow in the tree"
   instead of reporting the truth. It now asserts the **owner rule as
   geometry**: the switch's painted content box (the nearest `Padding` ancestor
   — the same element in both shells) is ≥ 44 tall, the track is 51 × 31, and
   taps ±5 px outside it flip the database row. The ±5 px taps are the part
   that cannot be faked.
2. **The stale T02 comment is rewritten** (I carried that wording since
   iteration 1).
3. **The subcard tests stay copy-addressed** (`subscriptionCard()`), so
   mandate item 3's subcard revert fails with a design message (24 px radius,
   16 px padding) rather than a missing-key error.

## 4. The three mandatory items — what the test side can say

The integrator measured these; I add the test-side consequences, because two
of them change what a suite is allowed to assert.

**Item 1 (B11 ✓, B09 open, B10 ✓, un-skip all four).** Three of four proofs are
live and green. B09 is unsatisfiable in the feature (shared
`isKnownZoneId` against a links-less tz dataset; the raw id never reaches the
bloc) — `SHARED_REQUEST.md` §5. B11's proof is now live in my responsive file
too, widened to 320/390/430 × light/dark.

**Item 2 (parent e-mail from the DB).** Unsatisfiable as written; §4 filed;
tripwire + name-follows-seed tests above. **Four tests assert the literal** and
must be updated together when §4 lands — my own included
(`settings_states_test.dart`, `settings_view_test.dart`, and the a11y control
list).

**Item 3 (un-fork `_P16Sect`, the subcard, `SettingsRow`).** I measured what
each revert costs, without patching the screen, by rendering the shared
components in the same harness:

| fork → shared | measured difference | effect on this suite |
|---|---|---|
| `_P16Sect` → `NestSectionLabel` | identical typography — 13 px, w700, `letter-spacing .78`, `ink-2`, `maxLines 1` — only the **line box** differs: **18 px vs 16 px** at scale 1.0 (23 vs 21 at 1.3) | **no assertion of mine breaks**: the typography test passes unchanged and the "box scales ×1.3" check is relative, so it holds for both |
| subcard → `NestCard` | radius **24 vs design 16**; padding **all(16) vs design 14/16**; same `surface` colour and `sh-1` | exactly **two** assertions fail, by design, with a legible message |
| `SettingsRow` → `NestListRow` (switch rows) | the ±5 px taps **still land** (the 44-high wrapper inside the shared row's 10 px padding is enough) — but the row **grows 56 → 64 px**, because 44 + 20 exceeds the 56 px min-height | the T02 proof still passes; **new vertical drift**: +8 px on each of three rows, ≈ +24 px down the page |

That last row is the finding I would most want the orchestrator to see: **item
3's un-fork of `SettingsRow` is not free** — it does not re-open the 44 px
target (good), but it re-introduces the *same class of vertical drift* that
`SHARED_REQUEST.md` §1/§2 exist to close, this time +8 px × 3 rows. So the
sequencing still matters: §1 should also ask that the row not grow, and the
reverts follow the shared batch, not precede it.

## 5. Results

```
$ dart format .
Formatted 537 files (0 changed) in 1.55 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 2.9s)

$ flutter test test/features/settings
00:13 +137 ~2: All tests passed!

$ flutter test
01:48 +3028 ~4: All tests passed!
```

Zero failures. The full suite's `~4` is two P16 skips (B09 and T03), K01's
`k01_bugs_test.dart` skip (arrived from `Merge screen/K01`) and P12's
pre-existing one.

**Skip honesty.** `flutter test test/features/settings --run-skipped` fails on
exactly the two open P16 proofs and nothing else:

```
p16_bugs_test.dart        [P16-B09] the picker shows the device zone for a linked IANA id
settings_a11y_test.dart   [P16-T03] a switch is live 4 px to the LEFT and RIGHT of its track
```

## 6. Bugs

### Closed and proved — P16-B11 (major, ALIGNMENT) — iteration 3, mine + bug stage

Track at **x 303–354** at 390 px, flush with the row's 16 px trailing inset
(`370 − 16 = 354`), at 320/390/430 in both themes; my widened proof is live
(`skip: false`) and green. P16-T02's vertical proof survived the wrapper
change — both findings are now pinned on one layout.

### Closed and proved — P16-B10 (minor) — bug stage

Delete and Invite rows fenced like every other row; proofs live.

### Closed in earlier iterations, still green
P16-T01 (blocker, wrong navigator), P16-B08 (modal-close double tap),
P16-B01…B06 (iteration 1), P16-T02 (iteration 3).

### Open — P16-T03 (minor, new) — mine

`app/lib/features/settings/presentation/views/settings_view.dart:298`, `:316`,
`:334` — the three `SizedBox(width: 51, height: 44, Center(NestToggle(…)))`
wrappers. The horizontal 4 px of `NestToggle`'s hit slop is clipped; taps 4 px
either side of the track do nothing. Owner rule still met (51 × 44), so minor.
Repro: real app at `/settings`, Notifications, tap 4 px left of the switch's
left edge → nothing; the track itself flips.
Proof: `flutter test test/features/settings --run-skipped`.

### Open — P16-B09 (minor, shared) — bug stage
Linked IANA ids read as unknown; `SHARED_REQUEST.md` §5.

### Mandatory items still unmet
`ORCHESTRATOR_NOTES` (08:12) items 2 and 3 — §4 above. Item 2's premise is
false; item 3 is a build decision with the drift numbers in §4.

## 7. Observations (not bugs)

Unchanged from earlier iterations: the Family list's two static rows merge into
the Invite button's announcement (shared `NestListRow`); the shared
`Semantics(label:) > InkWell` wart, blast radius pinned; `.ptitle` declares no
`text-wrap: balance`, so the plain `Text` is correct by the CSS; `_P16Sect`'s
per-build `TextPainter` (accepted); the dialog Cancel wrapping at 320 × 1.3
(shared `NestButton` padding).

New this iteration: **a fenced tap still ripples but does nothing** — inside
the 300 ms guard window the user gets no feedback either way. Defensible at
300 ms; if the window is ever widened it becomes a silent dead tap.

## 8. Harness notes

- **A widget's nearest `Padding` ancestor is the row's content box** in both
  `SettingsRow` and `NestListRow`, which makes it the one shell-agnostic place
  to measure "is there room for the slop". My first attempt measured the
  toggle's *descendant* padding (the knob's, 27 px) instead.
- **`PRAGMA table_info(<table>)` through `customSelect` is the live schema**,
  and SQL column names are snake_case while drift's are camelCase.
- **`const MembersCompanion(name: Value('Sam'))`** — the plain constructor
  takes `Value<String>`; `const` needs the `Value` inside.
- Unchanged from iterations 1–3: Drift streams need `settleSettings`
  (`runAsync`); `bloc.close()` must be `unawaited` in a widget test;
  `scrollUntilVisible` walks down only (`scrollSettingsUpTo` walks up);
  a semantics-tree walk misses un-passed nodes (`getSemantics` does not);
  `testWidgets(skip: …)` takes a bool; never settle before asserting a
  time-windowed guard.

---


## From 4_review.md
# P16 Settings — QA code review (iteration 4)

Reviewed `git diff main...HEAD` and the iteration 3→4 delta
(`git diff 7160fff...HEAD`) against `docs/ARCHITECTURE.md`,
`docs/screens/RULES.md`, the design system in
`app/lib/core/design_system/`, `docs/DESIGN_SPEC.md` §5 P16,
`docs/screens/P16/ORCHESTRATOR_NOTES.md` (incl. the 08:12 update), and
the HTML source.

## Iteration-3 finding disposition

1. **Literal sizes/typography — STILL OPEN (minor, carried).**
   `settings_view.dart:235` (`SizedBox(2)`), `:252` (`height: 52`),
   `:528`/`:588` (`fromLTRB(14, 12, 14, 12)`), `:541`/`:601`
   (`fontSize: 14` overrides) all remain.
2. **`_P16Sect` — STILL PRESENT (promoted to major, finding 1).**
3. **Legacy `SettingsItem`/`watchItems()`/`getItems()` — STILL PRESENT
   (minor, carried).** `settings_repository.dart:9-10`, impl, two test
   doubles; no bloc consumer.
4. **Stale docs — PARTIALLY FIXED (minor, carried).**
   `p16_bugs_test.dart` header was rewritten for B10/B11, but the B10
   block comment (`// P16-B10 open (minor) — ...`), the B11 block in
   `p16_bugs_test.dart`, and the `settings_responsive_test.dart` B11
   comment still describe live, unskipped proofs as "open / pinned
   skip-marked".
5. **NestToggle tap-target + fork reversion — see below.**

## Findings this iteration

1. **major** — ORCHESTRATOR_NOTES 08:12 item 3 is not honored. The
   screen still forks three shared components:
   - `_P16Sect` (`settings_view.dart:69`) replaces `NestSectionLabel`.
   - The subscription card is a local `Container(key: p16_subcard, …)`
     (`settings_view.dart:215-219`) instead of `NestCard`.
   - The toggle rows, delete row, member rows and child rows use the
     local `SettingsRow` fork (`settings_view.dart:290, 313, 333, 373,
     475, 497`) instead of the shared `NestListRow`.
   The note is explicit: record the measured delta in SHARED_REQUEST.md
   and keep the shared widget. The forks are also UI debt that the next
   design-system change silently diverges from.
   Fix: revert to `NestSectionLabel`, `NestCard`, `NestListRow`; where a
   design metric genuinely differs, add the measurement to
   `SHARED_REQUEST.md` and wait for main.

2. **minor** — B11 is fixed in code but the docs/tests still call it
   open. The delta adds `width: 51` to the toggle wrapper
   (`settings_view.dart:298,316,337`), and the B11 proofs
   (`p16_bugs_test.dart` B11, `settings_responsive_test.dart` B11) are
   `skip: false`. Their comments, however, still say
   "OPEN BUG — pinned skip-marked ... run with --run-skipped".
   Fix: update the two comments to record B11 as fixed with the
   wrapper change.

3. **minor** — The iteration-4 delta's B10 fix is in but its own stale
   header remains: `p16_bugs_test.dart` B10 comment reads "P16-B10 open
   (minor) — ... Fix: wrap both row handlers ..." while `skip: false`
   and the code now wraps the handlers. Same stale-comment pattern as
   finding 2.

4. **minor** — P16-B09 still `skip: true`
   (`p16_bugs_test.dart:530`). The note at 08:12 asks to un-skip all
   four proofs, but the root cause (`latest_10y` dataset drops linked
   IANA ids; `isKnownZoneId`) is core shared code on main —
   SHARED_REQUEST §5 already records it and there is no feature-side
   workaround. Escalate to the orchestrator to land §5, then un-skip.

5. **minor (carried)** — Owner row still renders the literal
   `sarah@example.co.uk` (`settings_view.dart:468`). SHARED_REQUEST #4
   asks for `members.email`; 08:12 item 2 accepts that as the path.
   Once the column lands, the row should read it (TODO(P16) tracking).

6. **minor** — `P16TransientGuard` remains process-wide static state
   (no ownership of its lifetime outside this route). Every row now goes
   through it, so it works, but cross-screen reuse is still blocked by
   its design; tracked here for a future shared variant.

## Verified clean this iteration

- B10 fix present: the invite toast row (`:185`) and delete row (`:377`)
  now route through `P16TransientGuard.run` like every other row.
- T02 target is 51×31 track inside a 44 px wrapper; the a11y proof
  asserts a 56 px row, 6 px padding and 44 px hit box and is unskipped.
- `p16_transient_guard_test.dart` (new) pins the 300 ms window, the
  cross-test reset, and that the banner buttons are deliberately NOT
  fenced.
- No path edits outside `app/lib/features/settings/**`,
  `app/test/features/settings/**` and `docs/screens/P16/**` in the
  iteration-4 delta, except the earlier `dart format` nits on the
  shared `list_row_trailing_test.dart`; no app/lib/core or app/lib/app
  changes.
- CLOCK rule still holds (`appNowUtc()` only); no analytics/ads;
  parent-only route; architecture layering unchanged.


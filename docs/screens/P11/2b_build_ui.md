# P11 · Approvals — Stage 2b build UI (iteration 2)

Scope: `app/lib/features/approvals/presentation/views/**` +
`presentation/widgets/**` and the feature's `*view*` / `*widget*` tests. The
logic builder owns domain/data/bloc — re-read `2a_build_logic.md` before
finishing: **CONTRACT CHANGES: none** (events/states are still plan §2;
`Approval.kidNote` was added on their side and is the only new field consumed
here). Parallel-work note: the logic builder was also editing
`p11_bugs_test.dart` and, briefly, `approvals_view_geometry_test.dart` in the
same worktree; the final content of both was merged, not clobbered.

## Mandates closed

`ORCHESTRATOR_NOTES.md` items 1, 3, 4 and `FIXES_1.md` items BUG-P11-3 /
BUG-P11-4 — all implemented, all pinned by tests.

| item | status |
|---|---|
| 1 · child quotes from `quest_completions.kid_note` | **done** — rendered, with the curly quotes |
| 2 · pending set from the DB | unchanged (DATA OVER MOCKS) |
| 3 · "Approve all (N)" pill 8 px low | **done** — 734–786 / centre 760, surface still to the edge |
| 4 · card geometry with AND without a quote | **done** — 172 / 138 pinned, both in real fonts |
| BUG-P11-3 · BST day labels | **done** — calendar maths moved to `DateTime.utc` |
| BUG-P11-4 · both pills spun | **done** — only the pressed pill spins |
| BUG-P11-1 / BUG-P11-2 (data layer) | not mine — logic builder's CAS; their 9 bug proofs are now un-skipped and green |

## What I changed (`lib/`)

1. **`widgets/approval_card.dart`**
   * **`.qn` quote line** — `Padding(top: 10)` + `Text('“$kidNote”')` between
     `.hd` and the 14 px button row, `NestType.bodyStrong(ink).copyWith(
     fontSize: 17, height: 24/17)`. A NULL (or whitespace-only) note renders
     **no line and no gap** — card stays 138.
   * **`.qn` is Inter, measured, not assumed.** The CSS sets no
     `font-family` on `.qn`, so it inherits `--font-ui`. Checked against the
     PNG by ink extent: the design's quote ink is x 37.33→284.00 = **246.7 px**
     and Inter w700 @17 advances **249.2** (≈247 ink); Nunito @17 advances
     **232.4** — 14 px short. The same method validates on `.who`: design ink
     228.33 vs Inter w700 @16 = 229.99. (The bug stage's note guessed Nunito;
     the measurement does not support it. Both facts are recorded in the file
     header so nobody re-opens it by eye.)
   * **Alignment detail worth keeping** — `.qn` is a *sibling* of `.hd` in the
     HTML, so it starts at the card's padding edge **x 36**, level with the
     avatar, NOT indented under `.who` (x 90). The PNG agrees (ink starts
     37.3). Pinned in `approval_card_widget_test.dart`.
   * **Per-button busy (BUG-P11-4)** — `ApprovalCard` is now a `StatefulWidget`
     holding `ApprovalDecision? _pending`, set by `_press()` before dispatching.
     `loading: busy && _pending == <that button>`; both buttons stay
     `onPressed: null` while busy (the double-write guard is unchanged). No
     contract change: the bloc still only publishes `busyIds`.
2. **`widgets/approvals_bottom_cta.dart` (NEW)** — P11-private `.bottom-cta`.
   Visually identical to the shared `NestBottomCta` (surface fill, 1 px `line`
   top border, 20 px gutters, 16 px above the pill) but lifts its content by
   `MediaQuery.padding.bottom + 24`, so the pill lands on the design's rects
   while the surface still runs to the physical edge (OWNER bottom-edge rule).
   Screens cannot edit `core/`, so this is a stopgap; `SHARED_REQUEST.md` §3 now
   carries the before/after numbers and the `SafeArea` `max(inset, minimum)`
   trap that makes the obvious fix (`minimum: 24`) a no-op.
3. **`views/approvals_view.dart`** — uses `ApprovalsBottomCta`. Nothing else
   moved: title, nav, body, empty/loading/failure/error paths are unchanged.
4. **`widgets/approval_time.dart` (BUG-P11-3)** — `approvalDayLabel` now builds
   the two calendar dates with `DateTime.utc(y, m, d)`. `DateTime(y, m, d)` is
   LOCAL midnight, so on a Europe/London host the 29→30 Mar 2026 span is 23 h
   and `inDays` truncates it to 0 ("Yesterday" rendered as "Today"); UTC date
   fields carry no offset, so the difference is whole days in every host zone.

## Measured anchors — design vs app (logical px, 390×844, real fonts)

Design numbers are from the PNG by row/column profile; app numbers from
`approvals_view_geometry_test.dart` (±2 px asserted) with Inter/Nunito loaded
via `FontLoader`.

| element | design | app | Δ |
|---|---|---|---|
| status-bar reserve / compact nav | 0–47 / 47–107 | 0–47 / 47–107 | 0 |
| nav title box (18/24 w800, centred) | centred, 24 high | 61–85 | 0 |
| helper banner | 107–171 (2 lines × 20) | 107–171 | 0 |
| card 1 `Maya · Empty the dishwasher` (note) | top 187, h 172 | 187, 172 | 0 |
| card 2 `Maya · Lay the table` (NULL note) | — (mock has a quote) | top 375, h 138 | design box model ✓ |
| card 3 `Leo · Make your bed` (note) | 563 for the mock row | top 529, h 172 | DATA OVER MOCKS (mock row is "Tidy your bedroom") |
| `.qn` line box | x 37.3 ink, 10 px under `.hd`, 24 high | x 36, top+70, h 24 | 0 |
| `.row` pills | 48 high, gap 10, card+108 (quoted) / +74 (bare) | same | 0 |
| card gutters | 20 / 370 | 20 / 370 | 0 |
| CTA panel top (34 px inset) | 717 (line pixel at 717) | 717 | 0 |
| CTA pill (34 px inset) | 20–370, **734–786**, centre **760** | 734–786, centre 760 | **0** (was +8) |
| CTA pill (zero inset, test surface) | — | 768–820, 24 above the edge | per orchestrator ruling |
| bottom edge | design: paper strip below 810 | surface to 844 | OWNER override |

**No uniform vertical shift**: every anchor is exact, in both themes.

## Tests (mine / co-owned in this stage)

- `approvals_view_geometry_test.dart` — now 9 tests: card tops/heights
  187·172 / 375·138 / 529·172, quote at `card.top + 70`, quoted row at +108,
  bare row at +74, CTA at 24 above the edge and **734–786 at a simulated 34 px
  home inset** (`FakeViewPadding(bottom: 34 * 3)` — `view.padding` is in
  PHYSICAL pixels; `34` would land the pill 23 px low, which is exactly what
  happened before this fix).
- `approval_card_widget_test.dart` — +2 tests: quote copy/style/x/height and the
  NULL-or-blank case (138, row at +74). The file now loads the bundled faces:
  without them the fallback font wraps the quote to two lines and the card
  measures 220 instead of 172.
- `approvals_view_test.dart`, `approvals_view_states_test.dart` — updated for
  `ApprovalsBottomCta`; `approvals_view_states_test.dart` now also loads the
  real faces. That one was a genuine trap: with the fallback font the banner
  grows to 3 lines and both quotes wrap, the stack slides ~92 px and the LAST
  card's button row ends up *behind* the CTA — `tester.tap` then silently hits
  the panel and the "Not yet"/"two busy cards" write tests fail for a reason
  that has nothing to do with the screen.
- `p11_bugs_test.dart` — the three `skip: true` markers for BUG-P11-3 and
  BUG-P11-4 are gone. `flutter test test/features/approvals/p11_bugs_test.dart`
  → **9/9 pass**, none skipped.

## Verification

```
$ dart format --output=none --set-exit-if-changed lib/features/approvals test/features/approvals
Formatted 24 files (0 changed)
$ flutter analyze lib/features/approvals test/features/approvals
No issues found! (ran in 3.5s)
$ flutter test test/features/approvals
00:05 +131: All tests passed!          # 0 skipped (was 126 + 3 + 2 skipped)
```

Whole-app `flutter test` and the simulator were left to the integrator /
stage 5 per the stage rules — **no simulator was booted, installed on,
screenshotted or driven.**

## LEFT FOR NEXT ITERATION

- Stage 5 (`5_ui`): screenshots for `/approvals` in light + dark on
  `E7D5555E-378A-49DF-AAEE-16677AF4B9DB` + `compare.py`. Expected positions are
  the table above; the only intentional deltas from the PNG are (a) the seeded
  third card is the real `Leo · Make your bed` at 529, not the mock "Tidy your
  bedroom" at 563, and (b) card 2 has no quote because its note is NULL.
- Shared `NestBottomCta` still sits 8 px low for every other screen — the
  request stays open in `SHARED_REQUEST.md` §3.
- P11 can drop `ApprovalsBottomCta` for the shared component once it adopts the
  24 px bottom pad (one import + one class name).

VERDICT: PASS
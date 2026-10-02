# P02 Value tour — adversarial bug hunt (Stage 6, iteration 3)

Route `/value-tour`, feature `onboarding`, parent mode, seed `demo`, test
clock pinned to Sat 3 Oct 2026. `ORCHESTRATOR_NOTES.md` exists and is
mandatory; the iteration-3 build fixed BUG-7/8/9 (design copy, typographic
punctuation, full titles), retired the private tour bar for the shared
`NestNavBar(compact: true)` and adopted the `NestPager` tokens. Stage 5 UI
passes at 390×844; Stage 4 review leaves one MAJOR (finding 1) — independently
reproduced here as **P02-BUG-10**.

Proofs live in `app/test/features/onboarding/p02_bugs_test.dart`: the fixed
bugs are un-skipped regressions (10 passing), the one open item is marked
`skip: true` so `flutter test` stays green. No screen code was changed by this
stage (tests + `docs/screens/P02/**` only).

| Id | Severity | Status | Failing tests |
|---|---|---|---|
| P02-BUG-10 | MAJOR | OPEN | `P02-BUG-10a`, `10b`, `10c` |
| P02-BUG-1,2,3,6,7,8,9 | — | FIXED, proofs pass | `P02-BUG-1a/b/c`, `2`, `3a/b`, `6`, `8a/b`, `9` |
| P02-BUG-4/5 | — | VOID | reversed by ORCHESTRATOR_NOTES 1 → replaced by BUG-8 |

---

## P02-BUG-10 — MAJOR — Preview titles shrink far below the 15dp type size instead of wrapping

**Where:** `ValueTourPreviewRow` title slot —
`FittedBox(fit: BoxFit.scaleDown)` around the title
(`value_tour_preview_row.dart:83-101`; review iteration 3, finding 1).

**Repro / evidence**

- The FittedBox lays its child out **unbounded** and then scales it to the
  slot with no lower bound (`applyBoxFit(scaleDown, child, slot) = min(1,
  slotW/childW, slotH/childH)`), so the title's effective type size is
  `15dp × scale` — any slot/natural ratio, however small, is accepted.
- Review iteration 3 finding 1, measured with the device's real Inter:
  **320dp → scale ≈ 0.60 → ~9px**; **320dp × 1.3 → scale ≈ 0.43 → ~6.5px**
  (natural ≈ 212dp vs a ~92dp slot). At 390 × 1.3 the same path silently
  cancels the user's 1.3× request for the long titles.
- This stage's effective-scale proofs (widget-test font, unbounded paragraph
  vs FittedBox slot) reproduce the unbounded behaviour: **0.27 at 320×1.0,
  0.19 at 320×1.3, 0.37 at 390×1.3** (`P02-BUG-10a/b/c`).
- Violates DESIGN_SPEC §0 rule 9 (parent body text ≥ 15dp), rule 4 ("long
  text wraps or truncates with ellipsis") and the second half of
  ORCHESTRATOR_NOTES 3 ("320 width + text scale 1.3 wraps rather than
  ellipsises where the design has room").

**Failing tests**

- `P02-BUG-10a preview titles do not paint below 0.9x at 320dp x 1.0`
- `P02-BUG-10b preview titles do not paint below 0.9x at 320dp x 1.3`
- `P02-BUG-10c preview titles do not paint below 0.9x at 390dp x 1.3`

(each asserts the effective scale of all four titles ≥ 0.9; measured from
`slot / unbounded-paragraph width`, and 1.0 when no FittedBox wraps the
title, i.e. when it wraps/ellipsises at full size).

**Suggested fix:** bound the shrink. Keep the fit-to-slot path only while
`slot / natural ≥ ~0.92` (measure natural with a `TextPainter`/`LayoutBuilder`
using the same 15/20 w600 style); below that, let the title wrap
(`maxLines: 2`, `softWrap: true`) or ellipsise at the full 15dp. The row
height already uses `max(36, …)`, and the pager has vertical room at 1.3
(520dp), so wrapping costs nothing at 390. Keep 390×1.0 one line (device
scale ≈ 1.0 — verified by the UI stage).

**Interplay to watch when fixing:** if the fix wraps in the widget-test
fallback font at 390×1.0 (where natural ≫ slot), the `P02-BUG-2` row-height
proof (rows ≤ 40dp) may need a font-robust restatement (tile 36dp, gaps 8dp,
no vertical padding) — adapt the proof, never keep the shrink.

## Test-integrity fix made by this stage (review finding 2)

The former `P02-BUG-7` proof asserted
`paragraph.getMaxIntrinsicWidth(...) ≤ paragraph.size.width` — vacuous under
`FittedBox`, whose child is laid out unbounded, so `size.width` *is* the
intrinsic width. It has been **removed** and replaced by the `P02-BUG-10`
effective-scale proofs above. The 390dp "one line, no ellipsis" requirement
is verified on the device shot by the UI stage (title ink 81.0→244.0, pill at
254, no U+2026).

The same vacuous pattern remains in `value_tour_view_test.dart:1336-1348`
("no preview title is truncated at 320dp × text scale 1.3") — it asserts
`didExceedMaxLines == false` on the unconstrained single-line paragraph and
can never fail; it must be replaced by the scale assertion when BUG-10 is
fixed (already in the review's fix list).

---

## Fixed in iteration 3 — re-verified by the un-skipped proofs

- **P02-BUG-1/2/3** — pager 400dp (card y107→507 exact), 38dp preview rows,
  unified scroll on 320×568 / 375×667×1.3 (no exceptions, copy reachable,
  horizontal paging intact).
- **P02-BUG-6** — system back (in-flow and deep link) lands `/welcome`.
- **P02-BUG-7** — at 390dp all four titles render in full on one line
  (device ink 81.0→244.0; see the BUG-10 caveat for other widths).
- **P02-BUG-8** — design static copy restored: `Maya · weekly`, `Leo · once`,
  `Maya · daily`, `Maya · weekly`; chips `Sat 4 Oct` (proofs read the
  rendered rows/chips).
- **P02-BUG-9** — character-exact punctuation: `Today’s quests`,
  `Pip’s nest`, `Maya’s jar`, `“Put the bins out” — or make your own.`
- Shared-nav swap and `NestPager` tokens introduced no regressions: Skip is a
  single semantics node (`label 'Skip'`, `isButton`, tap action) at 89×44 with
  its right edge on the 20dp gutter (x=370), card geometry unchanged, no new
  exceptions.

## Checked — no new bug

- **320 / 430 / 1.3 matrices:** no RenderFlex overflow or exceptions at any
  probed surface; only the BUG-10 scaling is wrong.
- **Rapid taps / back / deep links / kid guard / dark tokens / money /
  timezone / async / a11y labels:** unchanged from iteration 2 (clean);
  the new shared bar keeps a single labelled, tappable Skip node.
- **External, not a screen finding:** `test/app/router_push_test.dart` still
  asserts the placeholder literal `'P02 Value tour'` (main-only), so the full
  suite is 611 passed + 3 skipped + 1 failed. `test/app/` is outside RULES §1;
  already filed as `SHARED_REQUEST.md` item 4 and owned by the orchestrator.

## Carry-over minors from the Stage 4 review (in the review's fix list)

1. Chip's 1.5dp border inflates the head row by +3 (tile y173 vs design 170)
   and forces `gap9` instead of the spec `gap10` on card 2 — needs a shared
   chip border-box request.
2. `ValueTourPreviewRow`'s doc comment still promises retirement in favour of
   the withdrawn shared-row request; the `NestTileTint` → colours switch is
   duplicated from `NestListRow`.
3. Card 2's caption is pinned to `maxLines: 1` (ellipsises below ~350dp)
   instead of the same wrap rule as BUG-10.
4. `_headChip`/`_dateChipLabel` live on `_ValueTourViewState` and are called
   from sibling widgets; move to file-private helpers.
5. `PopScope(canPop: false)` also intercepts a cold deep-link back and lands
   on `/welcome` (accepted in `2_build.md`; confirm intended).

## Verification (run this stage, `app/`)

- `flutter test test/features/onboarding/p02_bugs_test.dart` —
  **10 passed, 3 skipped, 0 failed**.
- `flutter test --run-skipped …/p02_bugs_test.dart` — `P02-BUG-10a/b/c` fail
  with measured scales **0.27 / 0.19 / 0.37** (< 0.9).
- `flutter test test/features/onboarding` — **134 passed, 3 skipped**.
- `flutter test` (full) — **611 passed, 3 skipped, 1 failed** (external
  `test/app/router_push_test.dart`, orchestrator-owned).
- `flutter analyze` — `No issues found!`; `dart format` clean.
- No screen code touched; only `p02_bugs_test.dart` and this file.

VERDICT: FAIL

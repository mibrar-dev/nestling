# P17 Parental gate — 2b build UI (iteration 3)

Scope: `app/lib/features/parental_gate/presentation/views/**`,
`presentation/widgets/**`, and the widget/view-side tests in
`app/test/features/parental_gate/` (`…view_test.dart`, the geometry/states
pinned layouts, `p17_bugs_test.dart`). No bloc/domain/data edits, no
DI/route edits, no simulator, no `flutter clean`.

Contract re-read: `2a_build_logic.md` says **CONTRACT CHANGES: none** — the
three events, all state fields and the London-day `challengeFor` are unchanged,
so nothing in this layer had to be re-cut.

Inputs: `ORCHESTRATOR_NOTES.md` (items 1–7 + the 07:13 keypad note),
`FIXES_2.md` (§3.1/§3.2/§3.3 + the 5_ui deviations), `6_bugs.md`, `4_review.md`,
`1_plan.md`, the design PNG (re-read this iteration) and the HTML source.

## The headline: the whole screen is now pinned to the design

`main` carries `9cac0c6 Merge shared/keypad_grid`, and this worktree is merged
with it (`e70760c`). The shared `NestKeypad` now *is* the CSS `.keypad`
(`repeat(3,1fr)` `Expanded` cells, row gap 10, `padding: 8 24 0`,
`NestKeypadFit.stretch` default + a `shrinkWrap` mode). Per ORCHESTRATOR_NOTES
07:13 I did **not** re-space anything locally — I only had to make the call site
compatible and re-check the pins.

`parental_gate_geometry_test.dart` — **11/11 green** (was 7/11 in iteration 2),
all against the design PNG with the bundled Inter/Nunito loaded through
`FontLoader`, so the numbers are device-faithful:

| Band (390×844, light, textScale 1.0) | Design | App | Δ |
|---|---|---|---|
| card top / left / width | 66 / 24 / 342 | 66 / 24 / 342 | 0 |
| card bottom / height | 778 / 712 | 778 / 712 | 0 |
| lock tile | 90…142 | 90…142 | 0 |
| title “Grown-ups only” centre | 168 | 168 | 0 |
| instruction centre | 201 | 201 | 0 |
| question centre | 228 | 228 | 0 |
| answer boxes centre (56×64) | 288 | 288 | 0 |
| keypad slot top | 336 | 336 | 0 |
| keypad row centres | 380 / 462 / 544 / 626 | same | 0 |
| keypad row pitch / column pitch | 82 / 88 | 82 / 88 | 0 |
| “Back to Pip” centre | 702 | 702 | 0 |
| caption centre | 749 | 749 | 0 |
| scrim barrier | (0,0)→(390,844) | same | 0 |

So ORCHESTRATOR_NOTES items 2–6 are all met, `5_ui`'s deviations 1 and 2 (keypad
pitch, card bottom/cancel/caption +26) are gone, and **SHARED_REQUEST #3 can be
closed** — no P17-local change was needed or made for the pitch.

## FIXES_2 items closed this iteration

### §3.1 MINOR — the dimmed backdrop row did not centre its items — CLOSED

`_GateBackdropBody`'s header `Row` no longer passes
`crossAxisAlignment: CrossAxisAlignment.start`; the `Row` default is `center`,
which is what `.kb-top { align-items: center }` says. `p17_bugs_test.dart`'s
**P17-BUG-4 proof is un-skipped and green** (`bug proofs (P17-BUG-1 shared;
BUG-2/3/4 fixed) P17-BUG-4: the backdrop header centres its items`), as is the
geometry twin `the backdrop row centres its items like .kb-top`.

That fix moved the greeting's *text* top from 55 to 60 — which exposed a latent
error in the geometry pin: `designBackdropHeaderTop = 55` is the `.kb-top`
**row** top (47 px status-bar reserve + 8 px `padding-top`), but the assertion
measured the greeting `Text` rect. CSS truth is 55 for the row and
`55 + (44 − 34)/2 = 60` for the centred h1 line box. The constant is now split
(`designBackdropHeaderTop = 55` for the row, `designBackdropGreetingTop = 60`
for the text) and both are pinned. This is a correction of a wrong expectation,
not a relaxation: nothing moved by more than ±0.5 px of CSS truth.

### §3.3 MAJOR (merge blocker) — `FittedBox` would throw with the merged keypad — CLOSED

The call site now matches the two patterns the finding prescribed, chosen by
available width inside a `LayoutBuilder`:

- at the design width (`constraints.maxWidth >= NestKeypad.contentWidth`, i.e.
  302 px content ≥ 280) the keypad is rendered **directly** — the CSS
  `.keypad` is a block-level grid that fills its parent, so the old
  `SizedBox(296) > FittedBox` wrapper was both redundant and (with `Expanded`
  cells) an unbounded-constraint crash;
- for narrower cards the scale-down is kept but the child is given an **explicit
  width**: `FittedBox(fit: scaleDown, child: SizedBox(width:
  NestKeypad.contentWidth, child: NestKeypad(fit: NestKeypadFit.shrinkWrap)))`,
  which paints the key at 232/280 = 59.7 px — still above the 56 px kid minimum
  that `every key keeps a ≥56 px rect at N px` asserts at 320, 390 and 430.

The merge-readiness guard `the keypad is never laid out under unbounded width`
is green, and the full 320/390/430 × textScale 1.0/1.3 matrix shows no layout
exception.

### §3.2 MAJOR (shared) — everything below the keypad +26 — CLOSED by the merge

No P17 change; the pins encode the shared component's new contract and pass.

### Loading placeholders — a regression I introduced and fixed

While re-checking §3.3 I updated the `_GateLoading` reserve for the new keypad
(352 → 326, the CSS grid's 8 + 4×72 + 3×10) but also wrongly added the caption's
`s2 + gap2` gap and its 18 px line box — the enclosing column already adds both,
so the loading card stood 28 px taller than the loaded one and
`the loading placeholders keep the loaded card height` went red (Δ28.0). The
two extra `SizedBox`s are gone and a comment now records why the placeholder
must not reserve them. That test is green again with Δ0.

### 6_bugs observation 1 — `_announcedAttempts` never reset — CLOSED

The BUG-3 fix resets `attempts` to 0 when the live challenge changes, but the
view's announcement counter kept its high-water mark, so the first wrong answer
on the new challenge was silent. The view now tracks `_announcedChallengeId`
and, when the challenge id changes, re-bases `_announcedAttempts` on the
incoming state's count before the announce check. View-only, no contract change.

### 6_bugs observation 4 / 3_test observation 6 — dead code — deliberately KEPT

`presentation/widgets/parental_gate_placeholder_card.dart` is unreferenced, but
so is the identical file in **ten** other features (kid_home, today, settings,
quests, pip, family, auth, kid_jar, design_system_gallery). It is the repo-wide
v1 scaffold, not P17 rot; deleting only P17's copy would make this feature the
odd one out. Left on disk with this note. `ParentalGateChallengeModel` is 2a's
call and has a round-trip test.

## Copy / owner rules re-verified this iteration

- Copy compared character-by-character with
  `design/html-source/screens/P17-parental-gate.html`: `Grown-ups only`,
  `Type the answer in numbers:`, `Back to Pip`,
  `This keeps settings and purchases safe.` — this screen has no curly
  punctuation, no dashes and no ellipsis, so ASCII-exact is the requirement;
  the question and digits stay DB-driven (never `seven times six` / `4`).
- `p17-parental-gate.html` sets **no** `letter-spacing` and no `text-wrap:
  balance`, so `NestType` defaults are correct and `NestBalancedText` must NOT
  be used (h2/h3/body/caption are excluded by the owner rule anyway). No
  `letterSpacing` added anywhere.
- No `google_fonts` / `GoogleFonts` in `lib` or tests (bundled Inter/Nunito).
- BOTTOM EDGE: this screen has no bottom bar; the scrim and the shared
  `KidScope` meadow run full-bleed to the physical edge — pinned by
  `the scrim barrier covers (0,0) to the physical edge` and the dark/light
  `kid background` group.
- ALIGNMENT: 24 px card gutters, centred digit row, `12` CSS keypad gap inside
  a `24`-padded grid → keys at 71…143 / 159…231 / 247…319, all pinned.
- CHILD ORDER / PIP: the backdrop takes the **active** child and falls back to
  the first in DB (insertion) order; Pip comes from the DB via `PipAvatar`
  (Maya = Mochi·sunny·stage 3), pinned by
  `the dimmed backdrop shows the child's own Pip in the slot` and the Leo
  probe in `p17_bugs_test.dart`. No `pip_stage_*.svg`.
- ACCESSIBILITY ACTIONS: every key, the delete key and both ghost buttons expose
  `SemanticsAction.tap` and change real state; the backdrop stays out of the a11y
  tree (`ExcludeSemantics`).
- CLOCK: no `DateTime.now()` in the view; the challenge text is DB/clock driven.

## Test results (my layer + the feature folder; no whole-app run, no simulator)

```
flutter analyze lib/features/parental_gate test/features/parental_gate
  → No issues found! (ran in 4.3s)

flutter test test/features/parental_gate/parental_gate_geometry_test.dart
  → +11: All tests passed!                     (iteration 2: +9 −2)

flutter test test/features/parental_gate/parental_gate_view_test.dart
                                       parental_gate_states_test.dart
  → +43: All tests passed!

flutter test test/features/parental_gate        (whole folder, incl. 2a's files)
  → +106 ~1: All tests passed!                  (iteration 2: +90 ~2 −2 … )
```

The single `~1` skip is **P17-BUG-1** (shared `app/lib/app/router.dart`
redirect loop on an expired kid-mode trial, SHARED_REQUEST #2) — out of my layer
by RULES §1, still honestly skip-marked. Nothing else in `parental_gate` is red.

`dart format` on my scope: `18 files (1 changed)` — the geometry test only.

## For the orchestrator

1. **SHARED_REQUEST #3 (`NestKeypad` CSS grid) is satisfied.** Delete it — the
   pitch now measures 82/88 and every P17 pin is green with no local hack.
2. **SHARED_REQUEST #1 (K03 tests asserting `P17 Parental gate`) is still
   needed** — those 7 `kid_home` reds are outside this worktree's rules; the
   real gate renders `Grown-ups only`.
3. SHARED_REQUEST #2 (P17-BUG-1 router loop) still open, still skipped.

## LEFT FOR NEXT ITERATION

Nothing in the 2b layer — every UI/layout/copy item from `FIXES_2.md` that
belongs to this screen is implemented, pinned and green. Carried, all outside
this layer:

- P17-BUG-1 shared router redirect loop (2a's/app layer, skip-marked);
- the 7 K03 scaffold-title reds (request #1, `kid_home` tests);
- 4_review finding 2 (backdrop reads `AppDatabase` via GetIt) — 2a declined it
  because the fix is a new repository method (a contract change), and it
  contradicts `1_plan.md` §(b);
- 3_test obs 1 (a 10 px internal scroll at 390 × textScale 1.3 — the plan's
  §(e) fallback, conformant), obs 3 (no `Back to Pip` during loading) and obs 4
  (`Try again` at the plan-mandated 44 px on a kid screen) — all plan/DS calls;
- midnight re-key of an open gate (`watchItems()` has no timer) — 2a, open by
  design.

VERDICT: PASS
# P03 Create account — build report (Stage 2, iteration 7 · INTEGRATE)

Route `/create-account` · feature `auth` · parent mode. This stage merged the
two parallel builders — `2a_build_logic.md` (logic) and `2b_build_ui.md` (UI) —
and made the combined tree compile and pass. No redesign; the merge needed no
signature reconciliation.

## Summary of 2a (logic)

Zero changes, re-verified by reading rather than assuming: the layer already
matches `1_plan.md` — `domain/auth_repository.dart` (`AuthProvider`,
`createAccount({email, name})` with the documented legacy `name:` alias for the
one shared caller outside RULES §1, `createAccountSocial`), the Drift impl
(idempotent owner row, email local-part → owner name, password never persisted,
RULES §4), the bloc (dirty-gated validation, `canSubmit`, `on Object catch` +
`addError`, in-flight guards) and DI/routes (`/create-account` registered with
`BlocProvider` + `AuthLoadRequested`).

**Contract changes: none** — so the two halves could not have drifted on a
BLoC state/event/member name, and `analyze` confirms it.

## Summary of 2b (UI)

- **P03-BUG-23 (the form block sat 2 dp low) — fixed, both proofs green.** The
  design's `.or-label` sets `font-size: 13px; font-weight: 600` and **no**
  line-height, so the browser lays it out in a 13 × 1.2077 ≈ 15.7 dp line box,
  while the caption token is fixed at 13/18 — the extra 2.3 dp landed on every
  element below the "or" row. `_OrRow` now styles the label with the design's
  metrics, and the Google-bottom → email-field-top gap and both field tops
  match the design's bands.
- Nothing else in its scope; the rest of `FIXES_6` was already closed in
  iteration 6 (BUG-16/22 proofs green, BUG-17 resolved shared-side by the
  bundled fonts, no `google_fonts` anywhere).

## What this stage changed (smallest possible)

1. **`create_account_view.dart` — the BUG-23 style is token-derived.**
   2b rebuilt it as a literal `TextStyle(fontFamily: 'Inter', fontSize: 13,
   …)`. The resolved pixels are right (both proofs pass), but the orchestrator
   rule is tokens-only, the iteration-6 review asserts "no hard-coded colours,
   radii or text sizes remain in the view", and a duplicated `'Inter'`/`13`
   means a later caption change (or §7's token) would silently skip this
   label. The style now takes family, size, tracking and colour **from
   `NestType.caption(color: tokens.ink2)`** and replaces only the line box,
   `_OrRow._orLabelLineBox = 15.7` — the single number the design owns, named,
   documented and already pinned by two proofs. Behaviour-identical: same
   Inter / 13 / w600 / ls 0 / 15.7÷13 / `ink2`. Also corrected the comment that
   read §9 as a shared-token ask (§9 says the opposite: pattern note, no core
   change).
2. **`p03_bugs_test.dart` — BUG-22's stale wording** (the open note in
   `6_bugs.md`: its proof tail still said the fallback "gates behind `!hit`",
   and its failure reason demanded the rejected `if (!hit && …)` form). Replaced
   with the shipped gesture-entry gate and a pointer to the probe in
   `6_bugs.md` that settled it. Comment and reason strings only.
3. **`SHARED_REQUEST.md` §9** — one paragraph: if §7's `legalCaption` is ever
   actioned, the useful shape covers "label whose CSS sets no line-height"
   too, so the next screen does not repeat this 2.3 dp.
4. **`docs/screens/P03/2_build.md`** — this file.

No behaviour, no contract, no test-logic change: the merge compiled and passed
before this stage started.

## Every FIXES_6 item

| Item | Source | Status |
|---|---|---|
| P03-BUG-23 (form 2 dp below the design bands) | 3_test | **done** (2b) — both proofs green: the font-independent row-height/gap proof and the `typography_test.dart` band proof with the design's own fonts. Re-expressed token-derived here |
| Filled-state capture (`ORCHESTRATOR_NOTES` iter-3 item 3) | 3_test | **done** in iteration 6 — `filled_shot.sh` + `ui/filled-{light,dark}.png` (the design's own filled state; `idb` HID is unavailable on this host, so the script drives the controllers/bloc, never a tap). The UI stage should compare those, not the empty launch frame |
| `_scratch_i6_test.dart` left by a builder | 3_test | **done** in iteration 6 (test stage deleted it); `analyze` clean |
| `!hit` gate question | 6_bugs | **settled** — probe shows `RenderDecoratedBox` claims in-panel points, so the shipped gesture-entry gate is the correct form. No code change; stale wording fixed above |
| Stale `!hit` comment in BUG-22's proof | 6_bugs (flagged for the next pass) | **done** (this stage) |
| `formError` can in principle be announced twice (shared live-region row + the listener's `sendAnnouncement`) | 6_bugs (observation, no proof filed) | **left for the owner** — pre-dates this switch, the live-region half is unobservable in a widget test, and the fix is a product call (drop `sendAnnouncement`, or scope it to messages with no visible row) |
| `SHARED_REQUEST.md` §7 (`NestType` legal-caption 13/20) | 3_test / 4_review / 6_bugs | **left, open** — orchestrator-owned, non-blocking; `P03-BUG-12` pins the current override and the geometry matches the design. §9 now notes the neighbouring case |
| BUG-16 / BUG-22 proofs, BUG-17, `google_fonts`, letter-spacing | 6_bugs "Checked" | **no action** — green from iteration 6; 0 skips on this screen |
| Iteration-5 review findings 1–3 | 4_review | closed in iteration 6 (Decision B recorded, overlap gate shipped, §5/§8 wording settled) |

One stale line worth flagging, not edited: 2a's "LEFT FOR NEXT ITERATION" says
"when SHARED_REQUEST §8 lands, the UI stage passes `errorText:`" — §8 landed in
iteration 6 (`0bafd2a`) and that switch is done, so the note is a step behind.

## Rules re-checked on the merged tree

- **FONTS** — no `google_fonts` import or `GoogleFonts.*` call in `lib/` or
  `test/`; Inter/Nunito are bundled assets.
- **LETTER SPACING** — no local tracking; the `_OrRow` style takes
  `letterSpacing` from the caption token (0, `fd92d95`), and the two caption
  line-height overrides remain `NestSpacing.s5 / 13`.
- **BOTTOM EDGE / ALIGNMENT** — untouched by this iteration; both now have
  pixel proofs from iteration 6 (bar surface to y=844; the 20 px gutters and
  band tops are what P03-BUG-23 was about).
- **CHIP ROWS / CHILD ORDER / PERIODS / TRIAL / PIP / DATA OVER MOCKS** — N/A on
  this static parent-mode form. **COPY** unchanged and byte-audited.
- **Simulators** — not used by this stage (UI stage only, and only
  604697A9-11DA-462F-9837-396E9CA2493A).

## Evidence (app/)

- `dart format --set-exit-if-changed .` → `Formatted 394 files (0 changed) in 0.83 seconds.`
- `flutter analyze` → `No issues found! (ran in 2.5s)` — no ignores, no weakened
  options.
- `flutter test test/features/auth` → `00:05 +159: All tests passed!` — 0 skipped.
  Per file: `auth_bloc_test.dart` 45, `create_account_view_test.dart` 49,
  `copy_audit_test.dart` 16, `p03_bugs_test.dart` 32, `seeded_submit_test.dart`
  7, `typography_test.dart` 10.
- `flutter test` (full suite) → `00:25 +1176: All tests passed!` — 0 failed,
  0 skipped.
- Targeted re-runs after the token re-expression: `P03-BUG-23`, `P03-BUG-22`,
  `P03-BUG-18` and the `typography_test.dart` band proof all pass individually,
  i.e. the geometry proofs still measure the same pixels.
- Touched paths only: `app/lib/features/auth/presentation/views/**`,
  `app/test/features/auth/**`, `docs/screens/P03/**` (RULES §1). Nothing shared.

VERDICT: PASS
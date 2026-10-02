# P03 Create account — test notes (Stage 3, iteration 2)

Route `/create-account` · feature `auth` · parent mode. Tests live in
`app/test/features/auth/`; the in-memory Drift DB comes from
`setUpTestScope()` (`Seed.demo` / `Seed.empty` / `Seed.fresh`) and every test
that pumps the app ends with `disposeApp(tester)` (RULES §7). No `lib/` file
was touched by this stage.

## Verdict

**Three real bugs found** (P03-BUG-9/10/11, all new). The iteration-2 build
fixed everything iteration 1 reported — I verified each fix against the
design on the simulator, not just against the proofs — but the caption
rewrite introduced two new defects and left a third from the shared field
component. Per the brief the screen is **not** patched, so `flutter test` is
**red by design**: 7 of the proofs in `p03_bugs_test.dart` fail. Everything
else passes (600 green, 1 skipped, 7 red).

## The iteration-2 fixes, verified

Every iteration-1 finding is genuinely fixed. On-device evidence from
`shot.sh` (BC440E48) plus `compare.py`:

| | iteration 1 | iteration 2 | design |
|---|---|---|---|
| mean diff, light | 13.14% | **5.08%** | — |
| mean diff, dark | 12.21% | **4.61%** | — |
| compare band 6 (CTA) | 32.67% | 15.76% | — |
| CTA panel top | y=630 | **y=682** | y=677 |
| caption height | 80dp | two text lines | two text lines |
| note clearance above the bar | 4dp | **38dp** | 35dp |
| headline break | "Create your family / account" | **"Create your / family account"** | same |
| compact nav bar | 44dp | **60dp** | 60dp |

Per-band, the app now lands within **0–5dp** of the design for every
element (back chevron 65.0–80.7 vs 65.0–80.7; Apple 255–306.7 vs 255–306.7;
email field 445–496.7 vs 443–494.7; note 627.7–644 vs 625.7–642). The
bottom-edge owner rule holds in both themes: the CTA's `surface` colour runs
to y=844 with no page tint under it. ORCHESTRATOR_NOTES §1 (shared header),
§2 (headline break), §4 (helper on the gutter, 6dp under the field) and §6
(note row on the 20dp gutter) are all satisfied and now pinned by tests;
§3's filled state is pinned by the existing `design filled state` group.

## Tests added this stage

`auth_bloc_test.dart` 41 → **45** (4 added) — the dirty-gating paths the
P03-BUG-2 fix introduced, none of which had a proof:

- **A rejected submit arms live validation for both fields**, and each field
  then clears only its own error as it is fixed.
- **Clearing a field after a rejected submit re-shows its error** — the
  `submitAttempted` flag is sticky, which is the intended trade (no red on
  the first keystroke, red forever after a real submit attempt).
- **A social sign-up never arms field validation** — a failed social submit
  must show only the server error, never "Enter a valid email address".
- **A valid submit after a rejected one still reaches the repository**, with
  the full seven-state sequence pinned.

`create_account_view_test.dart` 43 → **48** (5 added):

- **The helper is replaced by the error and comes back** (never both at
  once) — the P03-BUG-8 helper row and the field error share one slot.
- **A stale server error also displaces the helper, then both recover**.
- **The legal links are 44dp targets with a tap action** — label, button
  flag, `SemanticsAction.tap` (VoiceOver activation) for both.
- **Back pops when a route is stacked** — the `canPop` branch of
  `_onBack`, previously untested (only the deep-link `go('/value-tour')`
  branch had a proof); drives a real `GoRouter` with `/` pushing
  `/create-account`.
- **The three helper/error recovery assertions run in dark mode too**, where
  the error/helper colours differ.

`p03_bugs_test.dart` 13 → **20** (7 new proofs, all RED — the bugs below).
The other 13 proofs (BUG-1/2/3/4/5/7/8 + the skipped shared BUG-6) are green
regression guards.

Total feature tests: 104 → **121** (113 green, 1 skipped, 7 red).

## Bugs found

### P03-BUG-9 (MAJOR) — the caption splits the "Privacy Notice" link, leaving a
### lone underlined "Notice" on the second line

`app/lib/features/auth/presentation/views/create_account_view.dart:328-340`
(`_LegalLine`'s `Text.rich`).

The caption renders as plain text and lets the line breaker fall where it
likes. With the app's Inter the sentence fits one word further than the
design's font did, so the break lands **inside** the link:
`…Terms and Privacy` / `Notice`. Measured on the device
(`ui/light.png`, light): caption line 1 spans x 37–354 (nine word runs ending
in "Privacy"), line 2 is a single 41dp run at x 175–215 with an underline
band directly under it — one dangling underlined word.

ORCHESTRATOR_NOTES §5 (mandatory) requires
`By continuing you agree to our Terms and` / `Privacy Notice`. Proof:
P03-BUG-9 / 9b — the label's layout boxes, read off the caption's own
`RenderParagraph`, must all sit on a single caption line, at 320/390/430 ×
1.0/1.3. Fix direction: make the two-word label unbreakable (U+00A0 between
the words) — this is also why the QA screenshot reads differently from the
design even though the caption's *height* is now right.

### P03-BUG-10 (MAJOR) — the 44dp link targets no longer sit over the words
### they represent

`app/lib/features/auth/presentation/views/create_account_view.dart:342-355`
and `367-390` (`_LegalLine`'s `Positioned.fill` overlay + `_LegalHitTarget`).

The P03-BUG-1 fix replaced the `Wrap` with a zero-height overlay that
centres both targets as **one adjacent 88dp block**
(`Row(mainAxisSize: min)`, x 151–239 at 390dp, both on the same row, gap 0)
while the words they claim to represent sit elsewhere. Measured at every
width: the "Terms" target does not overlap the word "Terms" (390: target
151–195 vs label 89–155) and neither does the "Privacy Notice" target.
Tapping the visible underlined "Terms" at the end of caption line 1 does
nothing, while the middle of the sentence — plain words, not links — is
covered by two invisible buttons.

This is a regression introduced by the iteration-2 fix: in iteration 1 each
target wrapped its own label, so a tap on the word hit its target. The links
are inert in v1 (`TODO(P03)`), so there is no user-visible failure yet, but
the touch targets are simply in the wrong place and will stay wrong when the
routes land. Proofs: P03-BUG-10 (320/390/430, overlap of each target with
its own label) and P03-BUG-10b (the targets can never touch — the words
" and " always separate the two links).

### P03-BUG-11 (MINOR) — the validation error is indented 20dp while the
### helper it replaces sits on the gutter

`app/lib/features/auth/presentation/views/create_account_view.dart:181-217`
(password field) — the error comes from the shared `NestTextField`'s
`errorText`, which Material renders 20dp inside the field, while
ORCHESTRATOR_NOTES §4 (and the iteration-2 BUG-8 fix) moved the helper onto
the 20dp gutter. Measured: helper `left = 20`, error `left = 40`. The text
therefore jumps 20dp sideways the moment an error appears — the same defect
§4 fixed for the hint, left in place for the error line. The design's
`.field` is a flex column (`.field .error`, `components.css:134`), so label,
input, hint and error all share the gutter.

Proof: P03-BUG-11. Fix direction: own the error row the way the helper row is
owned now (the screen may also want a shared fix for `NestTextField`'s
errorText padding — filed as SHARED_REQUEST §5).

## Non-blocking observations

- `submitAttempted` is never reset. It is harmless today (the bloc is
  route-scoped and a successful submit navigates away), but it means any
  later refactor that keeps the bloc alive after navigation would inherit
  permanently-dirty fields. Pinned by the "clearing a field after a rejected
  submit re-shows its error" proof so the behaviour is a decision, not an
  accident.
- The design PNG shows a home-indicator pill; the app shows none. Verified
  again this iteration to be a capture artefact: this simulator does not
  draw the pill in `simctl` screenshots at all (a springboard capture shows
  none either). The bottom-edge rule itself is satisfied and now has a
  dedicated proof in `create_account_view_test.dart`.
- `_headlineMaxWidth = 240` is a measured literal rather than a token. It is
  documented and justified from the HTML break, and it produces the design's
  line break, but it will drift if the Nunito build changes. Flagged for the
  review stage rather than as a bug.
- Shared items 2 and 4 (doubled screen-reader labels on `NestBrandButton` /
  `NestButton`) remain open; the P03-BUG-6 proof stays skipped for that
  reason — the only skip in the suite.

## Results (`app/`)

- `dart format --set-exit-if-changed .` → `Formatted 359 files (0 changed)`.
- `flutter analyze` → `No issues found!` — no ignores, no weakened options.
- `flutter test test/features/auth` → **113 passed, 1 skipped, 7 failed**
  (the 7 are the new proofs above; nothing else is red).
  Per file: `auth_bloc_test.dart` 45/45, `create_account_view_test.dart`
  48/48, `seeded_submit_test.dart` 7/7, `p03_bugs_test.dart` 13 green + 1
  skipped + 7 red.
- `flutter test` (full suite) → **600 passed, 1 skipped, 7 failed**.
- `shot.sh` light + dark + `compare.py` → `ui/light.png`, `ui/dark.png`,
  `ui/compare-light.png`, `ui/compare-dark.png`.

VERDICT: FAIL

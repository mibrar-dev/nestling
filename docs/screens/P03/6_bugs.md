# P03 Create account — bug hunt (Stage 6, iteration 2)

Route `/create-account` · feature `auth` · parent mode · design
`design/screens/{light,dark}/P03-create-account.png` + HTML source. Tree
tested: worktree `screen/P03` at `d298b36` plus the uncommitted iteration-2
build/test work. **No screen code was changed by this stage** — only
`app/test/features/auth/p03_bugs_test.dart` and this report.
`ORCHESTRATOR_NOTES.md`'s six mandatory items are mapped below; the standing
orchestrator rules (PIP — vacuous here, status bar, data-over-mocks, bottom
edge, alignment) were applied.

Executable proofs: `app/test/features/auth/p03_bugs_test.dart` — every
open-bug proof is `skip:`-marked with its id so the suite stays green
(11 skipped). Run
`flutter test test/features/auth/p03_bugs_test.dart --run-skipped` to watch
all of them fail; un-skip each one with its fix.

## Ledger

| ID | Severity | Area | Status |
|---|---|---|---|
| P03-BUG-1 | — | caption one 44dp link row per line | **fixed** iteration 2; proofs 1a–1d green |
| P03-BUG-2 | — | validation error on first keystroke | **fixed** iteration 2 (`submitAttempted` gating); proofs 2a–2d green |
| P03-BUG-3 | — | compact nav bar 44 → 60dp | **fixed** by shared `fc981bc`; proof green |
| P03-BUG-4 | — | legal links announced twice | **fixed** iteration 2 (overlay targets carry one label); proof green |
| P03-BUG-5 | — | non-`Exception` throw stranded the spinner | **fixed** iteration 2 (`on Object catch`); proof green |
| P03-BUG-6 | minor | `NestButton` announces "Create account\nCreate account" | **open, shared** (SHARED_REQUEST §4); proof stays skipped |
| P03-BUG-7 | — | headline break "Create your family / account" | **fixed** iteration 2 (`maxWidth: 240`); proof green, UI stage confirms both lines match |
| P03-BUG-8 | — | password helper indented 40 vs 20 | **fixed** iteration 2 (feature-owned helper row); proof green |
| P03-BUG-9 | **MAJOR** | caption splits the "Privacy Notice" label: lone underlined "Notice" on line 2 | open, in scope; proofs 9/9b |
| P03-BUG-10 | **MAJOR** | 44dp link targets sit as one centred 88dp block, not over their words | open, in scope; proofs 10 (320/390/430), 10b |
| P03-BUG-11 | minor | validation error indented 40 while label/input/helper are at 20 | open, in scope; proof 11 |
| P03-BUG-12 | minor | caption link lines 18dp vs the design's 20dp → CTA panel ~4dp short, hairline 682.7 vs 677.7 (UI deviation 2) | new this stage; proof 12 |
| P03-BUG-13 | minor | with a 2-line caption the 44dp targets render 44×36 (DESIGN_SPEC §0.9 needs 44×44) | new proof; proof 13 |
| P03-BUG-14 | minor | `on Object catch` never `addError`s → observers get no stack trace | new proof; proof 14 |

Iteration-1 closures were independently re-checked, not just accepted: the
caption is text-height (harness 54 ≤ 58), the panel no longer eats the form,
first keystrokes stay clean, the link labels announce once, the headline is
240-capped, the nav is 60dp and the helper runs on the gutter. The UI stage's
design compare improved from 13.15%/12.21% to **5.08%/4.61%**, with bands
1–5 at 1.5–5.9%.

ORCHESTRATOR_NOTES status: §1 fixed by the shared merge (do-not-patch
respected); §2 fixed (headline break verified pixel-for-pixel by the UI
stage); §3 the filled-state widget pin is green — the filled *simulator*
capture is still blocked by missing HID tooling (idb/SimulatorKit) and is
carried for the next stage with GUI tooling; §4 fixed for the helper
(P03-BUG-11 is the error-line half); §5 **broken** (P03-BUG-9); §6 fine
(shield + text on the gutter).

## P03-BUG-9 (MAJOR) — the caption splits the "Privacy Notice" label across two lines

**Where** `create_account_view.dart` `_LegalLine` (`Text.rich`, ~:328-340).
The caption is plain flowing text and the line breaker falls where the app's
Inter runs out of room — one word later than the design's font, splitting
the two-word link.

**Repro** Open `/create-account` (light or dark). Caption line 1 reads
"…Terms and Privacy", line 2 is a lone underlined "Notice". Mandatory
ORCHESTRATOR_NOTES §5 requires
"By continuing you agree to our Terms and" / "Privacy Notice".

**Proofs** `P03-BUG-9` (the label must sit on one caption line) and
`P03-BUG-9b` (both labels on one line at 320/390/430 × 1.0/1.3). Today both
fail: the label spans 2 line boxes.

**Evidence (independent pixel scan of `ui/app_light_2.png` vs the design
PNG, sky-coloured runs):**

| caption line | design | app |
|---|---|---|
| line 1 | x 258.3–297.0 ("Terms") | x 236.0–275.0 ("Terms") **+ 307.0–353.7 ("Privacy")** |
| line 2 | x 150.3–239.7 ("Privacy Notice" whole) | x 175.3–214.7 ("Notice") |

**Suggested fix** Make the label unbreakable — the review's
`'Privacy\u00A0Notice'` (U+00A0) in the span, or render the caption as two
centred line blocks matching §5. No literal `\n`: 320dp and scale 1.3 must
still wrap (proof 9b sweeps them).

## P03-BUG-10 (MAJOR) — the 44dp link targets do not sit over their words

**Where** `create_account_view.dart` `_LegalLine`'s
`Positioned.fill`/`Center`/`Row(mainAxisSize: min)` overlay + the two
`_LegalHitTarget`s (~:342-390).

The iteration-2 caption rewrite kept the links as an overlay, but the overlay
centres the two 44dp boxes as **one adjacent 88dp block** (x 151–239 at
390dp) regardless of where the words land. The visible words are at the line
ends; the invisible targets cover the middle of the sentence. The targets
also touch (`privacy.left == terms.right == 195`), so the " and " gap between
the links is not protected.

**Repro** Tap the page — the underlined "Terms" at the end of line 1 is
untappable (its centre x≈255 is outside the 151–239 block), while two
invisible buttons cover plain words such as "…you agree to our…". Links are
inert v1 (`TODO(P03)`), so nothing happens either way today; the touch
geometry is simply wrong and stays wrong when the routes land.

**Proofs** `P03-BUG-10` at 320/390/430 (each target must overlap the label
box it serves — fails for at least one label at every width) and
`P03-BUG-10b` (the targets must not be contiguous).

**Suggested fix** Make each label's own span/word the target so the hit box
is exactly where the word is (e.g. `TextSpan` with a `TapGestureRecognizer`,
or a two-line centred layout with the keyed link widgets inline), while
keeping one semantics node per link and the 44dp minimum (P03-BUG-13). Run
proofs 9/9b/10/10b/11/13 together — they are the same code path.

## P03-BUG-11 (minor) — the validation error is indented while the helper is on the gutter

**Where** `create_account_view.dart:201` — `errorText: errorText` on
`NestTextField`; Material lays `InputDecoration.errorText` out on the field's
content box (left **40**), while the label, input and the iteration-2
feature-owned helper all start at the 20dp gutter (left **20**). The text
jumps 20dp sideways the moment an error appears. ORCHESTRATOR_NOTES §4 (and
the design's `.field` flex column) wants every line on the gutter.

**Repro** Attempt a submit with an invalid form (or the empty-submit path
used by tests): "Use at least 8 characters" renders at left 40 while the
helper it displaced was at left 20.

**Proof** `P03-BUG-11` (`error.left == field.left`; today 40 vs 20).
**Suggested fix** Own the error row like the helper row: pass
`errorText: null` and render the error in the feature-owned slot with
`NestType.caption(color: tokens.danger)`. SHARED_REQUEST §5 tracks the
component-level fix for other screens; P03 must not wait for it.

## P03-BUG-12 (minor, new) — the caption link lines are 18dp instead of the design's 20dp, so the CTA panel is ~4dp short

**Where** `create_account_view.dart` `_LegalLine` — `NestType.caption`
(13/18) for every span. The design's inline styles set
`.link { line-height: 20px }` (`P03-create-account.html:26`); a line box
containing a 20px inline box grows to 20px, so the design's two-line caption
is **40dp**, not 36dp, and its CTA panel is 167dp vs the app's ~162dp. This
is the root cause of UI iteration-2 deviation 2 ("bottom-CTA hairline +5px"),
which the UI stage could not localise.

**Repro / evidence** 1px gutter scan, `ui/app_light_2.png` vs the design
light PNG (identical in dark):

| | design | app |
|---|---|---|
| CTA hairline | y 677.7 | y 682.7 |
| primary button | y 694.0–745.7 | y 698.0–749.7 |
| caption link-line spacing | 20dp (759.3 → 779.3) | 18dp (762.3 → 780.3) |

**Proof** `P03-BUG-12`: the line height of the line containing each link,
computed from the caption's own `RenderParagraph`/`TextPainter` metrics, must
be 20dp (currently 18dp at every width).

**Suggested fix** Give the caption (or at least its link spans) the design's
`height: 20/13`, e.g. `base.copyWith(height: 20 / 13)` and the same on
`link`. The panel then measures 40 + the fixed 126/127, moving the hairline
to ~678 (design 677.7).

## P03-BUG-13 (minor, new proof) — the 44dp legal targets render 44×36 on a two-line caption

**Where** `_LegalLine`'s `Positioned.fill` overlay: `Positioned.fill` hands
the child the **stack's** size, and the stack is exactly the caption text
(two 18dp lines = 36dp). `ConstrainedBox(minHeight: 44)` is then clamped by
`BoxConstraints.enforce` to 36, so on the device — where the caption is
always two lines — the targets are 44×36, under DESIGN_SPEC §0.9's 44×44
parent minimum. In the widget harness the fallback font wraps the caption to
three lines at 320/390, so the old assertions passed blindly; at **430dp**
the harness also produces two lines and reproduces the device geometry.

**Repro** `P03-BUG-13` at 430dp: target heights are 36 (fails ≥44). On device
the review measured the same 44×36 (`ui/app_light_2.png` geometry).
**Suggested fix** Let the hit boxes overflow the 40dp caption block
(`Stack(clipBehavior: Clip.none)` + `Positioned(top: -2, bottom: -2)` for a
44dp box) — or whatever implementation the BUG-9/10 fix uses, as long as the
final hit box is ≥44×44 and covers its own label.

## P03-BUG-14 (minor, new proof) — a caught repository failure keeps no stack trace

**Where** `auth_bloc.dart:101` and `:117` — `on Object catch (error)` emits
`formError` and drops the error and stack entirely; no `addError` reaches the
bloc observer, so the one place a developer wants the stack has nothing.

**Repro** `P03-BUG-14`: with a `_RecordingObserver` installed, submit against
a repository that throws `StateError` — the user sees the error, the
observer sees **nothing** (`errors == []`). **Suggested fix**
`on Object catch (error, stackTrace)` → emit the state **and**
`addError(error, stackTrace)`. (The P03-BUG-5 proof still passes: the error
is reported, not rethrown.)

## P03-BUG-6 (minor, shared) — `NestButton` still announces its label twice

Carried from iteration 1: core `nest_button.dart` merges its explicit label
with the inner `Text`, so the CTA reads "Create account\nCreate account".
Proof `P03-BUG-6` stays skipped; SHARED_REQUEST §4. Items §2 (brand buttons)
and §5 (NestTextField error padding) are also still open and correctly
non-blocking.

## Checked — no bug found

- **Kid-mode guard** — `APP_MODE=kid` + session kid mode deep-linking
  `/create-account` redirects to `/parental-gate`.
- **Restart / Drift persistence** — one owner row after create, no rename of
  an existing owner, password never written (`seeded_submit_test.dart`).
- **Back / deep links** — no history → `/value-tour`; the form renders on
  `Seed.fresh`, `Seed.empty`, `Seed.demo`; back-pops when a route is stacked
  (new iteration-2 test).
- **Rapid double taps** — the `isSubmitting` guard still blocks a second
  submit; all three buttons disable/spin together.
- **Text scale 1.3 + width 320/390/430** — the matrix produces no overflow;
  the headline's 240dp cap still wraps to ≤3 lines with real Nunito
  ("Create your" 206dp at scale 1.3 < 240 < "family account" 257dp), so no
  clip.
- **Dark-mode contrast** — unchanged token pairs (all text ≥4.5:1; lilac
  shield decorative at 3.7:1 light).
- **0/1/6 children, long UK names, empty lists, money, timezone/BST** — N/A
  on this screen (static form, no money/date logic, `members` stream never
  displayed).
- **Async gaps** — controllers disposed, no timers, `emit` after close is a
  no-op in bloc 9.2.1; the caught-error path now needs P03-BUG-14's
  `addError` for observability only.
- **Observations, not filed** — `submitAttempted` is intentionally sticky
  (pinned by tests); because the CTA is disabled while invalid, field errors
  can only appear programmatically — a plan-level UX tension
  (`1_plan.md` §(b)/(d)), not a regression; `_headlineMaxWidth = 240` is an
  accepted measured literal (review accepted, proof 7 guards it); the design
  PNG's home-indicator pill is a `simctl` capture artifact; the test
  harness' fallback font is much wider than Inter/Nunito, so harness line
  counts are not product geometry (real-font checks used where it mattered).

## Suite state at hand-off (`app/`)

- `dart format --set-exit-if-changed .` → `359 files (0 changed)`.
- `flutter analyze` → `No issues found!` (no ignores added).
- `flutter test test/features/auth` → **113 passed, 11 skipped, 0 failed**.
- `flutter test` (full) → **600 passed, 11 skipped, 0 failed**.
- The 11 skips are the open-bug proofs: `P03-BUG-6` (shared) and
  `P03-BUG-9`, `9b`, `10` ×3, `10b`, `11`, `12`, `13`, `14`. All iteration-1
  proofs (1a–1d, 2a–2d, 3, 4, 5, 7, 8) run **green**. `--run-skipped` fails
  all 11 for the reasons above.

## Verdict

Two MAJOR bugs remain (P03-BUG-9: the mandatory two-line caption break is
broken; P03-BUG-10: the link targets sit in the wrong place) plus four minor
ones. The fixes are localised to `_LegalLine` (9/10/12/13), the password
error slot (11) and the two catch blocks (14). Fix 9+10+12+13 together in one
`_LegalLine` pass, then 11 and 14, then un-skip their proofs and re-run the
simulator compare.

VERDICT: FAIL

# P03 Create account — bug hunt (Stage 6, iteration 3)

Route `/create-account` · feature `auth` · parent mode · design
`design/screens/{light,dark}/P03-create-account.png` + HTML source. Tree
tested: worktree `screen/P03` at `29162fc` plus the uncommitted iteration-3
build/test work. **No screen code was changed by this stage** — only
`app/test/features/auth/**` and this report. `ORCHESTRATOR_NOTES.md`'s
iteration-2/3 items and the standing rules (PIP — vacuous here, status bar,
data-over-mocks, bottom edge, alignment, COPY, CHILD ORDER) were applied.

Executable proofs: `app/test/features/auth/p03_bugs_test.dart` — every
open-bug proof is `skip:`-marked with its id so the suite stays green
(7 skipped across the feature). Run
`flutter test test/features/auth/p03_bugs_test.dart --run-skipped` to watch
them fail; un-skip each one with its fix.

## Ledger

| ID | Severity | Area | Status |
|---|---|---|---|
| P03-BUG-1…14 | — | iterations 1–2's bugs (caption geometry, validation gating, nav bar, labels, spinner, headline, helper/targets/lines/stack) | **all fixed** by iteration 3; proofs green |
| P03-BUG-6 | minor | `NestButton` announces "Create account\nCreate account" | **open, shared** (§4); proof skipped |
| P03-BUG-15 | **MAJOR** | subtitle ships `You're` with a straight U+0027 where the design HTML has U+2019 | open, in scope; proofs `P03-BUG-15` + `copy_audit_test.dart` "subtitle" |
| P03-BUG-16 | minor | an invalid field no longer paints the danger border | open, **blocked on shared §5**; proof skipped |
| P03-BUG-17 | minor | subtitle breaks after "Children" instead of "Children never" | open, **shared §6** (font pipeline); no local test possible |
| P03-BUG-18 | minor | the legal targets' overhang is not hit-testable — ~32dp effective height, not 44dp | new this stage; proof 18 |
| P03-BUG-19 | minor | legal targets lag the first painted frame; the one-shot measurement can go stale (font swap) | new this stage; proof 19 |
| P03-BUG-20 | minor | validation errors lost Material's live region — client errors are announced by nothing | new this stage; proof 20 |

Iteration-3 closures were independently re-checked by me: the caption is
unbreakable (NBSP), each target overlaps its own word at 320/390/430 and
survives live resize/scale/theme changes, the error sits on the 20dp gutter,
the caption lines are 20dp and the CTA hairline lands at 678 vs the design's
677, and a repository `Error` is both surfaced and reported to observers.

ORCHESTRATOR_NOTES status: **item 1 FIXED** (one U+00A0; device line 1 =
"Terms" only, line 2 = "Privacy Notice"); **item 2 half** — the curly
apostrophe is still U+0027 (P03-BUG-15, mandatory) and the specified break is
font-pipeline-blocked (P03-BUG-17, shared §6); **item 3 outstanding** — the
filled-state capture is still host-blocked (no SimulatorKit/HID in this
Xcode; the filled *state* is pinned by the green widget test); iteration-2
items §4/§5/§6 are all satisfied (helper gutter, two-line caption, note row).

## P03-BUG-15 (MAJOR) — the subtitle uses a straight apostrophe where the design has U+2019

**Where** `create_account_view.dart:116` — `"You're the grown-up in charge. "`
with U+0027. The HTML writes `You&rsquo;re` (U+2019); ORCHESTRATOR_NOTES
iteration-3 item 2 names the character explicitly, and the standing COPY
rule requires the design's typographic characters exactly.

**Repro** Open `/create-account`: the subtitle's apostrophe is a straight
tick. Byte check on the view: subtitle apostrophe `0x27`, zero U+2019
anywhere in the file. `copy_audit_test.dart` ("subtitle") is red on it.

**Proofs** `P03-BUG-15` (finds the U+2019 string; fails today) and
`copy_audit_test.dart` "subtitle". Both are skip-marked with this id; un-skip
both with the fix. **Suggested fix** one character:
`'You\u2019re the grown-up in charge. '` (keep the rest verbatim; no hard
newline).

## P03-BUG-16 (minor, shared §5) — an invalid field no longer paints the danger border

**Where** `create_account_view.dart:173-185`, `:210-223` — both fields pass
`errorText: null` so the error can own the gutter (the BUG-11 fix), but
`NestTextField` derives its `errorBorder` from the same `errorText` flag. The
invalid input keeps the resting `line` border; only the message is red. The
design marks the input itself:
`.field input[aria-invalid="true"] { border-color: var(--danger) }`
(`components.css:135`, SPACING_SPEC §3).

**Repro** Reject a submit with an invalid form (programmatic — the CTA is
disabled while invalid): the email/password boxes stay grey while their
messages turn red. **Proof** `P03-BUG-16` (skipped).

**Fix / decision** P03 cannot fix this without re-opening BUG-11: with the
component as it stands the two proofs are mutually exclusive. SHARED_REQUEST
§5 now asks for a separate `hasError`/`errorBorder` flag so the border is
independent of the message row. Keep the visible gutter fix; if the
orchestrator declines the shared change, retire this proof explicitly rather
than passing `errorText` again.

## P03-BUG-17 (minor, shared §6) — the subtitle breaks one word early

**Where** `create_account_view.dart:113-117` — `NestType.body` (Inter 16/24,
no letter-spacing) is already the design token, but the Inter build
`google_fonts` serves is ~3–4% wider than the design's render, so the
subtitle that fits "…Children never" in 350dp (design line 1 ends x 368.3)
runs out of room in the app (line 1 ends x 330.7; "never" drops to line 2,
which ends x 180.3 vs the design's 128.3). Pixel-verified this stage.

**No local test is possible**: the harness font is not Inter, so a widget
test's break says nothing about the device. The copy is verbatim and the
style is the token, so this is not a styling bug — SHARED_REQUEST §6 (pin or
bundle the design's Inter build). Do **not** chase it with a local
size/letter-spacing/width hack; that trades a 3% glyph drift for a token-rule
violation.

## P03-BUG-18 (minor, new) — the legal targets are only ~32dp reachable

**Where** `create_account_view.dart:414-418` (`_targetRect`) and `:456-468`
(`Positioned.fromRect`). Each 44dp box is centred on its word, so it
overhangs the caption Stack (40dp for two 20dp lines) by ~12dp at one end.
Flutter only hit-tests a child when the tap is inside the parent box
(`rendering/proxy_box.dart:183-192`), so the overhang is dead: the effective
height per target is ~32dp, though `tester.getSize` reports 44dp. The design
HTML does not clip the same way — `.link { min-height:44px; margin:-12px 0 }`
boxes stay fully hit-testable in the browser.

**Repro** `P03-BUG-18` (430dp, the device's two-line geometry): a hit test at
the target box's top+1 and bottom-1 must land on that target; today the
overhang end misses. Hit-test-based, so it cannot be fooled by the rendered
rect. **Suggested fix (decide explicitly)** either make the caption block at
least 44dp tall (`ConstrainedBox(minHeight: NestDevice.tapParent)` around the
Stack; the hairline moves 678 → ~674 vs the design's 677) or implement a
custom render object whose hit test accepts the overhang (keeps the 678
hairline). Since the links are inert v1, keeping the current geometry plus a
documented limitation is also defensible — but then this proof should be
retired with that decision recorded.

## P03-BUG-19 (minor, new) — the targets lag the first frame and the measurement can go stale

**Where** `create_account_view.dart:350-411` (`_scheduleMeasure`/`_measure`):
the boxes are read from the laid-out paragraph in a post-frame callback and
re-scheduled only from `initState`/`didChangeDependencies` (MediaQuery size,
text scaler, theme). Consequences:

- the targets do not exist in the first painted frame (proof: one
  `pumpWidget` → no `p03_terms`);
- any reflow that is not a MediaQuery/theme change leaves them stale. The
  real one on device is the runtime Google Fonts swap: no font is bundled
  (`pubspec.yaml` has no `fonts:`), so the first layout can use a fallback
  face; when Inter arrives the paragraph reflows and nothing re-measures
  until an unrelated dependency change.

**Repro** `P03-BUG-19` (first frame). **Suggested fix** derive the boxes
during layout (a small `RenderBox`/`CustomPainter` that computes them from a
`TextPainter` in `performLayout`), which fixes both halves; a chained
post-frame re-measure would still leave the first-frame window. Add/extend a
proof that a relayout without a dependency change keeps each target on its
word.

## P03-BUG-20 (minor, new) — validation errors are no longer announced

**Where** `create_account_view.dart:186-192` (email) and `:234-240`
(password). Moving the message out of `InputDecoration` (correct for the
gutter) also moved it out of Material's live region
(`material/input_decorator.dart:419`), and the screen's
`SemanticsService.sendAnnouncement` only fires for server `formError`s. A
VoiceOver user therefore hears nothing when a field goes invalid.

**Repro** `P03-BUG-20`: after a rejected submit, the error nodes'
`isLiveRegion` flag is false. **Suggested fix** wrap each owned error row in
`Semantics(liveRegion: true, child: ExcludeSemantics(child: Text(...)))` so
it announces once, and keep `sendAnnouncement` for `formError`.

## Carried — not numbered

- **`height: 20 / 13` hard-codes a type metric** (`:425`, `:430`) — review
  finding 7; filed as SHARED_REQUEST §7 (`NestType.legalCaption` 13/20). The
  override is legitimate until the token lands (P03-BUG-12 pins it); the
  stopgap is `NestSpacing.s5 / 13`.
- **The filled-state capture** (ORCHESTRATOR_NOTES item 3) is still
  host-blocked: this Xcode ships no SimulatorKit/HID and there is no
  Simulator.app GUI. The filled state itself is pinned by the green "design
  filled state" widget test; re-attempt when HID tooling exists.
- **Shared items §2/§4/§6** (brand labels, `NestButton` label, font width)
  remain open and non-blocking.

## Checked — no bug found

- **Kid-mode guard** — `APP_MODE=kid` + session kid mode deep-linking
  `/create-account` redirects to `/parental-gate`.
- **Restart / Drift persistence** — one owner row after create, no rename,
  password never written (`seeded_submit_test.dart`).
- **Back / deep links** — no history → `/value-tour`; back-pops when a route
  is stacked; the form renders on all three seeds.
- **Rapid double taps** — the `isSubmitting` guard blocks a second submit;
  all three buttons disable/spin together.
- **Text scale 1.3 + width 320/390/430** — matrix clean; the caption targets
  survive live resize/scale/theme changes (new iteration-3 proofs).
- **Dark-mode contrast** — unchanged token pairs (text ≥4.5:1; lilac shield
  decorative).
- **0/1/6 children, long UK names, empty lists, money, timezone/BST** — N/A
  on this screen (static form, no money/date logic, `members` stream never
  displayed). **CHILD ORDER** N/A (no children listed).
- **Design-faithful non-finding** — the two legal targets overlap when the
  caption wraps to two lines (the later box wins); the HTML's inline hit
  boxes overlap between consecutive lines the same way. Do not “fix” it.
- **Observations** — the first-frame target gap is invisible in screenshots
  (`shot.sh` waits for a stable frame); `submitAttempted` stays sticky by
  design; the design PNG's home-indicator pill is a `simctl` capture
  artefact.

## Suite state at hand-off (`app/`)

- `dart format --set-exit-if-changed .` → `364 files (0 changed)`.
- `flutter analyze` → `No issues found!` (no ignores added).
- `flutter test test/features/auth` → **132 passed, 7 skipped, 0 failed**.
- `flutter test` (full) → **659 passed, 7 skipped, 0 failed**.
- The 7 skips are the open-bug proofs: `P03-BUG-6` (shared),
  `P03-BUG-15` ×2 (`p03_bugs_test.dart` + `copy_audit_test.dart`),
  `P03-BUG-16` (shared-blocked), `P03-BUG-18`, `P03-BUG-19`, `P03-BUG-20`.
  `--run-skipped` fails each for the documented reason.

## Verdict

One MAJOR bug remains (P03-BUG-15: the mandatory curly apostrophe — a
one-character fix) plus four minor ones, two of which need an explicit
decision (P03-BUG-16 shared component fix, P03-BUG-18 target geometry) and
one shared font-pipeline item (P03-BUG-17). Fix 15, 19 and 20 in P03, decide
16/18, then un-skip their proofs and re-run the simulator compare.

VERDICT: FAIL

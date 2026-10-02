# P03 Create account — test notes (Stage 3, iteration 3)

Route `/create-account` · feature `auth` · parent mode. Tests live in
`app/test/features/auth/`; the in-memory Drift DB comes from
`setUpTestScope()` (`Seed.demo` / `Seed.empty` / `Seed.fresh`) and every test
that pumps the app ends with `disposeApp(tester)` (RULES §7). No `lib/` file
was touched by this stage.

## Verdict

**Two real bugs found** (P03-BUG-15 and P03-BUG-16). The iteration-3 build
fixed everything iterations 1–2 reported — I verified each fix on the
simulator, including the ones whose proofs it also had to re-anchor — and the
screen is now within 0–2 dp of the design everywhere above the fold. But the
mandatory `ORCHESTRATOR_NOTES.md` copy item is still unmet and the BUG-11 fix
silently dropped a design-system affordance. Per the brief the screen is
**not** patched, so `flutter test` is **red by design**: 2 proofs fail.
Everything else passes (659 green, 1 skipped, 2 red).

## The iteration-3 fixes, verified

| | iter 2 | iter 3 | design |
|---|---|---|---|
| compare.py mean diff, light | 5.08% | **4.66%** | — |
| compare.py mean diff, dark | 4.61% | — | — |
| CTA surface top | y=682 | **y=678** | y=677 |
| submit button | 698–749.7 | **694–745.7** | 694–745.7 |
| legal caption, line 1 | `…Terms and Privacy` | **`…Terms and` (759.3)** | 759 |
| legal caption, line 2 | `Notice` | **`Privacy Notice` (779.0)** | 779 |
| per-element vertical drift | 0–5 dp | **0–2 dp** | — |

Every element from the back chevron to the privacy note now lands within
2 dp of the design (chevron 65.0 vs 65.0, h1 113.0 vs 112.7, Apple button
255–306.7 vs 255–306.7, email field 445 vs 443, note 627.7 vs 625.7). The
bottom-edge owner rule holds: the CTA's `surface` colour runs to y=844 with
no page tint under it, in both themes. BUG-9, 10, 11, 12, 13, 14 and the
iteration-2 fixes are all green regression guards.

I also checked the proofs the build re-anchored, since a test stage has to
be sure a "correction" is not a weakening. All four are sound:
`BUG-10b` (vertical separation instead of horizontal — the design's own
inline hit boxes overlap in x too, and the new form still fails the
iteration-2 adjacent block), `BUG-1a/b/d` (18dp → 20dp line height, which is
the HTML's `.link { line-height: 20px }` and matches the design PNG's 20 dp
line pitch), and the `BUG-9/9b` line-band predicate (the old 1 dp strips
genuinely missed whenever leading > 0). The new bounds still fail the buggy
values they guard against by a wide margin (64 vs 80, 156 vs 172, 108 vs 140).

## Tests added this stage

`copy_audit_test.dart` (new, **10**) — the COPY rule says every string must
be byte-identical to the HTML, so each string is checked on its own (one
deviation cannot mask another), with the design's typographic characters
written as explicit escapes:

- **h1, note (U+2014), helper + field labels, brand buttons, CTA** — all
  green; 8 of the 9 user-facing strings match the HTML byte-for-byte.
- **subtitle** — red (P03-BUG-15).
- **legal caption** — the whole sentence is verbatim *and* carries exactly
  one U+00A0 inside "Privacy Notice", which is what the COPY rule blesses for
  keeping a phrase together.
- **The measured link targets survive a live relayout (3, green)** — the
  caption's targets are positioned from a post-frame measurement of the
  paragraph, which is the most fragile thing in the iteration-3 code. A live
  resize to 320 and to 430, a live text-scale change to 1.3 and a light→dark
  theme switch all keep each target over its own word.

`p03_bugs_test.dart` 20 → **24** (1 new proof, red — P03-BUG-16).
`create_account_view_test.dart` and `auth_bloc_test.dart` unchanged this
iteration (48 and 45, both green): the dirty-gating, navigation, seeded
repository, submitting-state and a11y coverage from iterations 1–2 already
covers every event/state path the build left in place, and I found no new
gap in them.

Feature total: 121 → **132** (130 green, 1 skipped, 2 red).

## Bugs found

### P03-BUG-15 (MINOR, mandatory) — the subtitle uses a straight apostrophe

`app/lib/features/auth/presentation/views/create_account_view.dart:116`.

The app ships `"You're the grown-up in charge. "` with U+0027. The HTML has
`You&rsquo;re` (U+2019), and `ORCHESTRATOR_NOTES.md` iteration-3 item 2
(mandatory) says "curly apostrophe 'You're' (U+2019) as in the
design/HTML". The new COPY orchestrator rule requires the design's
characters exactly.

Repro: `flutter test test/features/auth/copy_audit_test.dart` — the
"subtitle" test. The full audit (all nine strings, transcribed from the
HTML with escapes) lives in that file, so any future copy drift in either
direction is caught.

### P03-BUG-16 (MINOR) — an invalid field no longer paints the danger border

`app/lib/features/auth/presentation/views/create_account_view.dart:173-185`
and `210-223` — the iteration-3 BUG-11 fix passes `errorText: null` to both
`NestTextField`s so the error message could own the gutter slot. But the
shared field also switches its border to `errorBorder` only while
`errorText != null` (`nest_text_field.dart:128-171`), so the input now keeps
the resting `line` border in the error state.

The design marks the input itself:
`design/html-source/components.css:135`
`.field input[aria-invalid="true"] { border-color: var(--danger) }`, and
`docs/design/SPACING_SPEC.md` §3 states "Error: text 13/18 danger w600;
input `[aria-invalid=true]` border danger". Measured: the border painted
inside the email field is `tokens.line` both before and after the error
appears, so the only signal is red text.

This is a direct consequence of the BUG-11 fix (the build note records it as
a deliberate "trade": "no red input border"), but it costs a design-system
affordance the error state is supposed to have, and the coupling lives in a
shared component, so it is filed as SHARED_REQUEST §5 as well. Proof:
P03-BUG-16.

### P03-BUG-17 (observation, mandatory note not met) — the subtitle still
### breaks one word early

`ORCHESTRATOR_NOTES.md` iteration-3 item 2 also asks for the break
`…Children never` / `need an email.`. The app renders `…Children` /
`never need an email.` (capture: line 1 x 20.7–331.0, line 2 x 21.3–180.3).

The screen's style is already exactly the design's token
(`NestType.body` = Inter 16/24, no letter-spacing = `--fs-body`/`--lh-body`),
so this is not a styling bug: the Inter build `google_fonts` serves is
~3–4% wider than the one the HTML was rendered with (helper 130.7 vs 125.7 dp
= 1.040; note 272.7 vs 264.7 dp = 1.030; Nunito h1 159.4 vs 157.0 = 1.015).
The design's line 1 is 348 dp inside a 350 dp content width — 2 dp of
headroom — so a 3% wider face cannot fit "never".

No widget test can pin this: the harness font is not Inter, so the break it
produces says nothing about the device. The copy audit pins the *string*, and
the geometry proofs pin the tokens; the residual is a font-pipeline
difference and is filed as SHARED_REQUEST §6. It cannot be fixed at screen
level without violating "tokens only".

## Non-blocking observations

- The two 44 dp link targets overlap by ~24 dp when the caption wraps to two
  lines, so the lower ~8 dp of the visible word "Terms" belongs to the
  "Privacy Notice" target. This is **design-faithful**: the HTML's
  `.link { min-height:44px; margin:-12px 0 }` boxes overlap the same way
  between consecutive lines and the later box wins the paint order there
  too. Not a finding — noting it so a future "fix" does not chase it.
- The link targets do not exist during the first frame (they are measured
  post-frame). At 60 fps that is a sub-16 ms window with no layout, and
  `shot.sh` waits for a stable frame, so it is invisible in practice; a
  screen reader announcing on first paint could miss them.
- ORCHESTRATOR_NOTES §3 (filled-state capture on the simulator) is still
  outstanding — it belongs to the UI stage, and the filled *state* is pinned
  by the existing widget proof in `create_account_view_test.dart`.
- Shared items 2, 4, 5 remain open; P03-BUG-6 is the suite's only skip.

## Results (`app/`)

- `dart format --set-exit-if-changed .` → `Formatted 364 files (0 changed)`.
- `flutter analyze` → `No issues found!` — no ignores, no weakened options.
- `flutter test test/features/auth` → **130 passed, 1 skipped, 2 failed**
  (only the two proofs above are red). Per file: `auth_bloc_test.dart`
  45/45, `create_account_view_test.dart` 48/48, `seeded_submit_test.dart`
  7/7, `copy_audit_test.dart` 9 green + 1 red, `p03_bugs_test.dart` 23
  green + 1 skipped + 1 red.
- `flutter test` (full suite) → **659 passed, 1 skipped, 2 failed**.
- `shot.sh` light + `compare.py` → `ui/light.png`, `ui/compare-light.png`
  (mean diff 4.66%; bands 0–5 are all under 3%).

VERDICT: FAIL
# P03 Create account — test notes (Stage 3, iteration 4)

Route `/create-account` · feature `auth` · parent mode. Tests live in
`app/test/features/auth/`; the in-memory Drift DB comes from
`setUpTestScope()` (`Seed.demo` / `Seed.empty` / `Seed.fresh`) and every test
that pumps the app ends with `disposeApp(tester)` (RULES §7). No `lib/` file
was touched by this stage.

## Verdict

**Two real bugs found**: one new regression the iteration-4 build introduced
(P03-BUG-21, accessibility), and one defect the build *retired the proof for*
instead of fixing (P03-BUG-16). Everything the build did fix is genuinely
fixed — I re-verified it on the simulator and with new proofs — and the
layout is byte-identical to iteration 3 (compare.py mean diff 4.66%, CTA
surface top 678 vs the design's 677, submit button 694–745.7 exactly, both
caption lines exact). Per the brief the screen is **not** patched, so
`flutter test` is **red by design**: 2 proofs fail. Everything else passes
(669 green, 1 skipped, 2 red).

## The iteration-4 fixes, verified

- **BUG-15 (curly apostrophe)** — fixed: the subtitle now ships U+2019 and
  the whole copy audit is green (10/10 strings byte-identical to the HTML).
- **BUG-18 (overhang not hittable)** — works, and without changing layout:
  probed the whole 44 dp column of both targets through the real hit test;
  the Privacy Notice target is hittable through its 12 dp overhang below the
  caption block (838 of 840), taps inside the bar take the normal path, the
  enabled submit button still navigates to `/privacy`, and the CTA hairline
  is still at 678.
- **BUG-19 (first frame / stale measurement)** — fixed and now pinned hard:
  the targets are built from a synchronous `TextPainter` mirror, and I added
  five proofs that compare the built rects against the *real* laid-out
  paragraph's own glyph boxes at 320/390/430 × 1.0/1.3 — exact equality, so
  the mirror can never silently drift from the text again.
- **BUG-20 (no live region)** — see below: the flag is set, but the region is
  empty, which is a regression rather than a fix.

## Tests added this stage

`copy_audit_test.dart` 10 → **15** (5 added, all green) — *"targets equal the
paragraph boxes"*: for each of 320/390/430 at scale 1.0 and 320/390 at 1.3,
the `p03_terms` / `p03_privacy` rect must equal exactly the box derived from
the rendered paragraph (label glyph box, re-centred on its own line, ≥44×44).
Font-independent — both sides come from real glyph metrics — and it is the
contract the whole mirror/verify machinery exists to keep.

`p03_bugs_test.dart` 24 → **27** (2 added, both red) — P03-BUG-16 restored,
P03-BUG-21 new.

No gaps left in the bloc, navigation, seeded-repository, submitting-state or
tap-target coverage: `auth_bloc_test.dart` (45), `create_account_view_test.dart`
(48) and `seeded_submit_test.dart` (7) are unchanged and green — every event
and state path the build left in place is already pinned.

Feature total: 132 → **142** (140 green, 1 skipped, 2 red).

## Bugs found

### P03-BUG-21 (MAJOR, regression from the BUG-20 fix) — the validation error
### is no longer in the semantics tree

`app/lib/features/auth/presentation/views/create_account_view.dart:190-201`
(email) and `246-258` (password):

```dart
Semantics(
  liveRegion: true,
  child: ExcludeSemantics(
    child: Text(state.emailError!, …),
  ),
),
```

`ExcludeSemantics` drops the `Text`'s own node, and the wrapper supplies only
a flag — no label. The resulting semantics node is
`liveRegion: true, label: ""`. Walking the whole tree after a rejected
submit shows it plainly:

```
SemanticsNode liveRegion=true label=""      ← the email error
SemanticsNode liveRegion=true label=""      ← the password error
```

So a screen reader announces an *empty* live region and cannot read the
message at all — it is not in the tree to navigate to either. Before
iteration 4 the error was a plain `Text` and produced a labelled node. The
existing BUG-20 proof passes anyway because
`tester.getSemantics(find.text(error))` resolves to the nearest enclosing
node — the empty live region — and only asserts `isLiveRegion`, never the
label. That is the hole the regression went through.

Repro: `flutter test test/features/auth/p03_bugs_test.dart` — proof
P03-BUG-21 asserts each error is findable by semantics label *and* that the
node carrying it is the live region.

### P03-BUG-16 (MINOR) — retired rather than fixed; the defect is unchanged

The iteration-4 build deleted this proof ("the shared `hasError` flag did
not land … per review finding 1 the proof is retired"), which is fair as
process but leaves the defect in place with no guard: an invalid input still
paints the resting `line` border, while the design marks the input itself —
`.field input[aria-invalid="true"] { border-color: var(--danger) }`
(`design/html-source/components.css:135`, and `docs/design/SPACING_SPEC.md` §3
"input [aria-invalid=true] border danger").

The build's reasoning is sound (re-passing `errorText` would re-open
P03-BUG-11's 20 dp indent, and the blocker really is shared code), but
retiring a proof is not the same as fixing a bug, so I have restored it as a
failing proof. `SHARED_REQUEST.md` §5 owns the unblock.

Repro: proof P03-BUG-16 — measure the borders painted inside the keyed field
before and after a rejected submit.

## Non-blocking observations

- On the device geometry the Terms target's top overlaps the submit button's
  last ~4 dp (button 694–745.7, caption line 1 centre ≈763.7 → target
  741.7–785.7), so a tap in that strip is delivered to both. The build
  records it ("both fire there and the submit wins functionally"); it is
  inert only because the links are still inert (`TODO(P03)`). Worth a
  comment where the link routes land.
- `_HitTestExpand.extra` is never read by `hitTest` — the overhang is bounded
  by each target's own 44 dp box instead, which is correct, but the field and
  its `markNeedsPaint` are dead weight and the name suggests it does
  something it does not.
- `_verifyTotal` is capped at 12 for the State's lifetime, so the post-frame
  font-swap verification stops after ~3 relayouts. Harmless today (every
  rebuild re-measures synchronously, which the five new proofs pin), but it
  is a silent ceiling on the safety net.
- P03-BUG-17 (subtitle breaks after "Children") remains a shared font-pipeline
  item (`SHARED_REQUEST.md` §6); no local test can pin it.
- ORCHESTRATOR_NOTES §3 (filled-state simulator capture) is still the UI
  stage's; the filled *state* is pinned by the widget test.
- Shared items 2, 4, 5 remain open; P03-BUG-6 is the suite's only skip.

## Results (`app/`)

- `dart format --set-exit-if-changed .` → `Formatted 364 files (0 changed)`.
- `flutter analyze` → `No issues found!` — no ignores, no weakened options.
- `flutter test test/features/auth` → **140 passed, 1 skipped, 2 failed**
  (only the two proofs above are red). Per file: `auth_bloc_test.dart` 45/45,
  `create_account_view_test.dart` 48/48, `copy_audit_test.dart` 15/15,
  `seeded_submit_test.dart` 7/7, `p03_bugs_test.dart` 27 green + 1 skipped +
  2 red.
- `flutter test` (full suite) → **669 passed, 1 skipped, 2 failed**.
- Prior iterations' reports are in the loop history; this file is the
  current one.
- `shot.sh` light + `compare.py` → `ui/light.png`, `ui/compare-light.png`
  (mean diff 4.66%, unchanged from iteration 3 — the hit-test work moved no
  pixels, as claimed; bands 0–5 all under 3%).

VERDICT: FAIL
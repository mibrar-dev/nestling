# P04 · Privacy consent — test notes (STAGE 3, iteration 4)

Feature `privacy_consent` · route `/privacy` · parent mode.
Scope this stage: `app/test/features/privacy_consent/**` + `docs/screens/P04/**`
(RULES §1). No production code touched; nothing patched.

Inputs re-verified: `1_plan.md`, `2_build.md` (iteration 4), `4_review.md`,
`5_ui.md`, `6_bugs.md`, `FIXES_3.md`, `SHARED_REQUEST.md` and the mandatory
`ORCHESTRATOR_NOTES.md` (12:03, 13:42 UPDATEs).

## Test inventory — 120 P04 tests (118 run, 2 skipped shared-blocked proofs)

| File | Tests | Role |
|---|---|---|
| `privacy_consent_bloc_test.dart` | 20 | every event/state path of `PrivacyConsentBloc` |
| `privacy_consent_repository_test.dart` | 13 | Drift contract on the in-memory DB (`Seed.demo` / `empty` / `fresh`) |
| `privacy_consent_view_test.dart` | 27 | copy, light+dark, 320/390/430 × 1.0/1.3 matrix, statuses, navigation, a11y, gutters, bottom edge |
| `privacy_consent_view_contract_test.dart` | 39 | states through the real router, every tap destination, optimistic switch, failure captions, **separator overlay**, row glyphs, nav geometry, dialog stress, short screens, alignment |
| `privacy_consent_copy_test.dart` | 5 | copy fidelity against the HTML design source (COPY rule) |
| `p04_bugs_test.dart` | 16 | adversarial proofs (9 fixed & green, 2 shared-blocked & skipped, clean-behaviour guards) |

## Tests added this iteration — the two structures the build rewrote

### 1. The separator overlay (P04-4, the fix that took four iterations)

The rows are now a single `Column` inside `NestList` and each row paints its
own 1 px separator as a `Positioned(top: 0, left: 72, right: 0, height: 1)`
overlay inside a `Stack`. That is new, hand-rolled drawing, so it got the most
attention. New group **"P04 — separator overlay (P04-4 contract)"**:

- *light and dark:* **row 1 carries no line** (the design's `+` sibling
  selector) and rows 2–4 carry **exactly one each** — a bare "3 dividers"
  count would also pass if all three were stacked on one row.
- *painted geometry:* every line's **top equals its row's top** (it sits on the
  boundary, not inside the row), its left is exactly **72 px** from the row's
  left edge, it runs to the row's right edge, and it is **1 px** tall;
  `color == tokens.line` in both themes, `thickness == 1`, `height == 1`.
- *zero layout height:* `NestList.height == sum(row heights)` (the design
  overlays the separators). The absolute 224 px is the UI check's job — under
  the block test font every row wraps, so only the identity is meaningful.
- *wrapped rows:* at **320 dp / scale 1.3** the rows grow past 56 px and each
  line still lands on its own (new) row top — catches a cached 56 px offset.
- *semantics:* each row is still **one merged node** labelled
  `title\nsubtitle`, not a button, with no tap/long-press/focus action — the
  `Stack` + `Positioned` must not split, duplicate or make the row tappable.
- *design-derived geometry:* `the overlay geometry is the design CSS rule, not
  a guess` reads `design/html-source/components.css`, extracts
  `.list-row + .list-row::before { … }` and asserts the app's `Positioned`
  matches the design's own `left`/`height`/`top: 0`/`right: 0` and
  `background: var(--line)`. If the design rule ever moves, the test fails
  loudly instead of the geometry drifting again.

### 2. Owner alignment on the rewritten list

`$width.dp: the promise rows fill the list card edge` (320/390/430):
`NestList`'s inner `Column` is `CrossAxisAlignment.center` and P04 now hands
it a single `Column` child — if that child were narrower than the card the rows
would sit inset against the 20 px gutters. Every row's left and right edges now
equal the card's (owner ALIGNMENT rule). Passes at all three widths.

### 3. The transactional upsert (P04-9)

- `overlapping first-run writes settle on the last value` — run twice (last
  write `false` and `true`): two concurrent `setCrashConsent` calls on a
  `Seed.fresh` database must end with **exactly one row** holding the **second**
  value. Before the transaction the first INSERT could win; now the
  UPDATE-then-conditional-INSERT pair is atomic, and this pins last-write-wins.
- The pre-existing `concurrent first-run writes still leave exactly one row`
  and `the first-run upsert creates one row and reuses it` still pass.

### 4. Re-verified (no change needed)

- Bloc: loading→loaded, empty stream, stream error, items without a `crash`
  row, `CrashToggled` on/off, both write-failure directions, optimistic emit,
  revert-to-stored (P04-8), error cleared by the next emission, Drift ON→OFF.
- Repository: default OFF (ICO), 5 rows, crash row mirrors the setting, other
  columns untouched, first-run upsert single-row/idempotent, `Seed.empty`,
  `Seed.demo`.
- Widget: light + dark, 320/390/430 × scale 1.0/1.3, 320×568 short screen,
  empty/loading/error/first-run states through the real router, every tap
  destination (back with and without history → `/create-account`, `Continue` →
  `/add-children` in loaded/loading/failure, toggle stays on `/privacy`, dialog
  opened and dismissed by `Close` and barrier), semantics on the icon buttons
  (`Back`, notice link, shield, toggle) with ≥ 44 px targets, 20 px gutters,
  bottom-CTA surface to the physical edge in both themes, copy fidelity
  character-by-character against the HTML source.

## Results

```
dart format --output=none --set-exit-if-changed .  → 362 files, 0 changed
flutter analyze                                    → No issues found! (ran in 2.6s)
flutter test test/features/privacy_consent/        → 00:02 +118 ~2: All tests passed!
flutter test (whole app)                           → 00:11 +645 ~2: All tests passed!
```

Zero failures. The 2 skips are the shared-blocked proofs; run deliberately they
fail exactly as documented and nothing else:

```
flutter test --run-skipped test/features/privacy_consent/p04_bugs_test.dart
→ 00:02 +14 -2   (P04-2, P04-7)
```

## Bugs found this iteration

**None.** No new defect surfaced in the iteration-4 tree. The separator
overlay, the transactional upsert and the single-Column list all behave
exactly as the design and the fixes describe — the geometry, ownership,
semantics and concurrency contracts above are now pinned by green tests.

## Remaining defects — outside RULES §1, tracked, still open

| Id | Severity | Defect | Blocker |
|---|---|---|---|
| P04-2 | major | Promise row 4 renders an **empty** peach tile; the design draws a trash glyph. | Needs `app/assets/icons/ic_trash.svg` + `NestIcons.trash` from `shared/shared_requests_batch1`, still absent from this worktree (13:42 UPDATE). RULES §1 keeps `app/assets/**` and `core/**` off limits. `SHARED_REQUEST.md` §1. Proof `[P04-2]` skipped; the flip instructions are encoded in the proof and in the row-glyph test. |
| P04-7 | minor | `privacy_shield.svg` bakes the light sky tint + white body, so dark mode renders the light artwork. | Shared asset (themed shield in the same batch). `SHARED_REQUEST.md` §2. Proof `[P04-7]` skipped. |

Resolved and now green: P04-1 (first-run write), P04-3 (header height),
P04-4 (separator drift), P04-5 (double tap), P04-6 (false "it stays off"),
P04-8 (revert target), P04-9 (non-atomic upsert).

Orchestrator notes: item 1 is covered by tests as far as RULES §1 allows; item 2
is pixel-exact (`[P04-3]` green); item 3 is now exact (separator overlay
derived from the design CSS); item 4 owner rules are asserted in both themes —
including the new row-edges-equal-card-edges alignment check.

## Notes (not defects)

- Widget tests run without the bundled Inter/Nunito faces, so the block test
  font widens every line and pushes the opt card below the fold although it
  fits on a 390×844 device; helpers scroll with `ensureVisible` before tapping
  the toggle. Absolute row heights are therefore asserted on the device (UI
  check), never in widget tests — only identities and offsets are.
- `SemanticsHandle` from `tester.ensureSemantics()` must be disposed **inside**
  the test body: `addTearDown` runs after the end-of-test semantics check.
- Drift reads inside `testWidgets` need `tester.runAsync`, and a
  `Future.delayed` must never outlive the test.
- The copy and separator tests read `design/html-source/**` at runtime; if the
  app is ever tested outside the repo they fail loudly with the searched paths
  rather than passing silently.

VERDICT: PASS

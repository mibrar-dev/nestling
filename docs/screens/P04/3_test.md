# P04 · Privacy consent — test notes (STAGE 3, iteration 9)

Feature `privacy_consent` · route `/privacy` · parent mode.
Scope this stage: `app/test/features/privacy_consent/**` + `docs/screens/P04/**`
(RULES §1). No production code touched; nothing patched.

Inputs re-verified: `1_plan.md`, `2_build.md` (iteration 9 integrate — fixed
P04-11), `5_ui.md`, `6_bugs.md`, `FIXES_8.md`, `SHARED_REQUEST.md` (§7) and
the mandatory `ORCHESTRATOR_NOTES.md`, including the new **LETTER SPACING**
rule (main `fd92d95`: `NestType` styles default to `letterSpacing: 0` because
the design CSS has no tracking; never add Material tracking back; call sites
apply tracking explicitly only where a screen's CSS asks for it).

## Test inventory — 168 P04 tests, 0 skipped, all green

| File | Tests | Role |
|---|---|---|
| `privacy_consent_bloc_test.dart` | 20 | every event/state path of `PrivacyConsentBloc` |
| `privacy_consent_repository_test.dart` | 13 | Drift contract on the in-memory DB (`Seed.demo` / `empty` / `fresh`) |
| `privacy_consent_view_test.dart` | 27 | copy, light+dark, 320/390/430 × 1.0/1.3 matrix, statuses, navigation, a11y, gutters, bottom edge |
| `privacy_consent_view_contract_test.dart` | 39 | states through the real router, every tap destination, optimistic switch, failure captions, separator overlay, row glyphs, nav geometry, dialog stress, short screens, alignment |
| `privacy_consent_copy_test.dart` | 5 | copy fidelity against the HTML design source (COPY rule) |
| `privacy_consent_artwork_test.dart` | 11 | artwork provenance + painted-pixel theme proof |
| `privacy_consent_a11y_test.dart` | 28 | contrast, system text scale, screen-reader shape, token hygiene, bundled-font rules |
| `privacy_consent_geometry_test.dart` | 8 (2 new) | design pixel geometry at real font metrics, letter-spacing contract, dialog title, design-CSS tracking |
| `p04_bugs_test.dart` | 17 | the eleven bug proofs + clean-behaviour guards |

## What the iteration-8 finding turned into

P04-11 (Material tracking in 14 of 15 runs) is **fixed**: the view wraps the
Scaffold body in `DefaultTextStyle.merge(letterSpacing: 0)`, and the core
shared fix landed on main (`NestType._inter/_nunito` now default
`letterSpacing: letterSpacing ?? 0`). The three red contract tests from
iteration 8 are green, and — importantly — **the exact-geometry suite still
passes unchanged**: chevron 73, h1 107/34, standfirst 149/24, shield 187/84,
rows 287/343/399/455 × 56, list 224, opt card 527/94, title one 22 px line,
CTA 708→844, gutters 20. Removing the tracking moved nothing, which confirms
the fix is cosmetic-only and the layout was always the design's.

Two tests added this stage, both about the new rule:

- `the inlined dialog title is the NestModal title` — `showDialog`'s Material
  re-applies the theme's tracked `bodyMedium` nearer the content than the
  screen's ambient style, so `NestModal(title:)` is unreachable from the screen
  and the view renders the title inline. That swap is invisible unless pinned,
  so the test asserts the inline title is still the shared slot: same
  `NestType.h3` size/weight/family, `ink`, centred, `maxLines: 3`, ellipsis,
  zero tracking — and that the four promise lines still follow it.
- `no class P04 uses declares letter-spacing` — the app-side tests prove what
  the screen renders; this one reads
  `design/html-source/components.css` and asserts none of the ten classes P04
  uses (`.h1 .body .body-s .caption .list-title .list-sub .opt-title .opt-sub
  .btn .footnote`) declares tracking, so the expectation tracks the design
  instead of silently disagreeing if a future edit adds it (only `.display`
  and `.status-time` use `-.01em`, and P04 uses neither).

## Re-verified (unchanged, all green)

- **Bloc (20)** — loading→loaded, empty stream, stream error, items without a
  `crash` row, both toggle directions, optimistic emit, revert-to-stored,
  error clearing, Drift ON→OFF round trip.
- **Repository (13)** — default OFF, 5 rows, crash-row mirror, untouched
  columns, transactional first-run upsert with last-write-wins, single-row,
  idempotent, racing writes, `Seed.empty` / `Seed.demo`.
- **Views** — light + dark at 320/390/430 × 1.0/1.3 plus a 320×568 short
  screen and a 1.6 system scale (clamped to 1.3); empty/loading/error/first-run
  states through the real router; every tap destination (back with and without
  history → `/create-account`, `Continue` → `/add-children` in
  loaded/loading/failure, toggle stays on `/privacy`, dialog opened and
  dismissed by `Close` and barrier); semantics labels and ≥ 44 px targets;
  separator overlay derived from the design CSS; trash glyph path provenance;
  painted-pixel shield theming; copy character-by-character; contrast;
  token hygiene; bundled-font rules; owner alignment and bottom-edge rules.
- **Bug proofs** — `[P04-1]` … `[P04-11]` all green, zero skips, so
  `--run-skipped` is a no-op and nothing hides behind a skip.

## Results

```
dart format --output=none --set-exit-if-changed .  → 376 files, 0 changed
flutter analyze                                    → No issues found! (ran in 6.6s)
flutter test test/features/privacy_consent/        → 00:05 +168: All tests passed!
flutter test (whole app)                           → 00:22 +862: All tests passed!
```

## Bugs found this iteration

**None.** The iteration-9 tree passes every P04 test, including the three that
were red in iteration 8 and the exact-geometry suite that guards against a
regression from the fix itself.

## Open items

None in P04 scope. `SHARED_REQUEST.md` §7's shared half is now satisfied in
core (`NestType` defaults to 0); its P04-local consequence is closed by the
screen's ambient `DefaultTextStyle.merge`. Orchestrator notes 1–4 hold, COPY is
locked to the HTML source, LETTER SPACING is pinned by four tests (three
app-side, one design-side), CHILD ORDER and PIP are N/A here.

## Notes

- Loading the bundled faces with `FontLoader` is per-test-isolate, so
  `privacy_consent_geometry_test.dart` measures device metrics while the other
  files keep the harness font and their relational assertions. Absolute
  geometry belongs to the geometry file and the UI check.
- `SemanticsHandle` must be disposed inside the test body; Drift reads and
  `Picture.toImage` inside `testWidgets` need `tester.runAsync`; a
  `Future.delayed` must never outlive a test.
- Light `lilac` on `lilacTint` measures 3.40:1 — compliant for the 24 px glyph
  and pinned by the contrast test; a shared palette value, so changing it is
  an orchestrator decision.

VERDICT: PASS

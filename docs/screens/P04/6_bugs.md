# P04 · Privacy consent — bug hunt (Stage 6, iteration 1)

Route `/privacy` · feature `privacy_consent` · parent mode · seeds `demo` and
first-run (`fresh`-equivalent, empty DB). **No screen code was changed.**
Added `app/test/features/privacy_consent/p04_bugs_test.dart`: **7 skipped bug
proofs** (each FAILS against the iteration-1 tree) plus **5 passing checks**
for the classes I cleared. Run the failing proofs with:

```
flutter test --run-skipped test/features/privacy_consent/p04_bugs_test.dart
```

Method: read the view/bloc/repository, the shared `Nest*` components, the
router/DI/schema/seed and both design sources; measured the design PNGs
(`design/screens/{light,dark}/P04-privacy.png`) and the committed simulator
shots (`docs/screens/P04/ui/app_{light,dark}_1.png`, `p04-{light,dark}.png`)
with pixel probes; every behavioural claim was first reproduced with a
throwaway test before it was written up. `ORCHESTRATOR_NOTES.md` (written
11:47) is honoured: items 1–3 are findings P04-2/P04-3/P04-4 below.

New findings: **P04-1 … P04-7** (5 major, 2 minor). The screen cannot pass:
`VERDICT: FAIL`.

## New findings

### P04-1 — the crash-report opt-in is silently dropped on a first run — MAJOR

- **Carried from stage 3** (BUG(P04-1)); still open. Re-proved this stage at
  the widget level.
- **Where:** `app/lib/features/privacy_consent/data/privacy_consent_repository_impl.dart:63`
  (`setCrashConsent` → `UPDATE settings WHERE family_id = 'fam1'`), surfaced
  by `privacy_consent_view.dart:151-163`.
- **Why:** a real first launch is an empty database. `Seed.fresh`
  (`app/lib/core/data/seed.dart:94-104`) writes only `app_state`, and nothing
  before P04 creates the `fam1` settings row (`AuthRepositoryImpl.createAccount`
  inserts a `members` row only). The UPDATE matches zero rows, the stream never
  re-emits, and the toggle stays OFF with no error — the screen's only
  interactive control is a no-op on the exact flow it belongs to.
- **Repro (test):** `--run-skipped … --plain-name '[P04-1]'` →
  `setUpTestScope(seedDemo: false)` + `pumpAppRoute('/privacy')` + tap
  `p04_crash_toggle` → expected stored `true`, actual `false`. The existing
  repository-level red test is
  `privacy_consent_repository_test.dart:105` (left red on purpose by stage 3
  as the loop's forcing function; it is the one red test in the suite).
- **Failing test:** `[P04-1] first run: the toggle tap is actually stored`.
- **Fix (feature-local, P04 data/ is editable):** follow the
  `AppSession._write` precedent — UPDATE, and when `changed == 0` insert the
  `settings` row (`insertOnConflictUpdate`, or `insert … onConflictDoUpdate`).
  `watchItems()` already watches that query, so the row appearing re-emits and
  the existing bloc path flips the toggle with no optimistic emit. Review
  stage 4 has the exact snippet; `SettingsRepositoryImpl._write` (P16) shares
  the defect and needs the same shared helper (SHARED_REQUEST §4).

### P04-2 — promise row 4 renders an empty peach tile (no trash glyph) — MAJOR

- **Where:** `privacy_consent_view.dart:104-114` — the `_PromiseRow` for
  "Delete everything anytime" has no `leadingAsset`; the root cause is the
  missing shared asset (`app/assets/icons/ic_trash.svg` +
  `NestIcons.trash`). `ic_bin` is a wheelie bin and `ic_basket` a laundry
  basket; neither matches the HTML glyph
  `M4 7h16M9.5 7V5h5v2M6.5 7l1 13h9l1-13` (peach tile, `aPeach` ink).
- **Repro (test):** `--run-skipped … --plain-name '[P04-2]'` → 4 `NestIcon`s
  expected, 3 found. Simulator: `docs/screens/P04/ui/app_light_1.png` /
  `app_dark_1.png` row 4 = blank peach square; design = peach tile with the
  trash glyph.
- **Failing test:** `[P04-2] every promise row renders its leading glyph`.
- **Fix:** land SHARED_REQUEST §1 (`ic_trash.svg` + `NestIcons.trash`) and
  pass `leadingAsset: NestIcons.trash, tint: NestTileTint.peach`; delete the
  `TODO(P04)`; then extend the proof to assert the icon asset name. Until the
  shared asset exists no correct in-scope substitute exists (orchestrator
  note 1 calls it "red-ink bin glyph").

### P04-3 — compact nav bar is 16 px short; the whole header block sits high — MAJOR

- **Where:** `privacy_consent_view.dart:28-41` uses
  `NestNavBar(compact: true)`; the component's compact branch
  (`nest_nav_bar.dart:42-82`) is `minHeight: 44` + horizontal padding only.
  The design's `.nav-bar.compact` is `min-height: 52; padding: 4px 12px 12px`
  → **60 px**, so the scroll area starts at 47 + 60 = 107, not 91.
- **Evidence (logical px, design → app):** back-chevron centre 73 → 69
  (screen probe), h1 cap top 112.3 → 96.3, subtitle 155 → 139, shield circle
  188.3–269.3 → 172.3–253.3, list top 287 → 271. Uniform −16 px; the bottom
  CTA is bottom-anchored and matches (Continue top 690 in both). In the widget
  proof, h1 line box 107 → 91 and chevron centre 73 → 69.
- **Repro (test):** `--run-skipped … --plain-name '[P04-3]'` → expected
  chevron centre 73, actual 69; expected h1 top 107, actual 91.
- **Failing test:** `[P04-3] header block matches the 60px design bar`.
- **Fix (shared, core):** compact bar → `minHeight: 52` with
  `EdgeInsets.fromLTRB(s3, s2, s3, s3)`, and drop the `title: ''` workaround
  in the view (SHARED_REQUEST §5, same file as §3). A local 4/12 padding shim
  around `NestNavBar` would match P04 but leaves every other compact screen
  broken — prefer the shared fix.

### P04-4 — real list dividers add 3 px; rows drift 57 px apart, opt card 13 px high — MAJOR

- **Where:** `NestList` (`nest_list_row.dart:131-135`) inserts
  `Divider(height: 1)` widgets between rows. The design overlays a 1 px
  `::before` on the row boundary, so 4 rows stay exactly 4 × 56 = 224 px;
  the app list is 227 px and every row after the first starts 1 px lower.
- **Evidence (logical px):** widget proof: list 427 = rows 424 + 3 (the sum
  invariant). Simulator: promise-tile tops 279 / 336 / 393 / 450 → 57 px
  apart, design 295 / 351 / 407 / 463 → 56 px apart; the opt card top is 514
  vs the design 527 (orchestrator target ≈ 528). Row content itself is
  correct (56 px, tiles 40/r12, divider indent 72).
- **Repro (test):** `--run-skipped … --plain-name '[P04-4]'` → expected
  `424.0` (sum of the four rows), actual `427.0`.
- **Failing test:** `[P04-4] dividers do not add height to the promise list`.
- **Fix (shared, core):** paint the separator over the boundary (Stack /
  overlay / negative offset) so it contributes no layout height; keep
  `indent: 72` and the `line` token (SHARED_REQUEST §6). No in-scope P04 fix
  exists: re-implementing the list would violate the design-system rule.

### P04-5 — a rapid double-tap on the crash switch loses the second tap — MINOR

- **Where:** `NestToggle.onTap: () => changed(!value)`
  (`nest_toggle.dart:35`) plus the bloc's deliberate no-optimistic-emit rule
  (`privacy_consent_bloc.dart:42-55`). Until the Drift stream re-emits, the
  widget still shows the old `value`, so a second tap before the round-trip
  requests the same value again: OFF → tap → tap ends ON instead of OFF.
- **Repro (test):** `--run-skipped … --plain-name '[P04-5]'` — tap twice with
  a frame between (the stream cannot re-emit under fake async without
  `runAsync`), then flush Drift: expected stored `false` (two toggles), actual
  `true` (the same value written twice). On a device the window is the
  write → stream → rebuild round-trip (1–2 frames; larger under load).
- **Failing test:** `[P04-5] double-tapping the switch toggles twice`.
- **Fix options (feature-local):** dispatch a value-free toggle event whose
  handler flips the current `state.crashConsent`, and/or add an in-flight
  guard while a write is pending, and/or emit the requested value
  optimistically (keep the RULES §4 no-load-event rule; the stream still
  reconciles). Product call: a debounced single tap is also acceptable if the
  design says so, but then the double tap must not leave the opposite state.

### P04-6 — a failed OFF write tells the parent "it stays off" while it stays ON — MAJOR

- **Where:** `privacy_consent_view.dart:167-176` — the failure caption is the
  fixed string "Oops — your choice wasn't saved. Continue anyway; it stays
  off."; `_onCrashToggled` keeps the prior `crashConsent` on error
  (`privacy_consent_bloc.dart:48-55`).
- **Why:** the caption's second sentence is only true when the prior state was
  OFF. When the parent tries to turn crash reports OFF and the write fails,
  the stored opt-in remains ON — the screen then makes a false statement
  about consent (ICO/Children's-Code messaging), even though the switch
  visibly stays ON.
- **Repro (test):** `--run-skipped … --plain-name '[P04-6]'` — fake repo emits
  a crash row with `enabled: true`, `setCrashConsent` throws; tap the toggle:
  `NestToggle.value` is `true` and `textContaining('stays off')` finds the
  caption.
- **Failing test:** `[P04-6] a failed OFF write never claims "it stays off"`.
- **Fix:** make the caption state-aware — e.g. when `state.crashConsent` is
  true: "Oops — your choice wasn't saved. Crash reports are still on.
  Continue anyway."; when false keep the spec'd line. (Plan §d's copy assumed
  the OFF-by-default path; check the wording with design.)

### P04-7 — dark mode renders the light-baked shield illustration — MINOR

- **Where:** `privacy_consent_view.dart:74-78` renders
  `NestlingIllustrations.privacyShield` (same asset both themes).
  `privacy_shield.svg` bakes the light sky-tint disc `#E6EFFE` and a white
  shield body (`#FFFFFF`); the dark design uses `#1A2A4A` + `#1F1C2E`.
- **Evidence (RGB probes on the committed shots):** disc at (165, 229):
  design dark `#1A2A4A` vs app dark `#E6EFFE`; shield body: design
  `#1F1C2E` vs app `#FFFFFF`. In `app_dark_1.png` the illustration is a
  glaring light blob on the dark surface.
- **Repro (test):** `--run-skipped … --plain-name '[P04-7]'` — pump dark, take
  the shield's `SvgAssetLoader` asset, load its XML in `runAsync`; expected
  "not contains `#E6EFFE`", actual the XML contains it (and `#FFFFFF`).
- **Failing test:** `[P04-7] the dark-mode shield does not bake light colours`.
- **Fix (shared asset):** a dark variant selected by theme, or a token-driven
  circle/body layer (SHARED_REQUEST §2; extend it to cover the body, not just
  the circle). Do not hand-edit core assets from P04. When the fix lands the
  proof should look up the dark asset (e.g. `privacy_shield_dark.svg`) and
  assert the new colours.

## Verified clean this iteration (passing proofs in the same file)

- **Parent/kid guard:** kid mode + `setAppMode('kid')` + deep link `/privacy`
  → `/parental-gate` (`/privacy` is in `_onboardingLocations`, so the guard
  covers it); no bypass found.
- **Deep link / back:** `/privacy` with no history renders and the chevron
  falls back to `/create-account` exactly as plan §c specifies; with history
  it pops (stage-3 coverage still green).
- **Restart persistence:** turn the opt-in ON, dispose the route, reopen
  `/privacy` on the same database → the switch is ON again. (The first-run
  case is the P04-1 bug; `Seed.demo`/`empty` are fine.)
- **Async gap (emit after close):** a write that fails after the parent has
  left is caught; bloc 9.2.1's handler emitter drops emits once the bloc
  closes (probe: delayed-throw repository inside `runZonedGuarded`, no zone
  error). A `Completer` completed with an error *after* `bloc.close()` can be
  reported as unhandled by the harness, but the production shape
  (repository awaits internally) is clean — not a bug.
- **Rapid double tap on the notice link:** two synchronous taps open exactly
  one dialog (barrier backs the second tap); Close returns to `/privacy`.
- **Text scale 1.3 / width 320:** the stage-2/3 matrix (320/390/430 × 1.0/1.3,
  320×568) is still green, including the dialog — no overflow found.
- **Dark-mode contrast:** tokens only; link `sky` 7.21:1, danger caption
  7.37:1 on dark paper, toggle track/knob fine. The one dark defect is the
  shared shield artwork (P04-7).
- **N/A classes with no surface here:** 0/1/6 children, long UK names, £0.00 /
  £999.99 / 9 999 coins, empty lists, money rounding and Europe/London / BST —
  P04 renders fixed copy and one settings boolean; it reads no child, quest or
  ledger data and no dates. The demo seed values are irrelevant to this
  screen by design.

## Carried items (stages 3–5, still open — not re-proved here)

- SHARED_REQUEST §1 (trash asset) = P04-2; §2 (dark shield) = P04-7;
  §3 (`NestNavBar` null title) folded into §5; §4 (first-run settings row)
  = P04-1 — review stage 4 shows the fix is feature-local and must be done by
  P04's own data layer, not deferred.
- New SHARED_REQUEST §5 (compact nav bar 60 px) and §6 (`NestList` divider
  overlay) were appended this stage with the measured evidence above.
- Review findings 4–8 (token literals in `_PromiseRow`, `'crash'` string
  literal in three places, `copyWith` can never clear `errorMessage`, the
  notice dialog is one run-on sentence instead of the four bullets the plan
  specifies, dead `PrivacyConsentPlaceholderCard`) are polish; review has the
  detail and none is user-blocking.
- **Suite state at hand-off:** `dart format --set-exit-if-changed .` → 356
  files, 0 changed; `flutter analyze` → No issues found; `flutter test
  test/features/privacy_consent/` → **76 passed, 7 skipped, 1 failed** — the
  single failure is the deliberate P04-1 proof
  (`privacy_consent_repository_test.dart:105`); full `flutter test` → **555
  passed, 7 skipped, 1 failed** (same single cause). My 7 new bug proofs are
  `skip`-marked so they add no red; every one fails when run with
  `--run-skipped`, as reported above. Iteration 2 must fix P04-1 (which turns
  the existing red test green) and un-skip the proofs it fixes.

## Verdict

Five majors: the only interactive control is a no-op on first run (P04-1,
feature-local fix), the fourth promise row has no glyph (P04-2), the whole
header block is 16 px out of position (P04-3), and the list's real dividers
break the vertical rhythm (P04-4), plus the false "it stays off" consent
message (P04-6). Two minors: the double-tap toggle race (P04-5) and the
light-baked dark shield (P04-7). The owner alignment rule and the orchestrator
notes 1–3 are not met yet, and the suite still carries the deliberate
first-run red test. Nothing here is a process item.

VERDICT: FAIL

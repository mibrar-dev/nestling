# P04 · Privacy consent — test notes (STAGE 3, iteration 1)

Feature `privacy_consent` · route `/privacy` · parent mode.
Scope: `app/test/features/privacy_consent/**` only (RULES §1). No production
code touched — the one real bug found is recorded, not patched.

## Test files (72 P04 tests)

| File | Tests | Covers |
|---|---|---|
| `privacy_consent_bloc_test.dart` | 16 | every event/state path of `PrivacyConsentBloc` |
| `privacy_consent_repository_test.dart` | 7 | Drift contract, in-memory DB (`Seed.demo` / `empty` / `fresh`) |
| `privacy_consent_view_test.dart` | 27 (pre-existing from STAGE 2) | copy, theming, 320/390/430 × 1.0/1.3 matrix, statuses, navigation, a11y, gutters, bottom edge |
| `privacy_consent_view_contract_test.dart` | 22 (new) | states through the real router, every tap destination, toggle lifecycle vs Drift + semantics, dialog stress, short screens, promise-row geometry, control a11y |

### Added this stage

**Bloc (`blocTest` + plain `test`)**

- `PrivacyConsentCrashToggled` props/equality; `LoadRequested` equality.
- Items stream **without** a `crash` row → `crashConsent == false`.
- `CrashToggled(false)` (the OFF path) delegates `setCrashConsent(false)` and
  emits **no** optimistic state — the state only moves when the stream re-emits.
- A failed OFF write keeps the prior ON consent, prior items and the message.
- Drift round-trip ON → OFF through one bloc (`watchCrashConsent` ends `false`).
- Existing load paths re-checked: loading→loaded, empty stream, stream error.

**Repository (in-memory Drift)**

- `Seed.demo` / `Seed.empty`: consent off by default (ICO), 5 rows, crash row
  mirrors the setting, other settings columns untouched by a write.
- **`Seed.fresh` (first run): consent write is silently lost — BUG(P04-1).**

**Widget — states through the real app router (DI repository override)**

- empty items list → full static screen, no failure caption, toggle live;
- stream error → inline danger caption, toggle disabled, `Continue` still
  reaches `/add-children`;
- no seed at all (first-run scope) → screen renders, consent off;
- still loading → content renders, toggle disabled, `Continue` still works.

**Widget — every tap destination**

- back **with** history → pops to `/create-account`; back **without** history →
  the `canPop` fallback lands on `/create-account`;
- `Continue` → `/add-children` (loaded, loading and failure states);
- crash toggle → stays on `/privacy`, writes ON then OFF through Drift, and the
  `toggled` semantics flag flips both ways;
- notice link → dialog, dismissed by `Close` **and** by the barrier, both return
  to `/privacy`;
- the toggle dispatches `PrivacyConsentCrashToggled` (recording repository).

**Widget — themes, widths, scales, states**

- light + dark; widths 320/390/430 at text scale 1.0 and 1.3 (STAGE 2 matrix
  kept) plus 320×568 short screen at 1.3 (scrolls the opt card into reach and
  taps it);
- dark toggle write-through, no `PipAvatar` and no v1 `pip_stage_*.svg`;
- promise-row geometry: 4 tiles 40×40 r12 in leaf/lilac/sky/peach order, three
  dividers at indent 72, row min-height 56, row 4 tile reserved with **no**
  stand-in glyph (shared item 1), titles/subs `softWrap` with no `maxLines`
  (SPACING_SPEC §9.3/§9.4 — wrap, never ellipsise), shield 84×84;
- dialog at 320/1.3: no overflow, `Close` keeps the 44 px parent target, dialog
  restates all four promises.

**Widget — accessibility**

- `Back` is a labelled `isButton` node ≥ 44×44; the notice link is a labelled
  button inside a 44×44 constrained box; the toggle announces `isEnabled` and
  its `isToggled` state; the h1 is a header (STAGE 2); the four promise rows are
  **not** announced as buttons; every tap target ≥ 44 (≥ 56 kid rule N/A —
  parent screen).
- Alignment: 20 px gutters shared by headline, `NestList`, opt card and CTA at
  320/390/430; bottom-CTA surface reaches the physical edge in both themes
  (owner rule), asserted in STAGE 2.

## Results

```
dart format --output=none --set-exit-if-changed .   → 355 files, 0 changed
flutter analyze   → No issues found! (ran in 2.5s)
flutter test test/features/privacy_consent/
                  → 00:01 +71 -1: Some tests failed.
flutter test (whole app)
                  → 00:10 +550 -1: Some tests failed.
```

71 of the 72 P04 tests pass. The single failure is the deliberate red test for
BUG(P04-1) below; no other feature regressed.

## Bugs found

### BUG(P04-1) — crash-consent opt-in is silently dropped on a first run — MAJOR

- **Where:** `app/lib/features/privacy_consent/data/privacy_consent_repository_impl.dart:63-67`
  (`setCrashConsent` → `UPDATE settings WHERE family_id = 'fam1'`),
  surfaced by `app/lib/features/privacy_consent/presentation/views/privacy_consent_view.dart:151-163`.
- **Why:** a real first launch starts from an empty database — `Seed.fresh`
  (`app/lib/core/data/seed.dart:96-104`) writes only the `app_state` row — and
  nothing before P04 creates the `fam1` `settings` row (`AuthRepositoryImpl.createAccount`
  inserts a `members` row only, `app/lib/features/auth/data/auth_repository_impl.dart:36-52`).
  The UPDATE therefore matches **zero rows**, the stream never re-emits, and the
  toggle stays OFF. P04 is the first screen in the onboarding flow that writes a
  setting, so it is the first screen to hit this.
- **Repro (test):**
  `app/test/features/privacy_consent/privacy_consent_repository_test.dart:105`
  `BUG(P04-1): consent persists on a first-run database` — red on purpose.
- **Repro (app):** `tools/screens/shot.sh app /privacy out <udid> light fresh parent`,
  tap the crash-report toggle → it never turns on, no error, nothing written.
  Equivalent widget scope: `setUpTestScope(seedDemo: false)` + tap
  `p04_crash_toggle` → `value` stays `false` (verified while writing the tests).
- **Scope of the loss:** only the optional crash-report flag (ICO nudge rule, so
  no legal harm), but the screen's only interactive control is a no-op on the
  very flow the screen belongs to, with no feedback.
- **Fix options (not applied, test stage does not patch):** upsert in the P04
  repository (`insertOnConflictUpdate`, or `insert … onConflictDoUpdate` when the
  update affects 0 rows) or create the `fam1` family + settings rows during
  onboarding bootstrap. `SettingsRepositoryImpl._write` (P16) has the same
  UPDATE-only shape. Filed as `SHARED_REQUEST.md` item 4.

## Observations (not bugs — no test change needed)

- **Sticky error string:** `PrivacyConsentState.copyWith`
  (`presentation/bloc/privacy_consent_state.dart:19-31`) uses
  `errorMessage ?? this.errorMessage`, so a message can never be cleared. The
  view keys the caption on `status == failure`, so there is no visible effect
  today; worth knowing before a retry path is added.
- **No retry after a failed write:** a `setCrashConsent` error drops the bloc
  into `failure`, which disables the toggle for the rest of the screen's life.
  This is what plan §d specifies ("it stays off", caption: "Continue anyway; it
  stays off"), and the test suite now pins it.
- **Test-font geometry:** widget tests run without the bundled Inter/Nunito
  faces (`GoogleFonts.config.allowRuntimeFetching = false` in `test_scope.dart`),
  so the block test font makes every glyph full-em wide. The opt card sits
  below the fold in tests although it fits on a 390×844 device (see
  `docs/screens/P04/ui/p04-light.png` vs `design/screens/light/P04-privacy.png`).
  Tests therefore scroll with `ensureVisible` before tapping the toggle; this is
  a harness artefact, not a screen defect.

## Open shared dependencies (unchanged by this stage)

- SHARED_REQUEST 1 — `ic_trash.svg` + `NestIcons.trash` still missing; row 4
  keeps the peach tile with no stand-in glyph (asserted by
  `promise row geometry`). Blocks pixel fidelity. When it lands, add a
  `NestIcon` assertion for row 4 and drop the empty-tile expectation.
- SHARED_REQUEST 2 — dark `privacy_shield.svg` circle bakes the light tint.
- SHARED_REQUEST 3 — `NestNavBar(compact: true, title: null)` crashes
  (Spacer inside Expanded); the view works around it with `title: ''`.

VERDICT: FAIL

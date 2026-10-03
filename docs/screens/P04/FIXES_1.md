# Fix list after iteration 1

## From 3_test.md
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


## From 4_review.md
# P04 · Privacy consent — QA code review (STAGE 4, iteration 1)

Feature `privacy_consent` · route `/privacy` · parent mode · branch `screen/P04`.
Reviewed surface: `git diff main...HEAD` **plus** the uncommitted working-tree
build and the untracked `app/test/features/privacy_consent/**` (the loop commits
each iteration, so the effective change set is both).

Checks run for this review:

```
dart format --output=none --set-exit-if-changed lib/features/privacy_consent \
     test/features/privacy_consent      → 16 files, 0 changed
flutter analyze                          → No issues found! (ran in 5.4s)
flutter test test/features/privacy_consent/
                                          → 00:01 +71 -1: Some tests failed.
tools/screens/compare.py (light)         → mean diff 7.52%
                                           band 0 0-105   2.74%
                                           band 1 105-211 13.18%   <-- worst
                                           band 2 211-316  6.97%
                                           band 3 316-422 12.39%   <-- worst
                                           band 4 422-527  9.74%
                                           band 5 527-633  9.79%
                                           band 6 633-738  0.40%
                                           band 7 738-844  4.84%
```

Pixel measurements below are logical px (PNG ÷ 3) taken from
`design/screens/light/P04-privacy.png` vs `docs/screens/P04/ui/p04-light.png`.

---

## Findings

### 1. BLOCKER — the crash-report opt-in is silently dropped on a real first run, and a red test is left in the tree

- **Where:**
  `app/lib/features/privacy_consent/data/privacy_consent_repository_impl.dart:62-67`
  (`setCrashConsent` → `UPDATE settings WHERE family_id = 'fam1'`), surfaced by
  `app/lib/features/privacy_consent/presentation/views/privacy_consent_view.dart:151-163`,
  pinned by the failing test
  `app/test/features/privacy_consent/privacy_consent_repository_test.dart:105`.
- **Evidence:** `flutter test test/features/privacy_consent/` → `+71 -1`, the single
  failure being `BUG(P04-1): consent persists on a first-run database`. RULES §7
  done-criteria #1 requires `flutter test` → all pass, so the whole-app suite is
  red on this branch and it cannot land.
- **Why it matters:** the screen's only interactive control is a no-op on the very
  flow the screen belongs to. On first launch `Seed.fresh`
  (`app/lib/core/data/seed.dart:96-104`) writes only the `app_state` row, and
  nothing before P04 creates the `fam1` `settings` row
  (`AuthRepositoryImpl.createAccount` inserts a `members` row only,
  `app/lib/features/auth/data/auth_repository_impl.dart:36-52`), so the UPDATE
  matches zero rows, the stream never re-emits, the toggle snaps back to OFF and
  **no error is shown**. This is also the ICO/Children's-Code control, so a
  silently-dropped opt-in is exactly the failure mode that rule cares about.
- **In P04's scope, not shared:** RULES §1 allows
  `app/lib/features/privacy_consent/data/**` ("repository interface + impl") and
  `SHARED_REQUEST.md` item 4 itself labels the file "feature-local,
  screen-agent territory". Filing it and deferring is not the right move; the
  screen can and must fix it.
- **Concrete fix** (`privacy_consent_repository_impl.dart`):

  ```dart
  @override
  Future<void> setCrashConsent({required bool consent}) async {
    final changed = await (_db.update(_db.settings)
          ..where((s) => s.familyId.equals(Seed.familyId)))
        .write(SettingsCompanion(crashReportConsent: Value(consent)));
    if (changed == 0) {
      await _db.into(_db.settings).insert(
        SettingsCompanion.insert(
          familyId: Seed.familyId,
          crashReportConsent: Value(consent),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
  }
  ```

  `watchItems()` already watches that query, so the row appearing re-emits and the
  existing bloc path (`_crashFrom` → `crashConsent`) flips the toggle with no
  optimistic emit and no event re-add (RULES §4). Drift does not enable
  `PRAGMA foreign_keys` (`app/lib/core/data/app_database.dart:280-286`), so the
  insert succeeds while the `families` row is still missing; if FKs are ever
  turned on, add an `insertOrIgnore` of `FamiliesCompanion.insert(id: Seed.familyId)`
  first. Then the red test goes green and `flutter test` is clean.
  Keep SHARED_REQUEST item 4's second half — `SettingsRepositoryImpl._write`
  (P16) has the same UPDATE-only shape and still needs a shared helper.

### 2. MAJOR — the whole scroll area renders 16 px higher than the design (shared `NestNavBar` compact height), never filed

- **Where:** `app/lib/features/privacy_consent/presentation/views/privacy_consent_view.dart:28-41`
  (`NestNavBar(compact: true, title: '', onBack: …)`).
- **Evidence** (glyph bands, logical px, design → app): h1 `113–138` → `97–122`;
  subtitle `156–170` → `140–154`; shield circle `199–257` → `183–241`; nav chevron
  centre `72.5` → `68.5`. Uniform **−16 px** for every content element, while the
  bottom CTA starts at the same y in both (674) because it is bottom-anchored.
  `compare.py` agrees: the two worst bands are 105–211 (13.18%) and 316–422
  (12.39%) — exactly the h1 band and the promise-list band — and band 6
  (633–738, blank paper in both) is 0.40%.
- **Root cause:** `.nav-bar.compact` in `design/html-source/components.css:58`
  is `min-height: 52px; padding: 4px 12px 12px` around the 44 px `.nav-back`
  button → the bar is **60 px** tall, so the scroll area starts at y = 47 + 60 =
  107. `NestNavBar`'s compact branch
  (`app/lib/core/design_system/components/nest_nav_bar.dart:42-82`) is
  `ConstrainedBox(minHeight: NestDevice.tapParent)` + horizontal padding only
  → **44 px**, so P04's content starts at y = 91.
- **In P04's scope only as a request:** the component is
  `app/lib/core/**`, which RULES §1 puts off limits. What P04 can and must do is
  file it (RULES §2) so the orchestrator can fix the bar once for every compact
  screen. Nothing about the 16 px offset is mentioned in `SHARED_REQUEST.md`.
- **Concrete fix:** append SHARED_REQUEST item 5 — `NestNavBar` compact should be
  `minHeight: 52` with `EdgeInsets.fromLTRB(NestSpacing.s3, NestSpacing.gap2,
  NestSpacing.s3, NestSpacing.s3)` (4 top / 12 sides / 12 bottom, matching
  `.nav-bar.compact`) so it resolves to 60 px. Note the blast radius from
  `nestling_assets.dart` (`NestIcons.back`, "Screens: P03, P04, P05, P06, P11,
  P14, K02, K04, K06, K08, K09, K10, K11"), and fold it into item 3 (same file,
  same ownership). Until it lands, P04's UI check must not be reported as clean.

### 3. MINOR — `2_build.md` states a UI-check conclusion the pixels contradict

- **Where:** `docs/screens/P04/2_build.md:79-86` — "heat-map shows sub-pixel font
  edges only — cards/tiles/toggle/CTA overlap".
- **Why:** finding 2 is a 16 px content offset, and `compare.py` reports 13.18%
  / 12.39% drift in the two bands that contain it. Cards do **not** overlap the
  design's cards. The build note is also the reason finding 2 was not caught.
- **Fix:** replace the sentence with the band table from `compare.py`, the
  measured glyph offsets, and the three known shared causes (items 1–3 of
  `SHARED_REQUEST.md` + finding 2). Keep "gutters aligned, CTA surface reaches
  the edge in both themes" — both are true and verified.

### 4. MINOR — magic numbers where a token exists

- **Where:** `privacy_consent_view.dart:239` `fromLTRB(12, 7, 16, 7)`,
  `:244-245` `width/height: 40`.
- **Fix:** `NestSpacing.s3` (12), `NestSpacing.gap7` (7 — the token exists
  precisely for this and is currently unused anywhere), `NestSpacing.s4` (16),
  `NestSpacing.s10` (40). The remaining literals (`84` shield at `:76-77`,
  `13` opt-card padding at `:120`, `56` min-height at `:237`, `22 / 16` at
  `:136`/`:265`, `decorationThickness: 1` at `:337`) have no token; the shared
  `NestListRow` hard-codes the same ones, so leave them or raise a small
  shared-request item alongside finding 2 rather than inventing local constants.

### 5. MINOR — `'crash'` is a bare string literal in three places

- **Where:** `presentation/bloc/privacy_consent_bloc.dart:18`, plus
  `data/privacy_consent_repository_impl.dart:46` and the tests.
- **Fix:** `abstract final class ConsentOptionIds { static const crash = 'crash'; }`
  in `app/lib/features/privacy_consent/domain/entities/consent_option.dart`
  (domain is P04's territory, RULES §1) and use it at every site, so the bloc's
  dependency on a repository row id cannot silently rot.

### 6. MINOR — `errorMessage` can never be cleared from the state

- **Where:** `presentation/bloc/privacy_consent_state.dart:29`
  (`errorMessage: errorMessage ?? this.errorMessage`).
- **Fix:** a sentinel (`Object? errorMessage = _unset` with
  `errorMessage == _unset ? this.errorMessage : errorMessage as String?`) or an
  explicit `clearError` flag. Harmless today because the caption keys on
  `status == failure`, but it blocks the retry path a future stage will want.

### 7. MINOR — the Privacy Notice dialog body is a run-on sentence

- **Where:** `privacy_consent_view.dart:311-319`.
- **Plan mismatch:** `1_plan.md` §c specifies "the 4 promise bullets". As shipped
  it renders one paragraph — "No ads or tracking — ever. Children only need a
  nickname. Data stored in the UK (London). Delete everything anytime." — which
  reads as broken prose.
- **Fix:** render the four titles as four separate centred lines (reuse the same
  const list the promise rows use so the copy cannot drift), then `Close`.

### 8. MINOR — `PrivacyConsentPlaceholderCard` is now dead code

- **Where:** `app/lib/features/privacy_consent/presentation/widgets/privacy_consent_placeholder_card.dart`
  — zero references after the placeholder view was replaced (grep confirms).
- **Fix:** delete it, or leave it if unreferenced placeholder cards are the
  repo-wide convention (`OnboardingPlaceholderCard` and
  `FamilyPlaceholderCard` are equally unreferenced on `main`, so this is a
  codebase-wide tidy-up, not a P04 defect).

---

## Verified correct (no action)

- **Copy, DESIGN_SPEC §5 P04:** every string matches the design exactly, with the
  curly apostrophes and em dashes from the HTML source, and UK spelling
  ("analytics", "stored", no US forms). Equal-weight CTA respected: a single
  primary "Continue", no manipulative accept/decline pair, and the opt-in toggle
  is OFF by default (`app_database.dart:207-209`) per the ICO nudge rule.
- **Design fidelity:** 20 px side gutters shared by headline, `NestList`, opt card
  and CTA; the 14 / 16 / 16 vertical rhythm; 40 px tiles with radius 12; divider
  indent 72; shield 84; toggle 51×31 in a 44 px box; opt card 13 v / 16 h with
  16/22 title and 15/22 sub; no `maxLines`/ellipsis anywhere, so rows wrap per
  SPACING_SPEC §9.3/§9.4.
- **Architecture:** feature-first; `domain/` still only holds the entity + the
  abstract repository; one bloc per feature with `LoadRequested` and
  initial/loading/loaded/failure; DI and routes unchanged and per feature.
  `analysis_options.yaml` untouched; no `lib/core/**`, `lib/app/**`,
  `tools/screens/**` or foreign-feature files in the diff — RULES §1 respected.
- **Architecture/DI:** `PrivacyConsentBloc` is a GetIt factory and the route
  wraps it in `BlocProvider(create: …)`, so `context.go` / `pop` close the bloc and
  cancel the `emit.forEach` subscription; no leaked streams. Bloc 9's default
  concurrent transformer lets `_onCrashToggled` write while the load
  `emit.forEach` is still open, which the current code depends on.
- **Performance:** `const` widgets throughout; `BlocBuilder` sits outside the
  scroll view so scroll offset survives a state change; a successful toggle
  causes zero rebuilds (no optimistic emit) and one on the stream re-emit. No
  rebuild storm, no `context.watch` in a builder callback.
- **Error handling:** the toggle write is wrapped, emits `failure` keeping prior
  items, and `Continue` stays enabled so the parent can never be trapped on this
  screen. The inline danger caption matches the spec'd copy.
- **Accessibility:** h1 is a header; the shield is `image: true` with the HTML
  alt text and `ExcludeSemantics` on the `SvgPicture`; the four promise rows are
  announced as containers, never as buttons; the toggle exposes
  label + `toggled` + `enabled`; `Continue`, `Back` and the notice link are
  labelled buttons; every target is ≥ 44 px (back 44, toggle 44, Continue 52,
  notice 44); the notice link's label is not duplicated (`ExcludeSemantics` on
  the inner `Text`). Contrast on token pairs: `ink`/`ink2` on paper and surface,
  `sky` link 5.42:1 light / 7.21:1 dark, `danger` caption 4.73:1 light / 7.37:1
  dark — all ≥ 4.5:1 for 13 px text.
- **OWNER bottom-edge rule: correct, and better than the design PNG.** Probing
  `(200, 820)` and `(200, 838)`: the design shows `rgb(251,247,240)` (cream paper)
  from y ≈ 810 to the edge, because the HTML `.home-indicator` sits outside
  `.bottom-cta`; the app shows `rgb(255,255,255)` all the way to y = 844 because
  `NestBottomCta` puts `SafeArea(top: false)` inside its own surface. The app is
  the intended behaviour — do not "fix" this against the PNG.
- **PIP / STATUS BAR:** no Pip on this screen (shield illustration), so the
  `PipAvatar` rule and the v1-Pip ban do not apply; `NestStatusBar` reserves 47 px
  and draws no glyphs.
- **Children's Code:** no analytics, ads or SDKs referenced anywhere in the diff;
  no child data read on this screen; the one data write is an optional,
  parent-only, default-OFF consent flag.
- **Navigation:** `context.go(FamilyRoutePaths.addChildren)` matches the
  onboarding flow convention already used by P01/P02 (`welcome_view.dart:37,43`);
  back falls back to `/create-account` when there is no history.

## Open shared dependencies (already filed by earlier stages — no P04 action)

`SHARED_REQUEST.md` item 1 (missing `ic_trash.svg` + `NestIcons.trash`, so row 4
ships a blank peach tile — a visible design deviation P04 cannot fix in scope),
item 2 (`privacy_shield.svg` bakes the light `#E6EFFE` circle, so dark mode shows
a light disc instead of the design's `#1A2A4A` — confirmed by reading
`design/screens/dark/P04-privacy.png` against `ui/p04-dark.png`), item 3
(`NestNavBar` compact + `title: null` crashes, worked around with `title: ''`
behind `TODO(P04)`). Item 4 is **not** in this list — see finding 1, which P04
must fix itself.


## From 5_ui.md
# P04 · Privacy consent — UI check (STAGE 5, iteration 1)

Route `/privacy` · SEED=fresh · parent mode · child maya · simulator 604697A9-11DA-462F-9837-396E9CA2493A.
Shots: `docs/screens/P04/ui/app_light_1.png`, `docs/screens/P04/ui/app_dark_1.png`
(`shot.sh` with absolute OUT path — relative OUT breaks because the script `cd`s to `app/` before copying).
Compares: `docs/screens/P04/ui/cmp_light_1.png`, `docs/screens/P04/ui/cmp_dark_1.png`.

## Mean diff

- Light: **7.52%** — bands: 0 (0–105) 2.73% · 1 (105–211) 13.18% · 2 (211–316) 6.97% ·
  3 (316–422) 12.39% · 4 (422–527) 9.74% · 5 (527–633) 9.79% · 6 (633–738) 0.40% · 7 (738–844) 4.84%
- Dark: **8.12%** — bands: 0 (0–105) 2.74% · 1 (105–211) 16.45% · 2 (211–316) 9.25% ·
  3 (316–422) 12.03% · 4 (422–527) 9.69% · 5 (527–633) 10.78% · 6 (633–738) 0.39% · 7 (738–844) 3.55%

Band 6 (~blank paper in both) ≈ 0.4% confirms the pipeline is aligned; drift concentrates in
bands 1–5 (content block). Status-bar glyphs (mock `9:41` vs OS clock `11:43`/`11:44`) are
ignored per orchestrator STATUS BAR rule; the bottom-edge strip difference is the OWNER-rule
override (app correct, see deviation 4 — not a failure).

## Verified matching (no action)

- Presence/order/copy: nav back chevron, H1 `Your family’s privacy`, sub
  `Exactly what we store — and nothing else.`, 84 px shield, 4 promise rows in order with
  exact titles/subs, opt card (`Optional: help improve Nestling` / `Share anonymous crash
  reports.` / `No names, no photos.`), toggle OFF, primary `Continue`, underlined sky
  `Read the full Privacy Notice`. No overflow, no clipping, no ellipsis anywhere; rows wrap.
- Geometry that matches: 20 px side gutters throughout; 40 px tiles, r12; divider indent 72;
  opt card 13 v / 16 h; toggle 51×31 in 44 px box; full-width pill CTA bottom-anchored at the
  same y as the design; footnote centred.
- Light-mode colours/radii/shadows match; no Pip on this screen so the PIP rule is N/A.

## Deviations

1. Scroll content sits ~16 px too high (all elements, both themes).
   Design value: compact nav bar 60 px tall (`.nav-bar.compact`: min-height 52 + padding
   4/12/12 around the 44 px back button) → scroll starts at y = 47 + 60 = 107; H1 at y 113–138.
   App value: `NestNavBar` compact resolves to 44 px → scroll starts at y = 91; H1 at y 97–122.
   Uniform −16 px for every content element; CTA unaffected (bottom-anchored). This is what
   bands 1 (13.18%/16.45%) and 3 (12.39%/12.03%) are measuring.
   Fix (shared, `app/lib/core/design_system/components/nest_nav_bar.dart` — off limits to P04):
   compact bar → `minHeight: 52` with padding 4 top / 12 sides / 12 bottom. File as SHARED_REQUEST
   item (not yet filed — `4_review.md` finding 2).
2. Row-4 tile has no trash-can glyph (both themes — blank peach tile).
   Design value: peach tile with 24 px trash-can line glyph.
   App value: empty peach 40×40 tile.
   Fix (shared, already filed as SHARED_REQUEST item 1): add `assets/icons/ic_trash.svg` +
   `NestIcons.trash`; P04 row 4 picks it up. A designer would reject the blank tile.
3. Dark-mode shield disc renders light (dark theme only).
   Design value: disc `#1A2A4A` (probed patch at (160, 215–228)).
   App value: disc `#E6EFFE` (same patch) — `privacy_shield.svg` bakes the light hex.
   Fix (shared, already filed as SHARED_REQUEST item 2): themed shield asset; do not hand-edit
   core assets from P04.
4. Bottom-edge strip below the CTA differs from the PNG — NOT a failure (owner override).
   Design value: cream `#FBF7F0` (light) / near-black (dark) strip with the home indicator
   outside the CTA panel.
   App value: CTA surface colour runs to the physical edge (white light / surface dark).
   Per the OWNER BOTTOM-EDGE rule the app is the intended behaviour; do not "fix" toward the PNG.

No fix is applicable inside P04 scope (RULES §1): deviations 1–3 are all shared
design-system/asset causes. No code edited in this stage.


## From 6_bugs.md
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


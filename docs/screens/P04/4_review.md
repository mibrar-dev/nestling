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

VERDICT: FAIL
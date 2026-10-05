# K10 · Payout day — QA code review (iteration 1)

Scope: `git diff main...HEAD` — `kid_jar` presentation/bloc/domain/data for
K10, feature tests, `docs/screens/K10/**`. No code was edited at this stage.

Checks run:

- `flutter analyze lib/features/kid_jar test/features/kid_jar` → No issues found.
- `flutter test --timeout 120s test/features/kid_jar/` → all tests passed
  (170 passed, 6 skipped; whole kid_jar suite incl. K09 regressions).
- All changed files are inside `app/lib/features/kid_jar/**`,
  `app/test/features/kid_jar/**`, `docs/screens/K10/**` — RULES §1 holds.
  No `core/**`, `app/**`, other features, or `tools/screens/**` touched.
- No `SHARED_REQUEST.md` filed; plan §g asserts every component is used,
  not modified — confirmed (`KidScope`, `NestStatusBar`, `NestIconButton`,
  `NestLockButton`, `NestKidButton`, `NestProgress(kid:true)`,
  `NestBalancedText`, `NestSpeechBubble`, `PipAvatar`, `jarPounds`,
  `combineLatest3`, `watchChild/watchLedger/watchGoals`).
- Architecture: feature-first layout holds; `PayoutCelebration` is a domain
  entity, `KidJarRepository.watchLatestPayout` is the abstract repo method,
  the Drift impl lives in `data/`, one `KidJarBloc` per route (factory in
  `kid_jar_di.dart` — separate instances for `/my-jar` and `/payout-day`,
  so K09/K10 state never cross-contaminates), routes in
  `kid_jar_routes.dart`. The guarded-subscription pattern is the K09-BUG-1 /
  K03-BUG-15 shape verbatim, with cancel-before-reload, release on error and
  release on `close()`.
- Design-system usage: no hard-coded hex colours outside the fixed
  illustration palettes (`_RainPalette`, `_CircleArrowPainter` ink glyph —
  same fixed-illustration rule as `JarIllustration`); no `google_fonts`
  import or `GoogleFonts.*` call; no `DateTime.now()` (comments only); no
  v1 `pip_stage_*.svg` reference. Letter spacing: none added — K10 CSS sets
  no tracking, `NestType` defaults stand. `NestBalancedText` on the
  `text-wrap: balance` `.kid-title` heading; no chip rows on this screen.
- Accessibility: every control (back, lock, Thanks Mum!, Try again, Back
  home) reaches `SemanticsAction.tap` through `NestIconButton`/
  `NestLockButton`/`NestKidButton`, and the view test drives
  `performAction(SemanticsAction.tap)` into real route/DB effects. Title is a
  header, notes merge title+subtitle into one label, progress bar and jar
  rain carry labels, Pip image + bubble merge per the K04 adjacency
  precedent. Tap targets ≥ 56 px.
- Children's Code: no analytics, ads, or child data egress; kid mode shows
  only the child's own DB-driven copy.
- Error handling: stream failure → `failure` with `Try again` that really
  reloads (subscription released before the retry); empty (`null` payout)
  gets its own kid-voice empty state. PERIODS ruling correctly documented as
  N/A for payout event history.
- Geometry/alignments are encoded in `payout_day_view_geometry_test.dart`
  (±2 px bands, both themes, 320/390/430 gutters, kid bar reaches the
  physical bottom edge) — to be re-verified against the PNGs at stage 5_ui.

Findings:

1. minor — `app/lib/features/kid_jar/presentation/views/payout_day_view.dart:334`
   Doc comment on `_PayoutPip` is truncated: it begins mid-sentence
   ("/// rows as adjacent image/bubble siblings that merge into one
   announcement"). Fix: restore the lead line, e.g. "Pip row: the child's
   own Pip and the speech bubble are adjacent image/bubble siblings that
   merge into one announcement (K04 adjacency precedent)."

2. minor — `app/lib/features/kid_jar/presentation/views/payout_day_view.dart:387-389`
   `_PayoutFailure({required this.message})` accepts `state.errorMessage`
   but never renders it (kid-voice fixed copy). Fix: drop the parameter and
   the `message:` argument at the call site (line 80), or surface it behind
   a debug-only trailing line — either is fine, but a write-only parameter
   is dead weight.

3. minor — `app/lib/features/kid_jar/presentation/bloc/kid_jar_bloc.dart:95`
   `_onPayoutRequested` reloads with `state.copyWith(status:
   KidJarStatus.loading)`, which preserves a stale `errorMessage` from a
   previous failure. Invisible today (the loading view wins and the next
   emission clears the error via `copyWithPayout`), but any listener reading
   `errorMessage` sees it during the reload. Fix: clear it explicitly, e.g.
   `emit(state.copyWith(status: KidJarStatus.loading).clearError())` with a
   small `clearError()` that rebuilds with `errorMessage: null` — note
   `copyWith` alone cannot null it because of the `??` fallback.

4. minor — `app/lib/features/kid_jar/data/kid_jar_repository_impl.dart:131-141`
   `_payoutFor` picks the companion move as the *newest* `Jar → …` move
   stamped at/after the payout instant. A later, unrelated jar→savings move
   would then be attributed to an older payout. Fix: prefer the *oldest*
   qualifying move (the one written alongside the payout per
   `recordPayout`'s single-`now` transaction), or stamp a shared id/note
   token on the payout row and its companion when `recordPayout` writes both
   so the link is explicit instead of temporal. Current behaviour is
   documented in the comment and covered by tests for the seeded cases, so
   this is hardening, not a defect in the demo path.

No blocker or major findings.

VERDICT: PASS

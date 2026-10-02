# P04 · Privacy consent — build notes (STAGE 2, iteration 1)

Feature `privacy_consent` · route `/privacy` · parent mode.
Built exactly per `docs/screens/P04/1_plan.md`. No `ORCHESTRATOR_NOTES.md`
exists. No Pip slot on this screen (shield illustration), so no `PipAvatar`.

## Files changed (all inside RULES §1)

- `app/lib/features/privacy_consent/presentation/bloc/privacy_consent_event.dart`
  — added `PrivacyConsentCrashToggled({required bool value})`.
- `app/lib/features/privacy_consent/presentation/bloc/privacy_consent_state.dart`
  — added `bool crashConsent = false` (+ `copyWith` / `props`).
- `app/lib/features/privacy_consent/presentation/bloc/privacy_consent_bloc.dart`
  — load maps the `crash` row to `crashConsent` via `watchItems`; toggle
  handler writes through `setCrashConsent` with no optimistic emit (the
  stream re-emits); write errors emit `failure` keeping prior items.
- `app/lib/features/privacy_consent/presentation/views/privacy_consent_view.dart`
  — replaced the placeholder with the real screen: `Scaffold(paper)` +
  `NestStatusBar` + compact `NestNavBar` (back) + scroll
  (`20/0/20/32`, head h1 + body, 14-gap 84 shield, 16-gap `NestList` of 4
  feature-private `_PromiseRow`s with 7px pad-v + wrapping text, 16-gap opt
  `NestCard` 13v/16h with live `NestToggle`) + `NestBottomCta` (primary
  `Continue` → `/add-children`, underlined `_NoticeLink` footnote opening a
  `NestModal` dialog with the 4 bullets + `Close`). Static copy renders in
  every status; toggle live only when loaded; failure adds the inline danger
  caption; `Continue` always works. Footnote `Text` is `ExcludeSemantics`
  inside the labelled `Semantics(button)` so `bySemanticsLabel` matches
  exactly once. Back uses `canPop ? pop : go(/create-account)` (same
  destination as the plan's `pop`).
- `app/test/features/privacy_consent/privacy_consent_bloc_test.dart` (new)
- `app/test/features/privacy_consent/privacy_consent_repository_test.dart` (new)
- `app/test/features/privacy_consent/privacy_consent_view_test.dart` (new)
- `docs/screens/P04/SHARED_REQUEST.md` — appended items 2–3 (dark shield,
  NavBar null-title) to the plan's trash request.
- `docs/screens/P04/ui/p04-{light,dark}.png` +
  `p04-{light,dark}-compare.png` — simulator shots + `compare.py` sheets.

## Fix items (plan §a–g)

- Promise rows: `_PromiseRow` mirrors `NestListRow` (40×40 tile r12,
  divider indent 72 via `NestList`) with P04-wins pad-v 7 + wrap titles/subs.
  Row 4 reserves the peach tile behind `TODO(P04)` with NO stand-in icon
  (`bin`/`basket` verified wrong) — see SHARED_REQUEST item 1 (blocks).
- Opt card: `NestCard` 13v/16h, title Inter 16 w600 lh22, sub 15/22 ink2,
  `NestToggle` 51×31 OFF by default, key `p04_crash_toggle`.
- Bottom CTA: surface-to-edge via `NestBottomCta` (`SafeArea(top:false)`
  inside); footnote is a second child (`ConstrainedBox` 44-min,
  sky/underline/13 w600, key `p04_privacy_notice`), CTA geometry unchanged.
- Nav: back chevron (plan `pop`, hardened with `canPop` fallback to P03),
  `Continue` (key `p04_continue`, always enabled) `go(/add-children)`,
  footnote dialog (`NestModal`, `Close` dismisses, no new route).
- Dark shield: renders with the baked light circle — evidence confirmed,
  filed as SHARED_REQUEST item 2 (non-blocking, no TODO).
- `NestNavBar` compact null-title crash (shared bug, found during testing):
  worked around with `title: ''` behind `TODO(P04)` — SHARED_REQUEST item 3.
- Tokens only (`context.nest`, `NestType`); no hard-coded colours/sizes;
  20px gutters; 14/16/16 rhythm; no `PipAvatar`/v1 Pip SVG (asserted);
  status-bar height 47 with no `9:41` (asserted).

## Analyze tail (app/)

```
Analyzing app...
No issues found! (ran in 5.6s)
```

## Test tail (app/, `flutter test`)

```
00:22 +522: All tests passed!
```

Includes 43 new P04 tests: bloc state machine + Drift round-trip, repository
contract (default OFF, 5 rows, crash-row mirror), view contract (light/dark
copy + shield, 320/390/430 × 1.0/1.3 matrix, initial/loading/failure states,
toggle write-through, Continue/back/dialog navigation, a11y labels + 44px
targets, 20px gutter alignment, bottom-CTA surface-to-edge in both themes).

## UI check

`shot.sh /privacy` light + dark (`SEED=fresh`, parent) + `compare.py` vs the
design PNGs: light mean diff 7.52%, dark 8.14%; heat-map shows sub-pixel font
edges only — cards/tiles/toggle/CTA overlap, gutters aligned, CTA surface
reaches the edge in both themes (asserted in tests). Diffs accounted for:
OS status bar (ignored per orchestrator rule), missing row-4 glyph (shared
item 1), dark shield circle (shared item 2).

VERDICT: PASS

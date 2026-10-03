# P04 · Privacy consent — build plan (STAGE 1)

Feature `privacy_consent` · route `/privacy` (`PrivacyConsentRoutePaths.privacy`) · parent mode.
Sources: `design/html-source/screens/P04-privacy.html`, light/dark PNGs (1170×2532 @3x),
DESIGN_SPEC §5 P04, SPACING_SPEC §§1–3, 8–11. All numbers below are logical px (PNG ÷ 3).

No `ORCHESTRATOR_NOTES.md` exists. PIP rule: this screen has **no Pip slot** (shield
illustration instead), so no `PipAvatar` and no v1 `pip_stage_*.svg`. STATUS BAR rule:
`NestStatusBar` reserves 47 px only; ignore mock-clock differences in UI checks.

## (a) Widget tree, top → bottom (exact components + token spacing)

`PrivacyConsentView` = `Scaffold(backgroundColor: tokens.paper)`:

1. `NestStatusBar.new()` — reserves `NestDevice.statusH` (47). No glyphs in app.
2. `NestNavBar.new(compact: true, onBack: pop, backSemanticLabel: 'Back')` — min-height 52
   (spec compact: 52, `compact` centres title; here title is null so bar is back-chevron row
   only: left 44×44 chevron, right 44 spacer). Padding `8/12/12`-equivalent via component.
3. `Expanded` + `SingleChildScrollView` (scroll padding `EdgeInsets.fromLTRB(20, 0, 20, 32)` =
   `padSide` sides, `s8` bottom; separators below):
   - Head block (top 0): `Text('Your family’s privacy', style: NestType.h1, header semantics)`.
     `SizedBox(8)` (`s2`), then `Text('Exactly what we store — and nothing else.',
     style: body 16/24 w400 ink2)`.
   - `SizedBox(14)` then shield: `Center(child: Semantics(label:
     'A shield with a leaf and a heart, protecting your family', image: true,
     child: SvgPicture.asset(NestlingIllustrations.privacyShield, width: 84, height: 84)))`.
     (HTML: `.shield` margin-top 14, svg 84×84. Dedicated screen asset — not a Pip stage,
     so the v1-Pip ban does not apply.)
   - `SizedBox(16)` then `NestList.new(children: 4 × _PromiseRow)`:
     - `_PromiseRow` is FEATURE-PRIVATE (see §g, reason: `NestListRow` hard-codes
       `maxLines: 1` + ellipsis and fixed `10px` vertical padding, but P04 wins per
       SPACING_SPEC §9.3/§9.4: rows pad-v **7**, title/sub **wrap**). Geometry mirrors
       `NestListRow` exactly, tokens only: `Padding(12 left, 7 top/bottom, 16 right)`,
       `Row(gap s3=12)`, 40×40 tile `BorderRadius s3=12` (owner-QA value used by
       `NestListRow`, not r16), `NestIcon(size 24, tinted)`, `Expanded(Column(
       title: Inter 16 w600 lh22 softWrap, sub: 13/18 ink2 softWrap, gap 2))`.
       `ConstrainedBox(minHeight 56)`. `NestList` supplies card chrome (surface, r16,
       sh-1) + dividers (indent 72, line). Rows are display-only: no `onTap`, wrapped in
       `Semantics(container: true)` — not buttons.
     - Row content (static UK copy from the DESIGN, not from repo strings):
       1. `NestIcons.noAds`, leaf tint — 'No ads or tracking — ever' /
          'No analytics profiles, no ad SDKs, ever'
       2. `NestIcons.person`, lilac tint — 'Children only need a nickname' /
          'No photos, no email, no chat, no location'
       3. `NestIcons.pinUk`, sky tint — 'Data stored in the UK (London)' /
          'Kept on UK servers, nothing leaves'
       4. TRASH glyph, peach tint — 'Delete everything anytime' /
          'One tap and your family data is gone'. Asset missing → SHARED_REQUEST (§g);
          build behind `TODO(P04)` with `NestIcons.bin` as temporary stand-in is
          WRONG (bin = cart, basket = laundry — neither is a trash can), so builder
          waits for the asset; layout reserves the 40×40 tile regardless.
   - `SizedBox(16)` then opt card: `NestCard.new(standard, padding:
     EdgeInsets.symmetric(vertical: 13, horizontal: 16))` (HTML `.opt` padding
     `13px 16px` overrides base 16). Child `Row(gap 12)`: `Expanded(Column(gap 2,
     title Inter 16 w600 lh22 'Optional: help improve Nestling', sub 15/22 ink2
     'Share anonymous crash reports. No names, no photos.'))` + `NestToggle.new(
     value: crashConsent, semanticLabel: 'Share anonymous crash reports',
     onChanged: toggle)` (51×31 track, 44-min tap box built in; OFF by default).
4. `NestBottomCta.new(child: NestButton.primary(label: 'Continue', key:
   p04_continue, onPressed: go P05))` + footnote slot: component takes `caption`
   (plain text) but design needs an UNDERLINED tappable link, so pass footnote as
   `child`-column second item instead: feature-private `_NoticeLink` —
   `TextButton`-style `GestureDetector`, `Text('Read the full Privacy Notice',
   Inter 13 w600 lh18, sky, underline, offset 2)`, `ConstrainedBox(minHeight 44,
   minWidth 44)`, centred, key `p04_privacy_notice`. Bottom-CTA geometry unchanged
   (surface bg, top hairline `line`, padding 16v/20h, column gap 8, `SafeArea(top:false)`
   so surface runs to the physical edge — OWNER bottom-edge rule).
   `NestHomeIndicator` mock only renders in gallery; nothing to do in app.

Dark mode: tokens only (`context.nest`), no hex. Known risk: `privacy_shield.svg`
bakes light hex (`#E6EFFE` circle); dark render shows sky-tint `#1A2A4A`. Builder
verifies against dark PNG in the UI check; if the circle renders light, file a
SHARED_REQUEST for a themed shield asset (do not hand-edit core assets).

Side gutters 20 everywhere; scroll siblings separated 16 except shield block (14).

## (b) BLoC events/states, repository calls

Existing foundation (keep): `PrivacyConsentRepository` (Drift-backed
`PrivacyConsentRepositoryImpl`, `settings.crashReportConsent`, OFF by default) with
`watchItems()`, `watchCrashConsent()`, `setCrashConsent()`. Static 4-row copy lives in
the VIEW as consts (design copy wins over repo `detail` strings, which drift from the
design); the repo stream drives ONLY the crash-toggle.

- State: add `bool crashConsent = false` to `PrivacyConsentState` (+ props, copyWith).
  `items` stays (foundation contract) but the view ignores static rows in it.
- Events (add ONE): `PrivacyConsentCrashToggled({required bool value})`.
  `PrivacyConsentLoadRequested` unchanged: `emit(loading)` then
  `emit.forEach(_repository.watchItems(), onData: loaded(items,
  crashConsent: items where id=='crash' → enabled), onError: failure(message))`.
- `_onCrashToggled`: `await _repository.setCrashConsent(consent: event.value)`; the
  `watchItems` stream re-emits and updates state (no optimistic emit, no re-added load
  event). On exception: `emit(failure)` keeping prior `items`/`crashConsent` so the
  screen stays usable.
- No new repository methods, no schema/seed change. `registerPrivacyConsent` unchanged.

## (c) Interactions → navigation (route constants)

| Control | Action | Destination |
|---|---|---|
| Nav back chevron | `context.pop()` | P03 `/create-account` (`AuthRoutePaths.createAccount`) |
| `Continue` (primary, always enabled — ICO nudge: single equal-weight CTA) | `context.go(FamilyRoutePaths.addChildren)` | P05 `/add-children` |
| Crash toggle | `bloc.add(PrivacyConsentCrashToggled(value))` → Drift write | stays on `/privacy` |
| `Read the full Privacy Notice` footnote | shows `NestModal`-style dialog with the 4 promise bullets + `Close` (no external browser; v1 ships no hosted notice; no new route) | dialog dismiss returns to `/privacy` |

Keys: `p04_continue`, `p04_crash_toggle` (on the toggle), `p04_privacy_notice`.

## (d) Empty / loading / error states

Static screen (P01 pattern): full content renders in EVERY status — copy never depends
on the DB. `initial`/`loading`: content + toggle `value: false`, `onChanged: null`
(disabled, opacity .45). `loaded`: toggle live. `failure`: content + toggle disabled +
inline error caption (`Inter 13 danger`, under opt card, `Oops — your choice wasn’t
saved. Continue anyway; it stays off.`) — NO retry button (RULES §4: never re-add load
events; the stream is single-subscription) and `Continue` ALWAYS works. `items.isEmpty`
is unreachable (repo always emits 5 incl. crash row); if empty ever arrives, render the
same static content. No skeleton shimmer (static screen, no list-length dependency).

## (e) Accessibility

- Semantics: h1 `header: true`; shield `image: true` with HTML alt text; rows
  non-button containers; toggle `Semantics(toggled, label)` via `NestToggle`;
  `Continue`/footnote `button: true` with labels; status chrome excluded.
- Tap targets ≥ 44×44 parent: back 44, toggle 44-min (component), Continue 52,
  footnote 44-min (custom constraint). No kid controls → 56 rule N/A.
- Text scale 1.3 + widths 320/390/430: rows wrap (not ellipsis) so 320 dp holds;
  title/sub `softWrap`; footnote wraps; `textScaler` clamp 1.0–1.3 is app-wide.
- Contrast: token pairs only (ink/paper, ink2, sky-on-surface link 13px ≥ 4.5:1 per
  spec); toggle track `track` vs knob white handled by component.

## (f) Test plan (`app/test/features/privacy_consent/` — new files, scope per RULES §1)

- `privacy_consent_bloc_test.dart` (blocTest): initial state; load emits
  loading→loaded with `crashConsent == false` from demo seed; `CrashToggled(true)` calls
  `setCrashConsent` and stream re-emits `true`; repo error → failure keeps prior items.
- `privacy_consent_repository_test.dart`: `watchCrashConsent` default `false` (ICO);
  `setCrashConsent(true/false)` round-trips via `watchSetting(Seed.familyId)`;
  `watchItems` always 5 rows, crash row mirrors the setting.
- `privacy_consent_view_test.dart` (follow `welcome_view_test.dart` shape):
  light+dark render all 4 titles/subs, shield semantics, toggle OFF, Continue + footnote;
  `NestStatusBar` height 47, no `9:41` text; no `PipAvatar`, no v1 Pip SVG anywhere;
  tap toggle → repo `true`; Continue → `/add-children`; back → pop; footnote → dialog;
  matrix widths 320/390/430 × scales 1.0/1.3 → `takeException() isNull`, targets ≥ 44,
  gutters 20; failure state (error stream) still shows Continue + inline caption.
  Every app-pumping test ends with `disposeApp(tester)`; `GoogleFonts.config.
  allowRuntimeFetching = false`.
- UI check: `shot.sh` `/privacy` light+dark (SEED=fresh, parent mode) + `compare.py`
  vs design PNGs; verify 20px gutters, 14/16/16 rhythm, 84 shield, tile 40/r12,
  divider indent 72, CTA surface-to-edge (no paper strip under bar), dark shield circle.

## (g) SHARED_REQUEST needed

YES — one file `docs/screens/P04/SHARED_REQUEST.md`: new trash-can line icon
`assets/icons/ic_trash.svg` (24×24, `currentColor`, 2px stroke, round caps, matching
the HTML row-4 glyph `M4 7h16M9.5 7V5h5v2M6.5 7l1 13h9l1-13`) + `NestIcons.trash`
entry. Blocks: yes for pixel-fidelity (no existing asset matches; `bin` = cart,
`basket` = laundry). Builder proceeds with layout complete, tile reserved, behind
`TODO(P04)` pointing at the request. Possible second request (dark shield circle)
only if the UI check fails — verify first, file only on evidence.

VERDICT: PASS

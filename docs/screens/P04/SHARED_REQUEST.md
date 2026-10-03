# Shared request — P04 Privacy consent
Need: new trash-can line icon for the 4th promise row ("Delete everything anytime").
The HTML source draws a trash can (lid + body + legs path); no existing asset matches:
`ic_bin` is a wheeled cart and `ic_basket` is a laundry basket (verified by reading
both SVGs). Add `app/assets/icons/ic_trash.svg` (24×24, stroke currentColor, 2px,
round caps) plus a `NestIcons.trash` entry in
`app/lib/core/design_system/assets/nestling_assets.dart`.
Files: `app/assets/icons/ic_trash.svg`,
`app/lib/core/design_system/assets/nestling_assets.dart`
Blocks: yes — without it P04 cannot match the design (wrong-bin glyph is a visible
defect). P04 builds layout-complete with the 40×40 tile reserved behind a
`TODO(P04)` until this lands.
**Status (iteration 5): landed on main as `ic_trash.svg` + `NestIcons.trash`;
P04 wires it on row 4 with the TODO deleted. Resolved.**

---
# Shared request — P04 dark shield (evidence from UI check)
Need: `privacy_shield.svg` bakes the light sky-tint circle (`#E6EFFE`); on the
simulator the dark-mode render shows the light circle instead of the design's
dark navy circle (verified in `docs/screens/P04/ui/p04-dark.png` vs
`design/screens/dark/P04-privacy.png`). Ship a themed shield (or a
token-coloured circle layer) so dark mode matches the design.
Files: `app/assets/illustrations/privacy_shield.svg` (or new dark variant +
asset entry)
Blocks: no — light mode is pixel-close; dark circle is a tint-only deviation.
P04 lands as-is behind no TODO.
**Status (iteration 5): landed on main as `NestPrivacyShield` (token
disc/body/heart); P04 renders it instead of the baked SVG. Resolved.**

---
# Shared request — P04 NestNavBar compact null-title crash — RESOLVED (STAGE 3, it. 2)
Need: `NestNavBar` compact with `title: null` nests a `Spacer` (an `Expanded`)
inside the title slot's `Expanded` and throws "Incorrect use of
ParentDataWidget" at build time (ownership chain ends in `NestNavBar`).
Fix the null path to render an empty 44px-centred slot (e.g. `SizedBox`
instead of `Spacer`). P04 works around it with `title: ''` (visually
identical back-only row) behind a `TODO(P04)`.
Files: `app/lib/core/design_system/components/nest_nav_bar.dart`
Blocks: no — workaround in place; remove `title: ''` once fixed.
**Status:** fixed by the shared merge (`shared/onboarding_header_and_seed`) —
the compact branch returns `SizedBox.shrink()` for a null *or empty* title
and resolves to 60 px tall (`min 52 + padding 4/12/12`). `[P04-3]` is
un-skipped and green. Cleanup done in iteration 3: P04 passes no `title`
(null) and the obsolete `TODO(P04)` is deleted.

---
# Shared request — P04 settings row missing on a first run (BUG P04-1)
Need: on a real first launch the database is empty (`Seed.fresh` writes only
`app_state`), and nothing before P04 creates the `fam1` **settings** row
(`AuthRepositoryImpl.createAccount` inserts a `members` row only). P04 is the
first screen in the onboarding flow that writes a setting, and
`PrivacyConsentRepositoryImpl.setCrashConsent`
(`data/privacy_consent_repository_impl.dart:63`) issues
`UPDATE settings WHERE family_id = 'fam1'` — which matches **zero rows**. The
parent's opt-in is silently dropped: the toggle stays OFF, no error is shown,
nothing is stored. Repro: launch with `SEED=fresh`, open `/privacy`, tap the
crash-report toggle → it never turns on.
Fix either by upserting in the P04 repository (`insertOnConflictUpdate`, or
`insert … onConflictDoUpdate` when the update affects 0 rows) or by creating
the `fam1` family + settings rows in the onboarding bootstrap (core, shared).
`SettingsRepositoryImpl._write` (P16) has the same UPDATE-only shape, so a
shared helper would fix both.
Files: `app/lib/features/privacy_consent/data/privacy_consent_repository_impl.dart`
(feature-local, screen-agent territory) and/or `app/lib/core/data/` bootstrap
(shared).
Blocks: **yes for correctness** — the screen's only interactive control does
nothing on first run. Red test left in place on purpose:
`app/test/features/privacy_consent/privacy_consent_repository_test.dart:105`.

---

# RESOLVED in iteration 2 — P04-1 upsert (kept for the P16 half)
`PrivacyConsentRepositoryImpl.setCrashConsent` now inserts the `fam1`
settings row (other columns take table defaults) when the UPDATE affects 0
rows; `watchSetting` re-emits and the toggle flips. The red test
(`consent persists on a first-run database`) is green and the `[P04-1]` bug
proof is un-skipped and passing. Remaining shared half: give P16's
`SettingsRepositoryImpl._write` (same UPDATE-only shape) the same treatment
via a shared helper.

---
# Shared request — P04 compact NestNavBar height — RESOLVED (STAGE 3, it. 2)
Need: `NestNavBar(compact: true)` resolves to 44 px, but the design's
`.nav-bar.compact` is `min-height: 52; padding: 4px 12px 12px` around the
44 px back button → **60 px**. Every compact screen's content therefore
starts 16 px too high (P04: back-chevron centre 69 vs 73; h1 line box 91 vs
107; shield 171 vs 187; list 271 vs 287). Fix the compact branch to
`minHeight: 52` with `EdgeInsets.fromLTRB(NestSpacing.s3, NestSpacing.s2,
NestSpacing.s3, NestSpacing.s3)` so it resolves to 60, and remove the
`title: ''` workaround (same file as item 3). Blast radius per
`nestling_assets.dart`: P03, P04, P05, P06, P11, P14, K02, K04, K06, K08,
K09, K10, K11.
Files: `app/lib/core/design_system/components/nest_nav_bar.dart`
Blocks: no for P04 alone (a local 4/12 padding shim could match the design),
yes for every compact screen to be fixed once. P04's bug proof is
`[P04-3]` in `app/test/features/privacy_consent/p04_bugs_test.dart`.
**Status:** resolved by the same shared merge. Verified in the test stage:
the back-chevron centre is now y 73 and the h1 line box top y 107, exactly
the design values (`[P04-3]` un-skipped and green in
`p04_bugs_test.dart`).

---
# Shared request — P04 NestList real dividers add height (orchestrator note 3)
Need: the design draws list separators as absolutely-positioned 1 px
`::before` overlays (`.list-row + .list-row::before`), so 4 × 56 px rows stay
224 px. `NestList` inserts real `Divider(height: 1)` widgets: +1 px per
divider (P04: 227 px; later rows drift 57 px apart vs the design's 56, and
the opt card lands at 514 instead of 527). Render the divider over the row
boundary (Stack/overlay or transform) so it does not contribute layout
height; keep the 72 px indent and the line token.
Files: `app/lib/core/design_system/components/nest_list_row.dart`
Blocks: no for light-mode pixel-close look; yes for exact vertical rhythm on
every `NestList` screen. P04's bug proof is `[P04-4]` in
`app/test/features/privacy_consent/p04_bugs_test.dart`.
**Status (iteration 5): shared `NestList` now paints the identical overlay
itself, and P04 consumes it with four direct row children (local overlay
deleted). Resolved for P04.**

---
# Shared request — P04 opt-card title wraps after the font bundling (core typography / NestToggle)
Need: with the bundled Inter faces, the theme's inherited `letterSpacing:
0.3` makes "Optional: help improve Nestling" **250.2px** wide in P04's
247px opt-card text column, so it wraps to two lines and the card is 22px
taller than the design (design one line, card 531–621; app iteration 7
531–643, both themes). Measured in a widget test with `FontLoader('Inter')`
loading the bundled faces:
- intrinsic width with the widget's own style: 242.5px;
- merged with the Scaffold `DefaultTextStyle` (Material bodyMedium,
  `letterSpacing: 0.3`): **250.2px**;
- P04 column: 247px (design: 255px — the design's toggle occupies 51px,
  `NestToggle` reserves `minWidth: 59`).
The design CSS sets no letter-spacing on `.opt-title`/body (only `.display`
and `.status-time` use -0.01em), so 0.3px is a Material default leaking
through `inherit: true`, not design tracking.
Either fix clears P04:
1. **Core typography (preferred):** `NestType._inter/_nunito` default
   `letterSpacing: letterSpacing ?? 0` (or zero it in `NestTheme`'s
   textTheme) so the design's "no tracking" applies app-wide.
2. **Core component:** `NestToggle` `minWidth: 59` → the design's 51 (the
   track still clears the 44px tap target); P04's column matches the
   design's 255px and the title fits even with the leak.
Blast radius: (1) every text on every screen; (2) every `NestToggle` screen.
P04's proof is `[P04-10]` in
`app/test/features/privacy_consent/p04_bugs_test.dart` (fails now: title
height 44 vs 22, card 116 vs 94).
Files: `app/lib/core/design_system/tokens/typography.dart` (or
`theme/nest_theme.dart`) and/or
`app/lib/core/design_system/components/nest_toggle.dart`.
Blocks: yes for P04's PASS this iteration; a P04-local `letterSpacing: 0` on
the opt-card title would clear this screen but leave the leak everywhere else.
**Status (iteration 8): P04 cleared locally** — the view zeroes the opt-card
title's `letterSpacing` (`privacy_consent_view.dart`), so the title is one
22px line and the card is back at the design's 94px; `[P04-10]` un-skipped
and green. **The shared half stays open**: the Material 0.3px tracking still
leaks into design text on every other screen until `NestType`/`NestTheme`
(or `NestToggle` width) is fixed in core.

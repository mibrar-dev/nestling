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
un-skipped and green. Leftover for the next build stage: P04 still passes
`title: ''` with the now-obsolete TODO comment at
`views/privacy_consent_view.dart:38-42`. It renders identically, so nothing
is broken; the workaround and its comment can go.

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

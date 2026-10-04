# P16 Settings — build plan (Stage 1)

Route `/settings` (SettingsRoutePaths.settings) · feature `settings` · parent mode only (kid mode redirects to P17 gate via router guard). Family branch of ParentShell → Family tab active; no per-screen tab-bar code.

Source of truth: `design/html-source/screens/P16-settings.html` (copy compared char-by-char below) + `design/screens/light|dark/P16-settings.png` (1170×2532 ÷ 3 = 390×844 logical). PNG shows the viewport scrolled to top (title → Subscription card); Notifications → About live below the fold in the same scroll.

## (a) Widget tree, top → bottom (all tokens, no hard-codes)

```
Scaffold (paper bg via NestTheme)
├─ NestStatusBar.new()                       // height 47 only; OS draws glyphs (ignore in UI check)
├─ Expanded: ListView(padding: L/R 20, bottom 32; separators 16)
│  ├─ Title "Family & settings"               // Nunito 900 28/34 (`.ptitle`: padding-top 8, wrap-anywhere)
│  ├─ NestSectionLabel("Family")              // 13/700 uppercase ls +6% ink-2; margin-top 24, +8 below
│  ├─ NestList (surface, r-m 16, sh-1; dividers 1px overlay inset left 72)
│  │  ├─ NestListRow(title "Sarah — you", subtitle "sarah@example.co.uk",
│  │  │    leading NestAvatar s32 leaf "S", no chevron, onTap: null (static row))
│  │  ├─ NestListRow(title "James — co-parent", subtitle "Invited · awaiting reply",
│  │  │    leading NestAvatar s32 sky "J", static)
│  │  └─ NestListRow(title "Invite co-parent", subtitle "Share the load",
│  │       leading 40px tile (surface-2, r 12, plus icon 24 ink), trailing "›" (ink-3),
│  │       onTap → toast placeholder; semantics label "Invite co-parent")
│  ├─ NestSectionLabel("Children")
│  ├─ NestList
│  │  ├─ NestListRow("Maya · 7–9" / "Pip: Fledgling · 120 coins", avatar s32 lilac "M", ›,
│  │  │    onTap → push /child-profile)       // child order: Maya then Leo (creation order, never alpha)
│  │  ├─ NestListRow("Leo · 4–6" / "Pip: Hatchling · 45 coins", avatar s32 peach "L", ›,
│  │  │    onTap → push /child-profile)
│  │  └─ NestListRow("Add child" / "Nickname + age band only", 40px plus-tile, ›,
│  │       onTap → push /add-children)
│  ├─ NestSectionLabel("Subscription")
│  ├─ NestCard.standard (surface, r-l 24, sh-1, padding 14h/16v — `.subcard` wins over base 16)
│  │  ├─ Text "Nestling Annual · £29.99/year" (16 w700 ink; static design copy — no DB field for plan/price)
│  │  ├─ Text "Renews 18 Oct 2027 · Covers the whole family" (13 ink-2, margin-top 2; static)
│  │  └─ 52px-min row: Text "Manage subscription" (15 w600 leaf) + "›" (ink-3),
│  │       onTap → push /paywall; semantics button "Manage subscription"
│  ├─ NestSectionLabel("Time zone")  // NEW, orchestrator-mandatory; placed directly after Subscription
│  ├─ NestList > single NestListRow(title "Time zone",
│  │    subtitle "{Short} ({GMT±n})" e.g. "London (GMT+0)" / "Dubai (GMT+4)" — short label only, never raw IANA,
│  │    trailing "›", onTap → opens zone picker sheet)
│  ├─ NestSectionLabel("Notifications")
│  ├─ NestList
│  │  ├─ NestListRow("Approvals waiting", no subtitle, trailing NestToggle ON,
│  │  │    toggle semantics "Approvals waiting notifications")
│  │  ├─ NestListRow("Payout day reminder" / "Friday before Saturday payout", NestToggle ON)
│  │  └─ NestListRow("Weekly family summary", NestToggle ON)
│  ├─ NestSectionLabel("Privacy")
│  ├─ NestList
│  │  ├─ NestListRow("Download our data", ›, onTap → push /privacy)
│  │  ├─ NestListRow("Privacy Notice", ›, onTap → push /privacy)
│  │  └─ NestListRow("Delete family account" (danger colour w700, no chevron),
│  │       onTap → NestModal confirm (Cancel / "Delete" danger); confirm → toast only + TODO(P16),
│  │       never wipes DB silently)
│  ├─ Inset info row `.lockhint` (surface-2, r-m 16, padding 12h/14v, gap 10):
│  │    lock icon 24 + Text "Kid mode needs parent gate — " + bold "On"/"Off" (em dash —, static, no toggle;
│  │    reflects kidGateEnabled from DB; 14/20)
│  ├─ NestSectionLabel("About")
│  └─ NestList
│     ├─ NestListRow("Help & feedback", ›, onTap → toast placeholder "Help & feedback is coming soon")
│     └─ NestListRow("Version 1.0.0" / "Made in the UK · No ads, ever", static, no chevron, onTap null)
└─ (tab bar + home-edge owned by ParentShell/NestTabBar; surface runs to physical edge — no tint strip)
```

Move banner (orchestrator-mandatory, session-once): when `pendingMove()` returns non-null zone Z and Z not in bloc `dismissedZones`, insert a leaf-tint NestCard directly below the title (above Family label) with exact copy: "Looks like you're in {Short} now. Switch the family time zone? History keeps London times; future days follow {Short}." + row of two small buttons: "Switch" (primary) → `confirmPendingMove()`; "Not now" (ghost) → adds Z to `dismissedZones` (bloc-local, never DB). Never auto-switches; kid mode never sees it (parent-only route).

Zone picker sheet: NestBottomSheet (grabber, paper bg, padding 8/20/50) with title "Time zone" + rows: device zone first (when known and ≠ family zone, subtitle shows IANA + " · Current location"), then curated list `Europe/London`, `Europe/Paris`, `America/New_York`, `Asia/Dubai`, `Asia/Karachi`, `Australia/Sydney` (each row: title = short label, subtitle = IANA id + GMT offset; checkmark on current family zone). Row tap → `setFamilyTimeZone(id)` + close sheet. Unknown ids ignored by service (no-op).

Copy notes (exact glyphs): em dash — in "Sarah — you", "James — co-parent", lock hint; en dash – in "7–9", "4–6"; middle dot · in subtitles ("Invited · awaiting reply", "Pip: Fledgling · 120 coins", "Nestling Annual · £29.99/year"); chevron › (text glyph, ink-3). Title "Family & settings" (&, not "and"). Never show raw IANA except picker subtitle.

Spacing recap: side gutters 20 everywhere; scroll siblings 16; sect margin-top 24 / 8 below; list rows min-height 56 (toggles min-height 52 per `.linkrow`); subcard padding 14/16; lockhint padding 12/14 gap 10. Cards/bars left/right edges all at x=20/370.

Pip: no Pip on this screen (avatars only) — PIP rule N/A. No coins/£ logic beyond static copy (DB values shown: coin counts + Pip stage names "Fledgling"/"Hatchling" from children rows).

## (b) BLoC + repository (local Drift, existing repo)

State (`SettingsState`, extend): `status`, `settings: AppSettings?`, `familyRoster: List<SettingsChildEntry>` (nickname, ageBand, pipStageName, coins, avatarColour, id — Maya then Leo by createdAt), `memberRows` static (Sarah/James from members table), `familyZoneId` (default Europe/London), `pendingZone: String?`, `dismissedZones: Set<String>` (default {}), `errorMessage`. No google_fonts anywhere.

Events (extend `SettingsEvent`): keep `SettingsLoadRequested`; add `SettingsNotificationsChanged({approvals?, payout?, summary?})`, `SettingsTimeZonePicked(zoneId)`, `SettingsMoveConfirmed()`, `SettingsMoveDismissed(zone)`.

Bloc wiring: `SettingsBloc(repository, zoneService: FamilyZoneService)` — both injected via `registerSettings` (settings_di.dart, feature-owned, editable). On Load: `emit.forEach` on combined stream (watchSettings + watchFamilyZoneId + roster stream + one-shot pendingMove, re-checked on zone change) — never re-add load events to refresh. Handlers call `repository.setNotifications(...)`, `repository.setFamilyTimeZone(id)` / `zoneService.confirmPendingMove()`.

Repository (settings-owned, editable): add `Stream<List<SettingsChildEntry>> watchRoster()` (children ordered by createdAt asc) + `Stream<List<SettingsMemberEntry>> watchMembers()` reading Drift tables directly in `SettingsRepositoryImpl`; new Equatable entities in `domain/entities/`. Reuse existing `watchSettings`, `setNotifications`, `setFamilyTimeZone`, `watchFamilyTimeZone`. GMT offset note: compute in view/bloc via `toFamilyZone(nowUtc, id).timeZoneOffset` → "GMT+4"/"GMT+0" (BST → GMT+1); no new shared helper (local format fn in feature widgets file).

## (c) Interactions → routes

| Control | Action |
|---|---|
| Maya / Leo row | `context.push(FamilyRoutePaths.childProfile)` (`/child-profile`) |
| Add child | `context.push(FamilyRoutePaths.addChildren)` (`/add-children`) |
| Invite co-parent | toast "Co-parent invite is coming soon" (no route exists) |
| Manage subscription | `context.push(PaywallRoutePaths.paywall)` (`/paywall`) |
| Time zone row | bottom-sheet picker (in-place, no route) |
| Notification toggles | direct DB write via bloc event (no nav) |
| Download our data / Privacy Notice | `context.push(PrivacyConsentRoutePaths.privacy)` (`/privacy`) |
| Delete family account | NestModal confirm → toast only (no nav, no DB wipe) |
| Help & feedback | toast placeholder (no route exists) |
| Version row | static, not tappable |
| Move banner Switch / Not now | `confirmPendingMove()` / session dismiss (no nav) |

## (d) Empty / loading / error

Loading: full-screen `Center(CircularProgressIndicator)` (matches current view). Loaded: tree above; roster lists always have ≥1 family member in demo/empty seeds (`Seed.empty` keeps Sarah + children? P08b seed = onboarded parent no children → Children list shows only "Add child" row; Family list always shows Sarah). Error: centered message + "Retry" button re-dispatching `SettingsLoadRequested` (permitted: stream terminated; not polling). Delete confirm + toasts via NestModal/NestToast.

## (e) Accessibility

Every tappable row wrapped in `Semantics(button: true, label, onTap:)` (NestListRow already does this when onTap != null); toggles carry `semanticLabel` + `toggled` + tap action (NestToggle built-in); danger row label "Delete family account"; sheet rows labelled with zone short label. Tap targets: rows ≥56 high, toggles 59×45 hit slop, link rows ≥52. Text scale: app clamps 1.0–1.3; titles maxLines 1 ellipsis, subtitles maxLines 1 ellipsis, subcard texts wrap. Width 320: roster rows keep avatar+chevron fixed, text Flexible ellipsis; subcard/linkrow wrap; no fixed 170px grids on this screen — safe.

## (f) Test plan (`app/test/features/settings/**`, feature-owned)

Unit: roster order Maya→Leo from Seed.demo; shortZoneLabel; GMT-offset formatter; unknown zone id ignored by setFamilyTimeZone; movedToDubai fixture flips zone without touching instants. Bloc: toggles flip DB (watchSettings emits); TimeZonePicked stores zone + mirrors settings.time_zone; MoveConfirmed stores device zone; MoveDismissed only touches bloc set. Widget (pump SettingsView via test_scope, end with disposeApp): all copy char-exact (—, –, ·, ›, &); toggles expose SemanticsAction.tap and performAction flips real DB value; time-zone row shows short label; banner appears once with deviceZoneReader Dubai, Switch confirms (DB=Asia/Dubai), Not now hides for session; picker lists device zone first; no google_fonts imports. UI check (stage 5 only, simulator 604697A9…): shot.sh light+dark vs PNG; title/first-row/cards y within ±2px; bottom edge = tab-bar surface to edge; gutters 20.

## (g) SHARED_REQUEST

None. Time-zone data layer already on main (`FamilyZoneService`, `SettingsRepository.setFamilyTimeZone/watchFamilyTimeZone`, `Seed.movedToDubai`, `shortZoneLabel`). No schema, route, DI, or design-system changes needed. Subscription plan/price/renew-date copy stays static (no DB fields — data-over-mocks does not apply).

VERDICT: PASS

# Shared batch 6 — REPORT (branch `shared/shared_batch6`)

Scope: P16 `SHARED_REQUEST.md` §§1–5 (plus `3_test.md` §4 revert costs).
All changes are minimal and backward-compatible: no public API renames, no
route changes, no `app/lib/features/**/presentation` screen code touched.
Defaults unchanged everywhere except the two measured design fixes
(section label 18→16, new `members.email` column + `NestCard.radius`).

Evidence read first: P16 `SHARED_REQUEST.md` §§1–5, P16 `3_test.md` §4,
`docs/ARCHITECTURE.md`, `docs/screens/RULES.md`,
`docs/design/SPACING_SPEC.md` (`.list-row` 56/60, `.toggle` 51×31 +
`::before` −4/−7, `.sect`/`.qgroup` 13 w700 ls .06em no line-height,
`.card` r-l 24 pad 16), `tools/screens/stages/common.md` (owner rules),
`design/html-source/screens/P16-settings.html:4-7,18-19,29,32-34`
(`.sect`, `.subcard`, owner/Invite rows, toggle rows),
`design/html-source/components.css:107-140` (list-row, toggle),
`design/html-source/tokens.css:77` (`--r-m:16`),
`app/lib/core/design_system/components/nest_{list_row,toggle,chip,chip_wrap,card,section_label}.dart`,
`app/lib/core/design_system/tokens/typography.dart`,
`app/lib/core/data/{app_database,seed,family_time,family_zone_service}.dart`.

## Files changed

- `app/lib/core/design_system/components/nest_list_row.dart` — trailing
  `ConstrainedBox(maxWidth)` → `_TrailingSlop` (lays out at intrinsic size,
  hit-tests the toggle's 59×44); `Padding` → wrapped in
  `_RowSlopForwarder` (same size, retries the trailing directly when the
  normal `Padding→Row` path rejects a tap in the row padding). Same
  padding/overflow pattern as `NestChip`/`NestToggle`. Row stays 56 with a
  51×31 toggle; 44 tap overhangs instead of adding layout.
- `app/lib/core/design_system/tokens/typography.dart` — `sectionLabel`
  13/18 → 13/16 (w700 ls .78 kept): the browser sets no line-height on
  `.sect`/`.qgroup`, natural box measured 16 px at 1.0 (P16 `3_test` §4).
- `app/lib/core/design_system/components/nest_card.dart` — new optional
  `radius: double?` (null → 24 `allL` for every variant, defaults unchanged;
  `padding:` already existed). Applies to `BoxDecoration`, `Material` and
  `InkWell` together, so the ripple stays on the card (fixes the
  `SHARED_REQUEST` §3 `Material` fork cost).
- `app/lib/core/data/app_database.dart` — `Members.email TEXT NULL` (v7),
  `schemaVersion` 6→7, `if (from < 7) addColumn(members.email)`, new
  `watchMembers([familyId])` (insertion/`rowid` order — the core row/query
  P16 reads for its Family section).
- `app/lib/core/data/app_database.g.dart` — regenerated via
  `dart run build_runner build` (email column + companions).
- `app/lib/core/data/seed.dart` — demo/empty/onboardingKids owner Sarah
  carries `sarah@example.co.uk`; James (co-parent, invited) stays NULL
  (P16 design shows “Invited · awaiting reply”, not an address).
- `app/lib/core/data/family_time.dart` — new `_zoneAliases` (IANA backward
  links the bundled `latest_10y` omits) + `canonicalZoneId()`; `isKnownZoneId`
  / `normalizeZoneId` / `resolveWriteZone` resolve links before `getLocation`
  (never stamp an alias).
- `app/lib/core/data/family_zone_service.dart` — `deviceZoneId` returns
  canonical (`normalizeZoneId`), `familyZoneId`/`watchFamilyZone` return
  canonical, `setFamilyTimeZone` stores canonical (DB never holds an alias).
- Tests: new `app/test/design_system/shared_batch6_test.dart` (13 tests),
  new `app/test/core/data/members_email_test.dart` (4 tests); updated 5
  migration fixtures to include the real `members` table (pre-v7 shape, no
  email) and 2 auth tests for the new column (see below).
- `app/lib/features/**/presentation/**`: untouched (per task).

## Item 1 — NestListRow + NestToggle stays 56 (§1) → DONE

Was: a 44-high trailing wrapper + 10 px row padding grew the row 56→64
(`3_test` §4); `NestToggle`'s own 59×44 slop never saw taps 5 px above/below
because the inner `Row` (31–40 high) rejected them first — and the old
`ConstrainedBox` trailing clipped before the toggle too.

Now: trailing lays out 51×31, hit-tests 59×44; the forwarder retries the
trailing directly for taps in the row padding. Row height unchanged (56
title-only, 60 title+sub — CSS `min-height:56 + padding 20`).

Tests (`shared_batch6_test.dart`, `pumpBothModes` light+dark):

- `row stays 56 with a toggle (44 tap overhangs, not layout)`
  (`getSize(NestListRow) ≈ 56 ±0.5`, `getSize(NestToggle) == 51×31`)
- `a tap 5 px above/below the track toggles it`
  (`tapAt(track.top−5) → [true]`, `tapAt(track.bottom+5) → [true,false]`
  via `StatefulBuilder`)
- `semantics expose the toggle action`
  (`byLabel(RegExp('Approvals waiting notifications'))` has
  `SemanticsAction.tap`; RegExp because the row title Text merges with the
  toggle label when `onTap` is null)

Merged impact: `list_row_trailing_test.dart` (56/60 pins) still green — no
update (new == design).

## Item 2 — NestSectionLabel 18→16 (§2) → DONE

Was: shared `sectionLabel` pinned 18 px line box; browser natural is 16 px
at 1.0 (P16 measured 18 vs 16, 23 vs 21 at 1.3). Now 13/16 w700 ls .78.

Checked every merged `NestSectionLabel` use (grep) against its design PNG:

- `today_loaded_body.dart:685` (P08 `.qgroup`: 13 w700 uppercase ls .06em,
  no line-height — same as P16 `.sect`) → new 16 == design. No test pins
  the old 18 (full suite green) — no update.
- `design_system_gallery` (`pip_lab`, `motion_lab`, `gallery_*` — dev-only
  `/design-system`, no design PNG) → no check, no update.
- `overflow_test.dart:280,428`, `display_test.dart:272` (shared widget smoke
  tests, no line-box pin) → green, no update.
- `letter_spacing_test.dart:60-65` (pins ls .78 only, not height) → green.

Tests:

- `sectionLabel is 13/16 w700 ls .78 (browser natural, not 18)`
- `label lays out 16 high at scale 1.0`

## Item 3 — NestCard radius + padding (§3) → DONE

Was: `NestCard.standard` always `allL` 24; P16 `.subcard` needs `--r-m` 16
(`tokens.css:77`) + `padding:14px 16px` (`P16-settings.html:7`), so P16 forked
a local surface `Container` (losing `NestCard`'s inner `Material`, breaking
the `Manage subscription` ripple — `FIXES_2.md` obs 2). `padding:` already
existed; `radius:` is new (null → 24, defaults unchanged).

Tests:

- `defaults unchanged (24 radius, 16 padding)`
- `subcard override (16 radius, 14/16 padding)`
- `tap variant keeps the override on Material + Ink`

Merged impact: none (defaults unchanged, full suite green).

## Item 4 — members.email (schema v7) (§4) → DONE

Was: `grep -i email` over `lib/core/data/*.dart` + `app_database.g.dart`
returned 0 hits (only P16 hard-coded `settings_view.dart:468` + gallery
`hintText`); `auth_repository_impl.dart:38` documented the omission.
Now: `members.email TEXT NULL`, v6→v7 `ADD COLUMN` (NULL backfill, no data
migration), demo/empty/onboardingKids Sarah = `sarah@example.co.uk`, James =
NULL, `watchMembers()` exposes `Member.email` in insertion order.

Tests (`members_email_test.dart`):

- `demo owner carries sarah@example.co.uk, James is NULL`
- `watchMembers exposes email in insertion order (Sarah, James)`
- `empty + onboardingKids seeds keep the owner email`
- `v6 → v7 migration keeps every row and email is NULL` (raw v6 DB +
  `PRAGMA user_version = 6`, then new writes/updates carry email)

Merged-test updates (new == DB, so updated):

- 5 migration fixtures now include the real `members` table (pre-v7 shape,
  no email) — without it the v7 `ADD COLUMN members.email` fails with
  `no such table: members` on the artificial minimal DBs (real v1–v6 DBs
  always have `members`): `children_order_test.dart` (`_v2Ddl`),
  `quest_order_test.dart` (`_v3Ddl`), `rewards_order_test.dart` (`_v4Ddl`),
  `completion_note_test.dart` (`_v5Ddl`), `time_migration_test.dart`
  (`_v1Ddl`). One line each, no behaviour change.
- 2 auth tests now expect the v7 column (password still absent; the stub
  still only derives the name — storing the email is the follow-up below):
  `seeded_submit_test.dart` (schema `contains('email')`, DB row email NULL),
  `auth_bloc_test.dart` (`contains('email')`, `isNot(contains('password'))`,
  row email NULL).

## Item 5 — IANA links (§5, P16-B09) → DONE

Was: bundled `latest_10y` (341 locations, no backward links) rejected
`Europe/Belfast`, `GB`, `Asia/Calcutta`, `US/Pacific`, `Europe/Kiev`,
`Asia/Saigon` → `deviceZoneId()` null, no move prompt, no “Current location”
row. Now: `_zoneAliases` resolves links to canonical before every
`getLocation` (UK: Belfast/`GB`/`GB-Eire` → London; `Asia/Calcutta` →
`Asia/Kolkata`; plus Saigon/Rangoon/Katmandu/Ulan_Bator, Kiev→Kyiv, US/*
→ America/*, Canada/*). `normalizeZoneId` returns canonical, never an alias;
`resolveWriteZone`/`deviceZoneId`/`setFamilyTimeZone` never stamp an alias.

Tests (all in `shared_batch6_test.dart`):

- `Europe/Belfast resolves to Europe/London`
- `Asia/Calcutta is accepted as Asia/Kolkata`
- `GB resolves (country link to London)`
- `canonical zones still resolve unchanged`
- `unknown ids still fall back safely`

Merged impact: `family_time_test.dart` (London/Dubai/unknown fallbacks)
still green — no update.

## Gates

- `cd app && dart format .` → clean (0 changed on re-run).
- `flutter analyze` → `No issues found!` (no new ignores).
- `flutter test` → `All tests passed!` (2908 passed, 2 skipped, 0 failed;
  includes 13 new `shared_batch6_test.dart` + 4 new `members_email_test.dart`;
  the 2 skips are pre-existing K01/P12).

## Follow-ups for screens (P16 must change — exact)

1. **Revert the three forks** (`ORCHESTRATOR_NOTES` 08:12 item 3;
   costs measured in `3_test.md` §4):
   - `_P16Sect` → shared `NestSectionLabel(label: …)` (typography identical —
     13 px w700 ls .78 ink-2 maxLines 1 — only the line box changed 18→16,
     now == design; no test of yours breaks).
   - Subcard → shared `NestCard(radius: NestRadii.m, padding:
     const EdgeInsets.symmetric(vertical: 14, horizontal: 16), child: …)`
     (`.subcard`: `border-radius: var(--r-m)` 16, `padding:14px 16px`,
     `P16-settings.html:7`; restores the inner `Material` so the `Manage
     subscription` ripple paints on the card, closing `FIXES_2.md` obs 2).
     Your two copy-addressed `subscriptionCard()` tests will fail by design
     until the revert (24 vs 16, all-16 vs 14/16) — that is the证明.
   - `SettingsRow` switch rows → shared `NestListRow(title: …,
     subtitle: …?, trailing: NestToggle(value: …,
     semanticLabel: '…', onChanged: …))` with **no** `SizedBox(width:51,
     height:44)` wrapper (that wrapper is what grew rows 56→64; the shared
     row keeps 56 via hit slop). Delete the P16-T03 `width:51` wrappers too —
     the shared trailing already preserves the full 59×44 (4 px horizontal
     slop); your T03 skip then passes. Your shell-agnostic T02 proof
     (track 51×31, content box ≥44, ±5 px taps flip the DB row) passes
     unchanged on the shared row.
2. **Field names (DB):** `members.email` (`TEXT NULL`), `Member.email`
   (`String?`), `MembersCompanion(email: Value(…))`, query
   `AppDatabase.watchMembers([familyId])` (`Stream<List<Member>>`,
   insertion/`rowid` order: Sarah, then James). Seed: owner Sarah
   `sarah@example.co.uk`, James `NULL` (design shows “Invited · awaiting
   reply”). Read the owner row subtitle from `members.email` (fallback to
   role-derived `Owner` when NULL); update the 4 literal-string tests
   (`settings_view_test.dart:113`, `settings_responsive_test.dart:365`,
   `settings_states_test.dart`, a11y control list) together. Auth follow-up
   (not P16, not this batch): `AuthRepository.createAccount` should persist
   the signup email into `members.email` instead of only deriving the display
   name (`auth_repository_impl.dart:38`, `:41`).
3. **NestCard params:** `radius:` (`double?`, px — pass `NestRadii.m` for 16,
   null keeps 24) and `padding:` (`EdgeInsetsGeometry?` — already existed;
   pass `EdgeInsets.symmetric(vertical: 14, horizontal: 16)` for the subcard).
4. **Zones (P16-B09):** no feature workaround needed — `isKnownZoneId` /
   `normalizeZoneId` / `FamilyZoneService.deviceZoneId` now resolve links
   (`Europe/Belfast` → `Europe/London`, `GB` → `Europe/London`,
   `Asia/Calcutta` → `Asia/Kolkata`); the picker lists London→Sydney plus the
   device zone, and `pendingMove`/`confirmPendingMove` store canonical.
   Un-skip the B09 proof.

VERDICT: PASS

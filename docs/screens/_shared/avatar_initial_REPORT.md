# Shared report — avatar_initial (grapheme-safe avatar initial)

Fixes K02-BUG-1 / K02-TEST-BUG-A / SHARED_REQUEST #3: an emoji (or other
non-BMP) first character in a child's nickname crashed avatar initials
across the app. `nickname[0].toUpperCase()` takes a UTF-16 code unit; for
`🐝 Bee` that is an unpaired surrogate and `toUpperCase()` throws
`string is not well-formed UTF-16`, failing the whole frame
(`/who-is-playing`, `/kid-home`, …). P05 accepts such nicknames (no
`inputFormatters`, no character filter), so every display is made safe
instead of blocking input.

## Files changed
- `app/lib/core/design_system/components/nest_avatar_initial.dart` — NEW:
  `String nestAvatarInitial(String name, {String fallback = '?'})`. Trims,
  returns `fallback` for empty/whitespace-only, else the first grapheme
  cluster (`package:characters`) upper-cased. `characters.first` is always
  well-formed, so `toUpperCase()` never throws (no-op for emoji/ZWJ).
- `app/lib/core/design_system/design_system.dart` — exports the helper.
- `app/pubspec.yaml` (+ lockfile) — `characters: ^1.4.1` promoted from
  transitive to direct dependency (was already shipped by Flutter).
- Avatar call sites (all `[0]`/`substring(0, 1)` initials replaced):
  - `app/lib/features/kid_home/presentation/widgets/profile_tile.dart:94`
    (`K01` tile) → `nestAvatarInitial(child.nickname)`.
  - `app/lib/features/kid_home/presentation/views/kid_home_view.dart:364`
    (`K03` header) → `nestAvatarInitial(nickname)`.
  - `app/lib/features/family/presentation/widgets/child_profile_body.dart:108`
    (`P15` hero) → `nestAvatarInitial(nickname)`.
  - `app/lib/features/family/presentation/widgets/kid_card_grid.dart:68`
    (`P05` cards) → `nestAvatarInitial(nickname)`.
  - `app/lib/features/today/presentation/widgets/today_loaded_body.dart:363`
    (parent `S` fallback) → `nestAvatarInitial(parentName, fallback: 'S')`.
  - `app/lib/features/today/presentation/widgets/today_loaded_body.dart:569`
    (kid `?` fallback) → `nestAvatarInitial(summary.nickname)`.
  - `app/lib/features/parental_gate/presentation/views/parental_gate_view.dart:400`
    (`•` placeholder) → `nestAvatarInitial(nickname ?? '', fallback: '•')`.
  - `app/lib/features/approvals/presentation/widgets/approval_card.dart:52`
    (`approvalInitial`, was `trimmed.substring(0, 1)`) → delegates to the
    helper with `fallback: ''` (preserves the card's empty-string contract).
  - `app/lib/features/quests/presentation/views/quest_editor_view.dart:859`
    (`_initial`, already `characters.first`) → delegates to the helper
    (single source; comment updated).
  - `app/lib/features/pocket_money/presentation/views/pocket_money_setup_view.dart:682`
    (already `characters.first`) → `nestAvatarInitial(child.nickname)`.
  - `app/lib/features/pocket_money/presentation/widgets/payout_sheet.dart:340`
    (already `characters.first`) → `nestAvatarInitial(name)`.
  - `app/lib/features/design_system_gallery/presentation/widgets/motion_lab_pip_panel.dart:158`
    (`_pretty` capitalize, not an avatar but the same UTF-16 class) →
    grapheme-safe (`characters.first` + `skip(1)`).
- `app/test/core/design_system/avatar_initial_test.dart` — NEW (see below).

## What / why
One shared helper instead of eleven local patches: SHARED_REQUEST #3 lists
7 sites across 4 features, and grep found 4 more of the same class
(parental gate, approvals, pocket-money ×2, plus the gallery capitalize).
All now delegate to `nestAvatarInitial`, which trims (so `"  maya"` →
`M`, `" "` → fallback) and uses `characters.first` (full emoji, accented
`É`, ZWJ `👨‍👩‍👧` stay intact). Existing fallbacks preserved: `?` for kids,
`S` for the P08 parent row, `•` for the gate placeholder, `''` for
`approvalInitial`. P05 input is untouched — emoji nicknames remain valid;
only display is hardened. Backward-compatible: same strings for all ASCII
names, same fallbacks, no API removed (`approvalInitial`/`_initial` kept
as delegating wrappers).

## Tests added (`app/test/core/design_system/avatar_initial_test.dart`)
Unit group `nestAvatarInitial`:
- `returns the emoji grapheme for an emoji-leading name` (`🐝 Bee` → `🐝`).
- `preserves an accented capital` (`Émile` → `É`).
- `upper-cases a lowercase letter` (`maya` → `M`).
- `returns the whole ZWJ sequence as one grapheme` (`👨‍👩‍👧 Fam` → `👨‍👩‍👧`).
- `empty name returns the fallback` (`''` → `?`/`S`/`''`).
- `whitespace-only name returns the fallback` (`' '` → `?`/`•`).
- `leading whitespace is ignored` (`'  maya'` → `M`, `'  🐝 Bee'` → `🐝`).
- `single emoji without text is returned as-is` (`🐝` → `🐝`).
Widget group `avatar initial widget regression (K02-BUG-1)` (temp DB rows,
asserts `currentPath` + `NestAvatar.initial`, never placeholder copy):
- `/who-is-playing renders with a 🐝 Bee child` (inserts `bee`/`🐝 Bee`,
  pumps `/who-is-playing`, `takeException()` null, avatar `🐝` present).
- `/kid-home renders with a 🐝 Bee active child` (renames `maya` →
  `🐝 Bee`, pumps `/kid-home`, `takeException()` null, avatar `🐝` present).
Grep proof: `grep -r '\[0\].*toUpperCase\|substring(0, 1)' app/lib` → no
matches. Remaining `[0]` in `app/lib` are list/byte indexes (`parts[0]`,
`names[0]`, `b[0]`) and two comments naming the old pattern — no string
initials.

## Follow-up for screen agents (do NOT land in this change)
- None required: ASCII names render identically and fallbacks are
  preserved, so merged screens need no edit. Unmerged branches carrying a
  local fix (`runes.first`/`characters.first` in K02, P09, P06) should
  swap it for `nestAvatarInitial` on their next `main` merge and drop the
  local helper. P05 keeps accepting emoji nicknames by design — do not add
  input filters.

## Verification
`cd app && dart format .` clean (0 changed), `flutter analyze` →
`No issues found!`, `flutter test --timeout 120s` → `01:45 +3267 ~2: All
tests passed!` (the `~2` skips are the pre-existing sibling parks).

VERDICT: PASS

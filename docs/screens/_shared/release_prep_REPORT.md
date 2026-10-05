# Shared release_prep report (release-blocking app fixes, no backend)

Branch: `shared/release_prep`. All six items from the task are implemented,
on-device only. `cd app && dart format .` clean (0 changed),
`flutter analyze` → No issues found!, `flutter test --timeout 120s` →
5260 passed, ~16 skipped, 0 failed (full suite, foreground).

## 1. Delete family account (P16)

Files: `app/lib/features/settings/domain/settings_repository.dart`,
`app/lib/features/settings/data/settings_repository_impl.dart`,
`app/lib/features/settings/presentation/views/settings_view.dart`.

What/why: new `SettingsRepository.deleteFamilyAccount()` — one transaction
that empties every table (`allTables` loop) and re-inserts a fresh
`app_state` row (id 1, onboarding incomplete, parent mode, trial with no
start — like `Seed.fresh`). The confirm dialog's Delete button now calls it,
then resets in-memory state (`AppModeController.selectMode(parent)` +
`AppSession.refresh()`) and `go`s to `/welcome` (router's onboarding guard
would send it there anyway). The "not available yet" toast is gone.

## 2. Download our data (P16)

Files: `app/lib/features/settings/data/family_data_export.dart` (new),
repository additions as above, `settings_view.dart` Download row.

What/why: `buildFamilyExport()` builds the JSON document (family, members,
children, quests, completions, ledger, goals, rewards, badges earned,
settings + meta with family zone and ISO-8601 UTC timestamps; `pinHash` is
dropped — verified `jsonEncode` never contains `pinHash`), writes
`nestling-export-<date>.json` to the temp dir and opens the OS share sheet
via `share_plus` (`SharePlus.instance.share`). Added `share_plus ^13.3.1`
and `url_launcher ^6.3.3` to `pubspec.yaml` (pubspec.lock updated). The share
call is injected (`ShareExportFn`) so tests mock it.

## 3. Privacy notice + terms links

Files: `app/lib/core/config/legal_links.dart` (new — both URLs in one
place), `create_account_view.dart` (`_LegalTarget` opens the hosted page),
`privacy_consent_view.dart` (modal summary kept, new `Full privacy notice`
link inside it), `paywall_view.dart` (Terms/Privacy open the pages; also
disabled while an action is working), `settings_view.dart` (Privacy Notice
row opens the notice).

What/why: all links open `https://getnestling.co.uk/privacy` and
`https://getnestling.co.uk/terms` with `LaunchMode.inAppBrowserView`.
`LegalLinks.launcherOverride` is the single test seam (product code never
sets it). Every control keeps its Semantics tap action (P03 also passes
`onTap:` on the wrapper node per the accessibility rule).

## 4. Logging

Files: `child_display.dart:18`, `family_bloc.dart:108`,
`quests_bloc.dart:125` (added `kDebugMode` guard + foundation import for the
last). Grep of all of `app/lib` for `print(`/`debugPrint(`/`log(`: the only
other hits are `pip_rive.dart` (3×), all already inside `assert((){…}())`
debug-only closures — left alone. No message carries names, emails or PINs
(avatar-colour token / error object only, debug builds only).

## 5. Notification defaults OFF

Files: `app_database.dart` (+ generated `app_database.g.dart` defaults),
`seed.dart`, `privacy_consent_repository_impl.dart`,
`settings_repository_impl.dart` (fallbacks), `settings_view.dart`
(fallbacks).

What/why: DDL defaults for `notifApprovals/Payout/Summary` are now false,
AND every first-row write is explicit (beforeOpen, P04 first-run insert,
seeds) because the DDL default only applies to new databases. `Seed.demo`
writes ON explicitly — the P16 design shows all three toggles checked, and
every demo-pinned test still passes. `Seed.empty/newFamily/onboardingKids`
ship OFF. No `schemaVersion` bump (no structural change; existing rows keep
their stored values), so no migration test was needed. Four old migration
stubs (`members_email`, `quest_order`, `rewards_order`, `completion_note`)
gained the faithful old-shape notif columns (`DEFAULT 1`) because
`beforeOpen` now writes them explicitly.

## 6. P15 clock leak

File: `app/lib/features/family/data/family_repository_impl.dart:41`.

What/why: `_defaultClock()` was `Seed.anchorOverride ?? DateTime.now()` in
product code — now `appNowUtc()` (pinned test clock, wall clock in
production). `DateTime.now()` is gone from the file.

## Tests

New file `app/test/shared/release_prep_test.dart` (19 tests): legal URL
constants; launcher called with the right URL + inAppBrowserView (unit +
override seam); one widget tap per control (P03 Terms, P03 Privacy via
semantics action, P04 full-notice link, P07 Terms+Privacy) asserting the URL
and the unchanged router location; delete wipes every table except the
fresh `app_state` row; second launch reads a fresh install; export document
keys/zone/ISO content, no-PIN-hash proof, file-name shape, mocked share
call; notif OFF on first-run/empty/newFamily/onboardingKids/fresh-missing
row + demo-ON preservation; no-`DateTime.now()` source guard.

Updated: `settings_navigation_test.dart` (delete now wipes + lands on
`/welcome` incl. second-launch redirect proof; Download row keeps tap action
and never navigates; Privacy Notice opens the hosted URL),
`p16_transient_guard_test.dart` (guard fence/expiry proved through the
Download row's export toast — needs `settleSettings`' real-time wait for
the platform channel), `paywall_view_test.dart` (legal links open hosted
pages), `privacy_consent_repository_test.dart` (inserted-row notif
defaults are OFF), 4 migration stubs (faithful old-shape notif columns),
`_RosterFlakyRepository`/`_FailsOnceRepository` (delegate the two new
repository methods), stale `[P16-T01]` comments.

## Follow-ups for screen agents

- P16 design still shows notification toggles checked — that is the SEEDED
  demo only; new families install with OFF. Do not "fix" the seed.
- `LegalLinks.launcherOverride` is test-only; never set it in product code.
- The P16 Download row shows `Couldn’t prepare the export — try again` on
  failure and stays on `/settings`; the share sheet is OS UI (no route).
- P03 legal overlay geometry is unchanged (hit-test proofs untouched); taps
  are now live — the BUG-22 overlap rule (submit wins) still holds.

VERDICT: PASS

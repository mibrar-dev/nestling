# prod_checklist report — shared/prod_checklist

## Files changed

- `docs/PRODUCTION_CHECKLIST.md` (new) — the deliverable: UK App Store + Play
  readiness audit grouped per the task (§1–§9) with status / evidence /
  next-step for every item, plus release-blocking summary and owner actions.
  Links to `docs/SETUP_CHECKLIST.md` for accounts/legal/keys instead of
  repeating it.
- `docs/screens/_shared/prod_checklist_REPORT.md` (this file) — what was run.

No app code touched (`AUDIT + WRITE ONLY`): no edits under `app/lib/`,
`app/test/`, `pubspec.yaml`, or any `features/<feature>/presentation/**`.

## What / why

Audited the repo for real evidence (file:line or command output, no invented
URLs/numbers) and wrote the checklist. Key findings: release signing is still
debug keys (`build.gradle.kts:33-37`), no flavours/`.env.example`, no
obfuscation config, dev gallery is the default route and reachable in release
(`router.dart:73-79,172`), 3 unguarded log calls, backend/payments/push are
local-only stubs by design (TODOs in `auth_repository_impl.dart`, toast-only
deletion in `settings_view.dart:399`, inert P03 legal links), crash toggle is
OFF-by-default but sends nowhere (no SDK wired), P12-BUG-04 (< 44 px
segmented at 320 dp) is the one BACKLOG item that blocks submission on
accessibility grounds, and release builds/sizes were not run in this pass.

## Commands run (this worktree)

- `git branch --show-current` → `shared/prod_checklist`; `git status` clean
  except the two new docs.
- `flutter --version` → 3.47.5, Dart 3.13.4 (matches task).
- `cd app && dart format --output=none --set-exit-if-changed .` → 681 files,
  0 changed.
- `cd app && flutter analyze` → `No issues found!` (6.7 s).
- `cd app && flutter test --timeout 120s` → `All tests passed!`
  (275 `*_test.dart` files; 5,231 passed, ~16 skipped).
- `flutter build appbundle --release` / `flutter build ipa` → **not run**
  (release signing unwired; recorded as ⚠️ in the checklist with CI next
  steps). No `flutter clean`, no `flutter run`, no other worktrees touched.
- Greps/reads backing every checklist row: `build.gradle.kts`, `project.pbxproj`,
  `Info.plist`, `AndroidManifest.xml`, `pubspec.yaml`, `launch_flags.dart`,
  `launch.dart`, `router.dart`, `app.dart`, `launch_splash.dart`,
  `env_flags.dart`, `app_database.dart` (schema v7, defaults, `clearAll`),
  `app_session.dart` (14-day trial), `seed.dart`, `pin_hash.dart`,
  `auth_repository_impl.dart`, `paywall_repository_impl.dart`,
  `paywall_view.dart`, `paywall_bloc.dart`, `privacy_consent_view.dart`,
  `privacy_consent_repository_impl.dart`, `create_account_view.dart`,
  `settings_view.dart`, `parental_gate_repository_impl.dart`,
  `semantics_actions_test.dart`, `BACKLOG.md`, `MARKETING.md`, `PRICING.md`,
  `TECH_STACK.md`, `SETUP_CHECKLIST.md`, `design/store/` contents.

## Test names added

None — docs-only change per the task (`do not change app code`). Verified the
existing suite still passes (see above) instead.

## Follow-up screens must do

- Nothing — shared docs only, no shared-code change, so no screen merges or
  rebaselines are needed. Screen agents should read §9 of the checklist for
  the BACKLOG items that touch their screens (notably P12-BUG-04).

VERDICT: PASS

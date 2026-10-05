# Shared backlog (do after all screens are merged)
- ~~NestSegmented with 6 options at 320 dp shrinks each option below the 44 px tap target (P12-BUG-04, proof skipped in app/test/features/pocket_money/p12_bugs_test.dart; see docs/screens/P12/SHARED_REQUEST.md).~~ DONE 5 Oct
- Parent-tab page title (`.ptitle`) is re-implemented privately in 4+ screens. Extract a shared NestPageTitle and migrate the screens (P12 review finding 6).
- Repositories read the family id from the seed constant `Seed.familyId` (10+ feature repos). OK for local-only (one family per device), but before Supabase, expose the current family from AppSession and replace every `Seed.familyId` in app/lib/features with it.
- ~~P15 family_repository_impl.dart:41 uses `Seed.anchorOverride?.toUtc() ?? DateTime.now()` in app code: replace with `clock.now()`/appNowUtc() (the test clock already pins the day); never read the seed test hook in product code.~~ DONE 5 Oct
- K03 still paints its own in-flow meadow band (kid_home_view.dart ~l.134-137, 550-599). Switch it to the shared kid_meadow when its next polish pass runs (see docs/screens/_shared/kid_meadow_REPORT.md).
- K01-BUG-7 (minor, latent): an orphaned child selection locks every tile on Who's playing (proof skipped in app/test/features/kid_home/k01_bugs_test.dart; docs/screens/K01/6_bugs.md). No shipped flow reaches it. Fix when K-screens that delete children land.
- NestListRow: static (non-interactive) rows in a list merge into the next interactive row's semantics announcement (P16 Family list → Invite button). Each row should be its own semantics node.
- Shared `Semantics(label:) > InkWell` pattern leaves an extra node (P16 settings_a11y_test pins it). Audit with the semantics_tap work.
- P17 minor review items (parental_gate_view.dart: canPop checks, typed-digit style, .gate-note margin, items rebuild filter, dead challenge model, CSS magic numbers → tokens): tidy in the cleanup pass.
- K02 keeps a feature-local `kidAvatarInitial` (kid_style_helpers.dart:65, used by kid_pin_view.dart:168 + its own test). Replace with shared `nestAvatarInitial` and delete the duplicate.
- K03 pet stage: nest rim 274 vs design 278 (K03-BUG-16) and bowl-height disagreement (K03-BUG-17; proofs skip-marked in k03_bugs_test.dart, see docs/screens/K03/SHARED_REQUEST.md #18). Re-measure the design PNG and settle it in the shared NestPetStage; un-skip both.

## K09 My jar (merged 4 Oct with 4 minor bugs open; proofs skipped in app/test/features/kid_jar/k09_bugs_test.dart)
- K09-BUG-10 `_relativeDay` (kid_jar_repository_impl.dart): rows older than last week or in the future get a wrong "This/Last <day>" label. Also label a same-day row "Today" (the demo seed is anchored to today, so on a Sunday the payout row reads "This Sunday").
- K09-BUG-9 a large history amount overflows its card at 320 px × 1.3 text.
- K09-BUG-8 `moveToSavings` writes a savings_move row when the goal does not exist (money leaves the jar to nowhere).
- K09-BUG-7/7b a load dispatched and the bloc closed in the same tick leaks a subscription.

- K05/K06 growth percentage: K05 floors the Pip growth percentage (K05-BUG-2) but K06 `PipGrowthCard` still uses `.round()`; make both floor so the two screens never disagree.

## K05 Quest complete (merged 5 Oct with 2 minor bugs open; proofs skipped in its bugs test)
- K05-BUG-5 a 4-digit lifetime count ellipsises on one line.
- K05-BUG-6 the progress node's semantics value contradicts its own label.

## K07 Pip evolves (merged 5 Oct, 1 latent minor open)
- K07-BUG-10 a stat number wider than its card (5+ digits at 320 px × 1.3) is clipped mid-digit; real counts are far below that. If needed, scale the three numbers together with one shared factor.

## Shell
- ~~Money tab icon: the parent tab bar draws a banknote glyph; every parent design (P08b, P16 …) draws a wallet/card glyph (rounded rect with a stripe). Swap the NestTabBar Money icon to the design glyph (flagged by P16 and P08b UI checks).~~ DONE 5 Oct

## K10 Payout day (merged 5 Oct, 1 latent minor)
- K10-BUG-4 the fund-card heading clamps a very long goal name at 320 px × 1.3.
- K10 copy: the saving line uses the goal title ("£5.50 went into your Lego Friends set") where the design says "your Lego fund" — owner may want a shorter phrase.

- K03B-BUG-2 (shared, latent): `explicitGeometry` in motion/pip_rive.dart adds `_explicitBleed` to `slotHeight`; K03b works around it with `pipBottom: 92`. Fix in shared code and drop the workaround.

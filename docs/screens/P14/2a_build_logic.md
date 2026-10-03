# P14 · Rewards manager — Stage 2a build logic (iteration 2)

Owner: logic builder. Layer: `domain/**`, `data/**`, `presentation/bloc/**`,
DI/route registration, plus unit/bloc tests (`bloc`/`repository` names) and
the three un-skipped bug proofs FIXES_1.md references. Views/widgets untouched
(UI builder owns them); no simulator used.

## CONTRACT CHANGES (additive only — existing call sites compile unchanged)

All four write events gain an optional `Completer<void>? result` channel
(review finding 1, P14-B03 logic half). The existing `const` constructors are
kept with `result` defaulting to null (a `const` constructor may declare a
`Completer?` parameter), so the view's fire-and-forget `bloc.add(...)` calls
need no edit. Callers that must observe the write (the editor sheet) pass
`result:` and await it:

- success → `result.complete()` after the write lands (the `watchItems`
  stream then re-emits the new list as before);
- failure → `result.completeError(error)`; the bloc **no longer emits
  `failure` for action writes**, so a failed write can never replace the
  loaded list with a full-screen error (review finding 1.2, P14-B03 root
  cause). Callers with no channel observe nothing; the list stays as it was.
- `result` is excluded from Equatable `props` (identity channel, not value).
- The stream's own error in `_onLoadRequested` is still the only source of
  the full-screen `failure` state, which is what `Try again` is for.

UI builder wiring still needed (their layer): `_submit()` awaits the
completer, keeps the sheet open with the `danger` 13/18 w600 caption above
Save on error, disables Save while the write is in flight (review finding
1.3–1.4); toggles pass a channel too so a failed flip can surface feedback.

## Files changed

- `app/lib/features/rewards/presentation/bloc/rewards_event.dart` — optional
  `result` on all four write events (contract above).
- `app/lib/features/rewards/presentation/bloc/rewards_bloc.dart` — handlers
  complete/completeError the channel; write-failure `failure` emits removed.
- `app/lib/features/rewards/data/rewards_repository_impl.dart` —
  `watchItems()` now serves `watchRewardsInCreationOrder` (P14-B05 major;
  the legacy price query stays in shared code for compatibility); 
  `deleteReward` removes the reward **and** its `reward_redemptions` rows in
  one transaction (P14-B04).
- `app/test/features/rewards/rewards_bloc_test.dart` — pinned creation order
  `[r-screen, r-film, r-bedtime, r-baking, r-cafe, r-dinner]` + seeded
  `needsOk` map (baking OFF); toggle test flips r-screen; create lands last;
  update keeps its creation slot; failure group rewritten for the channel
  (four `completeError`-with-no-emission proofs, one no-channel silence
  proof, success-completes proof, stream-error retry kept).
- `app/test/features/rewards/rewards_repository_test.dart` — new:
  creation-order pin, seeded-toggle pin, `deleteReward` redemption cascade
  (other rewards' requests survive).
- `app/test/features/rewards/rewards_order_test.dart` — `[P14-ORDER]`
  un-skipped (merge landed), comments updated.
- `app/test/features/rewards/p14_bugs_test.dart` — `[P14-B04]` and
  `[P14-B05]` un-skipped; stale "last card" comment fixed. B01/B02/B03 stay
  skipped (UI/shared layer: keyboard inset, scroll centring, sheet await).

Not changed (verified, already per plan): entities, repository interface,
`RewardModel`, `rewards_di.dart`, `rewards_routes.dart`; redemption
approve/deny untouched.

## FIXES_1.md items in this layer — all done

- Review 1 (major, logic half): result channel + no write-failure emits. DONE
- P14-B05 (major): creation-order query. DONE, proof live.
- P14-B04 (minor): cascade delete. DONE, proof live.
- `[P14-ORDER]` skip: removed, passes. DONE
- Review 2–6, 9 (view/sheet copy, spacer, centring, literals, force-unwrap,
  keyboard): UI builder's layer — not touched. Review 7–8 (view-test
  performAction/disposeApp): test stage's files — not touched. Review 10
  (probe scratch files): already gone from the tree.

## Verification

- `dart format lib/features/rewards test/features/rewards` clean.
- `flutter analyze lib/features/rewards test/features/rewards` → No issues
  found (single-`const`-constructor shape fixed the `prefer_const_*` infos;
  no ignores).
- `flutter test test/features/rewards/rewards_repository_test.dart
  test/features/rewards/rewards_bloc_test.dart` → 26/26 pass.
- Targeted proofs (name-filtered, not the whole files):
  `[P14-ORDER]` pass; `[P14-B04]` pass; `[P14-B05]` pass.
- Other feature test files checked statically: all order/toggle assertions
  are DB-driven (`rewardIdsInAppOrder`, `rewardNeedsOk`), the failure-state
  stub still hits the preserved stream-error path — no breakage expected
  from this layer. Full-suite green is the integrator's gate.
- No `google_fonts`, no `letterSpacing`, no shared-code edits.

## LEFT FOR NEXT ITERATION

Nothing in this layer. Open and owned elsewhere: B03 sheet-await + inline
caption and review 1.3–1.4 (UI builder, same worktree); B01 keyboard inset
(shared `showNestBottomSheet`, needs SHARED_REQUEST or feature-local pad —
UI builder call); B02 scroll centring + trailing spacer + failure copy
(UI builder); review 7–8 test hygiene (test stage).

VERDICT: PASS

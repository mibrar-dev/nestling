# P04 · Privacy consent — build notes (STAGE 2, iteration 3)

Feature `privacy_consent` · route `/privacy` · parent mode.
Built per `docs/screens/P04/1_plan.md`, fixing every item in
`docs/screens/P04/FIXES_2.md` that is fixable inside RULES §1, and
un-skipping the bug proof the fix turns green. `ORCHESTRATOR_NOTES.md`
(with its 12:03 UPDATE) is honoured: the header was not moved locally.

## Files changed (all inside RULES §1)

Production (`app/lib/features/privacy_consent/**`):

- `presentation/bloc/privacy_consent_bloc.dart` — the failure revert now
  restores the *stored* value (`_crashFrom(state.items)`, which mirrors the
  database) instead of `state.crashConsent`, which may be another tap's
  still-in-flight optimistic value (FIXES_2 finding 4 / P04-8). One line plus
  an intent comment; event shape, optimistic emit and stream reconciliation
  unchanged.
- `presentation/views/privacy_consent_view.dart` — deleted the stale
  `title: ''` workaround and its obsolete `TODO(P04)` (FIXES_2 finding 3);
  the bar is now `NestNavBar(compact: true, onBack: …)` with a null title,
  which the shared merge renders as `SizedBox.shrink()` in the same 60 px
  bar. The `canPop` fallback to `/create-account` is kept.

Tests (`app/test/features/privacy_consent/**`):

- `p04_bugs_test.dart` — un-skipped `[P04-8]` (green); header index marks it
  `[FIXED]`. `[P04-2]`, `[P04-4]`, `[P04-7]` stay skipped (shared-side, see
  below), each annotated with its repro and the shared change that turns it
  green.

Docs (`docs/screens/P04/**`): `SHARED_REQUEST.md` item 3 marked cleaned up
(workaround deleted); new screenshots `ui/app_{light,dark}_3.png` +
`ui/cmp_{light,dark}_3.png`.

## What happened to each FIXES_2 item

- Finding 1 (MAJOR, empty row-4 tile; orchestrator item 1) — NOT fixable in
  scope: `app/assets/icons/` still contains no trash can on main (verified;
  `ic_bin` is a wheelie bin, `ic_basket` a laundry basket), and RULES §1
  keeps `app/assets/**` + `app/lib/core/**` off limits while plan §g orders
  waiting for the asset with no stand-in. P04's side is ready: tile
  reserved, `TODO(P04)` in place, `[P04-2]` proof + contract-test `findsNothing`
  pin exact flip instructions (add `leadingAsset: NestIcons.trash`, un-skip,
  flip to `findsOneWidget`). Filed as SHARED_REQUEST item 1 since iteration 1.
- Finding 2 (MAJOR, +3 px divider drift; orchestrator item 3) — NOT fixable
  in scope: the height comes from shared `NestList`'s real `Divider`s;
  rebuilding the list locally would re-implement a design-system component
  (and `NestCard.standard` is r24 vs the list's r16). Rows themselves are
  exactly 56 px (40/r12 tiles, indent 72). Filed as SHARED_REQUEST item 6;
  `[P04-4]` stays skipped and pins `NestList.height == sum(rows)`.
- Finding 3 (MINOR, stale `title: ''`) — FIXED as described above; the bar
  resolves identically (60 px, probes unchanged — see UI check).
- Finding 4 (MINOR, revert-to-unpersisted) — FIXED as described above;
  `[P04-8]` un-skipped and green. Existing error-path tests (mock OFF-write
  failure, scripted `[P04-6]`) still pass unchanged: with static streams
  `_crashFrom(items)` equals the old `previous`.
- Finding 5 (MINOR, stale `2_build.md` sentences) — this note replaces
  them: no −16 px offset claim (header is pixel-exact since the shared
  merge), no "stays skipped" for `[P04-3]` (green), current suite tail below.
- Finding 6 (MINOR, remaining skips) — `[P04-2]` ← item 1, `[P04-4]` ←
  item 6, `[P04-7]` ← item 2. Kept skipped (red-by-design proofs of
  core-owned defects); un-skipping any of them would break RULES §7 for the
  whole app. This note, not "all tests pass", is where the open defects
  live: findings 1–2 above plus the dark shield disc (SHARED_REQUEST §2).

## Analyze tail (app/)

```
dart format --output=none --set-exit-if-changed lib/features/privacy_consent test/features/privacy_consent
→ 16 files, 0 changed
flutter analyze → No issues found! (ran in 3.7s)
```

## Test tail (app/, `flutter test`)

```
00:11 +585 ~3: All other tests passed!
```

585 passed, 3 skipped (the shared-blocked `[P04-2/4/7]` proofs), 0 failed.
P04 scope: 98 passed + 3 skipped, including the newly un-skipped `[P04-8]`
and the still-green `[P04-3]`.

## UI check (iteration 3)

`shot.sh /privacy` light + dark (`SEED=fresh`, parent, iPhone 16e) +
`compare.py` vs the design PNGs:

- Light mean diff **4.49%** — bands: 0: 1.57% · 1: 6.02% · 2: 1.98% ·
  3: 7.86% · 4: 7.31% · 5: 6.52% · 6: 0.40% · 7: 4.17%
- Dark mean diff **5.61%** — bands: 0: 1.55% · 1: 8.50% · 2: 9.14% ·
  3: 7.76% · 4: 7.12% · 5: 6.69% · 6: 0.39% · 7: 3.67%

Effectively identical to iteration 2 (null title renders the same bar), so
no pixel regression from either fix. Header is pixel-exact (chevron 66–80,
h1 113–138, subtitle 156–170, list top 289 — all Δ0 vs design). Residual
drift is the three filed shared causes — empty row-4 tile (§1, bands 3–5),
3 px divider rhythm (§6, bands 3–5, opt card 530 vs 527), light-baked dark
shield disc (§2, dark band 2) — plus simulator font edges and the ignored
status-bar clock. Gutters share 20 px and the CTA surface reaches the
physical edge in both themes (tested); the strip difference vs the PNG is
the intended OWNER-rule behaviour.

VERDICT: PASS

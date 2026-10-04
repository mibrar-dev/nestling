# P09 — 2a build, logic chunk (FIXES_4 iteration)

## CONTRACT CHANGES (UI builder: read first)

No shape changes. One behaviour fix inside the existing contract, plus two
flagged items that are yours or the loop's — not mine:

- **FIXED (P09-TEST-6 / BUG-P09-13): `_checkCoins` throws `ArgumentError`
  unconditionally.** The `assert` is gone: in debug it fired first and its
  file-path/line-number text leaked through `editorError` into the toast,
  defeating the finding-4 mapping. Release behaviour is unchanged. The
  interface doc (finding 8, fixed last iteration) is updated to match —
  "throws `ArgumentError` in all builds". Verified end to end with a
  throwaway replication of the parked proof (real repo + real bloc,
  9999 coins → `editorError == saveFailedMessage`; file deleted after the
  run). The bugs stage has already un-skipped the proof (`p09_bugs_test.dart`
  carries zero `skip: true` now).
- **CLOCK rule — one violation in the feature, not in this layer:**
  `quest_editor_view.dart:542` mints new ids with
  `DateTime.now().millisecondsSinceEpoch`. My layer (`domain/`, `data/`,
  `bloc/`, routes) has no `DateTime.now()` anywhere. Replacing it (e.g.
  `clock.now()`) is a view edit — yours if the orchestrator wants the rule
  applied to id minting too.
- **KID BACKGROUND rule:** n/a — P09 is a parent screen, no meadow anywhere.

Out of layer, documented (do not act on these here):

- **Stale proof — BUG-P09-5 regressed by the P15 merge, not by P09.**
  `p09_bugs_test.dart` "q-bed assigned to deleted Leo shows no selected
  pill" fails (Expected 1, Actual 0) with AND without this iteration's
  diff (proven via stash). Root cause: the merged `FamilyRepository.
  removeChild` (P15-BUG-6) now cascade-deletes the removed child's quests,
  so `q-bed` no longer exists when the editor opens `?id=q-bed` — the
  "Quest not found" screen has no pills at all. The proof's premise
  (orphan survives deletion) is void; the view fallback itself is intact
  for directly-planted orphans. Repair belongs to the proof (plant the
  orphan id straight into Drift instead of `removeChild`), i.e. the bugs
  stage's file — not `family/` (shared), not the view, not this layer.
- **Core `family_time_test` zone failure**: still `test/core/`, still
  off-limits; `SHARED_REQUEST.md` §7 stands.

## Files changed (logic layer only)

- `app/lib/features/quests/data/quests_repository_impl.dart` — assert
  removed from `_checkCoins` (+ comment rewritten to say why).
- `app/lib/features/quests/domain/quests_repository.dart` — create/update
  contract now promises unconditional `ArgumentError`.
- `app/test/features/quests/quests_repository_test.dart` (my file) — the
  two range-rejection tests now expect `throwsArgumentError` (debug and
  release agree by construction now).
- Nothing else: bloc/events/state/routes/DI untouched; no `google_fonts`;
  no shared-file edits → no new `SHARED_REQUEST.md`.

## Verification (logic layer only)

- `flutter analyze lib/features/quests test/features/quests` → No issues
  found.
- Logic + contract-consumer suites: 106/106 (bloc, repository, states,
  P10 bloc, coin-rules, data-integrity) and 91/91 (view, a11y, copy,
  robustness, geometry, hit-area) — the BUG-P09-9 rects are green again
  after 2b's compensation removal.
- Library + bugs groups: all green except the stale BUG-P09-5 proof
  above (pre-existing, mechanism fully explained, outside this layer).
- `dart format --set-exit-if-changed` on touched files → clean.
- Whole-app `flutter test` and any simulator deliberately NOT run
  (integrator / stage 5 own them); no simulator was booted.

## LEFT FOR NEXT ITERATION

- Nothing unfinished in the logic layer. Open elsewhere: the stale
  BUG-P09-5 proof (bugs stage), core zone test (core owner), stage 5
  re-shoot, CLOCK-rule call on the view's id mint (orchestrator/UI).

VERDICT: PASS

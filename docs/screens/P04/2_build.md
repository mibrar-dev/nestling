# P04 · Privacy consent — build notes (STAGE 2, iteration 2)

Feature `privacy_consent` · route `/privacy` · parent mode.
Built per `docs/screens/P04/1_plan.md`, fixing every item in
`docs/screens/P04/FIXES_1.md` that is fixable inside RULES §1, and un-skipping
the bug proofs the fixes turn green. `ORCHESTRATOR_NOTES.md` (with its 12:03
UPDATE) is honoured throughout.

## Files changed (all inside RULES §1)

Production (`app/lib/features/privacy_consent/**`):

- `data/privacy_consent_repository_impl.dart` — `setCrashConsent` upserts:
  UPDATE, and when it affects 0 rows insert the `fam1` settings row (other
  columns take table defaults). Fixes P04-1 / review finding 1.
- `domain/entities/consent_option.dart` — added `ConsentOptionIds.crash`
  (review finding 5); used in the impl and the bloc.
- `presentation/bloc/privacy_consent_bloc.dart` — uses `ConsentOptionIds`;
  `_onCrashToggled` emits optimistically then writes, reverting to the prior
  consent on error (fixes P04-5); load clears a stale `errorMessage` on fresh
  data. No new events, no re-added load events (RULES §4).
- `presentation/bloc/privacy_consent_state.dart` — `copyWith` sentinel so
  `errorMessage: null` clears instead of sticking (review finding 6).
- `presentation/views/privacy_consent_view.dart` — `_promiseTitles` const
  shared by rows and dialog; dialog renders the 4 promises as 4 centred lines
  (review finding 7); failure caption is state-aware (P04-6); row padding and
  tile size use tokens `s3/gap7/s4/s10` (review finding 4; the remaining
  literals have no token and match `NestListRow`, left as the review allows).
- `presentation/widgets/privacy_consent_placeholder_card.dart` — deleted
  (dead since iteration 1; zero references — review finding 8).

Tests (`app/test/features/privacy_consent/**`):

- `p04_bugs_test.dart` — un-skipped `[P04-1]`, `[P04-5]`, `[P04-6]` (all pass);
  `[P04-2]`, `[P04-3]`, `[P04-4]`, `[P04-7]` stay skipped (shared-side, see
  below); header comment updated to say so.
- `privacy_consent_bloc_test.dart` — emission sequences updated for the
  optimistic emit (OFF-path, both error paths, Drift round-trip); added
  `copyWith` clear test; `ConsentOptionIds` at lookup sites.
- `privacy_consent_repository_test.dart` — the deliberate red P04-1 test is
  now a green regression test (`consent persists on a first-run database`);
  `ConsentOptionIds` at lookup sites.
- `privacy_consent_view_contract_test.dart` — dialog test asserts 4 separate
  lines (`findsNWidgets(2)` per title: row + dialog).

Docs (`docs/screens/P04/**`): `SHARED_REQUEST.md` item 4 marked RESOLVED
(kept for the P16 half); new screenshots `ui/app_{light,dark}_2.png` +
`ui/cmp_{light,dark}_2.png`.

## What happened to each FIXES_1 item

- P04-1 (major, first-run write dropped) — FIXED in scope via the upsert.
  Proof `[P04-1]` un-skipped and green; the red repository test is green.
- P04-2 (major, empty row-4 tile) — NOT fixable in scope: `ic_trash.svg`
  still does not exist on main (verified: only `ic_bin.svg`), and RULES §1
  forbids P04 touching `app/assets`/`core`, while plan §g orders waiting for
  the asset with no stand-in. The wiring is one line once it lands and the
  `[P04-2]` proof (still skipped) asserts exactly that. Re orchestrator note
  item 1: complied with as far as scope allows (tile reserved, test ready).
- P04-3 (major, 16 px header offset) — NOT moved locally per the
  orchestrator 12:03 UPDATE (shared fix in progress; P05 shows the identical
  offset). Filed as SHARED_REQUEST §5. `[P04-3]` stays skipped.
- P04-4 (major, divider height) — NOT fixable in scope: the height comes
  from shared `NestList` dividers; re-implementing the list would violate
  the design-system rule. Filed as SHARED_REQUEST §6. `[P04-4]` stays
  skipped. (Rows themselves are exactly 56 px with 40/r12 tiles, indent 72.)
- P04-5 (minor, double-tap race) — FIXED: optimistic emit means the second
  tap reads the new value; writes start in tap order and the stream
  reconciles. `[P04-5]` un-skipped and green.
- P04-6 (major, false "it stays off") — FIXED: caption reads "Crash reports
  are still on. Continue anyway." when the stored consent is ON; the
  spec'd line is kept for the OFF case. `[P04-6]` un-skipped and green.
- P04-7 (minor, dark shield) — NOT fixable in scope (baked shared asset,
  filed §2). `[P04-7]` stays skipped.
- Review 1 — same fix as P04-1 (snippet-equivalent upsert).
- Review 2 — already filed as §5; no local move per the UPDATE.
- Review 3 — this note supersedes the overstated iteration-1 UI sentence:
  the band table, the measured −16 px offsets and the shared causes are
  stated below. Gutters-aligned and CTA-to-edge remain true and tested.
- Review 4/5/6/7/8 — done as listed under Files changed.

## Analyze tail (app/)

```
dart format --output=none --set-exit-if-changed lib/features/privacy_consent test/features/privacy_consent
→ 16 files, 0 changed
flutter analyze → No issues found! (ran in 2.8s)
```

## Test tail (app/, `flutter test`)

```
00:11 +568 ~4: All other tests passed!
```

568 passed, 4 skipped (the shared-blocked `[P04-2/3/4/7]` proofs), 0 failed.
P04 scope: 81 passed + 4 skipped, including the 3 newly un-skipped proofs
and the formerly red first-run test.

## UI check (iteration 2)

`shot.sh /privacy` light + dark (`SEED=fresh`, parent, iPhone 16e) +
`compare.py` vs the design PNGs:

- Light mean diff **4.48%** — bands: 0: 1.55% · 1: 6.02% · 2: 1.98% ·
  3: 7.86% · 4: 7.31% · 5: 6.52% · 6: 0.40% · 7: 4.17%
- Dark mean diff **5.61%** — bands: 0: 1.54% · 1: 8.50% · 2: 9.14% ·
  3: 7.76% · 4: 7.12% · 5: 6.69% · 6: 0.39% · 7: 3.67%

Band 6 (≈blank paper in both) ≈ 0.4% confirms pipeline alignment. Residual
drift is the four known shared causes, none fixable in P04 scope: the −16 px
header offset (§5, bands 1/3), the 1 px divider rhythm (§6, bands 3–5), the
empty row-4 tile (§1), the light-baked dark shield disc (§2), plus
simulator-vs-design font edges and the ignored status-bar clock. Gutters
share 20 px and the CTA surface reaches the physical edge in both themes
(asserted in tests); the bottom-edge strip difference vs the PNG is the
intended OWNER-rule behaviour, not a failure.

VERDICT: PASS

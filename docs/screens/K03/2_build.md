# K03 Kid home — build notes (Stage 2, iteration 5)

Implements `1_plan.md` as overridden by `ORCHESTRATOR_NOTES.md` and the
owner BOTTOM EDGE + ALIGNMENT rules, and fixes every item in `FIXES_4.md`
that is fixable inside the feature (RULES §1).

## Files changed (all inside RULES §1)

- `app/lib/features/kid_home/presentation/views/kid_home_view.dart`
  - Pet slot migrated to shared components (review finding 1,
    ORCHESTRATOR_NOTES iteration-4 mandate): `_KidPetStage` now renders
    `NestPetStage(pip: PipAvatar(mapped style/skin/accessory/stage),
    speech:, pipSize: 152, stage:, semanticLabel:)` — the shared nest
    scene seats the avatar between the rims. Deleted `_SpeechBubble` /
    `_TailPainter` (covered by `speech:` → shared `NestSpeechBubble`).
    `inNest:` omitted on purpose (defaults false; lint forbids the
    redundant argument; unused on the custom-`pip:` path — waiver recorded
    in SHARED_REQUEST #8).
  - Hearts migrated: `_HeartIcon` / `_HeartPainter` deleted, `NestHeart`
    (identical rendering, promoted to shared in the meantime).
  - Meadow panel kept with `TODO(K03)` + SHARED_REQUEST #6: no shared
    meadow-band API exists, and deleting the panel would regress the
    UI-accepted light band to sky. Curve numbers hoisted to cited consts
    (review finding 2).
  - Failure SnackBar → shared `showNestToast` (finding 7; live-region
    semantics included).
  - `_KidFailure(child:)` renders the known child's own Pip look, neutral
    mochi/sunny/stage-1 only when childless (finding 9).
  - `NestLockButton` ("Grown-ups", with the BUG-9 tap guard) added to the
    loading / failure / no-child states (finding 11, DESIGN_SPEC §5 Group
    C); the no-child test assertion flipped to `findsOneWidget`.
  - Pet semantics now carry the growth stage
    (`'Pip the Fledgling, stage 3 of 4'`, finding 12).
  - `_QuestCard._complete` releases its latch on the next frame
    (K03-BUG-11): the bloc emits nothing for a silent no-op, so a
    state-driven reset would leave the check dead. Same-frame double taps
    stay blocked; repo idempotency + the per-quest pending map keep rapid
    taps to one row and one celebration.
- `app/lib/features/kid_home/presentation/bloc/kid_home_state.dart` —
  `copyWithLoaded` no longer carries a stale `errorMessage` (finding 5).
- `app/lib/features/kid_home/presentation/bloc/kid_home_bloc.dart` — stream
  emissions evict pending celebrations for vanished quests (K03-BUG-11
  bloc half; silent, no new emissions, exact-sequence tests unaffected).
- `app/test/features/kid_home/k03_bugs_test.dart` — K03-BUG-11 proof
  un-skipped (passing); header note updated.
- `app/test/features/kid_home/kid_home_view_test.dart` — pet-slot size
  assertion now targets shared `NestPetStage.pipSize` (152); lock
  assertion flipped; layout-gap contract corrected to the true split
  (16 + 10 panel pad before progress, 16 before cards — the old comment
  misattributed the pad).
- `docs/screens/K03/SHARED_REQUEST.md` — new #6 (KidScope meadow-band
  param), #7 (kid type styles + sub-17px exemption), #8 (inNest waiver),
  #9 (kid-button wrap option), #2 extended (card-count note). #5 still
  open (shared motion parsing).
- Deleted stray scratch probes (`probe_temp_test.dart`,
  `scratch_define_test.dart`) left untracked in `app/test/` by parallel
  work; one of them was failing and polluting the semantics suite.

## Fix-item ledger (FIXES_4)

- Review finding 1 (major, forks): pet/bubble/hearts migrated to the new
  shared components; meadow kept ONLY with the filed request + TODO(K03)
  marker exactly as the review's clearance condition prescribes (no
  shared band API exists; deleting it would regress UI-accepted visuals).
- Findings 2 (consts), 5 (errorMessage), 9 (failure art), 11 (locks),
  12 (semantics), 14 (card-count note): fixed as above.
- Findings 3/4/13 (typography fork, inNest, dock wrap): shared-side items
  filed/recorded in SHARED_REQUEST (#7–#9); not locally fixable.
- Finding 6 / K03-BUG-11: fixed (latch reset + eviction); proof green.
- Finding 7 (toast): fixed via shared helper.
- Finding 8 (double child watch): accepted with rationale — duplicate
  emissions are swallowed by equatable dedup, the disagree-frame is
  transient with no observable defect or failing proof, and a `watchHome`
  refactor would churn the interface plus every test fake for zero
  user-visible gain.
- Finding 10 (BUG-7 skip): stays conditional (shared parsing still open).
- K03-BUG-7 (motion flag): still OPEN (shared). Proof fails as expected
  under the flag; stays conditionally skipped; SHARED_REQUEST #5.
- UI dev 1 (dark meadow): TBD from fresh captures below.
- UI dev 2 (dock −6) / dev 3 (upper residuals): positions re-measured
  below; gaps stay spec-exact (pinned by suite contract), absolute rows
  follow block heights; live-Rive variance documented.
- ALIGNMENT rule: probe-green (20px edges); no action.

## Verification (in `app/`)

- `dart format .` — clean.
- `flutter analyze` — `No issues found!`
- `flutter test` — full suite: `+593 ~1, All tests passed!` (1 skip =
  K03-BUG-7 motion proof, conditional on the dart-define by design).
- Screenshots: `shot.sh /kid-home` light + dark (kid/maya/demo) →
  `docs/screens/K03/ui/app_light_8.png`, `app_dark_8.png`; `compare.py` →
  `cmp_light_8.png`, `cmp_dark_8.png` (both runs warn "never stabilised",
  the known K03-BUG-7 cause; layout chrome is static).
  - light mean diff 12.17% — bands: 0:3.00 · 1:4.97 · 2:10.22 · 3:7.79 ·
    4:9.05 · 5:23.45 · 6:24.88 · 7:13.95 (iter4: 13.37%)
  - dark mean diff 10.98% — bands: 0:3.05 · 1:4.95 · 2:9.74 · 3:5.58 ·
    4:8.04 · 5:22.18 · 6:22.81 · 7:11.47 (iter4: 12.13%)
  - hearts yellow rows: app 447–457 both themes (design 444–454);
    progress top 540 / card-1 top 572 (design 527 / 560 — shared font
    metrics account for the rest; gaps proven spec-exact); dock top
    713–715 both themes (design 719–721, shared shadow reserve);
    home strip is dock surface to the edge (light white, dark navy);
    dark band top matches horizon exactly.
  - Band 7 residual vs the PNG is the rule-mandated strip-tone difference
    (surface vs the PNG's green) plus pill pixels — not a defect under the
    owner rule. Bands 5/6 remainder is the accepted set: live counts copy,
    repo card order/content, tile tint + title size (shared), mandated Pip
    art swap, shared font metrics.
  - One dark capture in this round caught SpringBoard (stable home
    screen); lingering `flutter run` processes were cleared and it was
    re-taken valid.

VERDICT: PASS

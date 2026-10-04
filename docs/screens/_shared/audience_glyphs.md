Icons per audience: kid screens use the KID designs' glyphs, parent screens use the PARENT designs' glyphs. ORCHESTRATOR DECISION: each screen matches its own design.

CONTEXT:
- shared/reward_glyphs made `rewardIconFor(key)` use the K08 (kid) glyphs everywhere, so P14 (parent) now differs from ITS design for some rewards (e.g. film). Read docs/screens/_shared/reward_glyphs_REPORT.md §2 for the per-key differences.
- Quests: P09 (parent editor) uses `NestIcons.questBed` etc. from the P09 HTML. K04 (kid quest detail) needs the K04 HTML bed (headboard post, pillow, base and legs; the K04 HTML tile paths `M2 18v-7 / M2 14h20v4 / … / M6 11V8h4v3`). Read ../nestling-screens/K04/docs/screens/K04/5_ui.md deviation 1 (read-only).
DO:
1. `rewardIconFor(String key, {required NestAudience audience})` and `questIconFor(String key, {required NestAudience audience})`, with `enum NestAudience { parent, kid }`, in core/design_system. Each returns the glyph from that audience's designs:
   - parent: P14/P09/P10/P08 HTML;
   - kid: K03/K04/K08 HTML.
   Where a key has only one design source, use it for both and list it in the report.
2. Add the kid quest glyphs (bed, dishes, bins, hoover, reading, plants, etc.: every quest icon key in the seed) from the kid HTML (K03/K04) as new assets. Keep the parent ones (questBed, …) as they are.
3. Merged code: P14 → rewardIconFor(audience: parent) (restore its own design glyphs); K03 kid quest cards → questIconFor(audience: kid) if K03's HTML glyphs differ from what it renders now; P09/P10/P08 → parent. You MAY edit these merged features' presentation code for this. Do NOT edit unmerged branches (K04, K08).
4. Tests: every seeded quest/reward key resolves for both audiences; P14, K03, P08 and P10 geometry/golden-ish tests stay green.
DONE = dart format clean, flutter analyze "No issues found!", full flutter test --timeout 120s green, docs/screens/_shared/audience_glyphs_REPORT.md (which call K04/K08 must use), committed.

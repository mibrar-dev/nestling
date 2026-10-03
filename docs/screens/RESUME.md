# Resume point — screen build (saved 2026-10-01 ~21:30 before a restart)

## Done
- `main` @ 4e197fd: Pip v2 merged (04bb615), motion lab fix, screen-loop tooling:
  - `tools/agents/run_agent.sh` (opencode runner with retries + status/events), `tools/agents/watch.sh` (Monitor: START/DONE/FAILED/RETRY/STALL)
  - `tools/screens/loop.sh <ID> <SIM>` — plan(muse) → build(muse) → test(deepseek) → review(bunny) → ui(muse, simulator) → bugs(deepseek), max 4 iterations, one branch/worktree per screen (`screen/<ID>` in `../nestling-screens/<ID>`)
  - `tools/screens/run_wave.sh <ID...>` — 3 parallel loops (one per simulator in `docs/screens/SIMS.txt`), never two screens of the same feature at once
  - `tools/screens/stages/*.md` stage prompts, `docs/screens/SCREENS.tsv` manifest (30 screens: id, slug, title, feature, route, mode, seed, child)
- Simulators: iPhone 16e 604697A9-11DA-462F-9837-396E9CA2493A, Nestling QA 2 BC440E48-B3A3-43BC-971B-0EF5DB621874, Nestling QA 3 E7D5555E-378A-49DF-AAEE-16677AF4B9DB (boot them after restart: `xcrun simctl boot <udid>`).

## In progress (interrupted)
- FOUNDATION (local-only Drift DB + seeds + Drift repos + full routing + launch flags + `tools/screens/shot.sh` + `compare.py` + `docs/screens/RULES.md`)
  - brief: `docs/screens/_foundation/BRIEF.md`
  - branch `foundation/local-data` (pushed, WIP commit e494031), worktree `../nestling-screens/_foundation`
  - opencode session `ses_f06e66b80ffewjC80X6GeHkn8M` ("Nestling FOUNDATION local data (muse-go)")

## Next steps
1. Boot the 3 simulators; re-arm the monitor: `bash tools/agents/watch.sh` (Monitor tool).
2. Resume foundation in the same session:
   `STATUS_DIR=$PWD/docs/screens/_status WORKDIR=../nestling-screens/_foundation tools/agents/run_agent.sh foundation_resume "opencode-go/muse-spark-1.3-contributor#xhigh" <resume-brief> ses_f06e66b80ffewjC80X6GeHkn8M`
   (resume brief = "your run was interrupted by a computer restart; re-check files on disk and finish docs/screens/_foundation/BRIEF.md").
3. Orchestrator verifies foundation (analyze/test, shot.sh on /today light+dark), merges `foundation/local-data` into main.
4. Pilot: `bash tools/screens/run_wave.sh P01 P08 K03`; review READY screens' `docs/screens/<ID>/ui/cmp_*.png`, merge each `screen/<ID>` into main.
5. Then the remaining 27 screens via run_wave.sh.

Models (OpenCode Go): muse `opencode-go/muse-spark-1.3-contributor#xhigh`, bunny `opencode-go/space-bunny-free#max`, deepseek `opencode-go/deepseek-v4.1-flash#max`. Backend = LOCAL ONLY until the owner finishes docs/SETUP_CHECKLIST.md.

## Orchestrator note
Launch every agent / loop / wave job with Bash `run_in_background: true` AND `timeout: 7200000` (2 h max). The default background limit is 30 min and kills long agents (happened to the foundation run at 22:32). Waves longer than 2 h: run them in a detached process (`nohup … &`) and rely on the Monitor (tools/agents/watch.sh) for events.

## Progress (2026-10-02 02:13)
- MERGED to main: foundation (69a678d), P01 Welcome (d7374f5, 3 iterations).
- Running: pilot wave (P08, K03 — loops started 23:18, pid in docs/screens/_status/run), main wave for the other 27 (`tools/screens/run_wave.sh P02 … K03b`, log docs/screens/_status/wave_main.log).
- After a restart: re-run `run_wave.sh` with the IDs that are not yet merged; a screen whose worktree has FIXES_<n>.md can resume with `START_IT=<n+1> bash tools/screens/loop.sh <ID> <SIM>`.
- Orchestrator merges a screen only after READY + own check (scope of `git diff main...screen/<ID>`, analyze, full tests, cmp_*.png).

## After screens (owner request, 2026-10-02) — do in this order once all 30 screens are merged
1. App icon: the Nestling icon (design/assets brand icon, app/assets/brand/app_icon*.png) on iOS (all sizes, no alpha on the 1024 marketing icon) and Android (adaptive icon: foreground + background, monochrome for Android 13+ themed icons). Use flutter_launcher_icons; verify on both simulators/emulators.
2. Splash: native splash (flutter_native_splash: paper colour + Nestling mark, light + dark, Android 12 splash API) handing off to an ANIMATED Flutter splash: Pip (child's style once known, Mochi on first launch) hatching/peeking out of the nest + logo, ≤1.6 s, skippable, respects Reduce Motion (static still). Record a simulator video for the owner.
3. Production checklist (docs/PRODUCTION_CHECKLIST.md + artifact): what the app has, what's left, and what the owner must set up (Apple/Google accounts, bundle ids, signing, Supabase London, Resend, RevenueCat products, privacy policy/terms on getnestling.co.uk, App Store / Play listings + age ratings + Children's Code/kids category, Data Safety, ICO registration, support email, TestFlight/internal testing, crash reporting consent), cross-referenced with docs/SETUP_CHECKLIST.md.
Owner wants a progress update every ~2 hours (session cron job; re-create it after a restart).

## Progress (2026-10-02 08:00) — after the 04:08 session stop
- Resumed: P08 at iteration 4, K03 at iteration 4, P02 at iteration 2 (MAX 6), via `tools/screens/finalize_iter.sh` + `START_IT`. Queue wave relaunched for P03…K03b (`docs/screens/_status/wave_main2.log`).
- Owner rules added to tools/screens/stages/common.md: bars run to the screen edge in their own colour (no green/page strip), perfect alignment; test stage now on Space Bunny max; keep 3 parallel loops (Mac heat).
- Recovery recipe: for each screen with a worktree, `bash tools/screens/finalize_iter.sh <ID> <last N>` then `START_IT=<N+1> nohup bash tools/screens/loop.sh <ID> <SIM> 6 &` (write docs/screens/_status/run/<ID>.{pid,sim,feature}), then `nohup bash tools/screens/run_wave.sh <remaining IDs> &`.

## Owner rule (2026-10-02 08:20): orchestrator + QA only
Claude delegates ALL implementation to OpenCode sub-agents with comprehensive briefs, including shared fixes:
`bash tools/agents/shared_fix.sh <name> <task.md>` (branch shared/<name>, header docs/screens/_shared/HEADER.md) → review `docs/screens/_shared/<name>_REPORT.md`, diff, analyze, tests → merge → `git merge main` into running screen worktrees. Claude edits code only when an agent is stuck. Last direct edit: 633dfd2.

## Detached launch (owner approved 2026-10-03 04:55)
Every wave and every shared-fix agent runs in a detached macOS `screen` session, so it survives the Claude app quitting:
- Wave: `bash tools/screens/start_detached.sh wave<N> "bash tools/screens/run_wave.sh <IDs…> > docs/screens/_status/wave<N>.log 2>&1"`
- Shared fix: `bash tools/screens/start_detached.sh fix_<name> "bash tools/agents/shared_fix.sh <name> <task.md>"`
- Inspect: `screen -ls`; attach with `screen -r wave<N>`; detach with Ctrl-a d.
- Current wave: `wave8` (P06 resume 4, then P09…K03b).
- P03/P05/K03 were started before the switch (nohup). If the app quits and they die, recover them with finalize_iter + a resume file + a new detached wave.
Merged so far: P01, P02, P04, P07, P08.
- WARNING: quitting a wave's `screen` session kills every loop that wave started (they share its process group). To retire a scheduler, kill ONLY its `run_wave.sh` bash PID, never `screen -X quit`. Since 08:25 run_wave.sh takes a lock (`_status/run/.lock`), so several waves can share the 3 simulators without racing.
- 09:10: run_wave.sh now starts each loop with `nohup`, so a loop survives its scheduler or its screen session ending (older waves, e.g. wave14, still run the old code: do NOT stop wave14 until its queue is empty).

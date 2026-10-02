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

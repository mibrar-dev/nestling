ROLE: Flutter motion engineer (sub-agent). Working dir = Nestling repo root; app/. The owner wants to SEE every animation running in the simulator.
Assets: app/assets/animations/lottie/{check_tick,coin_burst,confetti,badge_unlock}.json (docs/animation/LOTTIE.md), app/assets/animations/rive/pip.riv (artboards/stages/moods/view models + Jar artboard with `fill` and `drop` — see docs/animation/RIVE_GUIDE.md and app/lib/core/design_system/motion/pip_rive.dart which already wraps them: PipRive, PipJar, controller).
BUILD a "Motion lab" dev screen in the design_system_gallery feature: new view `motion_lab_view.dart` (+ widgets under presentation/widgets/), route `/motion-lab` added to design_system_gallery_routes.dart, and an entry button in the gallery app bar ("Motion") — minimal additive edit to the gallery view (another agent edits that file; re-read before writing).
Motion lab content (full-width, 20 px padding, design-system components only, light/dark aware):
- Lottie cards (one per file): the animation at its natural size on a surface card, name + duration, buttons Play / Loop toggle / Reset, and a "Reduced motion" preview showing the `still` frame. Confetti plays as a full-screen overlay (IgnorePointer) above the lab.
- Rive Pip panel: large PipRive (240 px); stage selector 1–4 (NestSegmented), mood buttons idle/happy/eating/sleepy, Evolve trigger, Tap (tap on Pip too); show current stage/mood text.
- Rive Jar panel: PipJar with a slider for fill 0–1 and a Drop button.
- "Play all" button that runs a scripted demo sequence (tick → coin burst → Pip happy → jar drop → badge unlock → Pip evolve → confetti) with ~0.4 s gaps.
Respect MediaQuery.disableAnimations. Do not change the motion assets.
Tests: widget test that pumps the motion lab (light + dark) without exceptions. Run ONLY `flutter analyze` (No issues found!) — another agent owns `flutter test` right now; the orchestrator will run the full suite. Do not run flutter clean.
Reply: files + how to open the screen.

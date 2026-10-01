// Motion lab — every animation in the app, on one screen, with its controls.
//
// Four Lottie one-shots, the Rive Pip rig, the Rive jar, and a scripted
// celebration so the whole thing can be judged as one sequence. Reachable at
// `/motion-lab`, and from the "Motion" button in the gallery app bar.
//
// Reduced motion is honoured the way `docs/animation/LOTTIE.md` §3 and
// `PipRive` describe it: when `MediaQuery.disableAnimationsOf` is true nothing
// plays, every Lottie shows its `still` marker frame, and the Rive widgets sit
// on their SVG fallbacks. The lab does not override the flag — a lab that
// animated anyway would be the one screen in the app ignoring the setting.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/design_system_gallery/presentation/widgets/motion_lab_assets.dart';
import 'package:nestling/features/design_system_gallery/presentation/widgets/motion_lab_confetti_overlay.dart';
import 'package:nestling/features/design_system_gallery/presentation/widgets/motion_lab_jar_panel.dart';
import 'package:nestling/features/design_system_gallery/presentation/widgets/motion_lab_lottie_card.dart';
import 'package:nestling/features/design_system_gallery/presentation/widgets/motion_lab_pip_panel.dart';

/// The motion lab.
class MotionLabView extends StatefulWidget {
  const MotionLabView({super.key, this.riveEnabled = true});

  /// Forwarded to [PipRive.riveEnabled] and [PipJar.riveEnabled]. See
  /// [PipRive.riveEnabled] for the one case a widget test cannot exercise the
  /// live rig: `flutter test` has no `librive_native.dylib`.
  final bool riveEnabled;

  @override
  State<MotionLabView> createState() => _MotionLabViewState();
}

class _MotionLabViewState extends State<MotionLabView>
    with TickerProviderStateMixin {
  /// One controller per [MotionLabAssets.all] entry, in the same order. The
  /// view owns them so the demo drives the same animations the buttons do.
  late final List<AnimationController> _controllers;

  late final Future<List<LottieComposition>> _compositions;

  /// Asset names whose Play loops.
  final Set<String> _looping = <String>{};

  /// The Rive handles, captured while the panels build their trigger rows so
  /// the demo can fire `evolve` and `drop` from a timer, where there is no
  /// BuildContext to ask. These are plain command objects, not contexts.
  PipRiveController? _pip;
  PipJarController? _jar;

  /// Anchors for the demo's scroll-to: Pip and the jar are below the fold, and
  /// an animation nobody can see is not a demo. Every Lottie card gets one
  /// too, so each Play-all step can bring its own panel on screen before it
  /// fires (alignment 0.1 keeps the whole widget visible under the app bar).
  final GlobalKey _pipKey = GlobalKey();
  final GlobalKey _jarKey = GlobalKey();
  late final List<GlobalKey> _cardKeys = List<GlobalKey>.generate(
    MotionLabAssets.all.length,
    (_) => GlobalKey(),
  );

  /// Rive one-shot wall-clock lengths, from `docs/animation/RIVE_GUIDE.md`
  /// §4.3 (all authored at 60 fps): happy 72 f = 1.2 s, eat 108 f = 1.8 s,
  /// evolve 90 f = 1.5 s, Jar drop 96 f = 1.6 s. Idle is a 3.0 s loop.
  static const Duration _pipHappyDuration = Duration(milliseconds: 1200);
  static const Duration _pipEvolveDuration = Duration(milliseconds: 1500);
  static const Duration _jarDropDuration = Duration(milliseconds: 1600);

  /// Scroll-into-view used before every step, per the motion-QA contract.
  static const Duration _revealDuration = Duration(milliseconds: 350);
  static const double _revealAlignment = 0.1;

  /// Debug-only autoplay, set with `--dart-define=MOTION_AUTOPLAY=<name>`.
  /// Scriptable single-animation entry for `simctl recordVideo` proofs.
  /// One of: pip_idle, pip_happy, pip_eating, pip_evolve, jar_drop,
  /// check_tick, coin_burst, confetti, badge_unlock, play_all.
  static const String _autoplay = String.fromEnvironment('MOTION_AUTOPLAY');

  bool _autoplayFired = false;

  List<_DemoStep> _script = const <_DemoStep>[];

  /// Cancellation token: every [_playAll] run captures its own value, and
  /// every await checks it, so Stop/dispose ends the loop without timers.
  int _demoToken = 0;
  int _step = -1;
  bool _demoRunning = false;
  bool _confettiVisible = false;
  bool _reduceMotion = false;
  PipStage _stage = PipStage.fledgling;
  PipMood _mood = PipMood.idle;
  double _fill = 0.5;

  AnimationController get _confettiController =>
      _controllerFor(MotionLabAssets.confetti);

  @override
  void initState() {
    super.initState();
    _controllers = List<AnimationController>.generate(
      MotionLabAssets.all.length,
      (index) => AnimationController(
        vsync: this,
        duration: MotionLabAssets.all[index].duration,
      ),
    );
    _confettiController.addStatusListener(_onConfettiStatus);
    _compositions =
        Future.wait(
          MotionLabAssets.all.map((asset) => AssetLottie(asset.path).load()),
        ).then((compositions) {
          // The spec durations above are the lab's labels; the parsed ones are
          // what the controllers must actually run at.
          if (mounted) {
            for (var i = 0; i < compositions.length; i++) {
              _controllers[i].duration = compositions[i].duration;
            }
          }
          // Autoplay waits for the Lottie set so its durations are real, then
          // fires once on the next frame (Rive needs one frame to bind too).
          if (_autoplay.isNotEmpty && !_autoplayFired) {
            _autoplayFired = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) unawaited(_runAutoplay(_autoplay));
            });
          }
          return compositions;
        });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
  }

  @override
  void dispose() {
    _demoToken++;
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('ds-section-motion'),
      appBar: AppBar(title: const Text('Motion lab')),
      body: FutureBuilder<List<LottieComposition>>(
        future: _compositions,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _LoadFailure(error: snapshot.error);
          }
          final compositions = snapshot.data;
          return Stack(
            children: [
              // Deliberately not a ListView: a dev lab that builds every panel
              // up front is a lab whose scripted demo can drive the Rive
              // panels the owner has not scrolled to yet.
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  NestSpacing.padSide,
                  0,
                  NestSpacing.padSide,
                  NestSpacing.s10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _sections(compositions),
                ),
              ),
              if (_confettiVisible && compositions != null)
                MotionLabConfettiOverlay(
                  composition: _compositionAt(compositions, _confettiIndex),
                  controller: _confettiController,
                ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _sections(List<LottieComposition>? compositions) {
    const assets = MotionLabAssets.all;
    return <Widget>[
      const SizedBox(height: NestSpacing.s4),
      Text(
        'Every Lottie one-shot and both Rive artboards, with the controls a '
        'designer needs to judge them. Sources: docs/animation/LOTTIE.md and '
        'RIVE_GUIDE.md.',
        style: context.nestText.body,
      ),
      const SizedBox(height: NestSpacing.s4),
      _demoCard(),
      if (_reduceMotion) ...[
        const SizedBox(height: NestSpacing.s3),
        _reducedMotionNotice(),
      ],
      const SizedBox(height: NestSpacing.s4),
      const NestSectionLabel(label: 'Lottie one-shots'),
      const SizedBox(height: NestSpacing.s2),
      for (var i = 0; i < assets.length; i++) ...[
        if (i > 0) const SizedBox(height: NestSpacing.s3),
        MotionLabLottieCard(
          key: _cardKeys[i],
          asset: assets[i],
          composition: _compositionAt(compositions, i),
          controller: _controllers[i],
          loop: _looping.contains(assets[i].name),
          playEnabled: !_reduceMotion,
          onPlay: () => _play(assets[i]),
          onLoopChanged: (value) => _setLoop(assets[i], value),
          onReset: () => _reset(assets[i]),
        ),
      ],
      const SizedBox(height: NestSpacing.s4),
      const NestSectionLabel(label: 'Rive · Pip'),
      const SizedBox(height: NestSpacing.s2),
      MotionLabPipPanel(
        key: _pipKey,
        stage: _stage,
        mood: _mood,
        motionEnabled: !_reduceMotion,
        riveEnabled: widget.riveEnabled,
        onStageChanged: (value) =>
            setState(() => _stage = PipStage.values[value - 1]),
        onMoodChanged: (value) => setState(() => _mood = value),
        onController: (controller) => _pip = controller,
        onPipTap: () => _pip?.poke(),
        triggers: _pipTriggerRow(),
      ),
      const SizedBox(height: NestSpacing.s4),
      const NestSectionLabel(label: 'Rive · coin jar'),
      const SizedBox(height: NestSpacing.s2),
      MotionLabJarPanel(
        key: _jarKey,
        fill: _fill,
        motionEnabled: !_reduceMotion,
        riveEnabled: widget.riveEnabled,
        onFillChanged: (value) => setState(() => _fill = value),
        onController: (controller) => _jar = controller,
        onJarTap: () => _jar?.drop(),
        actions: _jarDropButton(),
      ),
    ];
  }

  // ---------------------------------------------------------------- controls

  Widget _demoCard() {
    return NestCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NestButton(
            label: _demoRunning ? 'Stop' : 'Play all',
            leading: Icon(_demoRunning ? Icons.stop : Icons.play_arrow),
            onPressed: _reduceMotion
                ? null
                : _demoRunning
                ? _stopDemo
                : _playAll,
          ),
          const SizedBox(height: NestSpacing.s2),
          Text(_demoCaption, style: context.nestText.caption),
        ],
      ),
    );
  }

  String get _demoCaption {
    if (_reduceMotion) {
      return 'Off: the OS has asked for reduced motion, so the lab does not '
          'play anything.';
    }
    if (!_demoRunning) {
      final gap = MotionLabAssets.demoGap.inMilliseconds;
      return 'Scripted demo — tick, coin burst, Pip happy, jar drop, badge '
          'unlock, Pip evolve, confetti, $gap ms apart.';
    }
    final step = _step >= 0 && _step < _script.length ? _script[_step] : null;
    return 'Step ${_step + 1} of ${_script.length}'
        '${step == null ? '' : ' · ${step.label}'}';
  }

  Widget _reducedMotionNotice() {
    return NestCard(
      variant: NestCardVariant.inset,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.accessibility, size: 20),
          const SizedBox(width: NestSpacing.s3),
          Expanded(
            child: Text(
              'Reduced motion is on, so every Lottie here is parked on its '
              'still frame and Pip and the jar are on their SVG fallbacks. '
              'Turn it off to watch them: iOS Simulator → Features → '
              'Accessibility → Reduce Motion.',
              style: context.nestText.caption,
            ),
          ),
        ],
      ),
    );
  }

  /// Evolve and Tap. The [PipRive] handle comes from the panel's `onReady`
  /// callback (`_pip`), not from a context lookup: the buttons sit next to
  /// the rig, not below it, so `PipRive.of` cannot resolve there.
  Widget _pipTriggerRow() {
    return Row(
      children: [
        Expanded(
          child: NestButton(
            label: 'Evolve',
            leading: const Icon(Icons.auto_awesome),
            variant: NestButtonVariant.secondary,
            onPressed: _reduceMotion ? null : () => _pip?.playEvolve(),
            fullWidth: false,
            minHeight: NestDevice.tapParent,
            fontSize: 15,
            horizontalPadding: NestSpacing.s3,
          ),
        ),
        const SizedBox(width: NestSpacing.s2),
        Expanded(
          child: NestButton(
            label: 'Tap Pip',
            leading: const Icon(Icons.back_hand_outlined),
            variant: NestButtonVariant.secondary,
            onPressed: _reduceMotion ? null : () => _pip?.poke(),
            fullWidth: false,
            minHeight: NestDevice.tapParent,
            fontSize: 15,
            horizontalPadding: NestSpacing.s3,
          ),
        ),
      ],
    );
  }

  /// Drop. Same kept-handle story as [_pipTriggerRow]: `PipJar.of` cannot
  /// resolve from a sibling context.
  Widget _jarDropButton() {
    return NestButton(
      label: 'Drop coins',
      leading: const Icon(Icons.savings_outlined),
      variant: NestButtonVariant.secondary,
      onPressed: _reduceMotion ? null : () => _jar?.drop(),
      fullWidth: false,
      minHeight: NestDevice.tapParent,
      fontSize: 15,
      horizontalPadding: NestSpacing.s3,
    );
  }

  // ---------------------------------------------------------------- playback

  AnimationController _controllerFor(MotionLabAsset asset) {
    final index = _assetIndex(asset);
    return _controllers[index < 0 ? 0 : index];
  }

  static int _assetIndex(MotionLabAsset asset) =>
      MotionLabAssets.all.indexWhere((entry) => entry.name == asset.name);

  LottieComposition? _compositionAt(
    List<LottieComposition>? compositions,
    int index,
  ) => compositions == null || index >= compositions.length
      ? null
      : compositions[index];

  static int get _confettiIndex =>
      MotionLabAssets.all.indexWhere((asset) => asset.name == 'confetti');

  void _play(MotionLabAsset asset) {
    if (_reduceMotion) return;
    final controller = _controllerFor(asset);
    if (_looping.contains(asset.name)) {
      controller.repeat();
    } else {
      controller.forward(from: 0);
    }
    if (asset.playsFullScreen && !_confettiVisible) {
      setState(() => _confettiVisible = true);
    }
  }

  void _reset(MotionLabAsset asset) {
    if (_reduceMotion) return;
    _controllerFor(asset).reset();
    if (asset.playsFullScreen && _confettiVisible) {
      setState(() => _confettiVisible = false);
    }
  }

  void _setLoop(MotionLabAsset asset, bool value) {
    setState(() {
      if (value) {
        _looping.add(asset.name);
      } else {
        _looping.remove(asset.name);
      }
    });
  }

  void _onConfettiStatus(AnimationStatus status) {
    final finished =
        status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed;
    // Looping reports `completed` at every seam, so the overlay would blink
    // once per loop; keep it up for as long as the confetti is looping.
    if (!finished ||
        _looping.contains(MotionLabAssets.confetti.name) ||
        !_confettiVisible) {
      return;
    }
    setState(() => _confettiVisible = false);
  }

  // -------------------------------------------------------------------- demo

  /// Wall-clock length of a Lottie step: the parsed composition duration the
  /// controllers were retimed to, falling back to the documented label.
  Duration _lottieDuration(MotionLabAsset asset) {
    final controller = _controllerFor(asset);
    final d = controller.duration;
    if (d != null && d.inMilliseconds > 0) return d;
    return asset.duration;
  }

  GlobalKey _cardKeyFor(MotionLabAsset asset) {
    final index = MotionLabAssets.all.indexWhere(
      (entry) => entry.name == asset.name,
    );
    if (index < 0 || index >= _cardKeys.length) return _cardKeys.first;
    return _cardKeys[index];
  }

  Future<void> _playAll() async {
    if (_reduceMotion || _demoRunning) return;
    final token = ++_demoToken;
    bool alive() => mounted && token == _demoToken && _demoRunning;

    final script = <_DemoStep>[
      _DemoStep(
        'check_tick',
        () => _runLottieStep(MotionLabAssets.byName('check_tick'), token),
      ),
      _DemoStep(
        'coin_burst',
        () => _runLottieStep(MotionLabAssets.byName('coin_burst'), token),
      ),
      _DemoStep('Pip · happy', () => _runPipHappyStep(token)),
      _DemoStep('Jar · drop', () => _runJarDropStep(token)),
      _DemoStep(
        'badge_unlock',
        () => _runLottieStep(MotionLabAssets.byName('badge_unlock'), token),
      ),
      _DemoStep('Pip · evolve', () => _runPipEvolveStep(token)),
      _DemoStep(
        'confetti',
        () => _runLottieStep(MotionLabAssets.confetti, token),
      ),
    ];
    setState(() {
      _script = script
          .map((step) => _DemoStep(step.label, () async {}))
          .toList(growable: false);
      _demoRunning = true;
      _step = 0;
    });
    for (var i = 0; i < script.length; i++) {
      if (!mounted || token != _demoToken) return;
      if (mounted) setState(() => _step = i);
      await script[i].run();
      if (!mounted || token != _demoToken) return;
      // 400 ms gap between steps, per the motion-QA contract.
      await Future<void>.delayed(MotionLabAssets.demoGap);
      if (!alive() && mounted && token == _demoToken) {
        // Stop was pressed during the gap: exit without restarting.
        if (!_demoRunning) return;
      }
    }
    if (!mounted || token != _demoToken) return;
    _stopDemo();
  }

  /// One Lottie step: scroll its card on screen (alignment 0.1, 350 ms),
  /// play, await the composition duration, then the caller adds the 400 ms
  /// gap. The scroll comes first so the animation is fully visible.
  Future<void> _runLottieStep(MotionLabAsset asset, int token) async {
    await _reveal(_cardKeyFor(asset));
    if (!mounted || token != _demoToken) return;
    _play(asset);
    await Future<void>.delayed(_lottieDuration(asset));
  }

  Future<void> _runPipHappyStep(int token) async {
    await _reveal(_pipKey);
    if (!mounted || token != _demoToken) return;
    if (mounted) setState(() => _mood = PipMood.happy);
    // Hold for the 1.2 s happy one-shot, then park back on idle so the
    // `mood == 1` condition does not immediately retrigger it.
    await Future<void>.delayed(_pipHappyDuration);
    if (!mounted || token != _demoToken) return;
    if (mounted) setState(() => _mood = PipMood.idle);
  }

  /// Jar step: park at 0.20, scroll on screen, fire the 1.6 s drop while the
  /// fill tweens 0.20 → 0.62, then hold for the rest of the drop.
  Future<void> _runJarDropStep(int token) async {
    if (mounted) setState(() => _fill = 0.2);
    await _reveal(_jarKey);
    if (!mounted || token != _demoToken) return;
    await _awaitRiveReady(needPip: false);
    if (!mounted || token != _demoToken) return;
    _jar?.drop();
    await _animateFill(0.2, 0.62, const Duration(milliseconds: 1000), token);
    if (!mounted || token != _demoToken) return;
    const elapsed = Duration(milliseconds: 1000);
    final rest = _jarDropDuration - elapsed;
    if (rest > Duration.zero) await Future<void>.delayed(rest);
  }

  /// Waits until the Rive view models are bound (or a 10 s cap). Triggers
  /// fired before the bind are dropped silently, so every scripted trigger —
  /// autoplay and Play-all — goes through here first. Number writes (mood,
  /// stage, fill) do not need it: the bind pushes the current values itself.
  Future<void> _awaitRiveReady({
    bool needPip = true,
    bool needJar = true,
  }) async {
    // Without Rive (tests, missing native lib) nothing ever binds.
    if (!widget.riveEnabled) return;
    for (var i = 0; i < 100; i++) {
      final pipReady = !needPip || (_pip?.isBound ?? false);
      final jarReady = !needJar || (_jar?.isBound ?? false);
      if (pipReady && jarReady) return;
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }
  }

  Future<void> _runPipEvolveStep(int token) async {
    await _reveal(_pipKey);
    if (!mounted || token != _demoToken) return;
    await _awaitRiveReady(needJar: false);
    if (!mounted || token != _demoToken) return;
    _pip?.playEvolve();
    await Future<void>.delayed(_pipEvolveDuration);
  }

  /// Tweens the jar fill so the drop visibly raises the level.
  Future<void> _animateFill(
    double from,
    double to,
    Duration duration,
    int token,
  ) async {
    const steps = 20;
    final slice = duration ~/ steps;
    for (var i = 1; i <= steps; i++) {
      await Future<void>.delayed(slice);
      if (!mounted || token != _demoToken) return;
      setState(() => _fill = from + (to - from) * i / steps);
    }
  }

  /// Scrolls a panel into view so the step that is about to fire is
  /// watchable. Alignment 0.1 puts the panel near the top, fully on screen.
  Future<void> _reveal(GlobalKey key) async {
    final target = key.currentContext;
    if (target == null) return;
    try {
      await Scrollable.ensureVisible(
        target,
        duration: _revealDuration,
        curve: Curves.easeOut,
        alignment: _revealAlignment,
      );
    } on Object {
      // The panel may not be laid out yet on the autoplay path; the step
      // still plays, just without the scroll.
    }
  }

  void _stopDemo() {
    _demoToken++;
    if (!_demoRunning && _step < 0) return;
    setState(() {
      _demoRunning = false;
      _step = -1;
      _script = const <_DemoStep>[];
    });
  }

  // ---------------------------------------------------------- autoplay ----
  // Debug-only entry for scripted `simctl recordVideo` proofs. The value
  // comes from `--dart-define=MOTION_AUTOPLAY=<name>` (see [_autoplay]).

  Future<void> _runAutoplay(String name) async {
    if (_reduceMotion) return;
    // The Rive FileLoader decodes natively and binds its view model
    // asynchronously; triggers fired before the VMI exists are dropped
    // silently (_write no-ops on null). Hold for it, then keep a static gap
    // between the scroll and the trigger so a recording shows
    // scroll-settle → animation as two separate motion blocks.
    Future<void> settle([int ms = 1200]) =>
        Future<void>.delayed(Duration(milliseconds: ms));
    switch (name) {
      case 'pip_idle':
        setState(() {
          _stage = PipStage.fledgling;
          _mood = PipMood.idle;
        });
        await _reveal(_pipKey);
        await settle(2000);
      case 'pip_happy':
        setState(() {
          _stage = PipStage.fledgling;
          _mood = PipMood.idle;
        });
        await _reveal(_pipKey);
        await settle(2000);
        if (!mounted) return;
        setState(() => _mood = PipMood.happy);
        // Reset mid-play (entry blend is 120 ms, exit at ~1.32 s): the
        // `mood == 1` entry condition is level-triggered, so leaving happy
        // selected past the exit replays the one-shot. The write lands while
        // the machine is inside the eating/happy state, where no transition
        // reads it, so the play runs to completion exactly once.
        await settle(800);
        if (!mounted) return;
        setState(() => _mood = PipMood.idle);
      case 'pip_eating':
        setState(() {
          _stage = PipStage.fledgling;
          _mood = PipMood.idle;
        });
        await _reveal(_pipKey);
        await settle(2000);
        if (!mounted) return;
        setState(() => _mood = PipMood.eating);
        // Same retrigger guard as happy: exit is at ~1.92 s, so park back on
        // idle mid-play.
        await settle();
        if (!mounted) return;
        setState(() => _mood = PipMood.idle);
      case 'pip_evolve':
        // Stage 3 → 4: start fledgling, burst, land on songbird.
        setState(() {
          _stage = PipStage.fledgling;
          _mood = PipMood.idle;
        });
        await _reveal(_pipKey);
        await settle(2000);
        if (!mounted) return;
        await _awaitRiveReady(needJar: false);
        if (!mounted) return;
        _pip?.playEvolve();
        // Let the full 1.5 s burst play before landing on songbird: swapping
        // the stage swaps the artboard (new view-model instance), which would
        // cut the one-shot short.
        await Future<void>.delayed(const Duration(milliseconds: 1600));
        if (!mounted) return;
        setState(() => _stage = PipStage.songbird);
      case 'jar_drop':
        setState(() => _fill = 0.2);
        await _reveal(_jarKey);
        await settle(2000);
        if (!mounted) return;
        await _awaitRiveReady(needPip: false);
        if (!mounted) return;
        _jar?.drop();
        final token = _demoToken;
        await _animateFill(
          0.2,
          0.62,
          const Duration(milliseconds: 1000),
          token,
        );
      case 'check_tick' || 'coin_burst' || 'confetti' || 'badge_unlock':
        final asset = MotionLabAssets.byName(name);
        await _reveal(_cardKeyFor(asset));
        await settle(600);
        if (!mounted) return;
        // Replay 3× with a static gap so a recording captures at least one
        // full burst even if its start overlaps the scroll-settle.
        for (var i = 0; i < 3; i++) {
          _play(asset);
          await Future<void>.delayed(
            _lottieDuration(asset) + const Duration(milliseconds: 600),
          );
          if (!mounted) return;
        }
      case 'play_all':
        await settle(2000);
        if (!mounted) return;
        await _awaitRiveReady();
        if (!mounted) return;
        await _playAll();
      default:
        // Unknown name: stay on the lab for a manual look.
        break;
    }
  }
}

/// One line of the scripted demo.
class _DemoStep {
  const _DemoStep(this.label, this.run);

  final String label;
  final Future<void> Function() run;
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(NestSpacing.padSide),
      child: NestCard(
        variant: NestCardVariant.inset,
        child: Text(
          'Could not load the Lottie assets: $error',
          style: context.nestText.bodySmall,
        ),
      ),
    );
  }
}

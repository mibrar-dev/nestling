// Nestling — Pip the chick and the coin jar, Rive integration.
//
// Built from `tools/rive/pip/artboards/*.rml` with the Rive CLI 1.2.0 and
// compiled to `assets/animations/rive/pip.riv` (~26 KB, six artboards).
//
// THE CONTRACT. Every stage artboard carries the SAME rig, so nothing here
// branches on behaviour — only on which artboard to show:
//
//   artboard  PipEgg | PipHatchling | PipFledgling | PipSongbird | Jar
//             | PipStage (Pip standing IN the nest: shadow -> nest back ->
//             |   Pip -> nest front rim, `stage` selects the visible rig)
//   machine   "Pip"  (Jar uses "Jar")
//   viewmodel "Pip"  ->  mood, stage, evolve, tap
//             "Jar"  ->  fill (0..1), drop (trigger)
//
// The art itself is generated from app/assets/illustrations/*.svg by
// tools/rive/gen_pip.py, so the .riv and the brand SVGs can never drift.
//
// If `pip.riv` is missing or fails to decode, both widgets degrade to the
// static SVG via flutter_svg, and reduced motion uses the same path.

import 'dart:ffi' as ffi;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nestling/core/data/env_flags.dart';
import 'package:nestling/core/design_system/assets/nestling_assets.dart'
    as nest_assets;
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:rive/rive.dart' as rive;

/// Asset path of the Rive file. Keep in sync with `pubspec.yaml` `assets:`.
const String kPipRiveAsset = 'assets/animations/rive/pip.riv';

/// Artboard that draws Pip standing IN the nest. The `stage` view-model
/// property selects which of the four rigs is visible.
const String kPipStageArtboard = 'PipStage';

// View-model property names. These are the public surface of `pip.riv`;
// renaming one on the Rive side is a breaking change here.
const String kPipPropMood = 'mood';
const String kPipPropStage = 'stage';
const String kPipPropEvolve = 'evolve';
const String kPipPropTap = 'tap';
const String kJarPropFill = 'fill';
const String kJarPropDrop = 'drop';

/// Pip's mood. The integer values are part of the Rive contract.
enum PipMood {
  idle(0),
  happy(1),
  eating(2),
  sleepy(3);

  PipMood(this.value);

  /// The value written to the `mood` view model property.
  final double value;
}

/// Pip's growth stage. 1-based.
enum PipStage {
  egg(1, 'PipEgg'),
  hatchling(2, 'PipHatchling'),
  fledgling(3, 'PipFledgling'),
  songbird(4, 'PipSongbird');

  PipStage(this.stage, this.artboard);

  /// The 1-based stage number written to the `stage` view model property.
  final int stage;

  /// The artboard inside `pip.riv` that draws this stage.
  final String artboard;

  /// The static SVG used when the `.riv` is unavailable or motion is reduced.
  String get fallbackAsset => 'assets/illustrations/pip_stage_$stage.svg';

  /// The artboard that follows this one, or `null` at the final stage.
  PipStage? get next => stage < 4 ? PipStage.values[stage] : null;
}

/// Returns `true` when `assets/animations/rive/pip.riv` is bundled and starts
/// with the `RIVE` fingerprint (0x52 0x49 0x56 0x45). Resolved once per run.
final Future<bool> _pipRiveAvailable = (() async {
  try {
    final data = await rootBundle.load(kPipRiveAsset);
    if (data.lengthInBytes < 4) return false;
    final b = data.buffer.asUint8List(data.offsetInBytes, 4);
    return b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x56 && b[3] == 0x45;
  } on Exception {
    return false;
  }
})();

/// Whether the native Rive decoder is actually linked into this process.
///
/// A synchronous FFI symbol check, deliberately NOT `RiveNative.init()`: init
/// reports success on builds without librive_native, and the first real call
/// then throws — including through internal completers the caller can never
/// observe (`FileLoader.file()` does `completeError` + `rethrow`, so the zone
/// sees an unhandled async error even when the rethrow is caught; same for
/// `RiveNative.init()`'s own completer chain). Probing the symbol keeps every
/// widget off the native path without touching the rive package at all, which
/// is what keeps `flutter test` green: an uncaught async error fails the run
/// even when the widget rendered its fallback correctly. A renamed symbol
/// degrades to the SVG fallback, never to a crash.
/// (Coupled to rive_native 0.1.11's `loadRiveFile` export.)
bool _nativeDecoderPresent() {
  try {
    ffi.DynamicLibrary.process().lookup('loadRiveFile');
    return true;
  } on Object {
    return false;
  }
}

/// Whether the Rive native runtime can actually be used in this process.
///
/// `RiveNative.init()` throws an [ArgumentError] (an [Error], not an
/// [Exception]) when `librive_native.dylib` is missing, and the runtime's own
/// loader only catches [Exception] - so without this guard the failure escapes
/// into the widget tree. That is real on a build where the native library was
/// not bundled, and it is what `flutter test` hits every time.
Future<bool> _riveRuntimeReady() async {
  try {
    await rive.RiveNative.init();
    return true;
  } on Object {
    return false;
  }
}

/// One shared loader for the whole app, so the file is decoded once no matter
/// how many PipRives or Jars are on screen.
/// `null` means "not available", and the widgets then stay on the SVG path
/// without touching the native runtime at all.
rive.FileLoader? _sharedLoader;
Future<rive.FileLoader?>? _sharedLoaderFuture;

Future<rive.FileLoader?> _loaderOnce() => _sharedLoaderFuture ??= () async {
  // Sync capability gate FIRST: on a build without the native decoder this
  // returns before any rive-package call, so no internal completer can leak
  // an unhandled async error into the zone (see [_nativeDecoderPresent]).
  if (!_nativeDecoderPresent()) return null;
  if (!await _pipRiveAvailable) return null;
  if (!await _riveRuntimeReady()) return null;
  // Probe the native decoder inside a guard that catches Errors too. On a
  // build without librive_native, `RiveNative.init()` still reports success,
  // but the first real FFI call throws ArgumentError (an Error, not an
  // Exception), which the rive package's own `on Exception` handlers let
  // escape into the widget tree. Probing here keeps every widget on its SVG
  // fallback without ever instantiating a RiveWidgetBuilder — which matters
  // in `flutter test`, where an uncaught async error fails the run even
  // though the widget would have rendered its fallback correctly.
  try {
    final loader = rive.FileLoader.fromAsset(
      kPipRiveAsset,
      riveFactory: rive.Factory.rive,
    );
    await loader.file();
    return _sharedLoader ??= loader;
  } on Object {
    return null;
  }
}();

/// Imperative one-shot triggers. Obtain with [PipRive.of] / [PipJar.of].
class PipRiveController {
  PipRiveController._(this._apply, this._isBound);

  final void Function(String property, double? value) _apply;
  final bool Function() _isBound;

  /// Whether the Rive view model is bound yet. Triggers fired before this is
  /// true are dropped silently (there is no view-model instance to receive
  /// them), so scripted drivers must await it before firing one-shots.
  /// Number writes do not need this: the bind itself pushes the current
  /// widget values.
  bool get isBound => _isBound();

  /// Jump and cheer. Played on quest completion.
  void celebrate() => _apply(kPipPropMood, PipMood.happy.value);

  /// Return to the resting idle loop.
  void rest() => _apply(kPipPropMood, PipMood.idle.value);

  /// Eat, for one 1.8 s chew cycle.
  void eat() => _apply(kPipPropMood, PipMood.eating.value);

  /// Play the evolution burst once.
  void playEvolve() => _apply(kPipPropEvolve, null);

  /// Fire the `tap` trigger, e.g. when the child pokes the mascot.
  void poke() => _apply(kPipPropTap, null);
}

/// Imperative handle for the jar.
class PipJarController {
  PipJarController._(this._apply, this._isBound);

  final void Function(String property, double? value) _apply;
  final bool Function() _isBound;

  /// See [PipRiveController.isBound].
  bool get isBound => _isBound();

  /// Drop three coins in with a splash (1.6 s).
  void drop() => _apply(kJarPropDrop, null);
}

/// Pip the chick.
///
/// Drive it declaratively with [stage] and [mood], or imperatively through
/// [PipRive.of].
class PipRive extends StatefulWidget {
  const PipRive({
    super.key,
    this.stage = PipStage.fledgling,
    this.mood = PipMood.idle,
    this.onTap,
    this.size,
    this.riveEnabled = true,
    this.onReady,
  });

  /// Growth stage. Chooses the artboard and the SVG fallback.
  final PipStage stage;

  /// Current mood. Changing it transitions the state machine.
  final PipMood mood;

  /// Called when the child taps Pip.
  final VoidCallback? onTap;

  /// Fixed width/height. When null the widget fills its parent.
  final double? size;

  /// Set false to force the static SVG even when the `.riv` is present.
  ///
  /// The widget already falls back on its own when the asset is missing or the
  /// native runtime cannot initialise. This exists for the one case it cannot
  /// detect: `flutter test`, where `librive_native.dylib` is absent and the
  /// runtime reports the failure through `FlutterError` on every frame
  /// instead of throwing once, so it is reported as a test failure even
  /// though the widget renders correctly.
  final bool riveEnabled;

  /// Called once with the imperative handle. Prefer this over [PipRive.of]
  /// when the handle is needed next to the widget (a control row below it)
  /// rather than below it: there is no descendant context there for [of] to
  /// resolve. The handle object is stable for the life of the [State]; its
  /// closures read the live view-model binding, and [PipRiveController.isBound]
  /// reports when triggers will land.
  final ValueChanged<PipRiveController>? onReady;

  /// Imperative handle, or `null` if there is no [PipRive] ancestor.
  ///
  /// The [context] must be *below* the [PipRive] — a descendant of its
  /// element. A context from a sibling or from above (e.g. a `Builder`
  /// wrapping both the widget and its control row) resolves to `null`,
  /// silently: `findAncestorStateOfType` only walks up. When the handle is
  /// needed next to the widget rather than below it, use [onReady] instead.
  static PipRiveController? of(BuildContext context) =>
      context.findAncestorStateOfType<_PipRiveState>()?.api;

  @override
  State<PipRive> createState() => _PipRiveState();
}

class _PipRiveState extends State<PipRive> {
  late final PipRiveController api = PipRiveController._(
    _write,
    () => _vmi != null,
  );

  rive.ViewModelInstance? _vmi;

  @override
  void initState() {
    super.initState();
    widget.onReady?.call(api);
  }

  void _write(String property, double? value) {
    final vmi = _vmi;
    if (vmi == null) return;
    if (value == null) {
      final trigger = vmi.trigger(property);
      assert(() {
        if (trigger == null) {
          debugPrint('PipRive: unknown trigger "$property".');
        }
        return true;
      }(), 'missing trigger "$property"');
      trigger?.trigger();
    } else {
      final number = vmi.number(property);
      assert(() {
        if (number == null) {
          debugPrint('PipRive: unknown number "$property".');
        }
        return true;
      }(), 'missing number "$property"');
      if (number != null) number.value = value;
    }
  }

  void _sync(rive.ViewModelInstance? vmi) {
    if (vmi == null || identical(vmi, _vmi)) return;
    // New view-model instance only (first bind, or a new artboard after a
    // stage swap). Rewriting the numbers on every parent rebuild re-fires the
    // one-shot whose `mood == N` entry condition is still true (the lab leaves
    // the mood button selected, and Play-all's jar fill tween rebuilds 20×),
    // so a rebuild must never look like a fresh trigger.
    _vmi = vmi;
    vmi.number(kPipPropMood)?.value = widget.mood.value;
    vmi.number(kPipPropStage)?.value = widget.stage.stage.toDouble();
  }

  @override
  void didUpdateWidget(PipRive oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A mood write IS the trigger for the happy/eat one-shots, so it must
    // only happen on a real change — never from a rebuild. (The artboard swap
    // rebinds a new view model, and [_sync] pushes the current values there.)
    if (oldWidget.stage == widget.stage && oldWidget.mood != widget.mood) {
      _write(kPipPropMood, widget.mood.value);
    }
  }

  @override
  void dispose() {
    _vmi = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce =
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false) ||
        kDisableAnimations;
    final child = GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: _PipBody(
        stage: widget.stage,
        reduceMotion: reduce,
        riveEnabled: widget.riveEnabled,
        onBind: _sync,
      ),
    );
    final size = widget.size;
    return size == null
        ? child
        : SizedBox.square(dimension: size, child: child);
  }
}

class _PipBody extends StatelessWidget {
  const _PipBody({
    required this.stage,
    required this.reduceMotion,
    required this.riveEnabled,
    required this.onBind,
  });

  final PipStage stage;
  final bool reduceMotion;
  final bool riveEnabled;
  final void Function(rive.ViewModelInstance?) onBind;

  @override
  Widget build(BuildContext context) {
    // Short-circuit BEFORE creating the future: merely calling `_loaderOnce`
    // initialises the native runtime, which must not happen on this path.
    if (reduceMotion || !riveEnabled) return _PipSvgFallback(stage: stage);
    return FutureBuilder<rive.FileLoader?>(
      future: _loaderOnce(),
      builder: (context, snap) {
        final loader = snap.data;
        if (loader == null) return _PipSvgFallback(stage: stage);
        return rive.RiveWidgetBuilder(
          fileLoader: loader,
          artboardSelector: rive.ArtboardSelector.byName(stage.artboard),
          stateMachineSelector: rive.StateMachineSelector.byName('Pip'),
          dataBind: rive.DataBind.auto(),
          builder: (context, state) => switch (state) {
            rive.RiveLoading() => _PipSvgFallback(stage: stage),
            rive.RiveFailed() => _PipSvgFallback(stage: stage),
            rive.RiveLoaded() => _bindLoaded(state),
          },
          onLoaded: (state) => onBind(state.viewModelInstance),
        );
      },
    );
  }

  Widget _bindLoaded(rive.RiveLoaded state) {
    onBind(state.viewModelInstance);
    // The builder's output IS the rendered widget: without a RiveWidget here
    // the state machine runs but paints nothing.
    return rive.RiveWidget(controller: state.controller);
  }
}

/// Static fallback scene: Pip standing IN the nest, the same geometry the
/// `PipStage` Rive artboard composes in one file.
///
/// Stack order: nest top-half clip, pip SVG, nest bottom-half clip — so the
/// front rim bites Pip's feet exactly like the artboard's masked front layer.
/// The split (0.55) and feet (0.40) fractions mirror `SPLIT_FRAC`/`FEET_FRAC`
/// in `tools/rive/gen_pip.py`; the per-stage contact fractions are measured
/// from the brand SVGs with the baked ground shadow excluded
/// (`art_bbox` in the generator: s1 206, s2 208, s3 213, s4 222).
class PipNestFallback extends StatelessWidget {
  const PipNestFallback({
    required this.stage,
    required this.pipH,
    required this.nestW,
    required this.stageW,
    super.key,
    this.pipAsset,
  });

  /// Growth stage. Selects the default pip art when [pipAsset] is null.
  final PipStage stage;

  /// Explicit pip art. Defaults to the stage's SVG.
  final String? pipAsset;

  /// Pip height; nest width derives as `pipH / 0.55`, stage as `nestW / 0.62`.
  final double pipH;
  final double nestW;
  final double stageW;

  /// Nest back/front split, measured from the nest top in nest heights.
  static const double split = 0.55;

  /// Visible-contact placement, measured from the nest top in nest heights.
  static const double feet = 0.40;

  /// Pip's visible contact point (feet, or shell/egg base for stages 1-2)
  /// inside its own 240-space SVG, as a fraction of 240.
  static double contactInSvg(PipStage stage) => switch (stage) {
    PipStage.egg => 206 / 240,
    PipStage.hatchling => 208 / 240,
    PipStage.fledgling => 213 / 240,
    PipStage.songbird => 222 / 240,
  };

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final nestH = nestW;
    final feetFromNestTop = feet * nestH;
    // Visible contact (not the SVG box bottom) lands at 58% nest height; the
    // box bottom is transparent padding + Pip's baked shadow, so aligning the
    // box (not the contact point) would float Pip above the nest.
    const nestTop = 6.0;
    const shadowBleed = 10.0;
    final pipTop = nestTop + feetFromNestTop - contactInSvg(stage) * pipH;
    final nestLeft = (stageW - nestW) / 2;
    final stageH = nestTop + nestH + shadowBleed;
    final glowD = nestW * 1.04;

    Widget nestSvg() {
      return SvgPicture.asset(
        nest_assets.NestlingIllustrations.nest,
        width: nestW,
        height: nestH,
        placeholderBuilder: (_) => const SizedBox.shrink(),
      );
    }

    return SizedBox(
      width: stageW,
      height: stageH,
      child: Stack(
        children: [
          if (tokens.isDark)
            Positioned(
              left: nestLeft - (glowD - nestW) / 2,
              top: nestTop + (nestH - glowD) / 2,
              child: Container(
                width: glowD,
                height: glowD,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x1AFFFFFF),
                ),
              ),
            ),
          Positioned(
            left: nestLeft + nestW * 0.05,
            top: nestTop + nestH - 10,
            child: _GroundShadow(
              width: nestW * 0.9,
              color: tokens.groundShadow,
            ),
          ),
          Positioned(
            left: nestLeft,
            top: nestTop,
            width: nestW,
            height: split * nestH,
            child: ClipRect(
              // OverflowBox (not Align+SizedBox): Align loosens the child
              // constraints, so a fixed-size SizedBox gets clamped to the
              // layer height and the SVG scales down instead of cropping.
              // Explicit maxes keep the full-size art; alignment crops it.
              child: OverflowBox(
                maxWidth: nestW,
                maxHeight: nestH,
                alignment: Alignment.topCenter,
                child: nestSvg(),
              ),
            ),
          ),
          Positioned(
            left: (stageW - pipH) / 2,
            top: pipTop,
            width: pipH,
            height: pipH,
            child: SvgPicture.asset(
              pipAsset ?? stage.fallbackAsset,
              width: pipH,
              height: pipH,
              placeholderBuilder: (_) => const SizedBox.shrink(),
            ),
          ),
          Positioned(
            left: nestLeft,
            top: nestTop + split * nestH,
            width: nestW,
            height: (1 - split) * nestH,
            child: ClipRect(
              child: OverflowBox(
                maxWidth: nestW,
                maxHeight: nestH,
                alignment: Alignment.bottomCenter,
                child: nestSvg(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft elliptical contact shadow: rx ≈ 45% of nest width, ry 8.
class _GroundShadow extends StatelessWidget {
  const _GroundShadow({required this.width, required this.color});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ShadowPainter(color), size: Size(width, 16));
  }
}

class _ShadowPainter extends CustomPainter {
  const _ShadowPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(covariant _ShadowPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Pip standing IN the nest, composed in Rive.
///
/// Draw order inside the artboard is ground shadow → nest back → Pip → nest
/// front rim, with Pip's feet just below the back/front split so the rim
/// bites them. [stage] selects which of the four rigs is visible;
/// [mood] behaves exactly as on [PipRive].
///
/// If the `.riv` is missing or reduced motion is on, this renders the static
/// [PipNestFallback] scene instead — same nest, same split, same feet.
class PipInNest extends StatefulWidget {
  const PipInNest({
    super.key,
    this.stage = PipStage.fledgling,
    this.mood = PipMood.idle,
    this.riveEnabled = true,
    this.pipAsset,
    this.pipH,
    this.nestW,
    this.stageW,
  });

  /// Growth stage. Selects the visible rig and the default fallback art.
  final PipStage stage;

  /// Current mood. Changing it transitions the state machine.
  final PipMood mood;

  /// Set false to force the static fallback. See [PipRive.riveEnabled].
  final bool riveEnabled;

  /// Explicit pip art for the fallback scene. Defaults to the stage's SVG.
  final String? pipAsset;

  /// Fallback-scene geometry (see [PipNestFallback]). When all three are
  /// supplied the fallback is the full nest scene, so it matches the Rive
  /// artboard's composition; otherwise Pip alone.
  final double? pipH;
  final double? nestW;
  final double? stageW;

  @override
  State<PipInNest> createState() => _PipInNestState();
}

class _PipInNestState extends State<PipInNest> {
  rive.ViewModelInstance? _vmi;

  void _sync(rive.ViewModelInstance? vmi) {
    if (vmi == null || identical(vmi, _vmi)) return;
    // New instance only — see [_PipRiveState._sync]: rewriting the numbers on
    // every parent rebuild re-fires the selected mood's one-shot.
    _vmi = vmi;
    vmi.number(kPipPropMood)?.value = widget.mood.value;
    vmi.number(kPipPropStage)?.value = widget.stage.stage.toDouble();
  }

  @override
  void didUpdateWidget(PipInNest oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) {
      _vmi?.number(kPipPropMood)?.value = widget.mood.value;
    }
    if (oldWidget.stage != widget.stage) {
      _vmi?.number(kPipPropStage)?.value = widget.stage.stage.toDouble();
    }
  }

  @override
  void dispose() {
    _vmi = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce =
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false) ||
        kDisableAnimations;
    // Short-circuit BEFORE creating the future: merely calling `_loaderOnce`
    // initialises the native runtime, which must not happen on this path.
    if (reduce || !widget.riveEnabled) {
      return _fallback();
    }
    return FutureBuilder<rive.FileLoader?>(
      future: _loaderOnce(),
      builder: (context, snap) {
        final loader = snap.data;
        if (loader == null) return _fallback();
        return rive.RiveWidgetBuilder(
          fileLoader: loader,
          artboardSelector: rive.ArtboardSelector.byName(kPipStageArtboard),
          stateMachineSelector: rive.StateMachineSelector.byName('Pip'),
          dataBind: rive.DataBind.auto(),
          builder: (context, state) => switch (state) {
            rive.RiveLoading() => _fallback(),
            rive.RiveFailed() => _fallback(),
            rive.RiveLoaded() => _bindLoaded(state),
          },
          onLoaded: (state) => _sync(state.viewModelInstance),
        );
      },
    );
  }

  /// The static fallback: the full nest scene when the caller supplied its
  /// geometry (so the fallback matches the artboard's composition), else Pip
  /// alone for standalone use.
  Widget _fallback() {
    final pipH = widget.pipH;
    final nestW = widget.nestW;
    final stageW = widget.stageW;
    if (pipH != null && nestW != null && stageW != null) {
      return PipNestFallback(
        stage: widget.stage,
        pipAsset: widget.pipAsset,
        pipH: pipH,
        nestW: nestW,
        stageW: stageW,
      );
    }
    return _PipSvgFallback(stage: widget.stage);
  }

  Widget _bindLoaded(rive.RiveLoaded state) {
    _sync(state.viewModelInstance);
    // The builder's output IS the rendered widget: without a RiveWidget here
    // the state machine runs but paints nothing. The box NestPetStage gives
    // this matches the artboard aspect, so contain is an exact fit.
    return rive.RiveWidget(controller: state.controller);
  }
}

/// The savings jar (shortlist #3).
///
/// [fill] is the coin level, 0..1, bound to the gold band inside the artboard
/// and masked to the glass. Fire [PipJar.of] to play the 1.6 s drop.
class PipJar extends StatefulWidget {
  const PipJar({
    super.key,
    this.fill = 0.5,
    this.onTap,
    this.size,
    this.riveEnabled = true,
    this.onReady,
  });

  /// Coin level, 0..1.
  final double fill;

  /// Called when the child taps the jar. Pair with [PipJar.of] for the drop.
  final VoidCallback? onTap;

  /// Fixed width/height. When null the widget fills its parent.
  final double? size;

  /// Set false to force the static SVG. See [PipRive.riveEnabled].
  final bool riveEnabled;

  /// Called once with the imperative handle. See [PipRive.onReady]: prefer
  /// this over [PipJar.of] for a control row next to the jar.
  final ValueChanged<PipJarController>? onReady;

  /// Imperative handle, or `null` if there is no [PipJar] ancestor.
  ///
  /// The [context] must be *below* the [PipJar]. See [PipRive.of]: a context
  /// from a sibling or from above resolves to `null`, silently.
  static PipJarController? of(BuildContext context) =>
      context.findAncestorStateOfType<_PipJarState>()?.api;

  @override
  State<PipJar> createState() => _PipJarState();
}

class _PipJarState extends State<PipJar> {
  late final PipJarController api = PipJarController._(
    _write,
    () => _vmi != null,
  );
  rive.ViewModelInstance? _vmi;

  @override
  void initState() {
    super.initState();
    widget.onReady?.call(api);
  }

  void _write(String property, double? value) {
    final vmi = _vmi;
    if (vmi == null || value != null) return;
    final trigger = vmi.trigger(property);
    assert(() {
      if (trigger == null) {
        debugPrint('PipJar: unknown trigger "$property".');
      }
      return true;
    }(), 'missing trigger "$property"');
    trigger?.trigger();
  }

  void _sync(rive.ViewModelInstance? vmi) {
    if (vmi == null || identical(vmi, _vmi)) return;
    // New instance only — see [_PipRiveState._sync]. `fill` is continuous so
    // a rewrite is harmless, but skipping it keeps parent rebuilds (the lab's
    // fill slider, Play-all's fill tween) from touching the view model at all.
    _vmi = vmi;
    vmi.number(kJarPropFill)?.value = widget.fill.clamp(0.0, 1.0);
  }

  @override
  void didUpdateWidget(PipJar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fill != widget.fill) {
      _vmi?.number(kJarPropFill)?.value = widget.fill.clamp(0.0, 1.0);
    }
  }

  @override
  void dispose() {
    _vmi = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce =
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false) ||
        kDisableAnimations;
    final child = GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: reduce || !widget.riveEnabled
          ? const _JarSvgFallback()
          : FutureBuilder<rive.FileLoader?>(
              // Only reached when the Rive path is live; see _PipBody.
              future: _loaderOnce(),
              builder: (context, snap) {
                final loader = snap.data;
                if (loader == null) return const _JarSvgFallback();
                return rive.RiveWidgetBuilder(
                  fileLoader: loader,
                  artboardSelector: rive.ArtboardSelector.byName('Jar'),
                  stateMachineSelector: rive.StateMachineSelector.byName('Jar'),
                  dataBind: rive.DataBind.auto(),
                  builder: (context, state) => switch (state) {
                    rive.RiveLoading() => const _JarSvgFallback(),
                    rive.RiveFailed() => const _JarSvgFallback(),
                    rive.RiveLoaded() => _bind(state),
                  },
                );
              },
            ),
    );
    final size = widget.size;
    return size == null
        ? child
        : SizedBox.square(dimension: size, child: child);
  }

  Widget _bind(rive.RiveState state) {
    // The builder's output IS the rendered widget: without a RiveWidget here
    // the state machine runs but paints nothing.
    if (state is rive.RiveLoaded) {
      _sync(state.viewModelInstance);
      return rive.RiveWidget(controller: state.controller);
    }
    return const SizedBox.expand();
  }
}

/// Static SVG used while the `.riv` loads, when it is absent, or when the
/// platform asks for reduced motion.
class _PipSvgFallback extends StatelessWidget {
  const _PipSvgFallback({required this.stage});

  final PipStage stage;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    stage.fallbackAsset,
    placeholderBuilder: (context) => const SizedBox.shrink(),
  );
}

class _JarSvgFallback extends StatelessWidget {
  const _JarSvgFallback();

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/illustrations/jar_coins.svg',
    placeholderBuilder: (context) => const SizedBox.shrink(),
  );
}

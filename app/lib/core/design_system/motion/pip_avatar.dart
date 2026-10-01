// Nestling — Pip v2 avatar (all three body styles, one widget).
//
// Each body style ships one Rive file built from its approved pose library:
//   assets/animations/rive/pip_{mochi,bolt,storybook}.riv
// with artboards Stage1..Stage4 + PipStage, state machine "Pip" and view
// model "Pip" (mood, stage, skin, accessory, bodyColor, darkColor,
// bellyColor, evolve, tap, blink). See docs/pip-v2/PIP_V2_CONTRACT.md and
// docs/pip-v2/ANIM_A_NOTES.md.
//
// The widget never branches on style except for which file/fallback to load:
// enums match the contract, so one code path drives any style.
//
// If the style's `.riv` is missing (a style whose animator has not landed
// yet), undecodable, or the platform requests reduced motion, the widget
// renders the approved static SVG fallback instead — never an empty hole.
// v1 `PipRive` (pip_rive.dart) is untouched.

import 'dart:ffi' as ffi;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nestling/core/data/env_flags.dart';
import 'package:rive/rive.dart' as rive;

/// Body style. The file stem selects the `.riv` and the fallback directory.
enum PipStyle {
  mochi('mochi'),
  bolt('bolt'),
  storybook('storybook');

  PipStyle(this.dir);

  /// `assets/illustrations/pip_v2/<dir>/`.
  final String dir;

  /// `assets/animations/rive/pip_<dir>.riv`.
  String get riveAsset => 'assets/animations/rive/pip_$dir.riv';
}

/// Pip's mood. Integer values are written to the `mood` view-model property
/// and gate the Body/Eyes/FX state machines, so they are pinned here.
enum PipMood {
  idle(0),
  happy(1),
  eating(2),
  sleepy(3),
  surprised(4),
  proud(5);

  PipMood(this.value);

  /// The value written to the `mood` view model property.
  final double value;
}

/// Colour skin. The number selects the variant; the colours are data-bound
/// into the body/belly fills (see `bodyColor`/`darkColor`/`bellyColor`).
enum PipSkin {
  sunny(0, Color(0xFFFFD93D), Color(0xFFE8A800), Color(0xFFFFF1B8)),
  berry(1, Color(0xFFFF9EBB), Color(0xFFE0608C), Color(0xFFFFE1EA)),
  sky(2, Color(0xFF8EC9FF), Color(0xFF4E9AE0), Color(0xFFE2F1FF)),
  mint(3, Color(0xFF8EE3B5), Color(0xFF3FA67E), Color(0xFFDDF8E8));

  PipSkin(this.value, this.body, this.dark, this.belly);

  /// The value written to the `skin` view model property.
  final double value;

  /// Data-bound into the `bodyColor`/`darkColor`/`bellyColor` properties.
  final Color body;
  final Color dark;
  final Color belly;
}

/// Worn accessory. The number drives the `accessory` view-model property,
/// whose Formula converters toggle exactly one accessory node visible.
enum PipAccessory {
  none(0),
  bow(1),
  cap(2),
  scarf(3),
  glasses(4);

  PipAccessory(this.value);

  /// The value written to the `accessory` view model property.
  final double value;
}

/// View-model property names. These are the public surface of
/// `pip_{mochi,bolt,storybook}.riv`; renaming one on the Rive side is a
/// breaking change here.
const String kPipAvatarPropMood = 'mood';
const String kPipAvatarPropStage = 'stage';
const String kPipAvatarPropSkin = 'skin';
const String kPipAvatarPropAccessory = 'accessory';
const String kPipAvatarPropBodyColor = 'bodyColor';
const String kPipAvatarPropDarkColor = 'darkColor';
const String kPipAvatarPropBellyColor = 'bellyColor';
const String kPipAvatarPropEvolve = 'evolve';
const String kPipAvatarPropTap = 'tap';
const String kPipAvatarPropBlink = 'blink';

/// Returns `true` when the asset is bundled and starts with the `RIVE`
/// fingerprint (0x52 0x49 0x56 0x45). Resolved once per asset per run.
final Map<String, Future<bool>> _pipAvatarAvailable = {};

Future<bool> _rivAvailable(String asset) =>
    _pipAvatarAvailable.putIfAbsent(asset, () async {
      try {
        final data = await rootBundle.load(asset);
        if (data.lengthInBytes < 4) return false;
        final b = data.buffer.asUint8List(data.offsetInBytes, 4);
        return b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x56 && b[3] == 0x45;
      } on Exception {
        return false;
      }
    });

/// Whether the native Rive decoder is actually linked into this process.
///
/// A synchronous FFI symbol check, deliberately NOT `RiveNative.init()`: init
/// reports success on builds without librive_native, and the first real call
/// then throws — including through internal completers the caller can never
/// observe. Probing the symbol keeps every widget off the native path
/// without touching the rive package at all, which is what keeps
/// `flutter test` green. (Coupled to rive_native 0.1.11's `loadRiveFile`.)
bool _nativeDecoderPresent() {
  try {
    ffi.DynamicLibrary.process().lookup('loadRiveFile');
    return true;
  } on Object {
    return false;
  }
}

/// Whether the Rive native runtime can actually be used in this process.
Future<bool> _riveRuntimeReady() async {
  try {
    await rive.RiveNative.init();
    return true;
  } on Object {
    return false;
  }
}

/// One shared loader per style file, so each `.riv` is decoded once no
/// matter how many avatars are on screen. `null` means "not available",
/// and the widgets then stay on the SVG path without touching the native
/// runtime at all.
final Map<String, rive.FileLoader?> _sharedAvatarLoaders = {};
final Map<String, Future<rive.FileLoader?>> _sharedAvatarLoaderFutures = {};

Future<rive.FileLoader?> _avatarLoaderOnce(String asset) =>
    _sharedAvatarLoaderFutures.putIfAbsent(asset, () async {
      // Sync capability gate FIRST: on a build without the native decoder
      // this returns before any rive-package call, so no internal completer
      // can leak an unhandled async error into the zone.
      if (!_nativeDecoderPresent()) return null;
      if (!await _rivAvailable(asset)) return null;
      if (!await _riveRuntimeReady()) return null;
      try {
        final loader = rive.FileLoader.fromAsset(
          asset,
          riveFactory: rive.Factory.rive,
        );
        await loader.file();
        return _sharedAvatarLoaders[asset] ??= loader;
      } on Object {
        return null;
      }
    });

/// Imperative one-shots for [PipAvatar]. Obtain with [PipAvatar.of].
class PipAvatarController {
  PipAvatarController._(this._apply, this._isBound);

  /// A detached controller that drops every write. For widget tests and
  /// previews that never bind a Rive view model.
  factory PipAvatarController.detached() =>
      PipAvatarController._((_, _) {}, () => false);

  // Wired to the owning [_PipAvatarState] on mount (see `_attachExternal`);
  // a detached controller drops writes silently.
  void Function(String property, double? value) _apply;
  bool Function() _isBound;

  /// Whether the Rive view model is bound yet. Triggers fired before this
  /// is true are dropped silently (there is no view-model instance to
  /// receive them); number writes do not need this since the bind itself
  /// pushes the widget's current values.
  bool get isBound => _isBound();

  /// Jump and cheer (Body/Eyes/FX happy one-shots).
  void celebrate() => _apply(kPipAvatarPropMood, PipMood.happy.value);

  /// Eat, for one chew cycle.
  void eat() => _apply(kPipAvatarPropMood, PipMood.eating.value);

  /// Settle into (or wake from) the sleepy loop.
  void sleep() => _apply(kPipAvatarPropMood, PipMood.sleepy.value);

  /// Startle (jump-back, wide eyes, "!").
  void surprise() => _apply(kPipAvatarPropMood, PipMood.surprised.value);

  /// Chest-out wink with a chest sparkle.
  void praise() => _apply(kPipAvatarPropMood, PipMood.proud.value);

  /// Return to the resting idle loop.
  void rest() => _apply(kPipAvatarPropMood, PipMood.idle.value);

  /// Play the evolution burst once.
  void playEvolve() => _apply(kPipAvatarPropEvolve, null);

  /// Fire the `tap` trigger (a poke plays the happy bounce).
  void poke() => _apply(kPipAvatarPropTap, null);

  /// Fire the `blink` trigger (one immediate blink on the Eyes layer).
  void blink() => _apply(kPipAvatarPropBlink, null);
}

/// Pip v2 avatar: any style, any stage, any mood/skin/accessory.
///
/// Drive it declaratively with [stage]/[mood]/[skin]/[accessory], or
/// imperatively through [PipAvatar.of]. With [inNest] the `PipStage`
/// artboard draws Pip standing in the nest (front rim biting the feet);
/// otherwise the `Stage<stage>` artboard draws Pip alone.
class PipAvatar extends StatefulWidget {
  const PipAvatar({
    required this.style,
    required this.stage,
    super.key,
    this.mood = PipMood.idle,
    this.skin = PipSkin.sunny,
    this.accessory = PipAccessory.none,
    this.inNest = false,
    this.onTap,
    this.controller,
    this.size,
    this.riveEnabled = true,
  }) : assert(stage >= 1 && stage <= 4, 'stage must be 1..4');

  /// Body style. Selects the `.riv` file and the fallback directory.
  final PipStyle style;

  /// Growth stage, 1..4. Selects the artboard (or the visible rig in
  /// `PipStage`) and the SVG fallback.
  final int stage;

  /// Current mood. Changing it transitions Body/Eyes/FX together.
  final PipMood mood;

  /// Colour skin. Recolours body/belly fills through data binding.
  final PipSkin skin;

  /// Worn accessory. Exactly one accessory node is visible at a time.
  final PipAccessory accessory;

  /// Draw Pip standing in the nest (`PipStage`) instead of alone.
  final bool inNest;

  /// Called when the child taps Pip.
  final VoidCallback? onTap;

  /// Optional external handle for one-shots. When null the widget still
  /// exposes one via [PipAvatar.of].
  final PipAvatarController? controller;

  /// Fixed width/height. When null the widget fills its parent.
  final double? size;

  /// Set false to force the static SVG even when the `.riv` is present.
  ///
  /// The widget already falls back on its own when the asset is missing or
  /// the native runtime cannot initialise. This exists for the one case it
  /// cannot detect: `flutter test`, where `librive_native.dylib` is absent
  /// and the runtime reports the failure through `FlutterError` on every
  /// frame instead of throwing once.
  final bool riveEnabled;

  /// Artboard drawn for [stage] when [inNest] is false.
  String get artboard => 'Stage$stage';

  /// Static fallback for [style]/[stage]. Mochi ships the approved idle
  /// pose per stage; styles whose art has not landed yet resolve to a
  /// clearly-marked placeholder the owning animator replaces.
  static String fallbackAsset(PipStyle style, int stage) {
    if (style == PipStyle.mochi) {
      return 'assets/illustrations/pip_v2/mochi/s${stage}_idle_1.svg';
    }
    return 'assets/illustrations/pip_v2/${style.dir}/placeholder.svg';
  }

  /// Imperative handle, or `null` if there is no [PipAvatar] ancestor.
  static PipAvatarController? of(BuildContext context) =>
      context.findAncestorStateOfType<_PipAvatarState>()?.api;

  @override
  State<PipAvatar> createState() => _PipAvatarState();
}

class _PipAvatarState extends State<PipAvatar> {
  late final PipAvatarController api = PipAvatarController._(
    _write,
    () => _vmi != null,
  );

  rive.ViewModelInstance? _vmi;

  @override
  void initState() {
    super.initState();
    _attachExternal();
  }

  void _attachExternal() {
    final external = widget.controller;
    if (external == null) return;
    external
      .._apply = _write
      .._isBound = () => _vmi != null;
  }

  void _write(String property, double? value) {
    final vmi = _vmi;
    if (vmi == null) return;
    if (value == null) {
      vmi.trigger(property)?.trigger();
    } else {
      vmi.number(property)?.value = value;
    }
  }

  void _writeAll(rive.ViewModelInstance vmi) {
    vmi
      ..number(kPipAvatarPropMood)?.value = widget.mood.value
      ..number(kPipAvatarPropStage)?.value = widget.stage.toDouble()
      ..number(kPipAvatarPropSkin)?.value = widget.skin.value
      ..number(kPipAvatarPropAccessory)?.value = widget.accessory.value
      ..color(kPipAvatarPropBodyColor)?.value = widget.skin.body
      ..color(kPipAvatarPropDarkColor)?.value = widget.skin.dark
      ..color(kPipAvatarPropBellyColor)?.value = widget.skin.belly;
  }

  void _sync(rive.ViewModelInstance? vmi) {
    if (vmi == null || identical(vmi, _vmi)) return;
    // New view-model instance only (first bind, or a new artboard after a
    // stage/style swap). Rewriting the numbers on every parent rebuild
    // re-fires the selected mood's one-shot, so a rebuild must never look
    // like a fresh trigger.
    _vmi = vmi;
    _writeAll(vmi);
  }

  @override
  void didUpdateWidget(PipAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) _attachExternal();
    final vmi = _vmi;
    if (vmi == null) return;
    // A mood write IS the trigger for the mood one-shots, so it must only
    // happen on a real change — never from a rebuild.
    if (oldWidget.mood != widget.mood) {
      vmi.number(kPipAvatarPropMood)?.value = widget.mood.value;
    }
    if (oldWidget.stage != widget.stage) {
      vmi.number(kPipAvatarPropStage)?.value = widget.stage.toDouble();
    }
    if (oldWidget.skin != widget.skin) {
      vmi.number(kPipAvatarPropSkin)?.value = widget.skin.value;
      vmi.color(kPipAvatarPropBodyColor)?.value = widget.skin.body;
      vmi.color(kPipAvatarPropDarkColor)?.value = widget.skin.dark;
      vmi.color(kPipAvatarPropBellyColor)?.value = widget.skin.belly;
    }
    if (oldWidget.accessory != widget.accessory) {
      vmi.number(kPipAvatarPropAccessory)?.value = widget.accessory.value;
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
      child: _PipAvatarBody(
        style: widget.style,
        stage: widget.stage,
        inNest: widget.inNest,
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

class _PipAvatarBody extends StatelessWidget {
  const _PipAvatarBody({
    required this.style,
    required this.stage,
    required this.inNest,
    required this.reduceMotion,
    required this.riveEnabled,
    required this.onBind,
  });

  final PipStyle style;
  final int stage;
  final bool inNest;
  final bool reduceMotion;
  final bool riveEnabled;
  final void Function(rive.ViewModelInstance?) onBind;

  @override
  Widget build(BuildContext context) {
    // Short-circuit BEFORE creating the future: merely calling
    // `_avatarLoaderOnce` initialises the native runtime, which must not
    // happen on this path.
    if (reduceMotion || !riveEnabled) {
      return _PipAvatarSvgFallback(style: style, stage: stage);
    }
    return FutureBuilder<rive.FileLoader?>(
      future: _avatarLoaderOnce(style.riveAsset),
      builder: (context, snap) {
        final loader = snap.data;
        if (loader == null) {
          return _PipAvatarSvgFallback(style: style, stage: stage);
        }
        return rive.RiveWidgetBuilder(
          fileLoader: loader,
          artboardSelector: rive.ArtboardSelector.byName(
            inNest ? 'PipStage' : 'Stage$stage',
          ),
          stateMachineSelector: rive.StateMachineSelector.byName('Pip'),
          dataBind: rive.DataBind.auto(),
          builder: (context, state) => switch (state) {
            rive.RiveLoading() => _PipAvatarSvgFallback(
              style: style,
              stage: stage,
            ),
            rive.RiveFailed() => _PipAvatarSvgFallback(
              style: style,
              stage: stage,
            ),
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

/// Static fallback: the approved idle SVG for Mochi, or the style's
/// placeholder until its art lands.
class _PipAvatarSvgFallback extends StatelessWidget {
  const _PipAvatarSvgFallback({required this.style, required this.stage});

  final PipStyle style;
  final int stage;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    PipAvatar.fallbackAsset(style, stage),
    placeholderBuilder: (context) => const SizedBox.shrink(),
  );
}

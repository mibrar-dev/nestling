// Pip lab — every Pip v2 style, stage, mood, skin and accessory on one
// screen, with the controls a designer needs to judge them. Reachable at
// `/pip-lab`, and from the "Pip" button in the gallery app bar.
//
// The large avatar is one shared [PipAvatar] (≈ 220 px) on a card; the
// "Picker preview" row shows all three styles at 64 px the way the kid sees
// them when choosing their Pip. "Play all moods" cycles the current style
// through every mood, holding each for its authored wall-clock length (idle
// 3 s loop, happy 1.2 s, eating 1.8 s, sleepy 3 s hold, surprised 0.8 s,
// proud 1.2 s — see docs/pip-v2/ANIM_{A,B,C}_NOTES.md), then fires evolve.
//
// Reduced motion is honoured the same way the motion lab honours it: nothing
// plays, the avatar sits on its SVG fallback, and the one-shot buttons are
// disabled. The lab does not override the flag.
//
// Debug-only autoplay, set with `--dart-define=PIP_LAB_AUTOPLAY=<style>`
// (mochi | bolt | storybook): boots straight into the lab and runs Play-all
// for that style, so `simctl recordVideo` captures a full pass without
// manual navigation.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart' hide PipMood;
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/design_system_gallery/presentation/widgets/pip_lab_controls.dart';

/// The Pip lab.
class PipLabView extends StatefulWidget {
  const PipLabView({super.key, this.riveEnabled = true});

  /// Forwarded to [PipAvatar.riveEnabled]. See [PipAvatar.riveEnabled] for
  /// the one case a widget test cannot exercise the live rig: `flutter
  /// test` has no `librive_native.dylib`.
  final bool riveEnabled;

  @override
  State<PipLabView> createState() => _PipLabViewState();
}

class _PipLabViewState extends State<PipLabView> {
  /// Wall-clock hold per mood, from the animator notes (all authored at
  /// 60 fps): happy 72 f = 1.2 s, eating 108 f = 1.8 s, evolve 90 f =
  /// 1.5 s, surprised ≈ 48 f = 0.8 s, proud 72 f = 1.2 s. Idle and sleepy
  /// are loops (3 s / 4 s breath), so Play-all holds each for one breath.
  static const Map<PipMood, Duration> _moodDurations = {
    PipMood.idle: Duration(milliseconds: 2000),
    PipMood.happy: Duration(milliseconds: 1200),
    PipMood.eating: Duration(milliseconds: 1800),
    PipMood.sleepy: Duration(milliseconds: 3000),
    PipMood.surprised: Duration(milliseconds: 800),
    PipMood.proud: Duration(milliseconds: 1200),
  };

  /// Evolve burst length, per the contract notes (90 f = 1.5 s).
  static const Duration _evolveDuration = Duration(milliseconds: 1500);

  /// Small beat between Play-all steps so a recording reads as separate
  /// moods rather than one blend.
  static const Duration _stepGap = Duration(milliseconds: 350);

  /// Debug-only autoplay, set with `--dart-define=PIP_LAB_AUTOPLAY=<style>`.
  /// One of: mochi, bolt, storybook, custom. `custom` cycles every skin ×
  /// accessory for the customisation recording instead of the moods.
  static const String _autoplay = String.fromEnvironment('PIP_LAB_AUTOPLAY');

  bool _autoplayFired = false;

  PipStyle _style = PipStyle.mochi;
  int _stage = 3;
  PipMood _mood = PipMood.idle;
  PipSkin _skin = PipSkin.sunny;
  PipAccessory _accessory = PipAccessory.none;
  bool _inNest = false;

  /// Imperative handle for the evolve/tap triggers. Detached until the
  /// avatar mounts and rewires it (see `PipAvatar._attachExternal`); writes
  /// before the bind are dropped silently.
  late final PipAvatarController _avatar = PipAvatarController.detached();

  /// Cancellation token: every [_playAll] run captures its own value, and
  /// every await checks it, so Stop/dispose ends the loop without timers.
  int _playToken = 0;
  int _step = -1;
  bool _playing = false;
  String _customLabel = '';
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    if (_autoplay.isNotEmpty && !_autoplayFired) {
      _autoplayFired = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_runAutoplay(_autoplay));
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
  }

  @override
  void dispose() {
    _playToken++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('ds-section-pip-lab'),
      appBar: AppBar(title: const Text('Pip lab')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          NestSpacing.padSide,
          0,
          NestSpacing.padSide,
          NestSpacing.s10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: NestSpacing.s4),
            Text(
              'Every Pip body style, stage, mood, skin and accessory, driven '
              'through one shared PipAvatar. Contract: '
              'docs/pip-v2/PIP_V2_CONTRACT.md.',
              style: context.nestText.body,
            ),
            const SizedBox(height: NestSpacing.s4),
            _stageCard(),
            if (_reduceMotion) ...[
              const SizedBox(height: NestSpacing.s3),
              _reducedMotionNotice(),
            ],
            const SizedBox(height: NestSpacing.s4),
            const NestSectionLabel(label: 'Body style'),
            const SizedBox(height: NestSpacing.s2),
            NestSegmented<PipStyle>(
              semanticLabel: 'Body style',
              value: _style,
              onChanged: _playing
                  ? null
                  : (value) => setState(() => _style = value),
              options: const <NestSegmentOption<PipStyle>>[
                NestSegmentOption<PipStyle>(
                  value: PipStyle.mochi,
                  label: 'Mochi',
                ),
                NestSegmentOption<PipStyle>(
                  value: PipStyle.bolt,
                  label: 'Bolt',
                ),
                NestSegmentOption<PipStyle>(
                  value: PipStyle.storybook,
                  label: 'Storybook',
                ),
              ],
            ),
            const SizedBox(height: NestSpacing.s4),
            const NestSectionLabel(label: 'Growth stage'),
            const SizedBox(height: NestSpacing.s2),
            NestSegmented<int>(
              semanticLabel: 'Growth stage',
              value: _stage,
              onChanged: _playing
                  ? null
                  : (value) => setState(() => _stage = value),
              options: const <NestSegmentOption<int>>[
                NestSegmentOption<int>(value: 1, label: '1'),
                NestSegmentOption<int>(value: 2, label: '2'),
                NestSegmentOption<int>(value: 3, label: '3'),
                NestSegmentOption<int>(value: 4, label: '4'),
              ],
            ),
            const SizedBox(height: NestSpacing.s4),
            const NestSectionLabel(label: 'Mood'),
            const SizedBox(height: NestSpacing.s2),
            PipLabMoodChips(
              mood: _mood,
              onChanged: (value) => setState(() => _mood = value),
            ),
            const SizedBox(height: NestSpacing.s3),
            _triggerRow(),
            const SizedBox(height: NestSpacing.s4),
            const NestSectionLabel(label: 'Skin'),
            const SizedBox(height: NestSpacing.s2),
            PipLabSkinSwatches(
              skin: _skin,
              onChanged: (value) => setState(() => _skin = value),
            ),
            const SizedBox(height: NestSpacing.s4),
            const NestSectionLabel(label: 'Accessory'),
            const SizedBox(height: NestSpacing.s2),
            PipLabAccessoryChips(
              accessory: _accessory,
              onChanged: (value) => setState(() => _accessory = value),
            ),
            const SizedBox(height: NestSpacing.s4),
            _playAllCard(),
            const SizedBox(height: NestSpacing.s4),
            const NestSectionLabel(label: 'Picker preview'),
            const SizedBox(height: NestSpacing.s2),
            PipLabPickerPreview(
              style: _style,
              stage: _stage,
              skin: _skin,
              riveEnabled: widget.riveEnabled,
              onSelected: (value) => setState(() => _style = value),
            ),
          ],
        ),
      ),
    );
  }

  /// The large avatar on its card, with the In-nest toggle underneath.
  Widget _stageCard() {
    return NestCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: PipAvatar(
              key: ValueKey(
                'piplab-avatar-${_style.name}-s$_stage-${_inNest ? 'nest' : 'solo'}',
              ),
              style: _style,
              stage: _stage,
              mood: _mood,
              skin: _skin,
              accessory: _accessory,
              inNest: _inNest,
              size: 220,
              riveEnabled: widget.riveEnabled,
              controller: _avatar,
              onTap: _reduceMotion ? null : () => _avatar.poke(),
            ),
          ),
          const SizedBox(height: NestSpacing.s2),
          Text(
            '${_style.name.toUpperCase()} · STAGE $_stage · ${_mood.name.toUpperCase()}',
            style: context.nestText.bodySmallStrong,
            textAlign: TextAlign.center,
          ),
          Text(
            'artboard ${_inNest ? 'PipStage' : 'Stage$_stage'} · machine Pip · '
            '${PipAvatar.fallbackAsset(_style, _stage).split('/').last}',
            style: context.nestText.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: NestSpacing.s2),
          Row(
            children: [
              Expanded(
                child: Text(
                  'In nest',
                  style: context.nestText.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              NestToggle(
                value: _inNest,
                semanticLabel: 'In nest',
                onChanged: (next) => setState(() => _inNest = next),
              ),
            ],
          ),
        ],
      ),
    );
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
              'Reduced motion is on, so Pip is on its static SVG and the '
              'one-shot buttons are off. Turn it off to watch the moods: '
              'iOS Simulator → Features → Accessibility → Reduce Motion.',
              style: context.nestText.caption,
            ),
          ),
        ],
      ),
    );
  }

  /// Evolve and Tap, firing the two triggers through the avatar controller.
  Widget _triggerRow() {
    return Row(
      children: [
        Expanded(
          child: NestButton(
            label: 'Evolve',
            leading: const Icon(Icons.auto_awesome),
            variant: NestButtonVariant.secondary,
            onPressed: _reduceMotion || _playing ? null : _evolveOnce,
            fullWidth: false,
            minHeight: NestDevice.tapParent,
            fontSize: 15,
            horizontalPadding: NestSpacing.s3,
          ),
        ),
        const SizedBox(width: NestSpacing.s2),
        Expanded(
          child: NestButton(
            label: 'Tap',
            leading: const Icon(Icons.back_hand_outlined),
            variant: NestButtonVariant.secondary,
            onPressed: _reduceMotion ? null : () => _avatar.poke(),
            fullWidth: false,
            minHeight: NestDevice.tapParent,
            fontSize: 15,
            horizontalPadding: NestSpacing.s3,
          ),
        ),
      ],
    );
  }

  Widget _playAllCard() {
    return NestCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NestButton(
            label: _playing ? 'Stop' : 'Play all moods',
            leading: Icon(_playing ? Icons.stop : Icons.play_arrow),
            onPressed: _reduceMotion
                ? null
                : _playing
                ? _stopPlayAll
                : _playAll,
          ),
          const SizedBox(height: NestSpacing.s2),
          Text(_playCaption, style: context.nestText.caption),
        ],
      ),
    );
  }

  String get _playCaption {
    if (_reduceMotion) {
      return 'Off: the OS has asked for reduced motion, so the lab does not '
          'play anything.';
    }
    if (!_playing) {
      return 'Cycles ${_style.name} through every mood, then evolves.';
    }
    if (_step == -2) return _customLabel;
    const moods = PipMood.values;
    final step = _step >= 0 && _step <= moods.length ? _step : -1;
    final label = step < moods.length
        ? moods[step < 0 ? 0 : step].name
        : 'evolve';
    return 'Step ${step + 1} of ${moods.length + 1} · $label';
  }

  // ---------------------------------------------------------------- playback

  /// One Evolve press: fire the trigger, let the 1.5 s burst play out, then
  /// land on the next stage (wrapping 4 → 1). Swapping the stage swaps the
  /// artboard (a new view-model instance), which would cut the one-shot
  /// short — hence the wait first.
  Future<void> _evolveOnce() async {
    final token = ++_playToken;
    await _awaitBound();
    if (!mounted || token != _playToken) return;
    _avatar.playEvolve();
    await Future<void>.delayed(_evolveDuration + _stepGap);
    if (!mounted || token != _playToken) return;
    setState(() => _stage = _stage % 4 + 1);
  }

  /// Play-all: every mood in contract order, each held for its authored
  /// length, then the evolve burst. Style switches are locked out while it
  /// runs (the segmented control is disabled); the caption counts steps.
  Future<void> _playAll() async {
    if (_reduceMotion || _playing) return;
    final token = ++_playToken;
    setState(() {
      _playing = true;
      _step = 0;
    });
    const moods = PipMood.values;
    for (var i = 0; i < moods.length; i++) {
      if (!mounted || token != _playToken) return;
      setState(() {
        _mood = moods[i];
        _step = i;
      });
      // Mood writes ARE the one-shot triggers (see PipAvatar.didUpdateWidget),
      // so each holds for its full authored length before the next lands.
      await Future<void>.delayed(_moodDurations[moods[i]]! + _stepGap);
    }
    if (!mounted || token != _playToken) return;
    setState(() => _step = moods.length);
    await _awaitBound();
    if (!mounted || token != _playToken) return;
    _avatar.playEvolve();
    await Future<void>.delayed(_evolveDuration + _stepGap);
    if (!mounted || token != _playToken) return;
    setState(() {
      _stage = _stage % 4 + 1;
      _mood = PipMood.idle;
    });
    _stopPlayAll();
  }

  /// Customisation pass: every skin × accessory on stage 3, ~0.85 s each
  /// (≈ 17 s for all 20), so one recording shows the whole matrix.
  Future<void> _playAllCustom() async {
    if (_reduceMotion || _playing) return;
    final token = ++_playToken;
    var done = 0;
    const total = 20; // 4 skins × 5 accessories, kept literal for the caption.
    setState(() {
      _playing = true;
      _step = -2;
      _stage = 3;
      _mood = PipMood.idle;
    });
    for (final skin in PipSkin.values) {
      for (final accessory in PipAccessory.values) {
        if (!mounted || token != _playToken) return;
        done++;
        setState(() {
          _skin = skin;
          _accessory = accessory;
          _customLabel =
              'Custom $done of $total · ${skin.name} + '
              '${accessory.name}';
        });
        // Skin/accessory writes recolour live (no one-shot to await), so a
        // short readable hold per cell is enough.
        await Future<void>.delayed(const Duration(milliseconds: 850));
      }
    }
    if (!mounted || token != _playToken) return;
    _stopPlayAll();
  }

  /// Waits until the Rive view model is bound (or a 10 s cap). Triggers fired
  /// before the bind are dropped silently, so every scripted trigger goes
  /// through here first. Number writes (mood, stage, skin) do not need it:
  /// the bind pushes the current values itself.
  Future<void> _awaitBound() async {
    // Without Rive (tests, missing native lib) nothing ever binds.
    if (!widget.riveEnabled) return;
    for (var i = 0; i < 100; i++) {
      if (_avatar.isBound) return;
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }
  }

  void _stopPlayAll() {
    _playToken++;
    if (!_playing && _step < 0) return;
    setState(() {
      _playing = false;
      _step = -1;
    });
  }

  // ---------------------------------------------------------- autoplay ----
  // Debug-only entry for scripted `simctl recordVideo` proofs. The value
  // comes from `--dart-define=PIP_LAB_AUTOPLAY=<style>` (see [_autoplay]).

  Future<void> _runAutoplay(String name) async {
    if (_reduceMotion) return;
    if (name.toLowerCase() == 'custom') {
      // Customisation matrix recording: settle, then every skin × accessory.
      await Future<void>.delayed(const Duration(milliseconds: 2000));
      if (!mounted) return;
      await _awaitBound();
      if (!mounted) return;
      await _playAllCustom();
      return;
    }
    final style = switch (name.toLowerCase()) {
      'mochi' => PipStyle.mochi,
      'bolt' => PipStyle.bolt,
      'storybook' => PipStyle.storybook,
      _ => null,
    };
    if (style == null) return;
    // Let the avatar mount and bind (triggers fired before the view-model
    // instance exists are dropped), with a static gap so a recording shows
    // settle → moods as separate motion blocks.
    if (mounted) setState(() => _style = style);
    await Future<void>.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    await _awaitBound();
    if (!mounted) return;
    await _playAll();
  }
}

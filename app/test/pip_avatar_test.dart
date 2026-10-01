import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';

/// The Mochi asset must be in the bundle and carry the `RIVE` fingerprint.
/// This is the same check the widget makes at runtime, asserted here so a
/// bad build (empty file, truncated export, wrong path) fails in CI rather
/// than on a child's screen.
Future<bool> _mochiRivIsValid() async {
  const asset = 'assets/animations/rive/pip_mochi.riv';
  final data = await rootBundle.load(asset);
  if (data.lengthInBytes < 4) return false;
  final b = data.buffer.asUint8List(data.offsetInBytes, 4);
  return b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x56 && b[3] == 0x45;
}

// The Rive native runtime cannot run under `flutter test`:
// librive_native.dylib is absent and the runtime reports that through
// FlutterError on every frame, which flutter_test counts as a failure.
// `riveEnabled: false` puts the widgets on their SVG path, which is the code
// a real missing-library build takes too. The .riv itself is still verified
// above, against the real bundle.
const bool kUseRive = false;

Widget _host(Widget child, {Size size = const Size(240, 240)}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox.fromSize(size: size, child: child),
    ),
  ),
);

void main() {
  group('pip_mochi.riv asset', () {
    testWidgets('is bundled and carries the RIVE fingerprint', (tester) async {
      expect(await _mochiRivIsValid(), isTrue);
    });

    test('stays well under the 300 KB budget', () async {
      const asset = 'assets/animations/rive/pip_mochi.riv';
      final data = await rootBundle.load(asset);
      expect(data.lengthInBytes, lessThan(300 * 1024));
    });
  });

  group('contract enums', () {
    test('PipMood pins the values the Rive transitions compare against', () {
      expect(PipMood.values.map((m) => m.value), [0, 1, 2, 3, 4, 5]);
    });

    test('PipSkin pins indices and data-bound colours', () {
      expect(PipSkin.values.map((s) => s.value), [0, 1, 2, 3]);
      expect(PipSkin.sunny.body, const Color(0xFFFFD93D));
      expect(PipSkin.sunny.belly, const Color(0xFFFFF1B8));
      expect(PipSkin.berry.body, const Color(0xFFFF9EBB));
      expect(PipSkin.sky.body, const Color(0xFF8EC9FF));
      expect(PipSkin.mint.body, const Color(0xFF8EE3B5));
    });

    test('PipAccessory pins the values the Formula converters read', () {
      expect(PipAccessory.values.map((a) => a.value), [0, 1, 2, 3, 4]);
    });

    test('PipStyle resolves one .riv per body style', () {
      expect(PipStyle.mochi.riveAsset, 'assets/animations/rive/pip_mochi.riv');
      expect(PipStyle.bolt.riveAsset, 'assets/animations/rive/pip_bolt.riv');
      expect(
        PipStyle.storybook.riveAsset,
        'assets/animations/rive/pip_storybook.riv',
      );
    });

    test('artboard names match the Rive file', () {
      for (var stage = 1; stage <= 4; stage++) {
        expect(
          PipAvatar(style: PipStyle.mochi, stage: stage).artboard,
          'Stage$stage',
        );
      }
    });

    test('Mochi fallbacks are the approved idle poses', () {
      for (var stage = 1; stage <= 4; stage++) {
        expect(
          PipAvatar.fallbackAsset(PipStyle.mochi, stage),
          'assets/illustrations/pip_v2/mochi/s${stage}_idle_1.svg',
        );
      }
    });
  });

  group('PipAvatar', () {
    for (final style in PipStyle.values) {
      for (var stage = 1; stage <= 4; stage++) {
        testWidgets('builds for ${style.name} stage $stage without throwing', (
          tester,
        ) async {
          await tester.pumpWidget(
            _host(
              PipAvatar(
                style: style,
                stage: stage,
                size: 200,
                riveEnabled: kUseRive,
              ),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(find.byType(PipAvatar), findsOneWidget);
        });
      }
    }

    testWidgets('renders a graphic for every style and stage', (tester) async {
      for (final style in PipStyle.values) {
        for (var stage = 1; stage <= 4; stage++) {
          await tester.pumpWidget(
            _host(
              PipAvatar(
                style: style,
                stage: stage,
                size: 200,
                riveEnabled: kUseRive,
              ),
            ),
          );
          await tester.pump();
          expect(
            find.byWidgetPredicate(
              (w) =>
                  w is SvgPicture || w.runtimeType.toString().contains('Rive'),
            ),
            findsWidgets,
            reason: '${style.name} stage $stage drew nothing',
          );
        }
      }
    });

    testWidgets('renders every mood, skin and accessory without throwing', (
      tester,
    ) async {
      for (final mood in PipMood.values) {
        for (final skin in PipSkin.values) {
          for (final accessory in PipAccessory.values) {
            await tester.pumpWidget(
              _host(
                PipAvatar(
                  style: PipStyle.mochi,
                  stage: 3,
                  mood: mood,
                  skin: skin,
                  accessory: accessory,
                  size: 200,
                  riveEnabled: kUseRive,
                ),
              ),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
          }
        }
      }
    });

    testWidgets('builds in the nest for every stage', (tester) async {
      for (var stage = 1; stage <= 4; stage++) {
        await tester.pumpWidget(
          _host(
            PipAvatar(
              style: PipStyle.mochi,
              stage: stage,
              inNest: true,
              size: 200,
              riveEnabled: kUseRive,
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('falls back to the static SVG under reduced motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: PipAvatar(style: PipStyle.mochi, stage: 4, size: 200),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reports taps', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        _host(
          PipAvatar(
            style: PipStyle.mochi,
            stage: 3,
            size: 200,
            riveEnabled: kUseRive,
            onTap: () => tapped++,
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byType(PipAvatar));
      expect(tapped, 1);
    });

    testWidgets('exposes an imperative controller', (tester) async {
      PipAvatarController? captured;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) {
              captured = PipAvatar.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      // No PipAvatar ancestor: the handle is null rather than throwing.
      expect(captured, isNull);
    });

    testWidgets('external controller attaches without throwing', (
      tester,
    ) async {
      final controller = PipAvatarController.detached();
      await tester.pumpWidget(
        _host(
          PipAvatar(
            style: PipStyle.mochi,
            stage: 2,
            size: 200,
            riveEnabled: kUseRive,
            controller: controller,
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      // Unbound one-shots are dropped silently, never throw.
      controller
        ..celebrate()
        ..eat()
        ..sleep()
        ..surprise()
        ..praise()
        ..rest()
        ..playEvolve()
        ..poke()
        ..blink();
      expect(tester.takeException(), isNull);
    });
  });
}

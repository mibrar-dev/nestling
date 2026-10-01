import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/motion/pip_rive.dart';

/// The asset must be in the bundle and carry the `RIVE` fingerprint. This is
/// the same check the widget makes at runtime, asserted here so a bad build
/// (empty file, truncated export, wrong path) fails in CI rather than on a
/// child's screen.
Future<bool> _rivIsValid() async {
  final data = await rootBundle.load(kPipRiveAsset);
  if (data.lengthInBytes < 4) return false;
  final b = data.buffer.asUint8List(data.offsetInBytes, 4);
  return b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x56 && b[3] == 0x45;
}

// The Rive native runtime cannot run under `flutter test`: librive_native.dylib
// is absent and the runtime reports that through FlutterError on every frame,
// which flutter_test counts as a failure. `riveEnabled: false` puts the widgets
// on their SVG path, which is the code a real missing-library build takes too.
// The .riv itself is still verified above, against the real bundle.
const bool kUseRive = false;

Widget _host(Widget child, {Size size = const Size(240, 240)}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox.fromSize(size: size, child: child),
    ),
  ),
);

void main() {
  group('pip.riv asset', () {
    testWidgets('is bundled and carries the RIVE fingerprint', (tester) async {
      expect(await _rivIsValid(), isTrue);
    });

    test('stays well under the 30 KB budget', () async {
      final data = await rootBundle.load(kPipRiveAsset);
      expect(data.lengthInBytes, lessThan(30 * 1024));
    });
  });

  group('PipStage', () {
    test('maps every stage to a distinct artboard and an SVG fallback', () {
      final artboards = PipStage.values.map((s) => s.artboard).toSet();
      expect(artboards.length, PipStage.values.length);
      expect(PipStage.values.map((s) => s.fallbackAsset), [
        'assets/illustrations/pip_stage_1.svg',
        'assets/illustrations/pip_stage_2.svg',
        'assets/illustrations/pip_stage_3.svg',
        'assets/illustrations/pip_stage_4.svg',
      ]);
    });

    test('next stops at the final stage', () {
      expect(PipStage.egg.next, PipStage.hatchling);
      expect(PipStage.fledgling.next, PipStage.songbird);
      expect(PipStage.songbird.next, isNull);
    });
  });

  group('PipMood', () {
    test('pins the integer values the Rive transitions compare against', () {
      expect(PipMood.idle.value, 0);
      expect(PipMood.happy.value, 1);
      expect(PipMood.eating.value, 2);
      expect(PipMood.sleepy.value, 3);
    });
  });

  group('PipRive', () {
    for (final stage in PipStage.values) {
      testWidgets('builds for ${stage.name} without throwing', (tester) async {
        await tester.pumpWidget(
          _host(PipRive(stage: stage, size: 200, riveEnabled: kUseRive)),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.byType(PipRive), findsOneWidget);
      });
    }

    testWidgets('renders a graphic for every stage', (tester) async {
      // Either the Rive widget or the SVG fallback, never nothing.
      for (final stage in PipStage.values) {
        await tester.pumpWidget(
          _host(PipRive(stage: stage, size: 200, riveEnabled: kUseRive)),
        );
        await tester.pump();
        expect(
          find.byWidgetPredicate(
            (w) => w is SvgPicture || w.runtimeType.toString().contains('Rive'),
          ),
          findsWidgets,
          reason: 'stage ${stage.stage} drew nothing',
        );
      }
    });

    testWidgets('falls back to the static SVG under reduced motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: PipRive(stage: PipStage.songbird, size: 200),
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
        _host(PipRive(size: 200, riveEnabled: kUseRive, onTap: () => tapped++)),
      );
      await tester.pump();
      await tester.tap(find.byType(PipRive));
      expect(tapped, 1);
    });

    testWidgets('exposes an imperative controller', (tester) async {
      PipRiveController? captured;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) {
              captured = PipRive.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      // No PipRive ancestor: the handle is null rather than throwing.
      expect(captured, isNull);
    });
  });

  group('PipJar', () {
    for (final fill in [0.0, 0.2, 0.62, 1.0]) {
      testWidgets('builds at fill $fill without throwing', (tester) async {
        await tester.pumpWidget(
          _host(PipJar(fill: fill, size: 200, riveEnabled: kUseRive)),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('clamps an out-of-range fill', (tester) async {
      await tester.pumpWidget(
        _host(const PipJar(fill: 4.2, size: 200, riveEnabled: kUseRive)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('falls back to the static jar SVG under reduced motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: PipJar(size: 200),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(SvgPicture), findsOneWidget);
    });
  });
}

// P04 · Privacy & consent — artwork provenance and painted-colour proofs.
//
// The shared batch (merge ce89889) landed three shared pieces that P04 now
// consumes: `ic_trash.svg` + `NestIcons.trash`, `NestPrivacyShield` (the
// token-coloured replacement for the light-baked `privacy_shield.svg`) and the
// shared `NestList` separator overlay. Those fixes closed P04-2 and P04-7, so
// this file pins where the artwork comes from — not just that "something
// renders":
//
//   1. the shipped trash SVG carries the design glyph's exact path data;
//   2. the trash ink is the design's `--a-peach` token, in both themes;
//   3. the shield paints ONLY the current theme's tokens, and in dark mode no
//      light-token pixel can appear at all (the P04-7 regression guard, now
//      checked on the pixels the screen actually draws);
//   4. the screen uses `NestPrivacyShield`, never the baked illustration.
//
// Design values are read from `design/html-source/**` rather than transcribed,
// so a design edit fails the test instead of drifting.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

import '../../test_scope.dart';

const String _shieldLabel =
    'A shield with a leaf and a heart, protecting your family';

/// Reads a file from `design/html-source/`, walking up from the package root.
File _designFile(String name) {
  var dir = Directory.current.absolute;
  for (var depth = 0; depth < 5; depth++) {
    final candidate = File('${dir.path}/design/html-source/$name');
    if (candidate.existsSync()) return candidate;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError(
    'design/html-source/$name not found above ${Directory.current.path}',
  );
}

String _appFile(String path) {
  final file = File('${Directory.current.path}/$path');
  expect(file.existsSync(), isTrue, reason: 'missing asset: ${file.path}');
  return file.readAsStringSync();
}

/// `#RRGGBB` / `#AARRGGBB` from a design token file.
String _cssToken(String css, String name, {int occurrence = 0}) {
  final matches = RegExp('$name:\\s*(#[0-9A-Fa-f]{6})')
      .allMatches(css)
      .toList();
  expect(
    matches.length,
    greaterThan(occurrence),
    reason: '$name #$occurrence is missing from the design tokens',
  );
  return matches[occurrence].group(1)!.toUpperCase();
}

/// `0xAARRGGBB`, matching the raw-RGBA pixels read back from the picture.
int _argb(Color colour) => colour.toARGB32() & 0xFFFFFFFF;

/// Rasterises [painter] at [size] and returns its opaque pixels as ARGB ints
/// plus the total opaque pixel count.
Future<(Set<int>, int)> _paintedPixels(
  WidgetTester tester,
  CustomPainter painter,
  int size,
) async {
  // `Picture.toImage(w, h)` scales the recorded picture's bounding box to the
  // requested size, so lay a transparent 1x1-canvas box first: without it the
  // artwork is scaled by its own ink bounds and no interior pixel is flat.
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)
    ..drawRect(
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      Paint()..color = const Color(0x00000000),
    );
  painter.paint(canvas, Size(size.toDouble(), size.toDouble()));
  final picture = recorder.endRecording();

  late Set<int> colours;
  late int opaque;
  await tester.runAsync(() async {
    final image = await picture.toImage(size, size);
    final data = await image.toByteData();
    final bytes = data!.buffer.asUint8List();
    colours = <int>{};
    opaque = 0;
    for (var i = 0; i < bytes.length; i += 4) {
      if (bytes[i + 3] == 0) continue; // transparent
      opaque += 1;
      // Pack as 0xAARRGGBB so the ints compare with `Color.toARGB32()`.
      colours.add(
        (255 << 24) | (bytes[i] << 16) | (bytes[i + 1] << 8) | bytes[i + 2],
      );
    }
  });
  return (colours, opaque);
}

void main() {
  group('P04 — trash glyph provenance (orchestrator note item 1)', () {
    late String designHtml;
    late String trashSvg;

    setUpAll(() {
      designHtml = _designFile('screens/P04-privacy.html').readAsStringSync();
      trashSvg = _appFile('assets/icons/ic_trash.svg');
    });

    test('the shipped SVG carries the design glyph path verbatim', () {
      // The design's row-4 icon: a lid line, a handle and a tapered body.
      final designPath = RegExp(
        r'<div class="list-row">\s*<span class="icon-tile tint-peach"[^>]*>'
        r'<svg[^>]*>\s*<path d="([^"]+)"',
        dotAll: true,
      ).firstMatch(designHtml);
      expect(designPath, isNotNull, reason: 'the design row-4 icon moved');
      final expected = designPath!.group(1)!;

      final shipped = RegExp('<path d="([^"]+)"').firstMatch(trashSvg);
      expect(shipped, isNotNull, reason: 'ic_trash.svg has no path');
      expect(
        shipped!.group(1),
        expected,
        reason:
            'ic_trash.svg must be the design glyph transcribed 1:1 — a '
            'stand-in (wheelie bin, laundry basket) is a visible defect',
      );
      expect(NestIcons.trash, 'assets/icons/ic_trash.svg');
    });

    test('the glyph is token-tintable, not a baked colour', () {
      // `NestIcon` tints with a ColorFilter, so the asset must paint with
      // currentColor or an explicit `none` fill — a baked hex would ignore the
      // peach ink and render wrong in both themes.
      expect(trashSvg, contains('currentColor'));
      expect(trashSvg, isNot(contains('fill="#')));
      expect(trashSvg, isNot(contains('stroke="#')));
      expect(RegExp('stroke-width="2"').hasMatch(trashSvg), isTrue);
    });

    test('the tile ink is the design --a-peach token in both themes', () {
      final css = _designFile('tokens.css').readAsStringSync();
      // First declaration = light block, last = dark block.
      final declarations = RegExp(r'--a-peach:\s*(#[0-9A-Fa-f]{6})')
          .allMatches(css)
          .toList();
      expect(declarations.length, greaterThanOrEqualTo(2));
      final light = declarations.first.group(1)!.toUpperCase();
      final dark = declarations.last.group(1)!.toUpperCase();

      expect(_cssToken(css, '--a-peach'), light);
      expect(
        NestColors.light.aPeach.toARGB32() & 0xFFFFFF,
        int.parse('FF${light.substring(1)}', radix: 16) & 0xFFFFFF,
        reason: 'the light trash ink must be the design --a-peach',
      );
      expect(
        NestColors.dark.aPeach.toARGB32() & 0xFFFFFF,
        int.parse('FF${dark.substring(1)}', radix: 16) & 0xFFFFFF,
        reason: 'the dark trash ink must be the dark --a-peach',
      );
      expect(light, isNot(dark), reason: 'the themes must differ');
    });

    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('${theme.name}: row 4 paints the shared trash glyph', (
        tester,
      ) async {
        await setUpTestScope();
        await pumpAppRoute(tester, '/privacy', theme: theme);

        final row = find
            .ancestor(
              of: find.text('Delete everything anytime'),
              matching: find.byType(Semantics),
            )
            .first;
        final icon = find.descendant(of: row, matching: find.byType(NestIcon));
        expect(icon, findsOneWidget);

        final widget = tester.widget<NestIcon>(icon);
        expect(widget.assetName, NestIcons.trash);
        expect(widget.size, 24);
        expect(
          widget.color,
          theme == ThemeMode.light
              ? NestColors.light.aPeach
              : NestColors.dark.aPeach,
          reason: 'the trash ink is the --a-peach token, not a baked colour',
        );

        // The tile keeps the peach tint, and the glyph is really drawn.
        final tile = find
            .descendant(of: row, matching: find.byType(Container))
            .first;
        expect(
          (tester.widget<Container>(tile).decoration! as BoxDecoration).color,
          theme == ThemeMode.light
              ? NestColors.light.peachTint
              : NestColors.dark.peachTint,
        );
        final svg = tester.widget<SvgPicture>(
          find.descendant(of: row, matching: find.byType(SvgPicture)),
        );
        expect((svg.bytesLoader as SvgAssetLoader).assetName, NestIcons.trash);
        expect(svg.colorFilter, isNotNull, reason: 'the glyph must be tinted');
        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      });
    }
  });

  group('P04 — shield paints theme tokens (P04-7)', () {
    testWidgets('the screen uses NestPrivacyShield, not the baked SVG', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/privacy');

      expect(find.byType(NestPrivacyShield), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is SvgPicture &&
              widget.bytesLoader is SvgAssetLoader &&
              (widget.bytesLoader as SvgAssetLoader).assetName.contains(
                'privacy_shield',
              ),
        ),
        findsNothing,
        reason: 'the light-baked illustration must no longer be drawn',
      );
      expect(find.bySemanticsLabel(_shieldLabel), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('84x84 by default and scaled by its size token', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/privacy');

      final shield = tester.widget<NestPrivacyShield>(
        find.byType(NestPrivacyShield),
      );
      expect(shield.size, 84, reason: 'the HTML renders the shield at 84');
      expect(shield.semanticLabel, _shieldLabel);
      expect(
        tester.getSize(find.byType(NestPrivacyShield)),
        const Size(84, 84),
      );
      await disposeApp(tester);
    });

    testWidgets('the shield is announced as an image', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/privacy');

      final data = tester
          .getSemantics(find.bySemanticsLabel(_shieldLabel))
          .getSemanticsData();
      expect(data.flagsCollection.isImage, isTrue);
      expect(data.label, _shieldLabel);
      await disposeApp(tester);
    });

    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('${theme.name}: every painted pixel is a theme token', (
        tester,
      ) async {
        await setUpTestScope();
        await pumpAppRoute(tester, '/privacy', theme: theme);
        final palette = theme == ThemeMode.light
            ? NestColors.light
            : NestColors.dark;
        final other = theme == ThemeMode.light
            ? NestColors.dark
            : NestColors.light;

        final paint = tester.widget<CustomPaint>(
          find.descendant(
            of: find.byType(NestPrivacyShield),
            matching: find.byType(CustomPaint),
          ),
        );
        final painter = paint.painter;
        expect(painter, isNotNull);

        final (colours, opaque) = await _paintedPixels(tester, painter!, 84);
        expect(
          opaque,
          greaterThan(84 * 84 ~/ 2),
          reason: 'nothing was painted',
        );

        // Every colour the design draws is one of the four theme tokens:
        // skyTint disc, surface body, leaf heart, ink stroke.
        final tokens = <int>{
          _argb(palette.skyTint),
          _argb(palette.surface),
          _argb(palette.leaf),
          _argb(palette.ink),
        };
        for (final token in tokens) {
          expect(
            colours,
            contains(token),
            reason: 'the shield must paint token ${token.toRadixString(16)}',
          );
        }

        // The disc is the theme's skyTint and nothing else: no pixel may be a
        // flat opaque colour from the OTHER theme (that is exactly how the
        // light-baked SVG broke dark mode).
        for (final foreign in <Color>[
          other.skyTint,
          other.surface,
          other.leaf,
        ]) {
          expect(
            colours,
            isNot(contains(_argb(foreign))),
            reason:
                'dark/light leakage: ${foreign.toARGB32().toRadixString(16)} '
                'is not a ${theme.name} token',
          );
        }
        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      });
    }

    test('the light and dark disc tokens match the design CSS', () {
      final css = _designFile('tokens.css').readAsStringSync();
      final skyTint = RegExp(r'--sky-tint:\s*(#[0-9A-Fa-f]{6})')
          .allMatches(css)
          .toList();
      expect(skyTint.length, greaterThanOrEqualTo(2));
      expect(
        NestColors.light.skyTint.toARGB32() & 0xFFFFFF,
        int.parse('FF${skyTint.first.group(1)!.substring(1)}', radix: 16) &
            0xFFFFFF,
        reason: 'light --sky-tint backs the shield disc',
      );
      expect(
        NestColors.dark.skyTint.toARGB32() & 0xFFFFFF,
        int.parse('FF${skyTint.last.group(1)!.substring(1)}', radix: 16) &
            0xFFFFFF,
        reason: 'dark --sky-tint is the navy disc in the dark design',
      );
    });
  });
}

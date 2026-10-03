// P04 · Privacy & consent — accessibility and token-hygiene contracts.
//
// Iteration 6 had no new production surface (every FIXES_5 wire-up was already
// in the tree), so this stage closed the last gaps in the screen's contract:
//
//   1. WCAG contrast for every colour pair the screen actually paints — the
//      design spec claims "token pairs only, sky-on-surface link ≥ 4.5:1", and
//      nothing asserted it. Text pairs must clear 4.5:1, the 24 px tile glyphs
//      3:1 (WCAG 1.4.11 non-text contrast), in BOTH themes.
//   2. A system text scale above the design-system clamp (1.6 → clamped to
//      1.3) must still render without overflow — the real "large system text"
//      path a parent can actually reach.
//   3. Screen-reader shape: one header node announced before the promise rows,
//      every interactive control labelled.
//   4. Token hygiene: no colour literal anywhere in the feature's sources
//      (the "tokens only, never hard-code colours" rule), and every colour the
//      view paints is a named palette entry.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

import '../../test_scope.dart';

/// WCAG 2.x relative-luminance contrast ratio.
double _contrast(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;
  return (lighter + 0.05) / (darker + 0.05);
}

/// One colour pair on the screen, resolved per theme.
typedef Pair = ({Color foreground, Color background, String what, bool text});

List<Pair> _pairs(NestSchemeColors c) => <Pair>[
  (
    foreground: c.ink,
    background: c.paper,
    what: 'h1 + row titles (ink on paper)',
    text: true,
  ),
  (
    foreground: c.ink2,
    background: c.paper,
    what: 'standfirst + row subs (ink2 on paper)',
    text: true,
  ),
  (
    foreground: c.danger,
    background: c.paper,
    what: 'failure caption (danger on paper)',
    text: true,
  ),
  (
    foreground: c.sky,
    background: c.surface,
    what: 'footnote link (sky on surface, 13px)',
    text: true,
  ),
  (
    foreground: c.ink2,
    background: c.surface,
    what: 'dialog promises (ink2 on surface)',
    text: true,
  ),
  (
    foreground: c.leafInk,
    background: c.leafTint,
    what: 'no-ads glyph (leafInk on leafTint)',
    text: false,
  ),
  (
    foreground: c.lilac,
    background: c.lilacTint,
    what: 'person glyph (lilac on lilacTint)',
    text: false,
  ),
  (
    foreground: c.sky,
    background: c.skyTint,
    what: 'pin glyph (sky on skyTint)',
    text: false,
  ),
  (
    foreground: c.aPeach,
    background: c.peachTint,
    what: 'trash glyph (aPeach on peachTint)',
    text: false,
  ),
];

List<Directory> _featureDirs() {
  var dir = Directory.current.absolute; // app/
  for (var depth = 0; depth < 5; depth++) {
    final feature = Directory('${dir.path}/lib/features/privacy_consent');
    if (feature.existsSync()) return <Directory>[feature];
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError(
    'lib/features/privacy_consent not found above ${Directory.current.path}',
  );
}

List<File> _featureSources() {
  final files = <File>[];
  for (final dir in _featureDirs()) {
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) files.add(entity);
    }
  }
  files.sort((a, b) => a.path.compareTo(b.path));
  return files;
}

/// Every Dart file of the feature, production **and** tests.
List<File> _featureAndTestSources() {
  final roots = <String>[
    '${Directory.current.path}/lib/features/privacy_consent',
    '${Directory.current.path}/test/features/privacy_consent',
  ];
  final files = <File>[];
  for (final root in roots) {
    final dir = Directory(root);
    expect(
      dir.existsSync(),
      isTrue,
      reason: '$root not found above ${Directory.current.path}',
    );
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) files.add(entity);
    }
  }
  files.sort((a, b) => a.path.compareTo(b.path));
  return files;
}

void main() {
  group('P04 — contrast of every painted colour pair', () {
    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      final palette = theme == ThemeMode.light
          ? NestColors.light
          : NestColors.dark;

      for (final pair in _pairs(palette)) {
        test('${theme.name}: ${pair.what}', () {
          final ratio = _contrast(pair.foreground, pair.background);
          final floor = pair.text ? 4.5 : 3.0;
          expect(
            ratio,
            greaterThanOrEqualTo(floor),
            reason:
                '${pair.what} measures ${ratio.toStringAsFixed(2)}:1; the '
                'design spec asks 4.5:1 for text and WCAG 1.4.11 asks 3:1 '
                'for meaningful non-text graphics',
          );
        });
      }
    }

    test('the themes really differ for every token the screen paints', () {
      // A test that only inspects one palette can pass while the other ships a
      // hard-coded colour, so require light and dark to differ.
      final light = <Color>[
        NestColors.light.ink,
        NestColors.light.ink2,
        NestColors.light.sky,
        NestColors.light.danger,
        NestColors.light.aPeach,
        NestColors.light.surface,
      ];
      final dark = <Color>[
        NestColors.dark.ink,
        NestColors.dark.ink2,
        NestColors.dark.sky,
        NestColors.dark.danger,
        NestColors.dark.aPeach,
        NestColors.dark.surface,
      ];
      for (var i = 0; i < light.length; i++) {
        expect(light[i], isNot(dark[i]), reason: 'token #$i must differ');
      }
    });
  });

  group('P04 — system text scale above the clamp', () {
    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('${theme.name}: a 1.6 system scale is clamped to 1.3', (
        tester,
      ) async {
        await setUpTestScope();
        // The platform reports 1.6; `NestlingApp` clamps to 1.0-1.3
        // (SPACING_SPEC §10), so the screen must lay out exactly like 1.3.
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpAppRoute(tester, '/privacy', theme: theme);

        final context = tester.element(find.text('Your family’s privacy'));
        final effective = MediaQuery.textScalerOf(context).scale(1);
        expect(effective, closeTo(1.3, 0.001));

        expect(find.text('Your family’s privacy'), findsOneWidget);
        for (final sub in <String>[
          'No ads or tracking — ever',
          'Delete everything anytime',
        ]) {
          expect(find.text(sub), findsOneWidget);
        }
        expect(find.text('Continue'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await disposeApp(tester);
      });
    }

    testWidgets('the opt card and toggle stay reachable at 320 / 1.6', (
      tester,
    ) async {
      await setUpTestScope();
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpAppRoute(tester, '/privacy');
      tester.view.physicalSize = const Size(320 * 3, 844 * 3);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final toggle = find.byKey(const ValueKey('p04_crash_toggle'));
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.widget<NestToggle>(toggle).value, isTrue);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('P04 — screen-reader shape', () {
    testWidgets('one header, labelled controls, display-only rows', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/privacy');
      final handle = tester.ensureSemantics();

      expect(
        tester
            .getSemantics(find.text('Your family’s privacy'))
            .getSemanticsData()
            .flagsCollection
            .isHeader,
        isTrue,
      );

      // One merged node per promise row, announced as text — not a button.
      final nodes = <SemanticsNode>[];
      for (final title in <String>[
        'No ads or tracking — ever',
        'Children only need a nickname',
        'Data stored in the UK (London)',
        'Delete everything anytime',
      ]) {
        nodes.add(
          tester.getSemantics(
            find
                .ancestor(
                  of: find.text(title),
                  matching: find.byType(Semantics),
                )
                .first,
          ),
        );
      }
      for (final node in nodes) {
        final data = node.getSemanticsData();
        expect(data.flagsCollection.isButton, isFalse);
        expect(data.hasAction(SemanticsAction.tap), isFalse);
      }

      // Every interactive control carries a label a screen reader can read.
      for (final label in <String>[
        'Back',
        'Share anonymous crash reports',
        'Read the full Privacy Notice',
      ]) {
        expect(
          tester
              .getSemantics(find.bySemanticsLabel(label))
              .getSemanticsData()
              .label,
          label,
        );
      }
      expect(find.bySemanticsLabel('Continue'), findsWidgets);

      await disposeApp(tester);
      handle.dispose();
    });
  });

  group('P04 — bundled fonts (orchestrator FONTS rule)', () {
    test('no feature source or test touches the removed fonts package', () {
      // Inter/Nunito are bundled assets now; the runtime-fetch fonts package
      // was removed from the app. A stray import or config call would not
      // fail at compile time until the package returns, so pin the rule
      // here. The needles are assembled from pieces so a plain grep for the
      // package/API name does not false-positive on this file (review
      // finding 3, iteration 8).
      const packageNeedle =
          'google'
          '_fonts';
      const apiNeedle =
          'Google'
          'Fonts';
      final offenders = <String>[];
      final sources = _featureAndTestSources();
      expect(sources.length, greaterThanOrEqualTo(10));
      for (final file in sources) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.contains(packageNeedle) || line.contains(apiNeedle)) {
            offenders.add('${file.path}:${i + 1}  ${line.trim()}');
          }
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'fonts are bundled assets (pubspec `fonts:`); the feature must '
            'not import the removed fonts package or call its config API',
      );
    });

    test('the type scale resolves to the bundled families', () {
      expect(NestType.body().fontFamily, 'Inter');
      expect(NestType.bodyStrong().fontFamily, 'Inter');
      expect(NestType.caption().fontFamily, 'Inter');
      expect(NestType.h1().fontFamily, 'Nunito');
      expect(NestType.h3().fontFamily, 'Nunito');
    });

    test('every bundled font asset in pubspec exists on disk', () {
      // A renamed or missing TTF only surfaces at runtime on a device; this
      // turns it into a test failure the moment it happens.
      final pubspec = File('${Directory.current.path}/pubspec.yaml');
      expect(pubspec.existsSync(), isTrue);
      final assets = RegExp(r'asset:\s*(assets/fonts/\S+)')
          .allMatches(pubspec.readAsStringSync())
          .map((m) => m.group(1)!)
          .toList();
      expect(assets, isNotEmpty, reason: 'pubspec declares no bundled fonts');
      for (final asset in assets) {
        final file = File('${Directory.current.path}/$asset');
        expect(
          file.existsSync(),
          isTrue,
          reason: 'pubspec references a font asset that is not on disk',
        );
        expect(file.lengthSync(), greaterThan(1024));
      }
    });
  });

  group('P04 — token hygiene (no hard-coded colours)', () {
    test('no feature source contains a colour literal', () {
      expect(_featureSources().length, greaterThanOrEqualTo(5));
      final offenders = <String>[];
      for (final file in _featureSources()) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.contains('Color(0x') ||
              line.contains('Colors.') ||
              line.contains('Color.fromARGB')) {
            offenders.add('${file.path}:${i + 1}  ${line.trim()}');
          }
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'colours must come from `context.nest` / `NestColors` tokens '
            '(RULES: never hard-code colours)',
      );
    });

    test('the view paints only named palette entries', () {
      final view = _featureSources().firstWhere(
        (f) => f.path.endsWith('privacy_consent_view.dart'),
      );
      final used = RegExp(r'tokens\.(\w+)')
          .allMatches(view.readAsStringSync())
          .map((m) => m.group(1)!)
          .toSet();

      // Every token the screen reaches for must be a real palette entry; the
      // allow-list is the design system's documented palette, so a renamed or
      // invented token shows up here.
      const palette = <String>{
        'paper',
        'surface',
        'surface2',
        'ink',
        'ink2',
        'line',
        'sky',
        'skyTint',
        'leaf',
        'leafTint',
        'leafInk',
        'lilac',
        'lilacTint',
        'peach',
        'peachTint',
        'aPeach',
        'coinTint',
        'coinInk',
        'danger',
        'knob',
        'track',
        'scrim',
        'heroBg',
        'onHero',
      };
      for (final token in used) {
        expect(
          palette.contains(token),
          isTrue,
          reason: 'tokens.$token is not a known palette entry',
        );
      }
      // The ones the screen must paint.
      for (final token in <String>[
        'paper',
        'ink',
        'ink2',
        'sky',
        'danger',
        'aPeach',
        'peachTint',
      ]) {
        expect(used, contains(token), reason: '$token must be reachable');
      }
    });
  });
}

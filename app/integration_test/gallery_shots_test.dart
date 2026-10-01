// Visual QA harness: screenshots every design-system gallery section, in
// light and dark, one PNG per section.
//
// The PNGs are written by test_driver/integration_test.dart into
// design/qa/sim/<RUN_LABEL>/; tools/sim_shots.sh runs this file and then
// builds the contact sheets. Run it with:
//
//   tools/sim_shots.sh baseline
//
// Section keys are the `ValueKey('ds-section-<slug>')`s on the gallery
// widgets. The list below is the contract with the QA tooling: it fixes the
// order, so the `<theme>_<nn>_<slug>` file names are stable across runs and
// sim_compare.py can line runs up. Add a slug here when a section is added.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/main.dart' as app;

/// Sections in gallery order. `motion` is the one screen behind the app bar
/// button, so it is captured last, per theme.
const List<String> gallerySections = <String>[
  'colour',
  'type',
  'spacing',
  'buttons',
  'cards',
  'lists',
  'chips',
  'segmented',
  'toggles',
  'stepper',
  'avatars',
  'coin-money-progress',
  'quest-cards',
  'nav-bars',
  'tab-bar',
  'bottom-cta',
  'fab-lock-pager',
  'inputs',
  'day-picker',
  'keypad',
  'overlays',
  'empty-state',
  'kid',
  'screens-p08',
  'screens-k03',
];

const List<ThemeMode> themes = <ThemeMode>[ThemeMode.light, ThemeMode.dark];

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('design system gallery shots', (tester) async {
    await app.main();
    await _settle(tester, frames: 30);

    // On iOS the Flutter view is not backed by an image the driver can read
    // until the surface is converted. Must happen after the first frame.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await binding.convertFlutterSurfaceToImage();
      await _settle(tester, frames: 10);
    }

    await _awaitGallery(tester);

    var captured = 0;
    for (final theme in themes) {
      GetIt.instance<ThemeModeController>().selectMode(theme);
      await _settle(tester, frames: 10);
      // Each pass walks the list from the top, so the frames match run to run.
      await _scrollToTop(tester);

      for (var i = 0; i < gallerySections.length; i++) {
        final slug = gallerySections[i];
        await _capture(tester, binding, theme, slug, i + 1);
        captured++;
      }
      captured += await _captureMotionLab(tester, binding, theme);
    }
    debugPrint('[qa] captured $captured screenshots');
  });
}

/// Screenshots the motion lab, which lives behind the app bar button rather
/// than in the gallery list. Returns 1.
Future<int> _captureMotionLab(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  ThemeMode theme,
) async {
  await tester.tap(find.widgetWithText(TextButton, 'Motion'));
  await _settle(tester, frames: 30);
  expect(
    find.byKey(const ValueKey('ds-section-motion')),
    findsOneWidget,
    reason: 'motion lab did not open',
  );
  await binding.takeScreenshot(
    _name(theme, gallerySections.length + 1, 'motion'),
  );
  debugPrint('[qa] ${_name(theme, gallerySections.length + 1, 'motion')}');
  await tester.pageBack();
  await _settle(tester, frames: 20);
  return 1;
}

Future<void> _capture(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  ThemeMode theme,
  String slug,
  int index,
) async {
  final finder = await _reveal(tester, slug);

  // ensureVisible pins the section to the top of the viewport (alignment
  // defaults to 0) so every run frames it identically. It also walks enclosing
  // scrollables, so screens-k03 scrolls its horizontal row to match.
  await Scrollable.ensureVisible(finder.evaluate().single);
  await _settle(tester);

  final name = _name(theme, index, slug);
  await binding.takeScreenshot(name);
  debugPrint('[qa] $name');
}

/// Scrolls the section into existence. A section below the fold is not built
/// yet, so the key is only findable after the list has scrolled past it —
/// which is what [WidgetTester.scrollUntilVisible] does for us.
Future<Finder> _reveal(WidgetTester tester, String slug) async {
  final finder = find.byKey(ValueKey<String>('ds-section-$slug'));
  if (finder.evaluate().isEmpty) {
    try {
      await _scrollDownTo(tester, finder);
    } on Object catch (_) {
      // dragUntilVisible throws once it runs out of scrolls, which here can
      // only mean the section is above the current offset: start from the top.
      // The expect below is what actually decides whether this worked.
      await _scrollToTop(tester);
      await _scrollDownTo(tester, finder);
    }
  }
  expect(finder, findsOneWidget, reason: 'no ds-section-$slug in the gallery');
  return finder;
}

Future<void> _scrollDownTo(WidgetTester tester, Finder finder) {
  return tester.scrollUntilVisible(
    finder,
    240,
    scrollable: find.byType(Scrollable).first,
    maxScrolls: 400,
  );
}

Future<void> _scrollToTop(WidgetTester tester) async {
  tester
      .state<ScrollableState>(find.byType(Scrollable).first)
      .position
      .jumpTo(0);
  await _settle(tester);
}

/// Waits for the gallery bloc to hand the list to the view.
Future<void> _awaitGallery(WidgetTester tester) async {
  final finder = find.byKey(
    ValueKey<String>('ds-section-${gallerySections.first}'),
  );
  for (var i = 0; i < 60 && finder.evaluate().isEmpty; i++) {
    await tester.pump();
  }
  expect(finder, findsOneWidget, reason: 'the gallery never loaded');
}

String _name(ThemeMode theme, int index, String slug) {
  return '${theme.name}_${index.toString().padLeft(2, '0')}_$slug';
}

/// Pumps [frames] frames instead of pumpAndSettle: the gallery and the motion
/// lab run looping Rive/Lottie animations, so the tree never goes idle.
Future<void> _settle(WidgetTester tester, {int frames = 8}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

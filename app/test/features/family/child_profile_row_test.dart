// P15 · Child profile — `.list-row` and the two row glyphs (Stage 3, it. 2).
//
// Iteration 2 replaced `NestListRow` with a P15-local `ProfileRow`
// (`child_profile_row.dart`) because the shared component starves the main
// column (P15-BUG-5 / ORCHESTRATOR_NOTES item 1), and swapped two glyphs
// (ORCHESTRATOR_NOTES item 2 / `5_ui` deviations 2+3). Both are new
// behaviour, so both are proved here:
//
//   1. `ProfileRow` as a component: the 40 px tile with the tint's colours
//      handed to the caller's glyph builder, `.list-main { flex: 1 }` vs
//      `.list-trail { flex-shrink: 0 }`, the 56 px minimum, and the
//      `Semantics(button:, onTap:)` contract;
//   2. the two glyphs are the DESIGN's — the circled check
//      (`ic_quests.svg` really is `<circle r="9"/>` + tick) and the coloured
//      `assets/illustrations/coin.svg`, not the `£` line icon;
//   3. no row paragraph is ellipsised anywhere in the width × scale matrix.
//
// This file owns the no-ellipsis matrix; `child_profile_theme_size_test.dart`
// keeps the band/geometry/surface proofs. Fonts are the bundled Inter/Nunito —
// without them Flutter's test font is far wider than Inter and every
// paragraph looks ellipsised.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/family/presentation/widgets/child_profile_row.dart';

import '../../test_scope.dart';

const _route = '/child-profile';

Future<void> _loadBundledFonts() async {
  final inter = FontLoader('Inter')
    ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-SemiBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'));
  final nunito = FontLoader('Nunito')
    ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf'));
  await inter.load();
  await nunito.load();
}

/// The whole app at [_route] on a given surface.
Future<void> _pumpAt(
  WidgetTester tester, {
  double width = 390,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(const NestlingApp(initialRoute: _route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// One canonical [ProfileRow] inside the shared card, on a 390 surface —
/// the same shape `_ProfileList` builds (tile, title, subtitle, trail).
Future<void> _pumpRow(
  WidgetTester tester, {
  NestTileTint tint = NestTileTint.neutral,
  ThemeMode theme = ThemeMode.light,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: NestTheme.light(),
      darkTheme: NestTheme.dark(),
      themeMode: theme,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 390 - 2 * NestSpacing.padSide,
            child: NestList(
              children: <Widget>[
                // Same row `_ProfileList` builds: sky tint, lock glyph, and
                // the `.list-trail` style (Inter 600 16) — the numbers below
                // only mean something if the trail is the real one.
                Builder(
                  builder: (context) => ProfileRow(
                    key: const Key('probe-row'),
                    title: 'Kid PIN',
                    subtitle: 'On · Maya knows their code',
                    tint: tint,
                    trailing: Text(
                      'Change ›',
                      style: NestType.body(color: context.nest.ink3)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    onTap: () {},
                    leading: (fg) => NestIcon(NestIcons.lock, color: fg),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// The asset a `SvgPicture.asset(...)` was built from (`SvgPicture` keeps no
/// `assetName` field, but the loader does).
String _assetOf(SvgPicture picture) =>
    (picture.bytesLoader as SvgAssetLoader).assetName;

/// Laid-out width of [text] at [style], unbounded and scaled by [scaler] —
/// the "intrinsic" width the design's `flex-shrink: 0` trail is entitled to.
/// The scaler matters: a `TextPainter` does not read MediaQuery, so at text
/// scale 1.3 the unscaled number would be 30 % short.
double _intrinsicWidth(
  String text,
  TextStyle style, {
  TextScaler scaler = TextScaler.noScaling,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: style.copyWith(fontSize: scaler.scale(style.fontSize ?? 14)),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  return painter.width;
}

/// The ambient text scaler at [finder].
TextScaler _scalerAt(WidgetTester tester, Finder finder) =>
    MediaQuery.textScalerOf(tester.element(finder));

void main() {
  setUpAll(_loadBundledFonts);

  group('ProfileRow component', () {
    testWidgets('the tile is 40 px with the tint colours', (tester) async {
      await _pumpRow(tester, tint: NestTileTint.sky);

      // Iteration 3 moved the literals to tokens (`NestSpacing.s10` = 40);
      // the rendered geometry must be unchanged — the design's numbers, not
      // the tokens', are what the UI check measures.
      expect(NestSpacing.s10, 40);
      expect(NestSpacing.s3, 12);
      expect(NestSpacing.s4, 16);
      expect(NestSpacing.gap10, 10);
      final padding = tester.widget<Padding>(
        find
            .descendant(
              of: find.byKey(const Key('probe-row')),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(
        padding.padding,
        // `.list-row { padding: 10px 16px 10px 12px }`
        const EdgeInsets.fromLTRB(12, 10, 16, 10),
      );

      final tile = tester.getRect(
        find
            .descendant(
              of: find.byKey(const Key('probe-row')),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(tile.width, 40);
      expect(tile.height, 40);

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byKey(const Key('probe-row')),
              matching: find.byType(Container),
            )
            .first,
      );
      final tokens = tester.element(find.byKey(const Key('probe-row'))).nest;
      expect((container.decoration! as BoxDecoration).color, tokens.skyTint);
      expect(
        (container.decoration! as BoxDecoration).borderRadius,
        BorderRadius.circular(NestSpacing.s3),
      );

      // The caller's glyph gets the tint's foreground, and keeps the 24 px
      // box `NestIcon` pins.
      final icon = tester.widget<NestIcon>(find.byType(NestIcon));
      expect(icon.color, tokens.sky);
      expect(icon.size, 24);
      expect(tester.getSize(find.byType(NestIcon)).width, 24);
    });

    testWidgets('the trail keeps its intrinsic width; main takes the rest', (
      tester,
    ) async {
      await _pumpRow(tester);

      final row = tester.getRect(find.byKey(const Key('probe-row')));
      final trail = tester.getSize(find.text('Change ›'));
      final trailStyle = tester.widget<Text>(find.text('Change ›')).style!;
      expect(
        trail.width,
        closeTo(_intrinsicWidth('Change ›', trailStyle), 0.01),
        reason: '.list-trail { flex-shrink: 0 }',
      );

      // `.list-row` padding 12 + 16, one 40 px tile and two 12 px gaps.
      final available = row.width - 12 - 16 - 40 - 2 * NestSpacing.s3;
      final main = available - trail.width;
      // The subtitle column: `.list-title` sits inside it.
      final title = tester.getSize(find.text('Kid PIN'));
      expect(
        title.width,
        lessThanOrEqualTo(main),
        reason: 'the main column must own the remaining width',
      );
      // And it must be wide enough for the widest P15 subtitle, or the
      // ellipsis bug is back.
      expect(main, greaterThan(171.3));
    });

    testWidgets('a row with no glyph renders no tile', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: NestTheme.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 390 - 2 * NestSpacing.padSide,
                child: NestList(
                  children: <Widget>[
                    ProfileRow(
                      key: const Key('probe-row'),
                      title: 'Kid PIN',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(NestIcon), findsNothing);
      expect(find.byKey(const Key('probe-row')), findsOneWidget);
    });

    testWidgets('the 56 px minimum holds; a tall trail grows the row', (
      tester,
    ) async {
      await _pumpRow(tester);
      expect(
        tester.getRect(find.byKey(const Key('probe-row'))).height,
        greaterThanOrEqualTo(56),
      );
      final short = tester.getRect(find.byKey(const Key('probe-row'))).height;

      await tester.pumpWidget(
        MaterialApp(
          theme: NestTheme.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 390 - 2 * NestSpacing.padSide,
                child: NestList(
                  children: <Widget>[
                    ProfileRow(
                      key: const Key('probe-row'),
                      title: 'Kid PIN',
                      subtitle: 'On · Maya knows their code',
                      onTap: () {},
                      trailing: const SizedBox(height: 80, width: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        tester.getRect(find.byKey(const Key('probe-row'))).height,
        greaterThan(short),
        reason: 'minHeight is a floor, not a fixed height',
      );
    });

    testWidgets('it is one labelled button, and tapping it calls onTap', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: NestTheme.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 390 - 2 * NestSpacing.padSide,
                child: NestList(
                  children: <Widget>[
                    ProfileRow(
                      key: const Key('probe-row'),
                      title: 'Kid PIN',
                      subtitle: 'On · Maya knows their code',
                      onTap: () => taps++,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final data = tester
          .getSemantics(find.byKey(const Key('probe-row')))
          .getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.label, contains('Kid PIN'));

      await tester.tap(find.byKey(const Key('probe-row')));
      expect(taps, 1);
      tester.semantics.performAction(
        find.semantics.byLabel('Kid PIN'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(
        taps,
        2,
        reason: 'VoiceOver/TalkBack must drive the same callback',
      );

      handle.dispose();
    });

    testWidgets('semanticLabel overrides the title announcement', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: NestTheme.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 390 - 2 * NestSpacing.padSide,
                child: NestList(
                  children: <Widget>[
                    ProfileRow(
                      key: const Key('probe-row'),
                      title: 'Kid PIN',
                      semanticLabel: 'Kid PIN, set, change',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        tester
            .getSemantics(find.byKey(const Key('probe-row')))
            .getSemanticsData()
            .label,
        'Kid PIN, set, change',
      );
      handle.dispose();
    });
  });

  group("ORCHESTRATOR item 2 · the two row glyphs are the design's", () {
    testWidgets('Quests = the circled check, Pocket money = the coin', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpAt(tester);

      Finder inRow(String key, Finder matching) =>
          find.descendant(of: find.byKey(Key(key)), matching: matching);

      // Quests: `NestIcons.quests` — and that asset IS the design's
      // `<circle cx="12" cy="12" r="9"/>` + tick.
      final questsIcon = tester.widget<NestIcon>(
        inRow('p15-row-quests', find.byType(NestIcon)),
      );
      expect(questsIcon.assetName, NestIcons.quests);
      expect(questsIcon.assetName, isNot(NestIcons.check));
      final svg = await rootBundle.loadString(NestIcons.quests);
      expect(svg, contains('<circle cx="12" cy="12" r="9"/>'));
      expect(svg, contains('4.5-5.5'));

      // Pocket money: the COLOURED illustration, which `NestIcon` would tint
      // into a `£`.
      final coin = tester.widget<SvgPicture>(
        inRow('p15-row-money', find.byType(SvgPicture)),
      );
      expect(_assetOf(coin), NestlingIllustrations.coin);
      expect(_assetOf(coin), isNot(NestIcons.poundCoin));
      expect(coin.width, 24);
      expect(coin.height, 24);
      expect(coin.colorFilter, isNull, reason: 'illustrations keep their own');
      // And no `£` line icon is left anywhere in that row.
      expect(inRow('p15-row-money', find.byType(NestIcon)), findsNothing);
      // The illustration really is the coloured coin, not a monochrome glyph.
      final coinSvg = await rootBundle.loadString(NestlingIllustrations.coin);
      expect(coinSvg, contains('#F4B400'), reason: 'the gold coin fill');

      // Kid PIN keeps the lock.
      expect(
        tester
            .widget<NestIcon>(inRow('p15-row-pin', find.byType(NestIcon)))
            .assetName,
        NestIcons.lock,
      );

      await disposeApp(tester);
    });

    testWidgets('each glyph sits in a 24 px box inside the 40 px tile', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpAt(tester);

      for (final key in const <String>['p15-row-pin', 'p15-row-quests']) {
        final tile = tester.getRect(
          find
              .descendant(
                of: find.byKey(Key(key)),
                matching: find.byType(Container),
              )
              .first,
        );
        expect(tile.width, 40, reason: key);
        expect(tile.height, 40, reason: key);

        final glyph = tester.getRect(
          find
              .descendant(
                of: find.byKey(Key(key)),
                matching: find.byType(NestIcon),
              )
              .first,
        );
        expect(glyph.width, closeTo(24, 0.01), reason: key);
        expect(glyph.height, closeTo(24, 0.01), reason: key);
        // Centred in the tile, on both axes.
        expect(glyph.center.dx, closeTo(tile.center.dx, 0.01), reason: key);
        expect(glyph.center.dy, closeTo(tile.center.dy, 0.01), reason: key);
      }

      // The coin is an SvgPicture, not a NestIcon — measure it the same way.
      final coinGlyph = tester.getRect(
        find
            .descendant(
              of: find.byKey(const Key('p15-row-money')),
              matching: find.byType(SvgPicture),
            )
            .first,
      );
      final coinTile = tester.getRect(
        find
            .descendant(
              of: find.byKey(const Key('p15-row-money')),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(coinGlyph.width, closeTo(24, 0.01));
      expect(coinGlyph.center.dx, closeTo(coinTile.center.dx, 0.01));
      expect(coinGlyph.center.dy, closeTo(coinTile.center.dy, 0.01));

      await disposeApp(tester);
    });
  });

  group('ORCHESTRATOR item 1 · nothing is ellipsised', () {
    // `child_profile_theme_size_test.dart` keeps the single 390 assertion
    // `2_build.md` cites; this group is the same contract generalised across
    // the width × scale matrix, plus the column arithmetic that produced the
    // iteration-1 bug.
    //
    // The design's own rule (components.css:118): `.list-sub` is
    // `white-space: nowrap` + `text-overflow: ellipsis`, so it degrades to an
    // ellipsis EXACTLY where the text cannot fit the column. What must never
    // happen is the iteration-1 bug: the column starved at the design's own
    // 390 / scale 1.0, where the CSS gives `.list-main` ≈187 px and every
    // subtitle fits.
    //
    // Measured with the bundled faces (laid width vs `didExceedMaxLines`):
    //
    //   width · scale   PIN sub        Quests sub      Money sub
    //   320   · 1.0     117.3 CUT      162.1 full      169.2 full
    //   320   · 1.3      96.1 CUT      179.4 CUT       179.4 CUT
    //   390   · 1.0     171.2 full     162.1 full      169.2 full
    //   390   · 1.3     166.1 CUT      210.8 full      219.9 full
    //   430   · 1.0     171.2 full     162.1 full      169.2 full
    //   430   · 1.3     206.1 CUT      210.8 full      219.9 full
    const widths = <double>[320, 390, 430];

    testWidgets('390 · scale 1.0 (the design): every string is in full', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpAt(tester);

      for (final key in const <String>[
        'p15-row-pin',
        'p15-row-quests',
        'p15-row-money',
      ]) {
        for (final paragraph
            in find
                .descendant(
                  of: find.byKey(Key(key)),
                  matching: find.byType(RichText),
                )
                .evaluate()) {
          final render = paragraph.renderObject! as RenderParagraph;
          expect(
            render.didExceedMaxLines,
            isFalse,
            reason: '$key: "${render.text.toPlainText()}" must not be cut',
          );
        }
      }

      await disposeApp(tester);
    });

    testWidgets('430 · scale 1.0: more room, still nothing cut', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpAt(tester, width: 430);

      final cut = <String>[];
      for (final key in const <String>[
        'p15-row-pin',
        'p15-row-quests',
        'p15-row-money',
      ]) {
        for (final paragraph
            in find
                .descendant(
                  of: find.byKey(Key(key)),
                  matching: find.byType(RichText),
                )
                .evaluate()) {
          final render = paragraph.renderObject! as RenderParagraph;
          if (render.didExceedMaxLines) {
            cut.add('${key.split('-').last}: ${render.text.toPlainText()}');
          }
        }
      }
      expect(cut, isEmpty);

      await disposeApp(tester);
    });

    testWidgets('320 · scale 1.0: only the PIN subtitle is past the column', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpAt(tester, width: 320);

      // `On · Maya knows their code` is 171.2 px and the CSS column at 320 is
      // 117.3 px, so the design ellipsises it too. Everything else fits.
      final cut = <String>[];
      for (final key in const <String>[
        'p15-row-pin',
        'p15-row-quests',
        'p15-row-money',
      ]) {
        for (final paragraph
            in find
                .descendant(
                  of: find.byKey(Key(key)),
                  matching: find.byType(RichText),
                )
                .evaluate()) {
          final render = paragraph.renderObject! as RenderParagraph;
          if (render.didExceedMaxLines) {
            cut.add('${key.split('-').last}: ${render.text.toPlainText()}');
          }
        }
      }
      expect(cut, <String>['pin: On · Maya knows their code']);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    for (final width in widths) {
      testWidgets('w$width · scale 1.3: degrades without breaking', (
        tester,
      ) async {
        await setUpTestScope();
        await _pumpAt(tester, width: width, textScale: 1.3);

        // 30 % larger type than the design renders. The CSS ellipsis is the
        // intended fallback; what must hold is that nothing overflows, the
        // rows keep their 56 px floor, and the trail still keeps its
        // intrinsic width instead of donating it to the flex distribution.
        expect(tester.takeException(), isNull);
        for (final key in const <String>[
          'p15-row-pin',
          'p15-row-quests',
          'p15-row-money',
        ]) {
          expect(
            tester.getRect(find.byKey(Key(key))).height,
            greaterThanOrEqualTo(56),
            reason: key,
          );
        }
        final trail = find.text('Change ›');
        expect(
          tester.getSize(trail).width,
          closeTo(
            _intrinsicWidth(
              'Change ›',
              tester.widget<Text>(trail).style!,
              scaler: _scalerAt(tester, trail),
            ),
            0.01,
          ),
        );
        // Only the subtitles may be cut; no TITLE is ever cut.
        for (final title in const <String>[
          'Kid PIN',
          'Quests',
          'Pocket money',
        ]) {
          final render = tester.renderObject<RenderParagraph>(
            find.descendant(
              of: find.byType(ProfileRow),
              matching: find.text(title),
            ),
          );
          expect(render.didExceedMaxLines, isFalse, reason: title);
        }

        await disposeApp(tester);
      });
    }

    testWidgets('the main column follows the CSS arithmetic at every width', (
      tester,
    ) async {
      // `.list-main { flex: 1 }` + `.list-trail { flex-shrink: 0 }` means:
      //   column = row − 12 − 16 (padding) − 40 (tile) − 2 × 12 (gaps)
      //           − trail intrinsic
      // Not "half the free space", which is what the shared component did.
      for (final width in widths) {
        await setUpTestScope();
        await _pumpAt(tester, width: width);

        for (final (key, trail) in <(String, String)>[
          ('p15-row-pin', 'Change ›'),
          ('p15-row-quests', '›'),
          ('p15-row-money', '›'),
        ]) {
          final row = tester.getRect(find.byKey(Key(key)));
          final trailFinder = find.descendant(
            of: find.byKey(Key(key)),
            matching: find.text(trail),
          );
          final trailWidth = tester.getSize(trailFinder).width;
          final column =
              row.width - 12 - 16 - 40 - 2 * NestSpacing.s3 - trailWidth;
          // Nothing may spill past the column the design hands it…
          final laid = <double>[
            for (final text
                in find
                    .descendant(
                      of: find.byKey(Key(key)),
                      matching: find.byType(Text),
                    )
                    .evaluate())
              (text.renderObject! as RenderParagraph).size.width,
          ];
          expect(
            laid.every((w) => w <= column + 0.01),
            isTrue,
            reason: '$key at w$width must not exceed its $column px column',
          );
          // …and the column is never the half-and-half the shared component
          // produced: it must be strictly wider than the widest trail.
          expect(
            column,
            greaterThan(row.width / 2 - 40),
            reason: '$key at w$width must not be halved',
          );
        }

        // The regression guard for P15-BUG-5, as an exact number at the
        // design's width: the PIN row — the one with the widest trail — must
        // hand its subtitle column 187.29 px, which fits the longest string
        // in the design (171.24 px).
        if (width == 390) {
          final row = tester.getRect(find.byKey(const Key('p15-row-pin')));
          final trailWidth = tester
              .getSize(
                find.descendant(
                  of: find.byKey(const Key('p15-row-pin')),
                  matching: find.text('Change ›'),
                ),
              )
              .width;
          final column =
              row.width - 12 - 16 - 40 - 2 * NestSpacing.s3 - trailWidth;
          expect(column, closeTo(187.29, 0.01));
          expect(column, greaterThan(171.24));
        }

        await disposeApp(tester);
      }
    });
  });
}

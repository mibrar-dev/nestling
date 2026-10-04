// K06 · Pip's nest — the ORCHESTRATOR_NOTES (11:30, "iteration 2 targets")
// items, pinned where a test can pin them. Each group names the item it
// answers, and each proof reads its oracle from the design source instead of
// transcribing it.
//
// Item 1 · locked wardrobe items must use the design's locked style
//   (`.k6-item.locked`: dashed 3 px border, `--surface-2` card, `--surface`
//   art circle, `--ink-2` glyph and label; `.k6-item`: `--surface` card,
//   `--lilac-tint` art circle, `--ink` glyph). Green today for every
//   colour/fill; the missing dashed stroke is stage 6's K06-BUG-6 (parked
//   there, with the pixel proof) and is deliberately not duplicated here.
//
// Item 2 · wardrobe glyphs must be the design's glyphs — "do not substitute".
//   The tile icons are shared `assets/icons/ic_*.svg`, which a screen agent
//   may not edit (RULES §1), so the substitution is filed as
//   `SHARED_REQUEST.md` §5 with the design's path data. The parity proof
//   below is parked for the same reason the copy proof is: it must fail until
//   the shared asset is fixed.
//
// Item 3 · prices 30/60 in the design vs 40/120 in the app — "write
//   SHARED_REQUEST.md … do not hard-code prices". Filed as
//   `SHARED_REQUEST.md` §6; the test side pins that the *rendered* price is
//   the seeded one (DATA OVER MOCKS) and never a literal.
//
// ITERATION 3 / ORCHESTRATOR_NOTES 13:52: `shared/shared_batch7` HAS LANDED
// (§1/§2/§3/§5/§6 fixed: the scarf/wellies glyphs, the prices — the seed moved
// to the design's 30/60 — the pet-slot params, the kid-button third row and the
// shared dashed border). Consequences in this file:
//   * the item-2 proofs for the two glyphs the note NAMES (scarf, wellies) are
//     live and green — K06 now paints `NestIcons.wardrobeScarf` /
//     `.wardrobeWellies`;
//   * the sun hat stays parked as §7: batch 7 left it on `NestIcons.sunHat`
//     and reported it as already matching, which this proof shows is not the
//     case;
//   * the item-3 `K06-BATCH7` proof is LIVE again (it was parked precisely
//     until the batch landed) and the seeded-price proof above now reads its
//     expectation out of the row, so it tracks the seed instead of a number.
//
// Item 4 · "Pip and the nest are correct" — no action, and nothing here
//   constrains the nest art box (note this: it contradicts stage 6's
//   K06-BUG-4; the orchestrator ruling wins, see docs/screens/K06/3_test.md).

import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/design_system/components/nest_icon.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_look.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_wardrobe_tile.dart';

import '../../test_scope.dart';

const String _middot = '·';

/// The design's `.k6-ward` order, which the repository already reproduces.
const List<String> _items = <String>['scarf', 'sunhat', 'wellies', 'crown'];

late String _html;

File _designSource() {
  var dir = Directory.current.absolute;
  for (var depth = 0; depth < 5; depth++) {
    final candidate = File(
      '${dir.path}/design/html-source/screens/K06-pip.html',
    );
    if (candidate.existsSync()) return candidate;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError(
    'K06 design source not found above ${Directory.current.path}',
  );
}

/// The `<path d="…">` data of the glyph inside tile [name] of `.k6-ward`,
/// normalised the way an SVG renderer sees it (case and spacing are not
/// geometry).
List<String> _designGlyphPaths(String name) {
  final ward = _html.split('<div class="k6-ward">').last.split('</div>').first;
  final tiles = RegExp(
    '<button class="k6-item[^"]*"[^>]*>(.*?)</button>',
    dotAll: true,
  ).allMatches(ward);
  final index = _items.indexOf(name);
  final body = tiles.elementAt(index).group(1)!;
  return _paths(body);
}

List<String> _paths(String svgSource) =>
    RegExp('d="([^"]*)"')
        .allMatches(svgSource)
        .map((m) => _norm(m.group(1)!))
        .toList();

String _norm(String pathData) => pathData.replaceAll(' ', '').toLowerCase();

/// The `.k6-item-p` numbers of the design's LOCKED tiles, in `.k6-ward` order
/// (Wellies 30, Crown 60), entity-free and straight from the source.
List<String> _designLockedPrices() {
  final ward = _html.split('<div class="k6-ward">').last.split('</div>').first;
  final out = <String>[];
  for (final tile in RegExp(
    '<button class="k6-item([^"]*)"[^>]*>(.*?)</button>',
    dotAll: true,
  ).allMatches(ward)) {
    if (!tile.group(1)!.contains('locked')) continue;
    final price = RegExp(
      '<span class="k6-item-p[^"]*">(.*?)</span>',
      dotAll: true,
    ).firstMatch(tile.group(2)!)!.group(1)!;
    out.add(RegExp('[0-9]+').firstMatch(price)!.group(0)!);
  }
  return out;
}

/// The shared asset the tile actually paints, resolved through the very same
/// constant the tile uses — never a guessed file name (`ic_sunhat.svg` does
/// not exist; the asset is `ic_sun_hat.svg`).
File _asset(String item) => File(pipWardrobeIcon(item));

void main() {
  setUpAll(() {
    _html = _designSource().readAsStringSync();
  });

  setUp(() async {
    await setUpTestScope();
  });

  group('item 1 — the locked tile style (design CSS)', () {
    // `.k6-item { background: var(--surface); border: 3px solid var(--ink) }`
    // `.k6-item.locked { background: var(--surface-2); border-style: dashed;
    //                     border-color: var(--ink-2); box-shadow: none }`
    // `.k6-item-art { background: var(--lilac-tint); color: var(--ink) }`
    // `.k6-item.locked .k6-item-art { background: var(--surface);
    //                                color: var(--ink-2) }`
    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('${theme.name}: owned vs locked fills and inks', (
        tester,
      ) async {
        await pumpAppRoute(tester, '/pip', theme: theme);
        final tokens = Theme.of(
          tester.element(find.byType(PipWardrobeTile).first),
        ).extension<NestTokens>()!;
        final colours = tokens.colors;

        /// The card Container of [id] and its art circle, told apart by their
        /// own constraints rather than by tree order.
        (BoxDecoration, BoxDecoration) tile(String id) {
          final containers = tester
              .widgetList<Container>(
                find.descendant(
                  of: find.byKey(Key('k06-ward-$id')),
                  matching: find.byType(Container),
                ),
              )
              .toList();
          final card = containers.firstWhere(
            (c) => c.constraints?.minHeight == kPipWardrobeTileHeight,
          );
          final art = containers.firstWhere(
            (c) => c.constraints?.maxWidth == kPipWardrobeArtSize,
          );
          return (
            card.decoration! as BoxDecoration,
            art.decoration! as BoxDecoration,
          );
        }

        for (final id in const <String>['scarf', 'sunhat']) {
          final (card, art) = tile(id);
          expect(card.color, colours.surface, reason: '$id card');
          expect(art.color, colours.lilacTint, reason: '$id art circle');
          expect(card.border, isNotNull, reason: '$id solid ink border');
          expect(card.boxShadow, isNotNull, reason: '$id sh-kid');
        }
        for (final id in const <String>['wellies', 'crown']) {
          final (card, art) = tile(id);
          expect(card.color, colours.surface2, reason: '$id locked card');
          expect(art.color, colours.surface, reason: '$id art circle is white');
          expect(card.boxShadow, isNull, reason: '$id drops sh-kid');
          // The dashed stroke is painted by a screen-local painter, not by the
          // decoration — its visibility is stage 6's K06-BUG-6.
          expect(
            find.descendant(
              of: find.byKey(Key('k06-ward-$id')),
              matching: find.byType(CustomPaint),
            ),
            findsWidgets,
            reason: '$id has a painted border layer',
          );
        }
        await disposeApp(tester);
      });
    }

    testWidgets('the glyph and label colours follow the locked class', (
      tester,
    ) async {
      await pumpAppRoute(tester, '/pip');
      final tokens = Theme.of(
        tester.element(find.byType(PipWardrobeTile).first),
      ).extension<NestTokens>()!;

      Color iconColour(String id) => tester
          .widget<NestIcon>(
            find
                .descendant(
                  of: find.byKey(Key('k06-ward-$id')),
                  matching: find.byType(NestIcon),
                )
                .first,
          )
          .color!;

      // `.k6-item-art { color: var(--ink) }` / `.locked … { color: ink-2 }`
      expect(iconColour('scarf'), tokens.ink);
      expect(iconColour('sunhat'), tokens.ink);
      expect(iconColour('wellies'), tokens.ink2);
      expect(iconColour('crown'), tokens.ink2);

      // `<svg width="30" height="30">` in every tile.
      for (final id in _items) {
        expect(
          tester
              .widget<NestIcon>(
                find
                    .descendant(
                      of: find.byKey(Key('k06-ward-$id')),
                      matching: find.byType(NestIcon),
                    )
                    .first,
              )
              .size,
          30,
          reason: '$id glyph is the design 30 px',
        );
      }
      await disposeApp(tester);
    });
  });

  group('item 2 — the glyphs are the design glyphs', () {
    testWidgets('each tile paints the shared asset its id maps to', (
      tester,
    ) async {
      await pumpAppRoute(tester, '/pip');
      for (final id in _items) {
        final asset = tester
            .widget<NestIcon>(
              find
                  .descendant(
                    of: find.byKey(Key('k06-ward-$id')),
                    matching: find.byType(NestIcon),
                  )
                  .first,
            )
            .assetName;
        expect(asset, pipWardrobeIcon(id), reason: id);
        expect(File(asset).existsSync(), isTrue, reason: '$asset exists');
      }
      await disposeApp(tester);
    });

    testWidgets('the two named tiles render the batch-7 assets, not the '
        'look-alikes', (tester) async {
      // The byte proofs below read whatever `pipWardrobeIcon(id)` returns, so
      // on their own they would still pass if the screen pointed at the old
      // look-alike files. This pins the ACTUAL asset each named tile paints,
      // by file name, which is what "do not substitute" means in practice.
      await pumpAppRoute(tester, '/pip');

      const expected = <String, String>{
        'scarf': 'assets/icons/ic_wardrobe_scarf.svg',
        'wellies': 'assets/icons/ic_wardrobe_wellies.svg',
      };
      // The look-alikes batch 7 replaced (a fringed blanket, a boot).
      const superseded = <String>[
        'assets/icons/ic_scarf.svg',
        'assets/icons/ic_wellies.svg',
      ];

      for (final entry in expected.entries) {
        final asset = tester
            .widget<NestIcon>(
              find
                  .descendant(
                    of: find.byKey(Key('k06-ward-${entry.key}')),
                    matching: find.byType(NestIcon),
                  )
                  .first,
            )
            .assetName;
        expect(asset, entry.value, reason: '${entry.key} tile');
        expect(
          superseded,
          isNot(contains(asset)),
          reason: '${entry.key} must not fall back to the look-alike',
        );
        expect(File(asset).existsSync(), isTrue, reason: '$asset exists');
      }
      await disposeApp(tester);
    });

    // Crown is deliberately NOT in this set: its asset draws the design's two
    // subpaths, written with an implicit lineto after the moveto and with the
    // second path relative (`m2 12h12` ≡ `M6 20h12`, since `z` puts the
    // current point back at (4,8)). Same geometry, different notation — so a
    // byte comparison there would be a brittle false positive, and the note
    // does not name it.
    // The two glyphs ORCHESTRATOR_NOTES 11:30 item 2 names by hand ("Scarf …
    // and Wellies … the app uses look-alikes. Do not substitute"). Live since
    // `shared/shared_batch7` landed the exact K06 paths and K06 switched its
    // tile icons to `NestIcons.wardrobeScarf` / `.wardrobeWellies`
    // (`pip_look.dart`).
    for (final item in const <String>['scarf', 'wellies']) {
      test('ORCHESTRATOR NOTES item 2: the $item glyph is the design path', () {
        final design = _designGlyphPaths(item).join();
        final app = _paths(_asset(item).readAsStringSync()).join();
        expect(
          app,
          design,
          reason:
              'assets/icons/${pipWardrobeIcon(item)} must draw the design '
              "glyph from K06-pip.html's .k6-item block verbatim",
        );
      });
    }

    // Sun hat: the note did not name it and `shared/shared_batch7` left it on
    // `NestIcons.sunHat` claiming its geometry already matched. It did not —
    // same silhouette, different coordinates plus an extra brim stroke
    // (`m2.413.8h19.2…` vs the design's `m316h18…`), which is why K06 could
    // not close its last design-fidelity major. `shared/k06_glyphs` (5ff0c40)
    // has since added the design's two paths as `NestIcons.wardrobeSunHat`,
    // `pipWardrobeIcon('sunhat')` points at it, and the byte proof is LIVE
    // again (was SHARED_REQUEST.md §7).
    test(
      'ORCHESTRATOR NOTES item 2 (extra): the sunhat glyph is the design path',
      () {
        final design = _designGlyphPaths('sunhat').join();
        final app = _paths(_asset('sunhat').readAsStringSync()).join();
        expect(
          app,
          design,
          reason:
              'assets/icons/${pipWardrobeIcon('sunhat')} must draw the design '
              "glyph from K06-pip.html's .k6-item block verbatim",
        );
      },
    );
  });

  group('item 3 — prices come from the database', () {
    testWidgets('the rendered price is the seeded one, never a literal', (
      tester,
    ) async {
      // The point of this proof is DATA OVER MOCKS ("never hard-code prices"):
      // the tile must show whatever the ROW says. So the expectation is read
      // out of the seeded wardrobe rather than typed in — shared batch 7 moved
      // these rows from 40/120 to the design's 30/60, and a literal here would
      // have reddened a proof that has nothing to do with prices being data.
      final db = GetIt.instance<AppDatabase>();
      final seeded = <String, int>{
        for (final row in await (db.select(
          db.pipWardrobe,
        )..where((w) => w.childId.equals('maya'))).get())
          row.item: row.priceCoins,
      };
      await pumpAppRoute(tester, '/pip');

      expect(find.text('${seeded['wellies']}'), findsOneWidget);
      expect(find.text('${seeded['crown']}'), findsOneWidget);
      // The number is announced with its item, never alone.
      expect(
        find.bySemanticsLabel('Wellies, ${seeded['wellies']} coins'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Crown, ${seeded['crown']} coins'),
        findsOneWidget,
      );
      await disposeApp(tester);
    });

    testWidgets('K06-BATCH7: the rendered price is the DESIGN number', (
      tester,
    ) async {
      // `shared/shared_batch7` HAS LANDED (ORCHESTRATOR_NOTES 13:52): the seed
      // now mirrors the design, so the database and the design agree and DATA
      // OVER MOCKS is satisfied by the design's own numbers. This proof was
      // parked until exactly that, and is live again with no expectation
      // changed.
      //
      // `.k6-item-p` in the design's `.k6-ward`, read from the source: the two
      // locked tiles carry 30 and 60.
      final designPrices = _designLockedPrices();
      expect(designPrices, <String>['30', '60']);

      await pumpAppRoute(tester, '/pip');
      for (final price in designPrices) {
        expect(find.text(price), findsOneWidget, reason: 'design price $price');
      }
      expect(find.bySemanticsLabel('Wellies, 30 coins'), findsOneWidget);
      expect(find.bySemanticsLabel('Crown, 60 coins'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('a re-seeded price renders without a code change', (
      tester,
    ) async {
      // The strongest form of "do not hard-code": move the row and the tile
      // follows. (The design/seed mismatch itself is `SHARED_REQUEST.md` §6.)
      final db = GetIt.instance<AppDatabase>();
      final before =
          await (db.select(db.pipWardrobe)..where(
                (w) => w.childId.equals('maya') & w.item.equals('crown'),
              ))
              .getSingle();
      await (db.update(db.pipWardrobe)
            ..where((w) => w.childId.equals('maya') & w.item.equals('crown')))
          .write(const PipWardrobeCompanion(priceCoins: Value(7)));
      await pumpAppRoute(tester, '/pip');

      expect(find.text('7'), findsOneWidget);
      // The PREVIOUS value is read from the row, not typed: this file's own
      // rule is that a price is never a literal (batch 7 moved these rows from
      // 40/120 to 30/60 and every literal here had to be re-based).
      expect(
        find.text('${before.priceCoins}'),
        findsNothing,
        reason: 'the old price is gone from the tile',
      );
      expect(find.bySemanticsLabel('Crown, 7 coins'), findsOneWidget);
      await disposeApp(tester);
    });
  });

  group('item 4 — Pip and the nest are correct (regression guard)', () {
    testWidgets('the nest slot still seats the child Pip at the design size', (
      tester,
    ) async {
      await pumpAppRoute(tester, '/pip');
      final slot = tester.getRect(find.byKey(const Key('k06-pet')));
      expect(slot.height, closeTo(206, 1.5));
      final pip = find.descendant(
        of: find.byKey(const Key('k06-pet')),
        matching: find.byType(PipAvatar),
      );
      expect(pip, findsOneWidget);
      expect(tester.getSize(pip).height, closeTo(134, 1.5));
      expect(find.text('Pip $_middot Fledgling'), findsOneWidget);
      await disposeApp(tester);
    });
  });
}

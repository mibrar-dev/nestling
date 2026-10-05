// K11 · My badges — STAGE 6 bug hunt (iteration 3).
//
// Iteration 1 proved two bugs here (K11-BUG-1 unclamped happyDays,
// K11-BUG-2 hard-coded `'maya'` fallback). Both were fixed by the
// iteration-2 build and are kept as UN-SKIPPED regression guards:
//
//   K11-BUG-1  `HappyWeekCard` clamps `happyDays` to 0..7 for the dots and
//              the why-line (widget + `HappyWeekCopy.why`).
//   K11-BUG-2  `BadgesRepositoryImpl` resolves the child from the roster
//              (persisted active id → first child in creation order → no
//              child = empty shelf); no hard-coded id anywhere.
//
// Iteration 3 (locked-medal art) found no new bugs. Its mandatory item
// (`ORCHESTRATOR_NOTES.md` 06:55: ink dashed ring, whole-element 40 %
// ribbon opacity, cream disc, both themes) is pinned two ways: the
// string-level checks in `badges_locked_art_test.dart` (stage 3) and the
// raster proof here — `K11-ART` samples the rendered pixels and asserts the
// exact composites, which is the only way to catch flutter_svg dropping the
// element opacity.
//
// Harness note: one DB write per `tester.runAsync` + a pump between writes.
// A second write in the same runAsync queues behind a stream re-query
// scheduled in the fake-async zone and deadlocks — a flutter_test/Drift
// harness behaviour, not product code (the build stage hit the same thing).
//
// Scaffolding mirrors `badges_view_test.dart` (in-memory Drift via
// `setUpTestScope`, `disposeApp` after every pump, no clock reads, no
// simulator).

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
// Material's `Badge` widget collides with the Drift row class.
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/badges/domain/entities/badge.dart' as domain;
import 'package:nestling/features/badges/presentation/widgets/badge_grid_cell.dart';
import 'package:nestling/features/badges/presentation/widgets/happy_week_card.dart';

import '../../design_system/test_harness.dart';
import '../../test_scope.dart';

const String _route = '/badges';

Future<void> _pumpRoute(
  WidgetTester tester, {
  double width = 390,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
  String route = _route,
}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(NestlingApp(initialRoute: route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// One real-async DB write, then a pump so the Drift stream re-query lands
/// in the fake-async zone before the next write is issued.
Future<void> _write(WidgetTester tester, Future<void> Function() body) async {
  await tester.runAsync(body);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = await setUpTestScope();
  });

  // -------------------------------------------------------------------------
  // K11-BUG-1 (fixed in iteration 2) — happyDays clamp
  // -------------------------------------------------------------------------
  testWidgets('K11-BUG-1 happyDays 8 clamps to the seven drawn days', (
    tester,
  ) async {
    await _pumpRoute(tester);
    expect(
      find.text('4 happy days this week — Pip hasn’t stopped singing.'),
      findsOneWidget,
    );

    // A stored count above the 0..7 the schema documents (`Children
    // .happyDays`, app_database.dart:93). The card draws seven days; the
    // why-line and the dots must clamp to them.
    await _write(
      tester,
      () => (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
        const ChildrenCompanion(happyDays: Value(8)),
      ),
    );
    expect(tester.takeException(), isNull);

    final checks = find.descendant(
      of: find.byType(HappyWeekCard),
      matching: find.byWidgetPredicate(
        (widget) => widget is NestIcon && widget.assetName == NestIcons.check,
      ),
    );
    expect(checks, findsNWidgets(7), reason: 'only seven days exist');
    expect(
      find.text('8 happy days this week — Pip hasn’t stopped singing.'),
      findsNothing,
      reason: 'the card must not claim a day it cannot draw',
    );
    expect(
      find.text('7 happy days this week — Pip hasn’t stopped singing.'),
      findsOneWidget,
      reason: 'the line clamps to the seven drawn days',
    );
    await disposeApp(tester);
  });

  // -------------------------------------------------------------------------
  // K11-BUG-2 (fixed in iteration 2) — child resolution
  // -------------------------------------------------------------------------
  testWidgets('K11-BUG-2 a non-Maya family with no active child shows Zoe', (
    tester,
  ) async {
    await _pumpRoute(tester);

    // A family whose only child is Zoe, with one earned badge, and no
    // active child (deep link to /badges before a child was picked).
    await _write(tester, () => db.delete(db.earnedBadges).go());
    await _write(tester, () => db.delete(db.children).go());
    await _write(
      tester,
      () => db
          .into(db.children)
          .insert(
            ChildrenCompanion.insert(
              id: 'zoe',
              familyId: Seed.familyId,
              nickname: 'Zoe',
              happyDays: const Value(2),
            ),
          ),
    );
    await _write(
      tester,
      () => db
          .into(db.earnedBadges)
          .insert(
            EarnedBadgesCompanion.insert(
              badgeId: 'bookworm',
              childId: 'zoe',
              familyId: Seed.familyId,
            ),
          ),
    );
    await _write(
      tester,
      () => (db.update(db.appState)..where((a) => a.id.equals(1))).write(
        const AppStateCompanion(activeChildId: Value<String?>(null)),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      find.text('One shiny one already. Pip is very impressed.'),
      findsOneWidget,
      reason: 'activeChildId null resolves this family (Zoe), not maya',
    );
    expect(
      find.text('No shiny ones yet. Finish a quest to earn your first!'),
      findsNothing,
      reason: 'that line was the maya fallback artifact for this family',
    );
    expect(find.text('Got it!'), findsOneWidget);
    expect(find.byType(BadgeGridCell), findsNWidgets(9));
    await disposeApp(tester);
  });

  // -------------------------------------------------------------------------
  // K11-ART (iteration 3, ORCHESTRATOR_NOTES 06:55) — raster colour proof
  // -------------------------------------------------------------------------
  for (final mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
    testWidgets('K11-ART locked medals in ${mode.name}', (tester) async {
      for (final (id, title) in _lockedIds) {
        await pumpNest(
          tester,
          RepaintBoundary(
            key: const ValueKey('k11-art-probe'),
            child: SizedBox(
              width: 350,
              child: BadgeGridCell(badge: _lockedBadge(id, title)),
            ),
          ),
          mode: mode,
        );
        await tester.pumpAndSettle();

        final tokens = tester.element(find.byType(BadgeGridCell)).nest;
        final medal = tester.getRect(find.byType(SvgPicture));
        final origin = tester.getTopLeft(
          find.byKey(const ValueKey('k11-art-probe')),
        );
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('k11-art-probe')),
        );
        late ui.Image image;
        await tester.runAsync(() async {
          image = await boundary.toImage(pixelRatio: 3);
        });
        final data = (await tester.runAsync(() => image.toByteData()))!;

        /// Samples the raster at a viewBox coordinate of the 64×64 medal.
        Color at(double vx, double vy) {
          final lx = medal.left - origin.dx + vx / 64 * 60;
          final ly = medal.top - origin.dy + vy / 64 * 60;
          final x = (lx * 3).round().clamp(0, image.width - 1);
          final y = (ly * 3).round().clamp(0, image.height - 1);
          final i = (y * image.width + x) * 4;
          return Color.fromARGB(
            data.getUint8(i + 3),
            data.getUint8(i),
            data.getUint8(i + 1),
            data.getUint8(i + 2),
          );
        }

        final fillComposite = _over(_ink3, 0.4, tokens.surface);
        expect(
          _close(at(32, 12), fillComposite),
          isTrue,
          reason: '$id ribbon fill: ink3 at 40 % over the tile surface',
        );
        // Element opacity groups fill+stroke: the stroke paints over the
        // fill at full alpha, then the whole ribbon at 40 %.
        expect(
          _close(at(32, 5), _over(_ink, 0.4, fillComposite)),
          isTrue,
          reason: '$id ribbon stroke: ink at 40 % over the ribbon fill',
        );
        expect(_close(at(32, 55), _disc), isTrue, reason: '$id disc #F3EEE5');

        // The dashed ring: probe densely and keep the pixel closest to ink —
        // not the darkest (the dark surface is darker than ink by luminance).
        var ringDist = 1 << 30;
        for (var deg = 0; deg < 360; deg += 3) {
          final rad = deg * math.pi / 180;
          final c = at(32 + 20 * math.cos(rad), 39 + 20 * math.sin(rad));
          final d =
              (_ch(c, 0) - 30).abs() +
              (_ch(c, 1) - 27).abs() +
              (_ch(c, 2) - 58).abs();
          if (d < ringDist) ringDist = d;
        }
        expect(
          ringDist,
          lessThanOrEqualTo(8),
          reason: '$id dashed ring is ink #1E1B3A in ${mode.name}',
        );

        // The glyph must actually PAINT (a malformed path would parse and
        // draw nothing): count glyph-coloured pixels inside the disc.
        final cx = (medal.left - origin.dx + 30) * 3;
        final cy = (medal.top - origin.dy + 36.5625) * 3;
        const r = 17 * 3;
        var glyphPixels = 0;
        for (var y = (cy - r).round(); y <= (cy + r).round(); y++) {
          for (var x = (cx - r).round(); x <= (cx + r).round(); x++) {
            if (x < 0 || y < 0 || x >= image.width || y >= image.height) {
              continue;
            }
            final dx = x - cx;
            final dy = y - cy;
            if (dx * dx + dy * dy > r * r) continue;
            final i = (y * image.width + x) * 4;
            final c = Color.fromARGB(
              data.getUint8(i + 3),
              data.getUint8(i),
              data.getUint8(i + 1),
              data.getUint8(i + 2),
            );
            if (_close(c, _ink3, tol: 30)) glyphPixels++;
          }
        }
        expect(
          glyphPixels,
          greaterThan(50),
          reason: '$id glyph paints its own strokes',
        );
      }
      await tester.pumpWidget(Container());
    });
  }
}

/// The five still-to-do ids and their design titles, in grid order.
const List<(String, String)> _lockedIds = <(String, String)>[
  ('bins-out', 'Bins out'),
  ('biscuit-sitter', 'Biscuit sitter'),
  ('tidy-hero', 'Tidy hero'),
  ('early-bird', 'Early bird'),
  ('plant-waterer', 'Plant waterer'),
];

const Color _ink = Color(0xFF1E1B3A);
const Color _ink3 = Color(0xFF6E6A8A);
const Color _disc = Color(0xFFF3EEE5);

domain.Badge _lockedBadge(String id, String title) => domain.Badge(
  id: id,
  title: title,
  detail: 'Keep going!',
  icon: 'medal',
  description: '',
  earned: false,
  earnedAt: null,
);

Color _over(Color fg, double a, Color bg) =>
    Color.alphaBlend(fg.withValues(alpha: a), bg);

int _ch(Color c, int i) => i == 0
    ? (c.r * 255).round()
    : i == 1
    ? (c.g * 255).round()
    : (c.b * 255).round();

bool _close(Color a, Color b, {int tol = 8}) =>
    (_ch(a, 0) - _ch(b, 0)).abs() <= tol &&
    (_ch(a, 1) - _ch(b, 1)).abs() <= tol &&
    (_ch(a, 2) - _ch(b, 2)).abs() <= tol;

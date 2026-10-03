// Shared harness for the P14 rewards tests.
//
// Two things every P14 widget test needs:
//
// 1. The real app at `/rewards` (DI, router, seeded in-memory Drift DB) on a
//    surface of a chosen width/height/text-scale/theme — `pumpAppRoute`
//    hard-codes 390x844 at scale 1.0, and the responsive sweep needs 320 and
//    430.
// 2. The bundled families. Widget tests do NOT load Inter/Nunito
//    automatically, and the fallback makes text far wider ("Needs my OK"
//    measures 143 px instead of 85). That is not cosmetic: without the real
//    fonts the editor sheet reports a 19 px horizontal + 16 px vertical
//    RenderFlex overflow at 320x568 @ text scale 1.3 that does NOT happen on
//    device (proved both ways in `3_test.md`). Any test that asserts geometry
//    or "no overflow" must `setUpAll(loadBundledFonts)`.
//
// Raw DB access goes through [rewardRows] — assertions about what a tap
// actually wrote read the table, never the widget's optimistic state.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart' as db;
import 'package:nestling/features/rewards/domain/rewards_repository.dart';
import 'package:nestling/features/rewards/rewards_routes.dart';

import '../../test_scope.dart';

/// The design's P14 order is the database order, and the ORCHESTRATOR_NOTES
/// (12:27) ruling is that the database order is CREATION order — the order the
/// rewards were added — with `Seed.demo()` inserting them in the sequence
/// below. Tests read the order from the database (`appOrderIds`) instead of
/// hard-coding a sort key; `seedInsertionOrder` is only used by the
/// skip-marked [P14-ORDER] proof.
const List<String> seedInsertionOrder = <String>[
  'r-screen',
  'r-film',
  'r-bedtime',
  'r-baking',
  'r-cafe',
  'r-dinner',
];
const List<String> demoRewardIds = <String>[
  'r-screen',
  'r-film',
  'r-bedtime',
  'r-baking',
  'r-cafe',
  'r-dinner',
];

/// `aria-label` subjects from `P14-rewards.html`, one per seeded row.
const Map<String, String> demoApprovalLabels = <String, String>{
  'r-screen': 'Needs approval for screen time',
  'r-film': 'Needs approval for Friday film',
  'r-bedtime': 'Needs approval for staying up later',
  'r-baking': 'Needs approval for baking',
  'r-cafe': 'Needs approval for park cafe',
  'r-dinner': 'Needs approval for dinner',
};

/// The two rows the design shortens, copied verbatim.
const Map<String, String> demoEditLabels = <String, String>{
  'r-screen': 'Edit 30 min extra screen time',
  'r-bedtime': 'Edit Stay up later',
  'r-film': 'Edit Pick Friday film',
  'r-dinner': 'Edit Choose dinner',
  'r-baking': 'Edit Baking together',
  'r-cafe': 'Edit Trip to the park cafe',
};

/// Loads the bundled Inter/Nunito faces into the test font manager.
Future<void> loadBundledFonts() async {
  final inter = FontLoader('Inter')
    ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-SemiBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'));
  await inter.load();
  final nunito = FontLoader('Nunito')
    ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf'));
  await nunito.load();
}

/// Pumps the real app at `/rewards` on a [width] x [height] logical surface.
///
/// [prepare] runs against the seeded in-memory database BEFORE the first frame,
/// so a test can empty the rewards table (or insert a row) and have the screen
/// open on that state instead of racing the stream.
Future<void> pumpRewardsApp(
  WidgetTester tester, {
  int width = NestLogical.width,
  int height = NestLogical.height,
  double textScale = 1.0,
  ThemeMode theme = ThemeMode.light,
  bool seedDemo = true,
  Future<void> Function(db.AppDatabase database)? prepare,
}) async {
  final database = await setUpTestScope(seedDemo: seedDemo);
  if (prepare != null) await prepare(database);
  await pumpAppRoute(tester, RewardsRoutePaths.rewards, theme: theme);
  tester.view.physicalSize = Size(width * 3, height * 3);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// Every reward row in raw table order. Tests that care about ORDER read it
/// through [appOrderIds] instead of sorting here; this helper answers "does
/// this row exist and what is in it".
Future<List<db.Reward>> rewardRows() {
  final database = GetIt.instance<db.AppDatabase>();
  return database.select(database.rewards).get();
}

Future<db.Reward> rewardRow(String id) async =>
    (await rewardRows()).firstWhere((row) => row.id == id);

Future<bool> rewardNeedsOk(String id) async => (await rewardRow(id)).needsOk;

/// The reward ids in the order the screen must render them.
///
/// Read from the repository's own query rather than a hard-coded sort key:
/// the ORCHESTRATOR_NOTES (12:27) ruling is that the list is CREATION order,
/// but the canonical query and the `needsOk` seed correction arrive with the
/// next main merge, so the screen test asserts the screen renders the
/// DATABASE order verbatim and leaves the choice of that order to the data
/// layer. The order itself is proved separately by the skip-marked
/// `[P14-ORDER]` test in `rewards_order_test.dart`.
///
/// Must be called through [rewardIdsInAppOrder] inside a widget test: a Drift
/// stream only delivers once the event loop runs, which under a widget test's
/// fake clock means real async.
Future<List<String>> appOrderIds() async {
  final repository = GetIt.instance<RewardsRepository>();
  return (await repository.watchItems().first).map((item) => item.id).toList();
}

/// Widget-test-safe wrapper around [appOrderIds] — see the note there.
Future<List<String>> rewardIdsInAppOrder(WidgetTester tester) async {
  final ids = await tester.runAsync(appOrderIds);
  if (ids == null) {
    throw StateError('runAsync returned null for appOrderIds()');
  }

  return ids;
}

/// Every semantics node in the pumped tree that exposes a tap action.
///
/// Text fields are excluded: the framework gives an editable its own node
/// (focusable/tappable) whose *label* is carried by the sibling `label` widget
/// rather than the node itself, and `NestTextField` is a shared component —
/// so counting it here would report a shared-component announcement style,
/// not a P14 defect. Every other tappable node must announce itself.
List<SemanticsNode> tappableSemanticsNodes(WidgetTester tester) {
  // `rootPipelineOwner` has no SemanticsOwner in a widget test; the owner
  // hangs off the render view the test pumped.
  final views = tester.binding.renderViews;
  final root = views.isEmpty
      ? null
      : views.first.owner?.semanticsOwner?.rootSemanticsNode;
  if (root == null) {
    throw StateError(
      'no semantics tree: call tester.ensureSemantics() and pump first',
    );
  }
  final found = <SemanticsNode>[];
  void visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    if (data.hasAction(SemanticsAction.tap) &&
        !data.flagsCollection.isTextField) {
      found.add(node);
    }
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(root);
  return found;
}

/// The rendered rect of the 51x31 switch track inside a toggle subtree, i.e.
/// the 31 px the design draws (the hit box is 59x44).
Rect visibleTrackRect(WidgetTester tester, Finder toggle) {
  return tester.getRect(
    find.descendant(of: toggle, matching: find.byType(AnimatedContainer)),
  );
}

/// Design surface P14 was drawn at. Duplicated from `NestDevice` so the test
/// does not have to import the design system for one number.
abstract final class NestLogical {
  static const int width = 390;
  static const int height = 844;
}

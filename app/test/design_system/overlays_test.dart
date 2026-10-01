import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/design_system_gallery/presentation/widgets/gallery_overlays.dart';

import 'test_harness.dart';

void main() {
  group('NestBottomSheet', () {
    testWidgets('opens with grabber, title and close', (tester) async {
      await pumpNest(
        tester,
        Builder(
          builder: (context) => NestButton(
            label: 'Open sheet',
            onPressed: () => showNestBottomSheet<void>(
              context,
              title: 'Choose a quest',
              child: const Text('Sheet content'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();
      expect(find.text('Choose a quest'), findsOneWidget);
      expect(find.text('Sheet content'), findsOneWidget);
      expect(find.byType(NestBottomSheet), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(NestBottomSheet), findsNothing);
    });

    testWidgets('renders inline in both modes', (tester) async {
      await pumpBothModes(
        tester,
        const SingleChildScrollView(
          child: NestBottomSheet(
            title: 'Choose a quest',
            child: Text('Sheet content'),
          ),
        ),
      );
    });
  });

  group('NestModal', () {
    testWidgets('opens centred and dismisses', (tester) async {
      await pumpNest(
        tester,
        Builder(
          builder: (context) => NestButton(
            label: 'Open modal',
            onPressed: () => showNestModal<void>(
              context,
              title: 'Grown-ups only',
              child: const Text('Modal content'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open modal'));
      await tester.pumpAndSettle();
      expect(find.byType(NestModal), findsOneWidget);
      expect(find.text('Modal content'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.byType(NestModal), findsNothing);
    });
  });

  group('NestToast', () {
    testWidgets('shows the message on a snackbar', (tester) async {
      await pumpBothModes(
        tester,
        Builder(
          builder: (context) => NestButton(
            label: 'Show toast',
            onPressed: () => showNestToast(context, 'Quest approved'),
          ),
        ),
      );
      await tester.tap(find.text('Show toast'));
      await tester.pump();
      expect(find.text('Quest approved'), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });

  group('GalleryOverlays', () {
    testWidgets('button labels never ellipsize at 320 and 1.3x', (
      tester,
    ) async {
      await pumpBothModes(
        tester,
        const SingleChildScrollView(child: GalleryOverlays()),
        surface: const Size(320, 568),
        textScale: 1.3,
      );
      for (final label in const ['Sheet', 'Modal', 'Toast']) {
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text(label),
        );
        expect(
          paragraph.didExceedMaxLines,
          isFalse,
          reason: '$label ellipsized',
        );
      }
    });
  });
}

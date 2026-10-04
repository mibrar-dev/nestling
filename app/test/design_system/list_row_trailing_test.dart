import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

import 'test_harness.dart';

/// `flutter test` replaces every font family with a wide test fallback
/// (~2× the design advances), so geometry assertions need the designs' own
/// Inter/Nunito builds (`assets/fonts/*.ttf`) loaded with a `FontLoader`
/// — the same pattern as `test/features/auth/typography_test.dart`.
Future<void> _loadDesignFonts() async {
  Future<void> family(String name, List<String> assets) async {
    final loader = FontLoader(name);
    for (final asset in assets) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }

  await family('Inter', const [
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-Medium.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
    'assets/fonts/Inter-Bold.ttf',
  ]);
  await family('Nunito', const [
    'assets/fonts/Nunito-Bold.ttf',
    'assets/fonts/Nunito-ExtraBold.ttf',
    'assets/fonts/Nunito-Black.ttf',
  ]);
}

/// `NestListRow` trailing regression (shared/list_row_trailing).
///
/// The trailing used to be `Flexible(child: tail)`, which handed it an
/// equal flex share: the text column got half the free width (129 px at
/// 390 instead of the design's ≈187 px), subtitles ellipsized, and the
/// chevron parked mid-row. The design (`components.css:116-119`) is
/// `.list-main { flex: 1; min-width: 0 }` + `.list-trail { flex-shrink: 0 }`,
/// so the trailing takes its intrinsic width at the right edge.
///
/// Row heights lock the CSS (`.list-row`: padding 10/16/12, min-height 56):
/// title 22 + sub 18 + padding 20 = 60 with a subtitle, 56 title-only.
/// Design pitch measured on `design/screens/light/P16-settings.png` ÷ 3:
/// card rows at 137/197/257 (dividers at 197/257), pitch 60.
void main() {
  setUpAll(_loadDesignFonts);

  /// P16-like row at the real list width (390 − 2 × 20 scroll gutters).
  Widget p16Row({String? trailingText = '›', String? subtitle}) {
    return SizedBox(
      width: 350,
      child: NestList(
        children: [
          NestListRow(
            title: 'Maya · 7–9',
            subtitle: subtitle ?? 'Pip: Fledgling · 120 coins',
            leadingAsset: NestIcons.lock,
            trailing: trailingText == null
                ? null
                : Text(
                    trailingText,
                    style: NestType.body(color: Colors.grey)
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    softWrap: false,
                  ),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  testWidgets('subtitle renders in full at 390', (tester) async {
    await pumpNest(tester, Center(child: p16Row()));
    expect(tester.takeException(), isNull);
    expect(
      tester
          .renderObject<RenderParagraph>(
            find.text('Pip: Fledgling · 120 coins'),
          )
          .didExceedMaxLines,
      isFalse,
      reason: 'P16 subtitle must not ellipsize at 390',
    );
    expect(
      tester
          .renderObject<RenderParagraph>(find.text('Maya · 7–9'))
          .didExceedMaxLines,
      isFalse,
    );
  });

  testWidgets('chevron right edge meets the row content right edge', (
    tester,
  ) async {
    await pumpNest(tester, Center(child: p16Row()));
    expect(tester.takeException(), isNull);
    final chevronRight = tester.getRect(find.text('›')).right;
    // Row content right edge = row box minus the 16px right padding
    // (`.list-row` padding `10px 16px 10px 12px`).
    final contentRight = tester.getRect(find.byType(NestListRow)).right - 16;
    expect(
      (chevronRight - contentRight).abs(),
      lessThanOrEqualTo(1),
      reason: 'chevron right $chevronRight vs content right $contentRight',
    );
  });

  testWidgets('row height matches the CSS (60 with sub, 56 title-only)', (
    tester,
  ) async {
    await pumpNest(
      tester,
      Center(
        child: SizedBox(
          width: 350,
          child: NestList(
            children: [
              NestListRow(
                key: const Key('row-with-sub'),
                title: 'Maya · 7–9',
                subtitle: 'Pip: Fledgling · 120 coins',
                leadingAsset: NestIcons.lock,
                trailing: const Text('›'),
                onTap: () {},
              ),
              NestListRow(
                key: const Key('row-title-only'),
                title: 'Invite co-parent',
                trailing: const Text('›'),
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(const Key('row-with-sub'))).height,
      60,
      reason: 'title 22 + sub 18 + padding 20 = 60',
    );
    expect(
      tester.getSize(find.byKey(const Key('row-title-only'))).height,
      56,
      reason: 'CSS min-height binds title-only rows',
    );
  });

  testWidgets('a long trailing word stays intact', (tester) async {
    await pumpNest(tester, Center(child: p16Row(trailingText: 'Change')));
    expect(tester.takeException(), isNull);
    expect(
      tester
          .renderObject<RenderParagraph>(find.text('Change'))
          .didExceedMaxLines,
      isFalse,
      reason: 'trailing must keep its intrinsic width under the cap',
    );
    expect(
      tester
          .renderObject<RenderParagraph>(
            find.text('Pip: Fledgling · 120 coins'),
          )
          .didExceedMaxLines,
      isFalse,
      reason: 'subtitle still fits beside a word trailing',
    );
  });
}

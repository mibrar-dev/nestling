// K06 · Pip's nest — the CARE ROW glyphs, byte-compared to the design source.
//
// The wardrobe glyphs went through two rounds of "the app draws a look-alike"
// fixes (Scarf/Wellies on `shared_batch7`, then the Sun hat on
// `shared/k06_glyphs`). The care row's three icons are the same class of
// artefact and had **no** proof at all until this file: `shared/k06_glyphs`
// added `ic_kid_feed.svg` / `ic_kid_play.svg` as the design's exact paths (K06
// now draws them), while Bath's `NestIcons.bubbles` was already exact.
//
// So this reads the design's three `.k6-care` buttons out of
// `K06-pip.html` — path AND circle geometry, in source order — and compares
// them with the asset each button actually paints. The oracle is the source,
// never a transcription, so a later "tidy" of the icons cannot re-green this.
//
// Plain `test`s (no widget pumping): the comparison is between the design file
// and the SVG assets on disk.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/components/nest_icon.dart';

/// The care row in design order: the `.k6-care` buttons, label → icon.
const Map<String, String> _careIcons = <String, String>{
  'Feed': NestIcons.kidFeed,
  'Play': NestIcons.kidPlay,
  'Bath': NestIcons.bubbles,
};

/// The `<svg>` attribute runs of an element body, whitespace-normalised.
///
/// `d="…"` on a `<path>` and `cx/cy/r` on a `<circle>` are the only geometry
/// the design's care icons use; order is preserved because it is the drawing
/// order.
List<String> _geometry(String svgSource) {
  final out = <String>[];
  for (final match in RegExp('(?:d|cx|cy|r)="([^"]*)"').allMatches(svgSource)) {
    out.add(match.group(1)!.replaceAll(' ', '').toLowerCase());
  }
  return out;
}

/// The design's own `.k6-care` button bodies, in source order.
List<String> _designCareButtons(String html) {
  final block = html.split('<div class="k6-care">').last.split('</div>').first;
  return RegExp(
    '<button class="btn-kid[^"]*"[^>]*>(.*?)</button>',
    dotAll: true,
  ).allMatches(block).map((m) => m.group(1)!).toList();
}

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
    'design/html-source/screens/K06-pip.html not found above '
    '${Directory.current.path}',
  );
}

void main() {
  late String html;

  setUpAll(() {
    html = _designSource().readAsStringSync();
  });

  test('the design source has three care buttons, in Feed/Play/Bath order', () {
    final buttons = _designCareButtons(html);
    expect(buttons, hasLength(3));
    final labels = buttons
        .map((b) => RegExp('<span>([^<]*)</span>').firstMatch(b)!.group(1)!)
        .toList();
    expect(labels, <String>['Feed', 'Play', 'Bath']);
  });

  for (final entry in _careIcons.entries) {
    test('the ${entry.key} icon is the design glyph, byte for byte', () {
      final index = _careIcons.keys.toList().indexOf(entry.key);
      final design = _geometry(_designCareButtons(html)[index]);
      final asset = File(entry.value);

      expect(asset.existsSync(), isTrue, reason: '${entry.value} exists');
      final app = _geometry(asset.readAsStringSync());

      expect(
        app,
        design,
        reason:
            "${entry.key} draws ${asset.path.split('/').last}: the design's "
            '.k6-care button has ${design.length} geometry run(s), the asset '
            '${app.length} — and their values must match exactly '
            '(whitespace and case normalised, nothing else)',
      );
    });
  }

  test('no care icon is a look-alike from the superseded set', () {
    // The wardrobe lesson, applied: the old `NestIcons.feedBowl` /
    // `NestIcons.ball` are the pre-`shared/k06_glyphs` look-alikes and must
    // not come back on this screen.
    const superseded = <String>{NestIcons.feedBowl, NestIcons.ball};
    expect(_careIcons.values.any(superseded.contains), isFalse);
    for (final asset in superseded) {
      expect(
        File(asset).existsSync(),
        isTrue,
        reason: '$asset still exists for other screens',
      );
    }
  });

  test('the three icons are distinct assets', () {
    // Cheap guard against a copy-paste swap wiring all three to one glyph.
    expect(_careIcons.values.toSet(), hasLength(3));
  });
}

// Launcher-icon contract for the Nestling brand art.
//
// The designer-approved sources live in `assets/brand/`; the Android safe
// zone variants are derived by `tools/brand/generate_icons.py` and wired
// into the build by the `flutter_launcher_icons` section of `pubspec.yaml`.
// These tests pin that chain: art is bundled at the right size, the adaptive
// foreground fits the central 66 % circle (radius 338 px of 1024), the
// monochrome icon is a white-only silhouette, and the generated iOS /
// Android launcher outputs reference the right drawables.
//
// File paths are relative to the package root (`flutter test` runs with the
// package root as the working directory).

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

/// Radius of the Android adaptive-icon safe zone on a 1024 px layer.
const double kSafeRadiusPx = 338;

/// Pixels at or below this alpha count as transparent.
const int kAlphaThreshold = 8;

Future<ui.Image> _decodePng(String path) async {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: 'missing $path');
  final bytes = await file.readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}

Future<ByteData> _rgba(ui.Image image) async {
  final data = await image.toByteData();
  expect(data, isNotNull);
  return data!;
}

/// Greatest distance from the layer centre among pixels above [kAlphaThreshold].
double _maxOpaqueDistance(ByteData rgba, int width, int height) {
  var maxSq = 0.0;
  final cx = (width - 1) / 2;
  final cy = (height - 1) / 2;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      if (rgba.getUint8((y * width + x) * 4 + 3) > kAlphaThreshold) {
        final dx = x - cx;
        final dy = y - cy;
        final sq = dx * dx + dy * dy;
        if (sq > maxSq) maxSq = sq;
      }
    }
  }
  return maxSq <= 0 ? 0 : math.sqrt(maxSq);
}

void main() {
  test('brand source art is bundled at the expected sizes', () async {
    final sizes = <String, int>{
      'assets/brand/app_icon.png': 1024,
      'assets/brand/app_icon_foreground.png': 1024,
      'assets/brand/app_icon_background.png': 1024,
      'assets/brand/play_store_icon_512.png': 512,
    };
    for (final entry in sizes.entries) {
      final image = await _decodePng(entry.key);
      expect(image.width, entry.value, reason: entry.key);
      expect(image.height, entry.value, reason: entry.key);
      image.dispose();
    }
  });

  test('adaptive foreground fits the Android safe zone', () async {
    const path = 'assets/brand/app_icon_foreground_adaptive.png';
    final image = await _decodePng(path);
    expect(image.width, 1024);
    expect(image.height, 1024);
    final rgba = await _rgba(image);
    final maxDist = _maxOpaqueDistance(rgba, image.width, image.height);
    expect(maxDist, greaterThan(0), reason: 'adaptive foreground is empty');
    expect(
      maxDist,
      lessThanOrEqualTo(kSafeRadiusPx),
      reason: 'opaque art escapes the 66 % safe circle',
    );
    image.dispose();
  });

  test('monochrome icon is a white-only silhouette in the safe zone', () async {
    const path = 'assets/brand/app_icon_monochrome.png';
    final image = await _decodePng(path);
    expect(image.width, 1024);
    expect(image.height, 1024);
    final rgba = await _rgba(image);
    var opaque = 0;
    var maxSq = 0.0;
    const cx = (1024 - 1) / 2;
    for (var y = 0; y < 1024; y++) {
      for (var x = 0; x < 1024; x++) {
        final o = (y * 1024 + x) * 4;
        final a = rgba.getUint8(o + 3);
        if (a > kAlphaThreshold) {
          opaque++;
          // White silhouette: all channels equal, either straight (255) or
          // premultiplied (channel == alpha) depending on the codec.
          final r = rgba.getUint8(o);
          final g = rgba.getUint8(o + 1);
          final b = rgba.getUint8(o + 2);
          expect(r, g, reason: 'non-white red at $x,$y');
          expect(g, b, reason: 'non-white green at $x,$y');
          expect(
            r == 255 || r == a,
            isTrue,
            reason: 'non-white silhouette at $x,$y',
          );
          final dx = x - cx;
          final dy = y - cx;
          final sq = dx * dx + dy * dy;
          if (sq > maxSq) maxSq = sq;
        }
      }
    }
    expect(opaque, greaterThan(0), reason: 'monochrome icon is empty');
    expect(
      math.sqrt(maxSq),
      lessThanOrEqualTo(kSafeRadiusPx),
      reason: 'monochrome art escapes the 66 % safe circle',
    );
    image.dispose();
  });

  test('pubspec wires the generated icons into flutter_launcher_icons', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('assets/brand/app_icon.png'));
    expect(
      pubspec,
      contains(
        'adaptive_icon_foreground: '
        'assets/brand/app_icon_foreground_adaptive.png',
      ),
    );
    expect(
      pubspec,
      contains(
        'adaptive_icon_monochrome: assets/brand/app_icon_monochrome.png',
      ),
    );
    expect(pubspec, contains('remove_alpha_ios: true'));
  });

  test(
    'iOS AppIcon lists all sizes incl. 1024 marketing without alpha',
    () async {
      const dir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
      final contents = jsonDecode(
        File('$dir/Contents.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final images = (contents['images'] as List).cast<Map<String, dynamic>>();
      expect(
        images.any(
          (e) => e['size'] == '1024x1024' && e['idiom'] == 'ios-marketing',
        ),
        isTrue,
        reason: 'missing 1024 ios-marketing entry',
      );
      final marketing =
          images.firstWhere((e) => e['size'] == '1024x1024')['filename']
              as String;
      final image = await _decodePng('$dir/$marketing');
      expect(image.width, 1024);
      final rgba = await _rgba(image);
      for (var i = 3; i < rgba.lengthInBytes; i += 4) {
        expect(rgba.getUint8(i), 255, reason: 'alpha channel in $marketing');
      }
      image.dispose();
    },
  );

  test('Android adaptive icon wires background/foreground/monochrome', () {
    const xmlPath =
        'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml';
    final xml = File(xmlPath).readAsStringSync();
    expect(xml, contains('@drawable/ic_launcher_background'));
    expect(xml, contains('@drawable/ic_launcher_foreground'));
    expect(xml, contains('@drawable/ic_launcher_monochrome'));
    for (final density in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
      for (final name in ['background', 'foreground', 'monochrome']) {
        expect(
          File(
            'android/app/src/main/res/drawable-$density/ic_launcher_$name.png',
          ).existsSync(),
          isTrue,
          reason: 'missing drawable-$density/ic_launcher_$name.png',
        );
      }
      expect(
        File('android/app/src/main/res/mipmap-$density/ic_launcher.png')
            .existsSync(),
        isTrue,
        reason: 'missing mipmap-$density/ic_launcher.png',
      );
    }
  });
}

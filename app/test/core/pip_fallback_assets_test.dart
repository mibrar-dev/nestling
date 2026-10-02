// Every Pip style x stage has static fallback art (reduced motion / tests),
// and the fallback never draws hidden eye variants (P08 review M1).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';

void main() {
  for (final style in PipStyle.values) {
    for (var stage = 1; stage <= 4; stage++) {
      test('fallback art exists for ${style.name} stage $stage', () {
        final file = File(PipAvatar.fallbackAsset(style, stage));
        expect(file.existsSync(), isTrue, reason: file.path);
        // A hidden group WITH content (not self-closing) is drawn by
        // flutter_svg anyway — e.g. every eye variant stacked into a blob.
        final hiddenWithContent = RegExp(r'<g\b[^>]*\bopacity="0"[^/>]*>');
        expect(
          hiddenWithContent.hasMatch(file.readAsStringSync()),
          isFalse,
          reason: 'hidden variant groups render in flutter_svg',
        );
      });
    }
  }
}

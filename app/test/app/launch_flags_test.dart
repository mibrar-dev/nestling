import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/app/launch_flags.dart';
import 'package:nestling/core/data/env_flags.dart';

void main() {
  group('LaunchFlags.isSupportedSeed', () {
    test('supports demo, empty, fresh, new_family and onboarding_kids', () {
      expect(LaunchFlags.isSupportedSeed('demo'), isTrue);
      expect(LaunchFlags.isSupportedSeed('empty'), isTrue);
      expect(LaunchFlags.isSupportedSeed('fresh'), isTrue);
      expect(LaunchFlags.isSupportedSeed('new_family'), isTrue);
      expect(LaunchFlags.isSupportedSeed('onboarding_kids'), isTrue);
    });

    test('rejects unknown and empty seeds', () {
      expect(LaunchFlags.isSupportedSeed(''), isFalse);
      expect(LaunchFlags.isSupportedSeed('Demo'), isFalse);
      expect(LaunchFlags.isSupportedSeed('onboardingKids'), isFalse);
    });
  });

  // P08 §6 / K03 §5: `tools/screens/shot.sh` always passes
  // `--dart-define=DISABLE_ANIMATIONS=1`, and `bool.fromEnvironment` maps
  // only `'true'` — both flags OR in the explicit `'1'` comparison. These
  // pin the test-env default (unset ⇒ false); the `=1` parse itself is
  // proved by the screenshot harness stabilising (see the batch report).
  group('DISABLE_ANIMATIONS parsing', () {
    test('defaults to false when the flag is unset', () {
      expect(kDisableAnimations, isFalse);
      expect(LaunchFlags.disableAnimations, isFalse);
    });
  });
}

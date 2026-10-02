import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/app/launch_flags.dart';

void main() {
  group('LaunchFlags.isSupportedSeed', () {
    test('supports demo, empty, fresh and onboarding_kids', () {
      expect(LaunchFlags.isSupportedSeed('demo'), isTrue);
      expect(LaunchFlags.isSupportedSeed('empty'), isTrue);
      expect(LaunchFlags.isSupportedSeed('fresh'), isTrue);
      expect(LaunchFlags.isSupportedSeed('onboarding_kids'), isTrue);
    });

    test('rejects unknown and empty seeds', () {
      expect(LaunchFlags.isSupportedSeed(''), isFalse);
      expect(LaunchFlags.isSupportedSeed('Demo'), isFalse);
      expect(LaunchFlags.isSupportedSeed('onboardingKids'), isFalse);
    });
  });
}

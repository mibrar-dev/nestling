// Runs before every test file: pins the demo seed's story day so dates in
// assertions stay deterministic (the app itself anchors to today).

import 'dart:async';

import 'package:nestling/core/data/seed.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Seed.anchorOverride = DateTime.utc(2026, 10, 3);
  await testMain();
}

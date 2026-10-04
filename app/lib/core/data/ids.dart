// Nestling — shared unique id generator.
//
// Ids are `newId(prefix)` (uuid v4); never derive ids from the clock.
// A millisecond timestamp (`appNowUtc().millisecondsSinceEpoch`,
// `clock.now()…`) collides whenever two inserts land in the same
// millisecond — which is every insert under the pinned test clock and a
// fast double-tap or restart in production — so Drift throws a UNIQUE
// violation and the raw SQL error reaches the user (P09 BUG-P09-14).
// A 128-bit crypto-random suffix is unique by construction, not by timing.

import 'dart:math';

/// Returns `'$prefix-<uuid v4>'` using a crypto-random 128-bit value.
///
/// The suffix is clock-independent: two calls in the same millisecond (or
/// under the pinned test clock) still return distinct values.
String newId(String prefix) {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  // UUID v4 version + variant bits, so the suffix parses as a v4 uuid.
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = StringBuffer();
  for (final b in bytes) {
    hex.write(b.toRadixString(16).padLeft(2, '0'));
  }
  final s = hex.toString();
  return '$prefix-${s.substring(0, 8)}-${s.substring(8, 12)}-'
      '${s.substring(12, 16)}-${s.substring(16, 20)}-${s.substring(20)}';
}

import 'package:characters/characters.dart';

/// Grapheme-safe avatar initial for NestAvatar and its call sites.
///
/// `name[0]` indexes UTF-16 code units, so a leading non-BMP character
/// (emoji, many CJK extensions, regional-indicator flags) yields an unpaired
/// surrogate and `String.toUpperCase()` then throws
/// `ArgumentError: string is not well-formed UTF-16`, failing the whole
/// frame (K02-BUG-1 / SHARED_REQUEST #3: `/who-is-playing`, `/kid-home`, …).
/// P05 accepts such nicknames, so every display must be safe instead of
/// blocking input.
///
/// Returns the first grapheme cluster (`package:characters`, which Flutter
/// ships), upper-cased. `characters.first` is always well-formed UTF-16,
/// so `toUpperCase()` never throws here — it is a no-op for emoji, ZWJ
/// sequences and other non-letters. Empty or whitespace-only names return
/// [fallback] (`'?'` for a kid, `'S'` for the parent row, `'•'` for the
/// parental-gate placeholder, `''` where the caller already handles empty).
String nestAvatarInitial(String name, {String fallback = '?'}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return fallback;
  }
  return trimmed.characters.first.toUpperCase();
}

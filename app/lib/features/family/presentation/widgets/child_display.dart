import 'package:flutter/foundation.dart';
import 'package:nestling/core/design_system/components/nest_avatar.dart';

/// Feature-private presentation mappings for the family roster (P05 cards).
/// Kept out of the bloc file so widgets do not depend on bloc internals.

/// Maps a stored `avatar_colour` token to its design-system colour.
NestAvatarColor avatarColourFor(String raw) {
  final colour = switch (raw) {
    'lilac' => NestAvatarColor.lilac,
    'peach' => NestAvatarColor.peach,
    'sky' => NestAvatarColor.sky,
    'leaf' => NestAvatarColor.leaf,
    'coin' => NestAvatarColor.coin,
    _ => null,
  };
  if (colour == null) {
    debugPrint('P05 unknown avatar colour: $raw');
    return NestAvatarColor.neutral;
  }
  return colour;
}

/// Seed rows store bands with a hyphen (`7-9`); the design shows an en-dash
/// (`7–9`). `13+` has no hyphen and passes through unchanged.
String displayAgeBand(String band) => band.replaceAll('-', '\u2013');

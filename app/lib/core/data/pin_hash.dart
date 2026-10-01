// Nestling — kid PIN hashing (local-only).
//
// The PIN itself is never stored; only this salted SHA-256 digest lives in
// `children.pin_hash`. Comparison is constant-time.

import 'dart:convert';

import 'package:crypto/crypto.dart';

const _pinSalt = 'nestling-pin-v1';

String hashPin(String pin) {
  final bytes = utf8.encode('$_pinSalt:$pin');
  return sha256.convert(bytes).toString();
}

bool verifyPin(String pin, String hash) => hashPin(pin) == hash;

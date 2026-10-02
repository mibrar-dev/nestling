// Nestling — tiny stream helpers for Drift-backed repositories.
//
// Drift `watch()` streams are single-subscription and never close; these
// `combineLatest` helpers merge them so a repository can expose one stream
// that re-emits when ANY underlying table changes.

import 'dart:async';

/// Re-emits `[a, b]` whenever either source emits (after both have emitted).
Stream<List<dynamic>> combineLatest2(Stream<dynamic> a, Stream<dynamic> b) {
  return _combine([a, b]);
}

/// Re-emits `[a, b, c]` whenever any source emits (after all have emitted).
Stream<List<dynamic>> combineLatest3(
  Stream<dynamic> a,
  Stream<dynamic> b,
  Stream<dynamic> c,
) {
  return _combine([a, b, c]);
}

/// Re-emits `[a, b, c, d]` whenever any source emits (after all have emitted).
Stream<List<dynamic>> combineLatest4(
  Stream<dynamic> a,
  Stream<dynamic> b,
  Stream<dynamic> c,
  Stream<dynamic> d,
) {
  return _combine([a, b, c, d]);
}

Stream<List<dynamic>> _combine(List<Stream<dynamic>> sources) {
  late final StreamController<List<dynamic>> controller;
  controller = StreamController<List<dynamic>>(
    onListen: () {
      final latest = List<dynamic>.filled(sources.length, null);
      final seen = List<bool>.filled(sources.length, false);
      final subs = <StreamSubscription<dynamic>>[];
      for (var i = 0; i < sources.length; i++) {
        subs.add(
          sources[i].listen((value) {
            latest[i] = value;
            seen[i] = true;
            if (seen.every((s) => s)) {
              controller.add(List<dynamic>.unmodifiable(latest));
            }
          }, onError: controller.addError),
        );
      }
      controller.onCancel = () async {
        for (final s in subs) {
          await s.cancel();
        }
      };
    },
  );
  return controller.stream;
}

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Pushes a route location at most once per frame (P10 · BUG-P10-1).
///
/// `+ Add` and an Active row both call `context.push`, and two taps that land
/// before the next frame would stack two `/quest-editor` routes: the parent
/// then has to press back twice. The guard drops the second push of the same
/// frame and re-arms in a post-frame callback, so it cannot latch — a push
/// that leaves via `go`, or one that throws, still re-arms on the next frame.
///
/// Feature-local copy of P08's `_PushOnce` (a cross-feature import is not
/// allowed by the feature contract); a `core/` promotion is filed in
/// `docs/screens/P10/SHARED_REQUEST.md`.
class QuestPushOnce extends StatefulWidget {
  const QuestPushOnce({required this.builder, super.key});

  /// Builds the subtree; call `push(location)` to navigate at most once per
  /// frame.
  final Widget Function(BuildContext context, void Function(String) push)
  builder;

  @override
  State<QuestPushOnce> createState() => _QuestPushOnceState();
}

class _QuestPushOnceState extends State<QuestPushOnce> {
  bool _armed = true;

  void _push(String location) {
    if (!_armed) return;
    _armed = false;
    // Plain field write only — the widget may be gone by the time the frame
    // ends, and a pushed page covers this control anyway.
    WidgetsBinding.instance.addPostFrameCallback((_) => _armed = true);
    unawaited(context.push(location));
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _push);
}

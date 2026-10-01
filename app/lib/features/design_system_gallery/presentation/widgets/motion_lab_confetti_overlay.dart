// Motion lab — confetti over the top of everything else.
//
// The comp is authored for the full 390 × 844 device frame, so the lab plays it
// exactly the way K07/P13 do: `Positioned.fill` + `BoxFit.cover`, above the
// content, wrapped in `IgnorePointer` so the 2.5 s of falling confetti never
// eats a tap meant for a control underneath it.

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Full-screen confetti. Must be a direct child of the lab's [Stack].
class MotionLabConfettiOverlay extends StatelessWidget {
  const MotionLabConfettiOverlay({
    required this.composition,
    required this.controller,
    super.key,
  });

  final LottieComposition? composition;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Lottie(
          composition: composition,
          controller: controller,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

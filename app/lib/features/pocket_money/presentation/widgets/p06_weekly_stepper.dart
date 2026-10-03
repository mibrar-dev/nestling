import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';

/// The design's minus sign — U+2212 MINUS SIGN, i.e. the `&minus;` the P06
/// HTML source prints inside every `.stepper button`
/// (`design/html-source/screens/P06-pocket-money.html:73,82`). It is a
/// full-width bar that matches the `+` next to it in weight and width, which
/// ASCII U+002D HYPHEN-MINUS does not.
const String kP06StepperMinusGlyph = '−';

/// P06's weekly-base stepper.
///
/// Token-for-token the shared [NestStepper] (44 px circular buttons, 1 px
/// `line` border on `surface`, Inter 20 w700 glyphs, 12 px gaps, a 64 px-wide
/// tabular `NestType.money` value) except for the two glyphs: the design
/// pairs U+2212 with U+002B so the decrease and increase signs read as one
/// family, while the shared component hard-codes a hyphen for decrease and
/// exposes no glyph override.
///
/// Retiring note (TODO(P06)): drop this widget once `NestStepper` takes a
/// `decreaseGlyph`/`increaseGlyph` pair (defaulting to U+2212/U+002B) — see
/// `docs/screens/P06/SHARED_REQUEST.md`. Kept here rather than pasting a
/// glyph over the shared component so the whole stepper stays reviewable and
/// disappears in one edit.
class P06WeeklyStepper extends StatelessWidget {
  const P06WeeklyStepper({
    required this.valueText,
    super.key,
    this.onDecrease,
    this.onIncrease,
    this.decreaseSemanticLabel = 'Decrease',
    this.increaseSemanticLabel = 'Increase',
  });

  final String valueText;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;
  final String decreaseSemanticLabel;
  final String increaseSemanticLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _StepBtn(
          key: const ValueKey('decrease'),
          label: kP06StepperMinusGlyph,
          semanticLabel: decreaseSemanticLabel,
          onPressed: onDecrease,
        ),
        const SizedBox(width: NestSpacing.s3),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 64),
          child: Text(
            valueText,
            style: NestType.money(color: context.nest.ink)
                .copyWith(fontSize: 18, height: 24 / 18),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: NestSpacing.s3),
        _StepBtn(
          key: const ValueKey('increase'),
          label: '+',
          semanticLabel: increaseSemanticLabel,
          onPressed: onIncrease,
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.label,
    required this.semanticLabel,
    required this.onPressed,
    super.key,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final tapped = onPressed;
    final enabled = tapped != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: SizedBox(
          width: NestDevice.tapParent,
          height: NestDevice.tapParent,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: tapped,
              child: Ink(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.surface,
                  border: Border.all(color: tokens.line),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: NestType.bodyStrong(color: tokens.ink)
                        .copyWith(fontSize: 20),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

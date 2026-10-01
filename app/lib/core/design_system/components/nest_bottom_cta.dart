import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

class NestBottomCta extends StatelessWidget {
  const new({required this.child, super.key, this.caption, this.dense = false});

  final Widget child;
  final String? caption;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final caption = this.caption;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border(top: BorderSide(color: tokens.line)),
        ),
        padding: EdgeInsets.symmetric(
          vertical: dense ? 14.0 : NestSpacing.s4,
          horizontal: NestSpacing.padSide,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            child,
            if (caption != null) const SizedBox(height: NestSpacing.s2),
            if (caption != null)
              Text(
                caption,
                style: NestType.caption(color: tokens.ink2),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}

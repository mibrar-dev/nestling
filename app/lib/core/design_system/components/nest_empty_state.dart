import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

class NestEmptyState extends StatelessWidget {
  const new({super.key, this.art, this.title, this.message, this.action});

  final Widget? art;
  final String? title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final artwork = art;
    final heading = title;
    final body = message;
    final callToAction = action;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: NestSpacing.s4,
        vertical: NestSpacing.s6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: NestSpacing.s2,
        children: [
          if (artwork != null)
            SizedBox(width: 160, height: 160, child: Center(child: artwork)),
          if (heading != null)
            Text(
              heading,
              style: NestType.h3(color: tokens.ink),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          if (body != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Text(
                body,
                style: NestType.bodySmall(color: tokens.ink2),
                textAlign: TextAlign.center,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ?callToAction,
        ],
      ),
    );
  }
}

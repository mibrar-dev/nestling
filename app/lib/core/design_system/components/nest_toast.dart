import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/radii.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

class NestToast extends StatelessWidget {
  const new({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        decoration: BoxDecoration(
          color: tokens.ink,
          borderRadius: NestRadii.allM,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: NestSpacing.gap14,
          horizontal: NestSpacing.s4,
        ),
        child: Text(
          message,
          style: NestType.bodySmallStrong(color: tokens.paper),
          textAlign: TextAlign.center,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

void showNestToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: NestToast(message: message),
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(
        NestSpacing.s5,
        0,
        NestSpacing.s5,
        NestDevice.homeH + NestSpacing.s4,
      ),
      duration: const Duration(seconds: 3),
      padding: EdgeInsets.zero,
    ),
  );
}

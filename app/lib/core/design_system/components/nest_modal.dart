import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/radii.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

class NestModal extends StatelessWidget {
  const new({required this.child, super.key, this.title});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final title = this.title;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: NestRadii.allXl,
        boxShadow: tokens.raisedShadow,
      ),
      padding: const EdgeInsets.fromLTRB(
        NestSpacing.s5,
        NestSpacing.s6,
        NestSpacing.s5,
        NestSpacing.s5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (title != null)
            Text(
              title,
              style: NestType.h3(color: tokens.ink),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          if (title != null) const SizedBox(height: NestSpacing.s4),
          DefaultTextStyle(
            style: NestType.bodySmall(color: tokens.ink),
            textAlign: TextAlign.center,
            child: child,
          ),
        ],
      ),
    );
  }
}

Future<T?> showNestModal<T>(
  BuildContext context, {
  required Widget child,
  String? title,
  bool dismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierColor: context.nest.scrim,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: NestSpacing.s6),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: NestModal(title: title, child: child),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/components/nest_icon.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/radii.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

class NestBottomSheet extends StatelessWidget {
  const new({required this.child, super.key, this.title, this.onClose});

  final Widget child;
  final String? title;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final title = this.title;
    final onClose = this.onClose;
    return Material(
      color: tokens.paper,
      borderRadius: NestRadii.topXl,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          NestSpacing.s5,
          NestSpacing.s2,
          NestSpacing.s5,
          NestDevice.homeH + NestSpacing.s4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpacing.s3),
              child: Center(
                child: SizedBox(
                  width: NestSpacing.s10,
                  height: NestSpacing.gap5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: tokens.line,
                      borderRadius: NestRadii.allPill,
                    ),
                  ),
                ),
              ),
            ),
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  NestSpacing.s1,
                  0,
                  NestSpacing.s1,
                  NestSpacing.s2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        title,
                        style: NestType.h3(color: tokens.ink),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onClose != null) ...<Widget>[
                      const SizedBox(width: NestSpacing.s2),
                      _CloseButton(onClose: onClose),
                    ],
                  ],
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const new({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Semantics(
      button: true,
      label: 'Close',
      onTap: onClose,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(NestSpacing.s3),
        child: InkWell(
          borderRadius: BorderRadius.circular(NestSpacing.s3),
          onTap: onClose,
          child: SizedBox(
            width: NestDevice.tapParent,
            height: NestDevice.tapParent,
            child: Center(child: NestIcon(NestIcons.close, color: tokens.ink)),
          ),
        ),
      ),
    );
  }
}

Future<T?> showNestBottomSheet<T>(
  BuildContext context, {
  required Widget child,
  String? title,
  VoidCallback? onClose,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: context.nest.scrim,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.92,
    ),
    builder: (sheetContext) => NestBottomSheet(
      title: title,
      onClose: onClose ?? () => Navigator.of(sheetContext).pop(),
      child: child,
    ),
  );
}

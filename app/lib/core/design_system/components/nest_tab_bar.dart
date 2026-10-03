import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/components/nest_icon.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

class NestTabItem {
  const new({required this.label, required this.icon});

  final String label;
  final String icon;
}

class NestTabBar extends StatelessWidget {
  const new({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
    this.semanticLabel = 'Primary',
  }) : assert(items.length == 4, 'NestTabBar requires exactly 4 items');

  final List<NestTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Semantics(
      label: semanticLabel,
      child: Container(
        height: NestDevice.tabH,
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border(top: BorderSide(color: tokens.line)),
        ),
        padding: const EdgeInsets.only(
          top: NestSpacing.s2,
          left: NestSpacing.s1,
          right: NestSpacing.s1,
          bottom: NestSpacing.s6,
        ),
        child: Row(
          children: <Widget>[
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _Tab(
                  item: items[i],
                  active: i == currentIndex,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const new({required this.item, required this.active, required this.onTap});

  final NestTabItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: NestDevice.tapParent),
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: NestSpacing.gap2),
                child: NestIcon(
                  item.icon,
                  color: active ? tokens.leaf : tokens.ink3,
                ),
              ),
              const SizedBox(height: NestSpacing.s1),
              Flexible(
                child: Text(
                  item.label,
                  style: NestType.tabLabel(
                    color: active ? tokens.leaf : tokens.ink3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

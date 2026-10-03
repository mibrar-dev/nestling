import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';

/// P09-only geometry that has no entry on the shared scale.
///
/// Everything that exists on the 4pt scale (`--s1..--s10`, `--tap`) comes
/// from [NestSpacing] / [NestDevice]; the four values below are the only
/// P09 measurements the design system does not carry, each with its CSS
/// source in `design/html-source/screens/P09-quest-editor.html`.
abstract final class QuestEditorMetrics {
  const new _();

  /// `.ic { border-radius: 14px }` — between `--r-s` (10) and `--r-m` (16).
  static const double iconTileRadius = 14;

  /// `.ic / .person { border: 1.5px solid var(--line) }` hairline.
  static const double hairline = 1.5;

  /// `.save { padding: 0 18px }`.
  static const double savePadding = 18;

  /// `.save { min-width: 64px }`.
  static const double saveMinWidth = 64;

  /// `.cancel` is a bare `<button>`, so the browser's 6px side padding
  /// sits between the sheet gutter and the label. Reproduced here so the
  /// header title lands where the design puts it (the title is centred in
  /// the space the two side buttons leave free).
  static const double cancelPadding = 6;

  /// `.due { min-height: 56px }` — the due row is taller than the 44px
  /// tap minimum (matches `.list-row`'s 56 minimum).
  static const double dueRowMinHeight = 56;
}

/// `.switchrow .tt` — 16/22 w600. The scale's [NestType.bodyStrong] is
/// 16/24 w700, so both the weight and the line height are overridden here
/// (screen wins, same rule as [NestButton]'s contextual overrides).
TextStyle questCardTitle(NestTokens tokens) =>
    NestType.bodyStrong(color: tokens.ink)
        .copyWith(fontWeight: FontWeight.w600, height: 22 / 16);

/// P09 `.lbl` — the small 13/18 w600 ink-2 label above every control group
/// ("Icon", "Who's it for?", "Repeats"). Not `NestSectionLabel`: the design
/// uses sentence case here, not the uppercase section label.
class QuestEditorLabel extends StatelessWidget {
  const new(this.label, {super.key, this.semanticHeader = false});

  final String label;

  /// Marks the group label as a semantic header for screen readers.
  final bool semanticHeader;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: context.nestText.fieldLabel,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    if (semanticHeader) {
      return Semantics(header: true, child: text);
    }
    return text;
  }
}

/// `.sheet-top .cancel` — text-only header action, ink-2 16 w600, 44 tap box.
class QuestCancelButton extends StatelessWidget {
  const new({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Semantics(
      button: true,
      label: 'Cancel',
      // One node per control: the label above owns the announcement and the
      // inner Text contributes no second copy, so VoiceOver says "Cancel,
      // button" (not "Cancel, Cancel, button"). `onTap` mirrors the InkWell
      // because `excludeSemantics` drops every descendant action.
      excludeSemantics: true,
      onTap: onPressed,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: NestDevice.tapParent,
              minHeight: NestDevice.tapParent,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: QuestEditorMetrics.cancelPadding,
              ),
              child: Center(
                child: Text(
                  'Cancel',
                  style: NestType.bodyStrong(color: tokens.ink2)
                      .copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.save` — leaf pill, min 64x44, 16 w700 label, `--surface` on leaf.
///
/// Screen-local because no shared component matches: the header pill is
/// 44 high (not [NestButton]'s 52) and its label is `--surface`, which is
/// the dark surface colour in the dark theme (see the dark design PNG).
class QuestSavePill extends StatelessWidget {
  const new({required this.onPressed, super.key});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Save',
      // One node per control (see [QuestCancelButton]); a disabled pill keeps
      // its label, reports `enabled: false` and exposes no tap action.
      excludeSemantics: true,
      onTap: onPressed,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Material(
          color: Colors.transparent,
          borderRadius: NestRadii.allPill,
          child: InkWell(
            borderRadius: NestRadii.allPill,
            onTap: onPressed,
            child: Container(
              constraints: const BoxConstraints(
                minWidth: QuestEditorMetrics.saveMinWidth,
                minHeight: NestDevice.tapParent,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: QuestEditorMetrics.savePadding,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tokens.leaf,
                borderRadius: NestRadii.allPill,
              ),
              child: Text(
                'Save',
                style: NestType.buttonLabel(color: tokens.surface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.ic` — 44x44 icon tile: radius 14, 1.5px `--line` border on `--surface`;
/// `.ic.sel` swaps to a leaf border, `--leaf-tint` fill and `--leaf-ink`
/// glyph.
class QuestIconTile extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final radius = BorderRadius.circular(QuestEditorMetrics.iconTileRadius);
    final shape = RoundedRectangleBorder(
      borderRadius: radius,
      side: BorderSide(
        color: selected ? tokens.leaf : tokens.line,
        width: QuestEditorMetrics.hairline,
      ),
    );
    // `Material.shape` paints the 1.5px border without insetting the child,
    // so the tile measures exactly 44x44 including its border (CSS
    // border-box). A `BoxDecoration` would add the border width on top.
    return Semantics(
      button: true,
      selected: selected,
      label: 'Icon: $label',
      // One node per tile: the `NestIcon` glyph carries no label, and the
      // tap action is mirrored here because `excludeSemantics` drops the
      // InkWell's own.
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected ? tokens.leafTint : tokens.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: SizedBox.square(
            dimension: NestDevice.tapParent,
            child: Center(
              child: NestIcon(
                icon,
                color: selected ? tokens.leafInk : tokens.ink2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.person` — 48-tall assignee pill: radius pill, 1.5px `--line` border on
/// `--surface`, padding `4 14 4 4`, 15 w600 label, optional 32 avatar.
class QuestPersonPill extends StatelessWidget {
  const new({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
    this.avatarInitial,
    this.avatarColour = NestAvatarColor.neutral,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// `null` renders the label alone — the design's "Anyone" pill.
  final String? avatarInitial;
  final NestAvatarColor avatarColour;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    const hairline = QuestEditorMetrics.hairline;
    final shape = RoundedRectangleBorder(
      borderRadius: NestRadii.allPill,
      side: BorderSide(
        color: selected ? tokens.leaf : tokens.line,
        width: hairline,
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      // One node per pill: the avatar initial and the label would otherwise
      // both merge into this node's label ("M\nMaya"). `onTap` mirrors the
      // InkWell because `excludeSemantics` drops the descendant action.
      excludeSemantics: true,
      onTap: onTap,
      // `Material.shape` paints the hairline without insetting the child, so
      // the pill measures exactly 48 high including its border (CSS
      // border-box); the padding carries the extra 1.5 on each side.
      child: Material(
        color: selected ? tokens.leafTint : tokens.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: NestSpacing.s6 * 2),
            child: Padding(
              padding: const EdgeInsets.only(
                left: NestSpacing.s1 + hairline,
                right: NestSpacing.s3 + NestSpacing.gap2 + hairline,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (avatarInitial != null) ...<Widget>[
                    NestAvatar(
                      initial: avatarInitial!,
                      size: NestAvatarSize.s32,
                      color: avatarColour,
                    ),
                    const SizedBox(width: NestSpacing.s2),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: NestType.bodySmallStrong(
                        color: selected ? tokens.leafInk : tokens.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One row of the "Due by" sheet: fixed label, 56 minimum height.
class QuestDueOptionRow extends StatelessWidget {
  const new({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: NestDevice.tapParent),
            child: Center(
              child: Text(
                label,
                style: NestType.bodyStrong(
                  color: selected ? tokens.leafInk : tokens.ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

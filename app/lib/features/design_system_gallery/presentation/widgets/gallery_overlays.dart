import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nestling/core/design_system/design_system.dart';

/// Overlay components: bottom sheet, modal, toast, empty state.
///
/// Each overlay opens live from its button so behaviour can be verified, and
/// renders from the same widget the buttons present.
class GalleryOverlays extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NestSectionLabel(
          key: ValueKey('ds-section-overlays'),
          label: 'Overlays',
        ),
        const SizedBox(height: NestSpacing.s2),
        Wrap(
          spacing: NestSpacing.s2,
          runSpacing: NestSpacing.s2,
          children: [
            NestButton(
              label: 'Sheet',
              variant: NestButtonVariant.secondary,
              fullWidth: false,
              minHeight: 44,
              onPressed: () => showNestBottomSheet<void>(
                context,
                title: 'Choose a quest',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NestListRow(
                      title: 'Put the bins out',
                      subtitle: '15 coins',
                      leadingAsset: NestIcons.bin,
                      tint: NestTileTint.leaf,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    NestListRow(
                      title: 'Read for 20 minutes',
                      subtitle: '10 coins',
                      leadingAsset: NestIcons.book,
                      tint: NestTileTint.sky,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
            NestButton(
              label: 'Modal',
              variant: NestButtonVariant.secondary,
              fullWidth: false,
              minHeight: 44,
              onPressed: () => showNestModal<void>(
                context,
                title: 'Grown-ups only',
                child: Text(
                  'Type the answer: seven times six.',
                  style: NestType.bodySmall(color: context.nest.ink2),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            NestButton(
              label: 'Toast',
              variant: NestButtonVariant.secondary,
              fullWidth: false,
              minHeight: 44,
              onPressed: () =>
                  showNestToast(context, 'Quest approved · +15 coins'),
            ),
          ],
        ),
        const SizedBox(height: NestSpacing.s4),
        const NestSectionLabel(
          key: ValueKey('ds-section-empty-state'),
          label: 'Empty state',
        ),
        const SizedBox(height: NestSpacing.s2),
        NestEmptyState(
          art: SvgPicture.asset(
            NestlingIllustrations.pipStage1,
            width: 160,
            height: 160,
            placeholderBuilder: (context) => const SizedBox.shrink(),
          ),
          title: 'Your nest is quiet',
          message: 'Add your first quest and Pip will start to hatch.',
          action: NestButton(
            label: 'Add a quest',
            fullWidth: false,
            minHeight: 44,
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}

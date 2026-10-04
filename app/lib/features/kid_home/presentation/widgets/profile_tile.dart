import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/presentation/widgets/kid_style_helpers.dart';

/// K01 profile tile (`.k1-tile`): a huge pressable card with the child's
/// avatar, nickname, age band and their own Pip.
///
/// Layout mirrors the HTML: surface card, 3 px ink border, r-xl (32),
/// `--sh-kid` shadow, centred column (gap 8, pet has its own 10 px top
/// margin on top of that gap — hence the [Padding] on the pet circle),
/// `min-height: 336`. When the tile is narrower than 150 px (320 px
/// screens) it switches to compact metrics: smaller avatar, smaller pet
/// circle, Pip to match. The name stays 28 px with ellipsis.
class ProfileTile extends StatefulWidget {
  const new({required this.child, required this.onSelected, super.key});

  final KidChild child;
  final VoidCallback onSelected;

  /// Tile key used by tests: `k01-tile-maya` / `k01-tile-leo`.
  static ValueKey<String> keyFor(KidChild child) =>
      ValueKey<String>('k01-tile-${child.id}');

  @override
  State<ProfileTile> createState() => _ProfileTileState();
}

class _ProfileTileState extends State<ProfileTile> {
  /// Tap guard: only one selection event per gesture burst; released on the
  /// next frame (K03 `_QuestCard` pattern). A second tap after the route
  /// pops back is a fresh gesture and works again.
  bool _busy = false;

  void _tap() {
    if (_busy) return;
    setState(() => _busy = true);
    widget.onSelected();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _busy) setState(() => _busy = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final child = widget.child;
    final ageLine = switch (child.ageBand) {
      final band when band.isNotEmpty => 'Age ${band.replaceAll('-', '–')}',
      _ => null,
    };
    return Semantics(
      button: true,
      enabled: true,
      label: ageLine == null ? child.nickname : '${child.nickname}, $ageLine',
      onTap: _tap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 336),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: NestRadii.allXl,
          border: Border.all(color: tokens.ink, width: 3),
          boxShadow: tokens.kidShadow,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: NestRadii.allXl,
          child: InkWell(
            borderRadius: NestRadii.allXl,
            onTap: _tap,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 150;
                final avatarSize = compact
                    ? NestAvatarSize.s64
                    : NestAvatarSize.s96;
                final petDiameter = compact ? 96.0 : 132.0;
                final pipSize = compact ? 80.0 : 112.0;
                final stage = child.pipStage.clamp(1, 4);
                return SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: NestSpacing.s2,
                      children: [
                        ExcludeSemantics(
                          child: NestAvatar(
                            initial: child.nickname.isEmpty
                                ? '?'
                                : child.nickname[0].toUpperCase(),
                            size: avatarSize,
                            color: avatarColorOf(child.avatarColour),
                          ),
                        ),
                        ExcludeSemantics(
                          child: Text(
                            child.nickname,
                            style: NestType.h1(color: tokens.ink)
                                .copyWith(height: 32 / 28),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (ageLine != null)
                          ExcludeSemantics(
                            child: Text(
                              ageLine,
                              style: NestType.kidCaption(color: tokens.ink2),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        else
                          // Keep the 8 px rhythm and the tile's height
                          // identical to a tile that HAS an age band.
                          const SizedBox(height: 20),
                        // `.k1-pet { margin-top: 10px }` on top of the
                        // column's 8 px gap → 18 px above the circle.
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Semantics(
                            image: true,
                            label: 'Pip the ${pipStageName(stage)}',
                            excludeSemantics: true,
                            child: Container(
                              width: petDiameter,
                              height: petDiameter,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: switch (avatarColorOf(
                                  child.avatarColour,
                                )) {
                                  NestAvatarColor.peach => tokens.peachTint,
                                  NestAvatarColor.sky => tokens.skyTint,
                                  NestAvatarColor.leaf => tokens.leafTint,
                                  NestAvatarColor.coin => tokens.coinTint,
                                  NestAvatarColor.neutral => tokens.surface2,
                                  NestAvatarColor.lilac => tokens.lilacTint,
                                },
                              ),
                              alignment: Alignment.center,
                              child: PipAvatar(
                                style: pipStyleOf(child.pipStyle),
                                stage: stage,
                                skin: pipSkinOf(child.pipSkin),
                                accessory: pipAccessoryOf(child.pipAccessory),
                                size: pipSize,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

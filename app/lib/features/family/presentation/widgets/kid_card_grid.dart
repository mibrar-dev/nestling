import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/family/domain/entities/family_child.dart';
import 'package:nestling/features/family/family_routes.dart';
import 'package:nestling/features/family/presentation/widgets/child_display.dart';

/// P05 already-added children: a 2-up grid that hugs its content.
///
/// Column widths are computed (`(W − 40 − 10) / 2`, never a fixed 170) and
/// the row height is derived from the card content scaled by the ambient
/// [TextScaler], so cards hug at 320 px wide and at text scale 1.3 alike.
class KidCardGrid extends StatelessWidget {
  const KidCardGrid({required this.children, super.key});

  final List<FamilyChild> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScaler = MediaQuery.textScalerOf(context);
        const verticalChrome = NestSpacing.s3 + NestSpacing.gap10;
        final cardH =
            verticalChrome +
            NestAvatarSize.s44.dimension +
            NestSpacing.gap2 +
            textScaler.scale(24) +
            NestSpacing.s1 +
            textScaler.scale(18) +
            NestSpacing.gap10;
        final colW = (constraints.maxWidth - NestSpacing.gap10) / 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: NestSpacing.gap10,
            mainAxisSpacing: NestSpacing.gap10,
            childAspectRatio: colW / cardH,
          ),
          itemBuilder: (context, index) => _KidCard(child: children[index]),
        );
      },
    );
  }
}

class _KidCard extends StatelessWidget {
  const _KidCard({required this.child});

  final FamilyChild child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final nickname = child.nickname;
    final initial = nickname.isNotEmpty ? nickname[0].toUpperCase() : '?';
    return NestCard(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              NestSpacing.gap10,
              NestSpacing.s3,
              NestSpacing.gap10,
              NestSpacing.gap10,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NestAvatar(
                    initial: initial,
                    color: avatarColourFor(child.avatarColour),
                  ),
                  const SizedBox(height: NestSpacing.gap2),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      nickname,
                      style: NestType.h3(color: tokens.ink),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: NestSpacing.s1),
                  Text(
                    'Age ${displayAgeBand(child.ageBand)}',
                    style: NestType.caption(color: tokens.ink2),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          // Mirrors `.edit { top: 1px; right: 1px }` — NestSpacing has no
          // 1 px step, so the design value stands with this note.
          Positioned(
            top: 1,
            right: 1,
            child: Semantics(
              button: true,
              label: 'Edit $nickname',
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(NestSpacing.s3),
                child: InkWell(
                  key: Key('editChild-${child.id}'),
                  borderRadius: BorderRadius.circular(NestSpacing.s3),
                  // Same contract as P08 kid cards (today_loaded_body.dart):
                  // the child profile is a StatefulShellRoute branch page
                  // reached with `go` + `?childId=` — `push` + `extra` does
                  // not navigate there (see 2_build.md).
                  onTap: () => context.go(
                    '${FamilyRoutePaths.childProfile}?childId=${child.id}',
                  ),
                  child: SizedBox(
                    width: NestDevice.tapParent,
                    height: NestDevice.tapParent,
                    child: Center(
                      child: NestIcon(
                        NestIcons.edit,
                        size: 20,
                        color: tokens.ink3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

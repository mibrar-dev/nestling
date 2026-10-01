import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';

/// Kid section: everything inside a [KidScope] on the day-sky background.
///
/// Mirrors section 5 of `design/html-source/design-system.html`: Nunito,
/// chunky 64px buttons, 56px targets, no red.
class GalleryKid extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return KidScope(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Let's do some quests!",
              style: NestType.kidTitle(color: context.nest.ink),
            ),
            Text(
              'Tap a quest when you finish it.',
              style: NestType.kidBody(color: context.nest.ink),
            ),
            const SizedBox(height: NestSpacing.s3),
            NestKidButton(label: 'I did it!', onPressed: () {}),
            const SizedBox(height: NestSpacing.s3),
            NestKidButton(
              label: 'Shop',
              color: NestKidButtonColor.coin,
              onPressed: () {},
            ),
            const SizedBox(height: NestSpacing.s3),
            Row(
              children: [
                Expanded(
                  child: NestKidButton(
                    label: 'Pip',
                    color: NestKidButtonColor.lilac,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: NestSpacing.s3),
                Expanded(
                  child: NestKidButton(
                    label: 'Play',
                    color: NestKidButtonColor.peach,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: NestSpacing.s3),
                Expanded(
                  child: NestKidButton(
                    label: 'Bath',
                    color: NestKidButtonColor.sky,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: NestSpacing.s3),
            const NestKidQuestCard(
              title: 'Tidy your bedroom',
              coinAmount: '15',
            ),
            const SizedBox(height: NestSpacing.s3),
            const _KidQuestDoneDemo(),
            const SizedBox(height: NestSpacing.s3),
            const NestPetStage(speech: "Let's do some quests!", pipSize: 160),
            const SizedBox(height: NestSpacing.s2),
            const NestProgress(fraction: 0.7, kid: true),
            const SizedBox(height: NestSpacing.s3),
            const NestPinDots(total: 4, filled: 2),
            const SizedBox(height: NestSpacing.s3),
            Align(
              alignment: Alignment.centerRight,
              child: NestLockButton(onPressed: () {}),
            ),
          ],
        ),
      ),
    );
  }
}

class _KidQuestDoneDemo extends StatefulWidget {
  const new();

  @override
  State<_KidQuestDoneDemo> createState() => _KidQuestDoneDemoState();
}

class _KidQuestDoneDemoState extends State<_KidQuestDoneDemo> {
  bool done = true;

  @override
  Widget build(BuildContext context) {
    return NestKidQuestCard(
      title: 'Empty the dishwasher',
      coinAmount: '20',
      done: done,
      onToggled: (next) => setState(() => done = next),
    );
  }
}

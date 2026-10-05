import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/design_system/design_system.dart' hide PipMood;
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/kid_home/kid_home_routes.dart';
import 'package:nestling/features/kid_jar/domain/entities/payout_celebration.dart';
import 'package:nestling/features/kid_jar/presentation/bloc/kid_jar_bloc.dart';
import 'package:nestling/features/kid_jar/presentation/bloc/kid_jar_event.dart';
import 'package:nestling/features/kid_jar/presentation/bloc/kid_jar_state.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/jar_amounts.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/payout_fund_card.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/payout_jar_rain.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/payout_note.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/pip_look.dart';
import 'package:nestling/features/parental_gate/parental_gate_routes.dart';

/// Screen copy, transcribed character-by-character from
/// `design/html-source/screens/K10-payout-day.html`. Only the amounts, the
/// goal figures, the child's nickname and Pip's look come from the database
/// (DATA OVER MOCKS).
abstract final class PayoutDayCopy {
  const new _();

  /// `K10:39` — a straight apostrophe (U+0027, byte-checked).
  static const String title = "It's payout day!";

  static const String back = 'Back';
  static const String grownUps = 'Grown-ups';
  static const String thanks = 'Thanks Mum!';
  static const String noteOneSub = 'Pocket money for this week';
  static const String noteTwoSub = 'Just like you asked';

  /// No source in the HTML (the design has no loading or error frame) —
  /// `1_plan.md` §d, kid voice.
  static const String loading = 'Loading payout day';
  static const String loadError = 'Oh no! Something went wrong.';
  static const String tryAgain = 'Try again';
  static const String empty = 'No payout yet';
  static const String emptyBody =
      'When Mum marks your pocket money as paid, the celebration starts here.';
  static const String backHome = 'Back home';

  static String paid(String amount) => 'Mum marked $amount as paid';
  static String movedTo(String amount, String goal) =>
      '$amount went into your $goal';
  static String pipSays(String nickname) => 'Pip says well done, $nickname!';
}

/// K10 Payout day (`/payout-day`) — the celebration after a payout lands:
/// the paid note, the savings note (when money moved), the live goal card,
/// cheering Pip and the `Thanks Mum!` bar.
///
/// Geometry, measured off `design/screens/light/K10-payout-day.png`:
/// status bar 0…47, back/lock row 47…107, then the `.scroll` 107…721 —
/// title 107…141, rain 141…411 (`.rain` carries no top margin), note 1
/// 427…493, note 2 509…575, fund 591…, Pip row below the fold — and the
/// `.kid-bar` 721…844, its 3 px surface running to the physical edge (the
/// mock pill strip the HTML still shows underneath is overridden by the
/// bottom-edge rule).
class PayoutDayView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return KidScope(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            const NestStatusBar(),
            const _PayoutTopRow(),
            Expanded(
              child: BlocBuilder<KidJarBloc, KidJarState>(
                builder: (context, state) {
                  return switch (state.status) {
                    KidJarStatus.initial ||
                    KidJarStatus.loading => const _PayoutLoading(),
                    KidJarStatus.failure => _PayoutFailure(
                      message: state.errorMessage,
                    ),
                    KidJarStatus.loaded =>
                      state.payout == null
                          ? const _PayoutEmpty()
                          : _PayoutBody(payout: state.payout!),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.nav-back.lg` chevron, 26 px (`K09:13`/`K10` share the glyph).
const double _backIconSize = 26;

/// `.krow-top` (`K10:15,37`): `padding: 0 20px 4px`, back left (transparent —
/// `.nav-back` has no fill), the parental-gate lock pushed right.
class _PayoutTopRow extends StatelessWidget {
  const _PayoutTopRow();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NestSpacing.padSide,
        0,
        NestSpacing.padSide,
        NestSpacing.s1,
      ),
      child: Row(
        children: [
          NestIconButton(
            icon: NestIcons.back,
            semanticLabel: PayoutDayCopy.back,
            size: NestDevice.tapKid,
            iconSize: _backIconSize,
            backgroundColor: Colors.transparent,
            borderColor: Colors.transparent,
            foregroundColor: tokens.ink,
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(KidHomeRoutePaths.home);
              }
            },
          ),
          const Spacer(),
          const _GateLockButton(),
        ],
      ),
    );
  }
}

/// Parental-gate lock with a tap guard (K08/K09 precedent).
class _GateLockButton extends StatefulWidget {
  const _GateLockButton();

  @override
  State<_GateLockButton> createState() => _GateLockButtonState();
}

class _GateLockButtonState extends State<_GateLockButton> {
  bool _busy = false;

  Future<void> _open() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await context.push(ParentalGateRoutePaths.gate);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NestLockButton(
      semanticLabel: PayoutDayCopy.grownUps,
      onPressed: _open,
    );
  }
}

/// The loaded screen: scroll + fixed bar, laid out in a column.
class _PayoutBody extends StatelessWidget {
  const _PayoutBody({required this.payout});

  final PayoutCelebration payout;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              NestSpacing.padSide,
              0,
              NestSpacing.padSide,
              NestSpacing.s8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: NestBalancedText(
                      PayoutDayCopy.title,
                      style: NestType.kidTitle(color: tokens.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // `.rain { margin: 0 auto }` clears the base 16 px rhythm.
                const Center(child: PayoutJarRain()),
                const SizedBox(height: NestSpacing.s4),
                PayoutNote(
                  disc: _CheckDisc(),
                  title: PayoutDayCopy.paid(jarPounds(payout.paidPence)),
                  subtitle: PayoutDayCopy.noteOneSub,
                ),
                if (payout.movedPence != null) ...[
                  const SizedBox(height: NestSpacing.s4),
                  PayoutNote(
                    disc: _MovedDisc(),
                    title: PayoutDayCopy.movedTo(
                      jarPounds(payout.movedPence!),
                      payout.goalTitle,
                    ),
                    subtitle: PayoutDayCopy.noteTwoSub,
                  ),
                ],
                const SizedBox(height: NestSpacing.s4),
                PayoutFundCard(payout: payout),
                const SizedBox(height: NestSpacing.s4),
                _PayoutPip(payout: payout),
              ],
            ),
          ),
        ),
        // Bottom edge (owner rule): the bar's own surface runs to the
        // physical screen edge — the `SafeArea` inset sits INSIDE the surface
        // box, so no meadow/sky strip shows under it. Same shape as K04.
        Container(
          decoration: BoxDecoration(
            color: tokens.surface,
            border: Border(top: BorderSide(color: tokens.ink, width: 3)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              // `.kid-bar { padding: 12px 20px 10px }`; the button's own
              // 6 px shadow room hands 6 of the 10 px back (K04 comment).
              padding: const EdgeInsets.fromLTRB(
                NestSpacing.padSide,
                NestSpacing.s3,
                NestSpacing.padSide,
                NestSpacing.s1,
              ),
              child: NestKidButton(
                label: PayoutDayCopy.thanks,
                onPressed: () => context.go(KidHomeRoutePaths.home),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// `.k10-ico` (leaf): check glyph for the paid receipt (`K10:76`).
class _CheckDisc extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: tokens.leafTint, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: NestIcon(NestIcons.check, size: 22, color: tokens.leafInk),
    );
  }
}

/// `.k10-ico` (lilac): the circle+arrow glyph for the savings move
/// (`K10:80`) — drawn feature-privately; no NestIcons glyph matches it.
class _MovedDisc extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: tokens.lilacTint,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: 22,
        height: 22,
        child: CustomPaint(painter: _CircleArrowPainter(color: tokens.ink)),
      ),
    );
  }
}

class _CircleArrowPainter extends CustomPainter {
  _CircleArrowPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    canvas
      ..drawCircle(const Offset(9.5, 15), 5.5, box)
      ..drawPath(
        Path()
          ..moveTo(17.5, 12)
          ..lineTo(17.5, 4)
          ..moveTo(17.5, 4)
          ..lineTo(15, 6.5)
          ..moveTo(17.5, 4)
          ..lineTo(20, 6.5),
        box,
      );
  }

  @override
  bool shouldRepaint(covariant _CircleArrowPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// rows as adjacent image/bubble siblings that merge into one announcement
/// (K04 adjacency precedent).
class _PayoutPip extends StatelessWidget {
  const _PayoutPip({required this.payout});

  final PayoutCelebration payout;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: NestSpacing.s3,
      children: [
        Semantics(
          image: true,
          label: 'Pip cheering',
          excludeSemantics: true,
          child: PipAvatar(
            style: pipStyleOf(payout.pipStyle),
            stage: payout.pipStage.clamp(1, 4),
            skin: pipSkinOf(payout.pipSkin),
            accessory: pipAccessoryOf(payout.pipAccessory),
            mood: PipMood.happy,
            size: 72,
          ),
        ),
        Flexible(
          child: NestSpeechBubble(text: PayoutDayCopy.pipSays(payout.nickname)),
        ),
      ],
    );
  }
}

/// First load and guarded reload: sky, meadow and chrome stay put.
class _PayoutLoading extends StatelessWidget {
  const _PayoutLoading();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Center(
      child: Semantics(
        label: PayoutDayCopy.loading,
        liveRegion: true,
        child: CircularProgressIndicator(color: tokens.leaf),
      ),
    );
  }
}

/// Stream failure: kid-friendly line and a `Try again` that reloads.
class _PayoutFailure extends StatelessWidget {
  const _PayoutFailure({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: NestSpacing.padSide),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NestIcon(NestIcons.jar, size: 96, color: tokens.ink3),
            const SizedBox(height: NestSpacing.s4),
            Text(
              PayoutDayCopy.loadError,
              style: NestType.kidBody(color: tokens.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: NestSpacing.s4),
            NestKidButton(
              label: PayoutDayCopy.tryAgain,
              color: NestKidButtonColor.white,
              fullWidth: false,
              onPressed: () =>
                  context.read<KidJarBloc>().add(const KidJarPayoutRequested()),
            ),
          ],
        ),
      ),
    );
  }
}

/// No payout has landed yet: the same shape with a `Back home` button.
class _PayoutEmpty extends StatelessWidget {
  const _PayoutEmpty();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: NestSpacing.padSide),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NestIcon(NestIcons.jar, size: 96, color: tokens.ink3),
            const SizedBox(height: NestSpacing.s4),
            Text(
              PayoutDayCopy.empty,
              style: NestType.kidBody(color: tokens.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: NestSpacing.s2),
            Text(
              PayoutDayCopy.emptyBody,
              style: NestType.kidCaption(color: tokens.ink2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: NestSpacing.s4),
            NestKidButton(
              label: PayoutDayCopy.backHome,
              color: NestKidButtonColor.white,
              fullWidth: false,
              onPressed: () => context.go(KidHomeRoutePaths.home),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/kid_home/kid_home_routes.dart';
import 'package:nestling/features/kid_jar/presentation/bloc/kid_jar_bloc.dart';
import 'package:nestling/features/kid_jar/presentation/bloc/kid_jar_event.dart';
import 'package:nestling/features/kid_jar/presentation/bloc/kid_jar_state.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/jar_amounts.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/jar_goal_card.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/jar_history_card.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/jar_illustration.dart';
import 'package:nestling/features/parental_gate/parental_gate_routes.dart';

/// Screen copy, transcribed character-by-character from
/// `design/html-source/screens/K09-jar.html`. The static lines are the design's
/// own; only the weekday, the amounts and the goal figures come from the
/// database (DATA OVER MOCKS).
abstract final class MyJarCopy {
  const new _();

  /// `K09-jar.html:47`
  static const String title = 'My jar';

  /// `K09-jar.html:45` — `.nav-back` aria-label.
  static const String back = 'Back';

  /// `K09-jar.html:45` — `.lock-btn` aria-label.
  static const String grownUps = 'Grown-ups';

  /// `K09-jar.html:69` — `coming on Saturday`.
  static const String comingOnPrefix = 'coming on';

  /// `K09-jar.html:82`
  static const String whatWentIn = 'What went in';

  /// `K09-jar.html:100` — centred `.kcap`, one paragraph.
  static const String footer =
      'Mum keeps the real money. This jar just shows how well you have done.';

  static String comingOn(String weekday) => '$comingOnPrefix $weekday';

  /// No source in the HTML (the design has no loading or error frame) —
  /// `1_plan.md` §d, kid voice.
  static const String loading = 'Loading your jar';
  static const String loadError = 'Oh no! Something went wrong.';
  static const String tryAgain = 'Try again';
}

/// K09 My jar (`/my-jar`) — the only kid screen in pounds: the jar
/// illustration, what is owed and on which weekday, the savings goal and every
/// line of money that went in.
///
/// Layout is the HTML's, measured off `design/screens/light/K09-jar.png`:
/// status bar 47, `.krow-top` 47…107 (56 px back / lock boxes, 4 px below),
/// then the `.scroll` column — title 107…141, jar 151…371, amount 377…421,
/// "coming on …" 423…449, goal card 465…618, "What went in" 634…660, history
/// card 676…. K09 has no bar of its own, so the shared meadow runs to the
/// physical bottom edge (BOTTOM EDGE owner rule) and the scroll carries the
/// home-indicator reserve in its tail padding.
class MyJarView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return KidScope(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              const NestStatusBar(),
              const _JarTopRow(),
              Expanded(
                child: BlocBuilder<KidJarBloc, KidJarState>(
                  builder: (context, state) {
                    return switch (state.status) {
                      KidJarStatus.initial ||
                      KidJarStatus.loading => const _JarLoading(),
                      KidJarStatus.failure => const _JarFailure(),
                      KidJarStatus.loaded => _JarBody(state: state),
                    };
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.nav-back.lg` chevron, 26 px (`K09-jar.html:13,45`). No token carries 26.
const double _backIconSize = 26;

/// `.krow-top` (`K09-jar.html:16,45`): `padding: 0 20px 4px`, back on the left
/// (transparent — `.nav-back` has no fill), the parental-gate lock pushed to
/// the right gutter. Both boxes are 56 (`--tap-kid`).
class _JarTopRow extends StatelessWidget {
  const _JarTopRow();

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
            semanticLabel: MyJarCopy.back,
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

/// Parental-gate lock with a tap guard: one `/parental-gate` push per gesture
/// burst, even on a fast double tap (K08 `_GateLockButton` precedent).
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
    return NestLockButton(semanticLabel: MyJarCopy.grownUps, onPressed: _open);
  }
}

/// The loaded screen: `.scroll` (`K09-jar.html:46-101`) with its
/// `--s4` separators. The tail padding is the design's `--s8` plus the
/// `--home-h` reserve the design keeps in a sibling element, so the last line
/// clears the OS home indicator exactly as it does in the design.
class _JarBody extends StatelessWidget {
  const _JarBody({required this.state});

  final KidJarState state;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final hasGoal = state.goalTargetPence > 0;
    final savedFraction = hasGoal
        ? (state.goalSavedPence / state.goalTargetPence).clamp(0.0, 1.0)
        : 0.0;
    final percent = (savedFraction * 100).round();
    final amount = jarPounds(state.owedPence);
    final children = <Widget>[
      Semantics(
        header: true,
        child: NestBalancedText(
          MyJarCopy.title,
          style: NestType.kidTitle(color: tokens.ink),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      const SizedBox(height: NestSpacing.gap10),
      Center(
        child: JarIllustration(
          fillFraction: savedFraction,
          percentLabel: percent,
        ),
      ),
      const SizedBox(height: NestSpacing.gap6),
      // The amount and its weekday are one spoken sentence ("£4.20 coming on
      // Saturday", `1_plan.md` §e) and stay two centred lines on screen.
      Semantics(
        label: '$amount ${MyJarCopy.comingOn(state.nextPayoutDay)}',
        excludeSemantics: true,
        child: Column(
          children: [
            // `.k9-amt .money` — Nunito 40/44. `.money` sets `font-weight:700`
            // and comes after `.kid-hero` in the cascade, so the design's hero
            // amount is Bold, not Black (measured stem 0.12 em on the PNG).
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                amount,
                style: NestType.kidHero(color: tokens.ink).copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
                maxLines: 1,
                softWrap: false,
              ),
            ),
            const SizedBox(height: NestSpacing.gap2),
            Text(
              MyJarCopy.comingOn(state.nextPayoutDay),
              style: NestType.kidBody(color: tokens.ink2),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      const SizedBox(height: NestSpacing.s4),
      if (hasGoal) ...<Widget>[
        JarGoalCard(
          title: state.goalTitle,
          savedPence: state.goalSavedPence,
          targetPence: state.goalTargetPence,
        ),
        const SizedBox(height: NestSpacing.s4),
      ],
      NestBalancedText(
        MyJarCopy.whatWentIn,
        style: NestType.kidTitle(color: tokens.ink)
            .copyWith(fontSize: 20, height: 26 / 20),
        textAlign: TextAlign.start,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: NestSpacing.s4),
      JarHistoryCard(items: state.items),
      const SizedBox(height: NestSpacing.s4),
      Text(
        MyJarCopy.footer,
        style: NestType.kidCaption(color: tokens.ink2),
        textAlign: TextAlign.center,
      ),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        NestSpacing.padSide,
        0,
        NestSpacing.padSide,
        NestDevice.homeH + NestSpacing.s8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// First load and guarded reload: sky, meadow and chrome stay put, so the
/// screen never flashes a bare scaffold.
class _JarLoading extends StatelessWidget {
  const _JarLoading();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Center(
      child: Semantics(
        label: MyJarCopy.loading,
        child: CircularProgressIndicator(color: tokens.leaf),
      ),
    );
  }
}

/// Stream failure: the kid-friendly line and a `Try again` that re-requests
/// the load. No card frame, because the design has none (K08 precedent).
class _JarFailure extends StatelessWidget {
  const _JarFailure();

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
              MyJarCopy.loadError,
              style: NestType.kidBody(color: tokens.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: NestSpacing.s4),
            NestKidButton(
              label: MyJarCopy.tryAgain,
              color: NestKidButtonColor.white,
              fullWidth: false,
              onPressed: () =>
                  context.read<KidJarBloc>().add(const KidJarLoadRequested()),
            ),
          ],
        ),
      ),
    );
  }
}

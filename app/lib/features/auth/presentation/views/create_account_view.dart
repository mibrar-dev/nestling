import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/auth/domain/auth_repository.dart';
import 'package:nestling/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nestling/features/auth/presentation/bloc/auth_event.dart';
import 'package:nestling/features/auth/presentation/bloc/auth_state.dart';
import 'package:nestling/features/auth/presentation/widgets/apple_glyph.dart';
import 'package:nestling/features/auth/presentation/widgets/google_glyph.dart';
import 'package:nestling/features/onboarding/onboarding_routes.dart';
import 'package:nestling/features/privacy_consent/privacy_consent_routes.dart';

/// P03 Create account — parent-mode form at `/create-account`.
///
/// Static form (no data dependency): the headline, brand buttons, fields,
/// note and bottom CTA render identically whatever the [AuthBloc] status is.
/// The route-level `BlocProvider` in `auth_routes.dart` owns the bloc and its
/// `watchItems()` subscription; `items` are never displayed.
class CreateAccountView extends StatefulWidget {
  const new({super.key});

  @override
  State<CreateAccountView> createState() => _CreateAccountViewState();
}

class _CreateAccountViewState extends State<CreateAccountView> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  /// Headline width cap (P03-BUG-7, ORCHESTRATOR_NOTES §2): with the app's
  /// Nunito 900, "Create your" is 158.6dp and "Create your family" is
  /// 251.2dp, so any cap in [198, 252) breaks the design's
  /// "Create your / family account" (no hard newline) and still wraps
  /// sensibly at 320dp and text scale 1.3.
  static const double _headlineMaxWidth = 240;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(OnboardingRoutePaths.valueTour);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.submitted != current.submitted && current.submitted,
      listener: (context, _) {
        context.read<AuthBloc>().add(const AuthSubmitConsumed());
        context.go(PrivacyConsentRoutePaths.privacy);
      },
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            previous.formError != current.formError &&
            current.formError != null,
        listener: (context, state) async {
          await SemanticsService.sendAnnouncement(
            View.of(context),
            state.formError!,
            TextDirection.ltr,
          );
        },
        child: Scaffold(
          backgroundColor: tokens.paper,
          body: Column(
            children: <Widget>[
              const NestStatusBar(),
              NestNavBar(compact: true, onBack: () => _onBack(context)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    NestSpacing.padSide,
                    0,
                    NestSpacing.padSide,
                    NestSpacing.s8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Semantics(
                        header: true,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _headlineMaxWidth,
                          ),
                          child: Text(
                            'Create your family account',
                            style: NestType.h1(color: tokens.ink),
                            maxLines: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: NestSpacing.s2),
                      Text(
                        'You’re the grown-up in charge. '
                        'Children never need an email.',
                        style: NestType.body(color: tokens.ink2),
                      ),
                      const SizedBox(height: NestSpacing.s6),
                      BlocSelector<AuthBloc, AuthState, bool>(
                        selector: (state) => state.isSubmitting,
                        builder: (context, isSubmitting) {
                          return NestAppleButton(
                            key: const ValueKey('p03_apple'),
                            label: 'Continue with Apple',
                            leading: const ExcludeSemantics(
                              child: AppleGlyph(),
                            ),
                            loading: isSubmitting,
                            onPressed: isSubmitting
                                ? null
                                : () => context.read<AuthBloc>().add(
                                    const AuthSocialSubmitted(
                                      AuthProvider.apple,
                                    ),
                                  ),
                          );
                        },
                      ),
                      const SizedBox(height: NestSpacing.s3),
                      BlocSelector<AuthBloc, AuthState, bool>(
                        selector: (state) => state.isSubmitting,
                        builder: (context, isSubmitting) {
                          return NestGoogleButton(
                            key: const ValueKey('p03_google'),
                            label: 'Continue with Google',
                            leading: const ExcludeSemantics(
                              child: GoogleGlyph(),
                            ),
                            loading: isSubmitting,
                            onPressed: isSubmitting
                                ? null
                                : () => context.read<AuthBloc>().add(
                                    const AuthSocialSubmitted(
                                      AuthProvider.google,
                                    ),
                                  ),
                          );
                        },
                      ),
                      const SizedBox(height: NestSpacing.s4),
                      const _OrRow(),
                      const SizedBox(height: NestSpacing.s4),
                      BlocBuilder<AuthBloc, AuthState>(
                        buildWhen: (previous, current) =>
                            previous.emailError != current.emailError,
                        builder: (context, state) {
                          return NestTextField(
                            key: const ValueKey('p03_email'),
                            label: 'Email',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            errorText: state.emailError,
                            onChanged: (value) => context.read<AuthBloc>().add(
                              AuthEmailChanged(value),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: NestSpacing.s4),
                      BlocBuilder<AuthBloc, AuthState>(
                        buildWhen: (previous, current) =>
                            previous.passwordError != current.passwordError ||
                            previous.formError != current.formError,
                        builder: (context, state) {
                          final errorText =
                              state.passwordError ?? state.formError;
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              NestTextField(
                                key: const ValueKey('p03_password'),
                                label: 'Password',
                                controller: _passwordController,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                errorText: errorText,
                                onChanged: (value) => context
                                    .read<AuthBloc>()
                                    .add(AuthPasswordChanged(value)),
                              ),
                              // P03-BUG-8: the helper is a feature-owned row
                              // on the field gutter (6dp below the input),
                              // not the indented InputDecoration line.
                              // Hidden while an error shows in its place
                              // (the shared field's error row takes over).
                              if (errorText == null) ...[
                                const SizedBox(height: NestSpacing.gap6),
                                Text(
                                  'At least 8 characters',
                                  style: NestType.caption(color: tokens.ink2),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: NestSpacing.s3),
                      Row(
                        spacing: NestSpacing.s2,
                        children: <Widget>[
                          ExcludeSemantics(
                            child: NestIcon(
                              NestIcons.shieldCheck,
                              size: 20,
                              color: tokens.lilac,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              'No child emails or photos — ever.',
                              style: NestType.bodySmallStrong(
                                color: tokens.ink2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return _HitTestExpand(
                    child: NestBottomCta(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          NestButton(
                            key: const ValueKey('p03_submit'),
                            label: 'Create account',
                            loading: state.isSubmitting,
                            onPressed: state.canSubmit
                                ? () => context.read<AuthBloc>().add(
                                    const AuthSubmitted(),
                                  )
                                : null,
                          ),
                          const SizedBox(height: NestSpacing.s2),
                          const _LegalLine(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Divider or divider (HTML `.or-row`, `aria-hidden`).
class _OrRow extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return ExcludeSemantics(
      child: Row(
        children: <Widget>[
          Expanded(child: Divider(height: 1, thickness: 1, color: tokens.line)),
          const SizedBox(width: NestSpacing.s3),
          Text(
            'or',
            style: NestType.caption(color: tokens.ink2)
                .copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: NestSpacing.s3),
          Expanded(child: Divider(height: 1, thickness: 1, color: tokens.line)),
        ],
      ),
    );
  }
}

/// Legal caption (P03-BUG-1/4/9/10/12/13).
///
/// The caption lays out as plain centred text lines at the design's 20dp
/// link-line height (`.link { line-height: 20px }`), so the line breaker
/// flows the words exactly like the design. The two-word label uses U+00A0
/// so it can never split across lines (ORCHESTRATOR_NOTES §5, COPY rule).
/// Each link's 44dp target is an overlay box measured off the laid-out text
/// (post-frame) and centred over its word — the HTML
/// `.link { min-height:44px; margin:-12px 0 }` trick, where the hit box
/// overlaps its line instead of adding layout height. The links are inert in
/// v1 (`TODO(P03)`). Never use `NestBottomCta.caption` here — it cannot
/// render links.
class _LegalLine extends StatefulWidget {
  const new();

  /// Two-word link label joined by U+00A0 NO-BREAK SPACE (COPY rule) so the
  /// line breaker can never split it (P03-BUG-9).
  static const String privacyLabel = 'Privacy Notice';

  @override
  State<_LegalLine> createState() => _LegalLineState();
}

class _LegalLineState extends State<_LegalLine> {
  final GlobalKey _paragraphKey = GlobalKey();

  /// Boxes the overlay currently shows (verification compares against these).
  Rect? _shownTerms;
  Rect? _shownPrivacy;

  /// Remaining post-frame verification passes (P03-BUG-19): a runtime font
  /// swap reflows the paragraph without rebuilding the widget, so a bounded
  /// chain re-checks the real paragraph against what was built.
  int _verifyLeft = 0;
  static const int _verifyBudget = 4;

  /// Hard stop for verification scheduling (P03-BUG-19): even under
  /// permanent drift the chain must end, or `pumpAndSettle` never settles.
  /// Reset on every dependency change below, so it bounds a chain, never
  /// the widget's lifetime.
  int _verifyTotal = 0;
  static const int _verifyTotalCap = 12;

  @override
  void initState() {
    super.initState();
    _verifyLeft = _verifyBudget;
    _scheduleVerify();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The caption's metrics move with these; rebuild re-measures
    // synchronously, and both verification budgets are re-armed.
    MediaQuery.sizeOf(context);
    MediaQuery.textScalerOf(context);
    _verifyLeft = _verifyBudget;
    _verifyTotal = 0;
    _scheduleVerify();
  }

  /// The single span children for the paragraph and the measuring painter,
  /// so the two can never diverge (P03-BUG-19).
  static List<TextSpan> _captionChildren(TextStyle link) => <TextSpan>[
    const TextSpan(text: 'By continuing you agree to our '),
    TextSpan(text: 'Terms', style: link),
    const TextSpan(text: ' and '),
    TextSpan(text: _LegalLine.privacyLabel, style: link),
  ];

  /// Target rects in paragraph coordinates, laid out synchronously with the
  /// same spans, alignment and text metrics the paragraph itself uses — so
  /// the targets exist in the first painted frame (P03-BUG-19). The root
  /// style repeats exactly what `Text.rich` resolves internally
  /// (`DefaultTextStyle` merged with the `style:` argument); without it the
  /// mirror would drift forever and the verification chain below would never
  /// settle. Each target is centred horizontally on its word and vertically
  /// on its *line* (not the glyph box, whose leading offset would make the
  /// overhang lopsided): exactly 12dp of overhang on every side, which
  /// `_HitTestExpand` covers exactly (P03-BUG-18).
  /// Union glyph box for [label] in [plain], via [boxesOf].
  static Rect? _unionBox(
    String plain,
    List<TextBox> Function(TextSelection) boxesOf,
    String label,
  ) {
    final start = plain.indexOf(label);
    if (start < 0) return null;
    Rect? box;
    for (final textBox in boxesOf(
      TextSelection(baseOffset: start, extentOffset: start + label.length),
    )) {
      final rect = textBox.toRect();
      box = box == null ? rect : box.expandToInclude(rect);
    }
    return box;
  }

  /// A 44dp target centred horizontally on [box] and vertically on its line
  /// (not the glyph box, whose leading offset would make the overhang
  /// lopsided): exactly 12dp of overhang on every side, which
  /// `_HitTestExpand` covers exactly (P03-BUG-18).
  static Rect? _targetOnLines(List<LineMetrics> metrics, Rect? box) {
    if (box == null) return null;
    final cy = box.center.dy;
    var y = 0.0;
    for (final metric in metrics) {
      if (cy >= y && cy <= y + metric.height) {
        return Rect.fromCenter(
          center: Offset(box.center.dx, y + metric.height / 2),
          width: math.max(box.width, NestDevice.tapParent),
          height: NestDevice.tapParent,
        );
      }
      y += metric.height;
    }
    return null;
  }

  static ({Rect? terms, Rect? privacy}) _measureSync(
    TextStyle rootStyle,
    List<TextSpan> children,
    TextAlign textAlign,
    TextDirection textDirection,
    TextScaler textScaler,
    Locale? locale,
    double maxWidth,
  ) {
    if (!maxWidth.isFinite || maxWidth <= 0) {
      return (terms: null, privacy: null);
    }
    final painter = TextPainter(
      text: TextSpan(style: rootStyle, children: children),
      textAlign: textAlign,
      textDirection: textDirection,
      textScaler: textScaler,
      locale: locale,
    )..layout(maxWidth: maxWidth);
    final metrics = painter.computeLineMetrics();
    Rect? targetFor(String label) => _targetOnLines(
      metrics,
      _unionBox(
        painter.text!.toPlainText(),
        painter.getBoxesForSelection,
        label,
      ),
    );

    return (
      terms: targetFor('Terms'),
      privacy: targetFor(_LegalLine.privacyLabel),
    );
  }

  void _scheduleVerify() {
    if (_verifyTotal >= _verifyTotalCap) return;
    _verifyTotal++;
    WidgetsBinding.instance.addPostFrameCallback((_) => _verify());
  }

  /// Re-measures the real paragraph and rebuilds on drift (font swaps).
  /// Quiescent trees never call setState, so tests stay deterministic.
  void _verify() {
    if (!mounted || _verifyLeft <= 0) return;
    _verifyLeft--;
    final renderObject = _paragraphKey.currentContext?.findRenderObject();
    final shownTerms = _shownTerms;
    final shownPrivacy = _shownPrivacy;
    if (renderObject is! RenderParagraph ||
        shownTerms == null ||
        shownPrivacy == null) {
      if (_verifyLeft > 0) _scheduleVerify();
      return;
    }
    final paragraph = renderObject;
    // Mirror the paragraph (same resolved text and metrics, like the
    // proofs' own helpers) so real boxes and built targets compare in the
    // same coordinates.
    final mirror = TextPainter(
      text: paragraph.text,
      textAlign: paragraph.textAlign,
      textDirection: paragraph.textDirection,
      textScaler: paragraph.textScaler,
      locale: paragraph.locale,
      maxLines: paragraph.maxLines,
      strutStyle: paragraph.strutStyle,
    )..layout(maxWidth: paragraph.size.width);
    final metrics = mirror.computeLineMetrics();
    final origin = paragraph.localToGlobal(Offset.zero);
    final stack = context.findRenderObject();
    final stackOrigin = stack is RenderBox
        ? stack.localToGlobal(Offset.zero)
        : origin;
    final shift = origin - stackOrigin;
    Rect? targetFor(String label) {
      final target = _targetOnLines(
        metrics,
        _unionBox(
          mirror.text!.toPlainText(),
          mirror.getBoxesForSelection,
          label,
        ),
      );
      return target?.shift(shift);
    }

    if (targetFor('Terms') != shownTerms ||
        targetFor(_LegalLine.privacyLabel) != shownPrivacy) {
      // Fonts (or metrics) moved under us: rebuild re-measures synchronously.
      setState(() {});
      _verifyLeft = _verifyBudget;
    }
    if (_verifyLeft > 0) _scheduleVerify();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    // Design `.link { line-height: 20px }` via the spacing token until
    // `NestType` grows a legal-caption variant (SHARED_REQUEST §7) —
    // every caption line holds a link, so the block is 40dp (P03-BUG-12).
    final base = NestType.caption(color: tokens.ink2)
        .copyWith(height: NestSpacing.s5 / 13);
    final link = NestType.caption(color: tokens.sky).copyWith(
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: tokens.sky,
      height: NestSpacing.s5 / 13,
    );
    // P03-BUG-19: boxes are measured synchronously from the layout
    // constraints (same spans the paragraph lays out, rooted in the same
    // ambient-plus-caption default style `Text.rich` resolves), so the
    // targets exist in the first painted frame.
    return LayoutBuilder(
      builder: (context, constraints) {
        final rootStyle = DefaultTextStyle.of(context).style.merge(base);
        final boxes = _LegalLineState._measureSync(
          rootStyle,
          _LegalLineState._captionChildren(link),
          TextAlign.center,
          Directionality.of(context),
          MediaQuery.textScalerOf(context),
          Localizations.maybeLocaleOf(context),
          constraints.maxWidth,
        );
        final terms = boxes.terms;
        final privacy = boxes.privacy;
        // Recorded for the verification chain (plain fields: assigning
        // during layout is safe, no setState).
        _shownTerms = terms;
        _shownPrivacy = privacy;
        return Semantics(
          label:
              'By continuing you agree to our Terms and ${_LegalLine.privacyLabel}',
          explicitChildNodes: true,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              ExcludeSemantics(
                child: Text.rich(
                  key: _paragraphKey,
                  TextSpan(children: _LegalLineState._captionChildren(link)),
                  style: base,
                  textAlign: TextAlign.center,
                  softWrap: true,
                ),
              ),
              if (terms != null)
                Positioned.fromRect(
                  rect: terms,
                  child: const _LegalTarget(
                    key: ValueKey('p03_terms'),
                    label: 'Terms',
                  ),
                ),
              if (privacy != null)
                Positioned.fromRect(
                  rect: privacy,
                  child: const _LegalTarget(
                    key: ValueKey('p03_privacy'),
                    label: _LegalLine.privacyLabel,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Expands the hit-test area without changing layout (P03-BUG-18).
///
/// The 44dp legal-link targets overhang the 40dp caption block, and every
/// box between the bar and the words bounds-checks taps away — so the
/// overhang would be dead. This wraps the whole bottom bar: taps inside its
/// own box take the normal path (zero behaviour change), while taps in the
/// extra strip are resolved by visiting every descendant directly, so each
/// box applies only its own bounds. Layout size is untouched (the 678
/// hairline holds).
class _HitTestExpand extends SingleChildRenderObjectWidget {
  const _HitTestExpand({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHitTestExpand();
}

class _RenderHitTestExpand extends RenderProxyBox {
  @override
  bool hitTest(BoxHitTestResult entry, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    // Normal path first: taps the layout box resolves keep working exactly
    // as before (a single path, no duplicates).
    var hit = child.hitTest(entry, position: position);
    // Caption overhang (P03-BUG-18/22): points outside the caption Stack
    // never reach the targets through normal descent — the Stack
    // bounds-checks them away, and the bar background's DecoratedBox claims
    // the tap instead (so `hit` is true over the bar's empty area). For
    // those points, descend into the caption Stack's children directly, so
    // every overhanging link box applies its own bounds (P03-BUG-18). Each
    // box still applies its own bounds.
    //
    // The exception is an interactive control: when the normal path already
    // landed on a gesture target (the submit button's strip overlapping a
    // link box), the link must NOT also be collected, or the tap activates
    // both once the routes land (P03-BUG-22). Ancestors add their entries
    // after ours returns, so at this point `entry` holds only the bar
    // subtree's results.
    final stack = _captionStack();
    if (stack != null) {
      final origin = stack.localToGlobal(Offset.zero);
      final mine = localToGlobal(Offset.zero);
      if (!Rect.fromLTWH(
        origin.dx - mine.dx,
        origin.dy - mine.dy,
        stack.size.width,
        stack.size.height,
      ).contains(position)) {
        final ownedByControl = entry.path.any(
          (e) =>
              e.target is RenderPointerListener ||
              e.target is RenderSemanticsGestureHandler,
        );
        if (!ownedByControl) {
          stack.visitChildren((grandchild) {
            if (grandchild is RenderBox) {
              final childOrigin = grandchild.localToGlobal(Offset.zero);
              if (grandchild.hitTest(
                entry,
                position: position - (childOrigin - mine),
              )) {
                hit = true;
              }
            }
          });
        }
      }
    }
    return hit;
  }

  /// The caption Stack, found by descent: the CTA subtree holds exactly one
  /// `Stack` (the caption's own — buttons and bars here are
  /// `GestureDetector`-based, never `Stack`s).
  RenderStack? _captionStack() {
    final child = this.child;
    RenderStack? found;
    void visit(RenderObject object) {
      if (found != null) return;
      if (object is RenderStack) {
        found = object;
        return;
      }
      object.visitChildren(visit);
    }

    if (child != null) visit(child);
    return found;
  }
}

/// One inert legal-link target (P03-BUG-1/4/10/13).
///
/// Carries the `p03_*` key and the exact single-node button semantics. The
/// `Positioned.fromRect` parent gives it tight ≥44×44 constraints, so it
/// fills its measured box over its word.
class _LegalTarget extends StatelessWidget {
  const new({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // TODO(P03): inert — no Terms/Notice routes exist in v1. When they
        // land, note the targets overlap: the Terms box reaches ~4dp into
        // the submit button's row (and the boxes overlap each other where
        // lines stack), so a tap there activates both — keep the submit
        // winning functionally or disambiguate then.
        onTap: () {},
        child: const SizedBox.expand(),
      ),
    );
  }
}

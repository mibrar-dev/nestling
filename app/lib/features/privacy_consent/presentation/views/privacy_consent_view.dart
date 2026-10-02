import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/auth/auth_routes.dart';
import 'package:nestling/features/family/family_routes.dart';
import 'package:nestling/features/privacy_consent/presentation/bloc/privacy_consent_bloc.dart';
import 'package:nestling/features/privacy_consent/presentation/bloc/privacy_consent_event.dart';
import 'package:nestling/features/privacy_consent/presentation/bloc/privacy_consent_state.dart';

/// The four promise titles, shared by the list rows and the Privacy Notice
/// dialog so the copy cannot drift between the two.
const List<String> _promiseTitles = <String>[
  'No ads or tracking — ever',
  'Children only need a nickname',
  'Data stored in the UK (London)',
  'Delete everything anytime',
];

/// P04 · Privacy & consent, route `/privacy`.
///
/// Static parent-mode screen: the four promise rows and the shield render in
/// every bloc status. Only the crash-report toggle is live data (Drift-backed
/// `settings.crashReportConsent`, OFF by default).
class PrivacyConsentView extends StatelessWidget {
  const PrivacyConsentView({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Scaffold(
      backgroundColor: tokens.paper,
      body: Column(
        children: <Widget>[
          const NestStatusBar(),
          NestNavBar(
            compact: true,
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AuthRoutePaths.createAccount);
              }
            },
          ),
          Expanded(
            child: BlocBuilder<PrivacyConsentBloc, PrivacyConsentState>(
              builder: (context, state) {
                final live = state.status == PrivacyConsentStatus.loaded;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    NestSpacing.padSide,
                    0,
                    NestSpacing.padSide,
                    NestSpacing.s8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Semantics(
                        header: true,
                        child: Text(
                          'Your family’s privacy',
                          style: context.nestText.h1,
                        ),
                      ),
                      const SizedBox(height: NestSpacing.s2),
                      Text(
                        'Exactly what we store — and nothing else.',
                        style: NestType.body(color: tokens.ink2),
                      ),
                      const SizedBox(height: NestSpacing.gap14),
                      Center(
                        child: Semantics(
                          label: 'A shield with a leaf and a heart, protecting your family',
                          image: true,
                          child: ExcludeSemantics(
                            child: SvgPicture.asset(
                              NestlingIllustrations.privacyShield,
                              width: 84,
                              height: 84,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: NestSpacing.s4),
                      // Not const: the rows read their titles from the shared
                      // `_promiseTitles` list (also used by the dialog).
                      // One child (a Column) so shared NestList injects no
                      // real Dividers: the design draws the separators as
                      // 1 px overlays, and real Dividers would add 3 px to
                      // the list (P04-4). Each row paints its own overlay
                      // divider instead; the card chrome is unchanged.
                      NestList(
                        children: <Widget>[
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              _PromiseRow(
                                title: _promiseTitles[0],
                                subtitle:
                                    'No analytics profiles, no ad SDKs, ever',
                                leadingAsset: NestIcons.noAds,
                                tint: NestTileTint.leaf,
                              ),
                              _PromiseRow(
                                title: _promiseTitles[1],
                                subtitle:
                                    'No photos, no email, no chat, no location',
                                leadingAsset: NestIcons.person,
                                tint: NestTileTint.lilac,
                                showDivider: true,
                              ),
                              _PromiseRow(
                                title: _promiseTitles[2],
                                subtitle: 'Kept on UK servers, nothing leaves',
                                leadingAsset: NestIcons.pinUk,
                                tint: NestTileTint.sky,
                                showDivider: true,
                              ),
                              _PromiseRow(
                                title: _promiseTitles[3],
                                subtitle:
                                    'One tap and your family data is gone',
                                // TODO(P04): trash-can glyph pending
                                // docs/screens/P04/SHARED_REQUEST.md
                                // (ic_trash.svg + NestIcons.trash). The 40x40
                                // peach tile is reserved; no stand-in icon is
                                // used because ic_bin (cart) and ic_basket
                                // (laundry) misrepresent the design.
                                tint: NestTileTint.peach,
                                showDivider: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: NestSpacing.s4),
                      NestCard(
                        padding: const EdgeInsets.symmetric(
                          vertical: 13,
                          horizontal: NestSpacing.s4,
                        ),
                        child: Row(
                          spacing: NestSpacing.s3,
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                spacing: NestSpacing.gap2,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Optional: help improve Nestling',
                                    style: NestType.body(color: tokens.ink)
                                        .copyWith(
                                          fontWeight: FontWeight.w600,
                                          height: 22 / 16,
                                        ),
                                    softWrap: true,
                                  ),
                                  Text(
                                    'Share anonymous crash reports. '
                                    'No names, no photos.',
                                    style: NestType.bodySmall(
                                      color: tokens.ink2,
                                    ),
                                    softWrap: true,
                                  ),
                                ],
                              ),
                            ),
                            NestToggle(
                              key: const ValueKey('p04_crash_toggle'),
                              value: state.crashConsent,
                              semanticLabel: 'Share anonymous crash reports',
                              onChanged: live
                                  ? (value) =>
                                        context.read<PrivacyConsentBloc>().add(
                                          PrivacyConsentCrashToggled(
                                            value: value,
                                          ),
                                        )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      if (state.status == PrivacyConsentStatus.failure)
                        Padding(
                          padding: const EdgeInsets.only(top: NestSpacing.s2),
                          child: Text(
                            // State-aware (P04-6): "it stays off" is only
                            // true when the prior consent was OFF; a failed
                            // OFF write leaves the opt-in ON, so say so.
                            state.crashConsent
                                ? 'Oops — your choice wasn’t saved. '
                                      'Crash reports are still on. '
                                      'Continue anyway.'
                                : 'Oops — your choice wasn’t saved. '
                                      'Continue anyway; it stays off.',
                            style: NestType.caption(color: tokens.danger),
                            softWrap: true,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          NestBottomCta(
            child: Column(
              spacing: NestSpacing.s2,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                NestButton(
                  key: const ValueKey('p04_continue'),
                  label: 'Continue',
                  onPressed: () => context.go(FamilyRoutePaths.addChildren),
                ),
                const _NoticeLink(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Feature-private promise row.
///
/// Mirrors [NestListRow] geometry (40x40 tile, radius 12, divider indent 72)
/// but P04 wins per SPACING_SPEC §9.3/§9.4: rows pad 7px vertically and
/// title/sub wrap instead of ellipsizing. Rows are display-only (no `onTap`).
///
/// The separator is an overlay, not layout: with [showDivider] the content
/// is wrapped in a [Stack] whose only extra child is a 1 px line
/// positioned over the row's top boundary — the same reference point the
/// design's `::before` (and shared `NestList`'s `indent: 72`) uses — so the
/// line contributes zero height (P04-4). The row is passed without the flag
/// for the first row of a list.
class _PromiseRow extends StatelessWidget {
  const _PromiseRow({
    required this.title,
    required this.subtitle,
    required this.tint,
    this.leadingAsset,
    this.showDivider = false,
  });

  final String title;
  final String subtitle;
  final NestTileTint tint;
  final String? leadingAsset;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final (Color tileBg, Color tileFg) = switch (tint) {
      NestTileTint.neutral => (tokens.surface2, tokens.ink),
      NestTileTint.leaf => (tokens.leafTint, tokens.leafInk),
      NestTileTint.coin => (tokens.coinTint, tokens.coinInk),
      NestTileTint.sky => (tokens.skyTint, tokens.sky),
      NestTileTint.lilac => (tokens.lilacTint, tokens.lilac),
      NestTileTint.peach => (tokens.peachTint, tokens.aPeach),
    };
    final asset = leadingAsset;
    final content = Semantics(
      container: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            NestSpacing.s3,
            NestSpacing.gap7,
            NestSpacing.s4,
            NestSpacing.gap7,
          ),
          child: Row(
            spacing: NestSpacing.s3,
            children: <Widget>[
              Container(
                width: NestSpacing.s10,
                height: NestSpacing.s10,
                decoration: BoxDecoration(
                  color: tileBg,
                  borderRadius: BorderRadius.circular(NestSpacing.s3),
                ),
                alignment: Alignment.center,
                child: asset == null
                    ? const SizedBox.shrink()
                    : NestIcon(asset, color: tileFg),
              ),
              Expanded(
                child: Column(
                  spacing: NestSpacing.gap2,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      style: NestType.bodyStrong(
                        color: tokens.ink,
                      ).copyWith(fontWeight: FontWeight.w600, height: 22 / 16),
                      softWrap: true,
                    ),
                    Text(
                      subtitle,
                      style: NestType.caption(color: tokens.ink2),
                      softWrap: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!showDivider) return content;
    // A Stack sizes to its non-positioned child, so this 1 px line paints
    // over the row boundary without adding layout height. `left: 72`
    // measured from the row's left edge is the same reference point the
    // design's `::before` uses.
    return Stack(
      children: <Widget>[
        content,
        Positioned(
          top: 0,
          left: 72,
          right: 0,
          height: 1,
          child: Divider(height: 1, thickness: 1, color: tokens.line),
        ),
      ],
    );
  }
}

/// Underlined tappable footnote. [NestBottomCta] only takes plain-text
/// `caption`, but the design needs a link, so this is a second child of the
/// bottom-CTA column instead (CTA geometry unchanged).
class _NoticeLink extends StatelessWidget {
  const _NoticeLink();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Semantics(
      button: true,
      label: 'Read the full Privacy Notice',
      container: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: NestDevice.tapParent,
          minWidth: NestDevice.tapParent,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => showNestModal<void>(
            context,
            title: 'Privacy Notice',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: NestSpacing.s2,
              children: <Widget>[
                // The four promises as separate lines (plan §c), reusing the
                // row titles so the copy cannot drift (review finding 7).
                for (final title in _promiseTitles)
                  Text(
                    title,
                    style: NestType.bodySmall(color: tokens.ink2),
                    textAlign: TextAlign.center,
                    softWrap: true,
                  ),
                NestButton(
                  label: 'Close',
                  variant: NestButtonVariant.secondary,
                  minHeight: NestDevice.tapParent,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          child: Center(
            child: ExcludeSemantics(
              child: Text(
                'Read the full Privacy Notice',
                key: const ValueKey('p04_privacy_notice'),
                style: NestType.caption(color: tokens.sky).copyWith(
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationThickness: 1,
                ),
                textAlign: TextAlign.center,
                softWrap: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

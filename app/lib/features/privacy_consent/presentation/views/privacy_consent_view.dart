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
            // TODO(P04): shared NestNavBar bug - compact with null title nests
            // Spacer (Expanded) inside Expanded and throws ParentDataWidget.
            // Empty title renders the same back-only row until core is fixed.
            compact: true,
            title: '',
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
                      const NestList(
                        children: <Widget>[
                          _PromiseRow(
                            title: 'No ads or tracking — ever',
                            subtitle: 'No analytics profiles, no ad SDKs, ever',
                            leadingAsset: NestIcons.noAds,
                            tint: NestTileTint.leaf,
                          ),
                          _PromiseRow(
                            title: 'Children only need a nickname',
                            subtitle:
                                'No photos, no email, no chat, no location',
                            leadingAsset: NestIcons.person,
                            tint: NestTileTint.lilac,
                          ),
                          _PromiseRow(
                            title: 'Data stored in the UK (London)',
                            subtitle: 'Kept on UK servers, nothing leaves',
                            leadingAsset: NestIcons.pinUk,
                            tint: NestTileTint.sky,
                          ),
                          _PromiseRow(
                            title: 'Delete everything anytime',
                            subtitle: 'One tap and your family data is gone',
                            // TODO(P04): trash-can glyph pending
                            // docs/screens/P04/SHARED_REQUEST.md
                            // (ic_trash.svg + NestIcons.trash). The 40x40
                            // peach tile is reserved; no stand-in icon is
                            // used because ic_bin (cart) and ic_basket
                            // (laundry) misrepresent the design.
                            tint: NestTileTint.peach,
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
                            'Oops — your choice wasn’t saved. '
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
/// Mirrors [NestListRow] geometry (40x40 tile, radius 12, divider indent 72
/// from [NestList]) but P04 wins per SPACING_SPEC §9.3/§9.4: rows pad 7px
/// vertically and title/sub wrap instead of ellipsizing. Rows are
/// display-only (no `onTap`).
class _PromiseRow extends StatelessWidget {
  const _PromiseRow({
    required this.title,
    required this.subtitle,
    required this.tint,
    this.leadingAsset,
  });

  final String title;
  final String subtitle;
  final NestTileTint tint;
  final String? leadingAsset;

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
    return Semantics(
      container: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 7, 16, 7),
          child: Row(
            spacing: NestSpacing.s3,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
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
                Text(
                  'No ads or tracking — ever. '
                  'Children only need a nickname. '
                  'Data stored in the UK (London). '
                  'Delete everything anytime.',
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/data/app_clock.dart';
import 'package:nestling/core/data/family_time.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/family/family_routes.dart';
import 'package:nestling/features/paywall/paywall_routes.dart';
import 'package:nestling/features/privacy_consent/privacy_consent_routes.dart';
import 'package:nestling/features/settings/domain/entities/settings_child_entry.dart';
import 'package:nestling/features/settings/domain/entities/settings_member_entry.dart';
import 'package:nestling/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:nestling/features/settings/presentation/bloc/settings_event.dart';
import 'package:nestling/features/settings/presentation/bloc/settings_state.dart';
import 'package:nestling/features/settings/presentation/widgets/p16_transient_guard.dart';
import 'package:nestling/features/settings/presentation/widgets/settings_rows.dart';
import 'package:nestling/features/settings/presentation/widgets/zone_picker_sheet.dart';

/// `.linkrow { min-height: 52px }` (`P16-settings.html:9`) — the
/// subscription card's "Manage subscription" row. Screen-local because the
/// 4pt grid has no 52 (the only other 52 on the platform is
/// `NestPager.stage`, a different metric); filed in SHARED_REQUEST.md §7.
const double _linkRowMinHeight = 52;

/// P16 · Family & settings (`/settings`, parent mode).
///
/// Layout follows `design/html-source/screens/P16-settings.html`: a scroll
/// column with the big title, then Family / Children / Subscription /
/// Time zone / Notifications / Privacy / About sections (20 px side
/// gutters, 16 px between scroll children, section labels 24 above + 8
/// below). The tab bar and home edge belong to `ParentShell`; this view
/// never paints over them.
///
/// All rows are driven by [SettingsState] — the database is the source of
/// truth for toggles, coins, Pip stage names and the zone. The view only
/// maps state to widgets and dispatches events; the loaded streams feed
/// every refresh (no manual reload events).
class SettingsView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Scaffold(
      backgroundColor: tokens.paper,
      body: Column(
        children: <Widget>[
          const NestStatusBar(),
          Expanded(
            child: BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, state) {
                switch (state.status) {
                  case SettingsStatus.initial:
                  case SettingsStatus.loading:
                    return const _SettingsLoading();
                  case SettingsStatus.failure:
                    return const _SettingsFailure();
                  case SettingsStatus.loaded:
                    return _SettingsLoaded(state: state);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsLoading extends StatelessWidget {
  const _SettingsLoading();

  @override
  Widget build(BuildContext context) {
    return Center(child: CircularProgressIndicator(color: context.nest.leaf));
  }
}

class _SettingsFailure extends StatelessWidget {
  const _SettingsFailure();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NestSpacing.padSide),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Something went wrong loading settings.',
              style: NestType.body(color: context.nest.ink2),
              textAlign: TextAlign.center,
              maxLines: 4,
            ),
            const SizedBox(height: NestSpacing.s4),
            NestButton(
              key: const ValueKey('p16_retry'),
              label: 'Try again',
              variant: NestButtonVariant.secondary,
              onPressed: () => context.read<SettingsBloc>().add(
                const SettingsLoadRequested(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsLoaded extends StatelessWidget {
  const _SettingsLoaded({required this.state});

  final SettingsState state;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final settings = state.settings;
    final zoneSummary = settingsZoneSummary(state.familyZoneId, appNowUtc());
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        NestSpacing.padSide,
        0,
        NestSpacing.padSide,
        32,
      ),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: NestSpacing.s2),
          child: Text(
            'Family & settings',
            style: NestType.h1(color: tokens.ink),
          ),
        ),
        if (state.pendingZone != null) ...<Widget>[
          const SizedBox(height: NestSpacing.s6),
          _MoveBanner(zone: state.pendingZone!),
        ],
        const SizedBox(height: NestSpacing.s6),
        const NestSectionLabel(label: 'Family'),
        const SizedBox(height: NestSpacing.s2),
        NestList(
          children: <Widget>[
            for (final m in state.memberRows) _MemberRow(member: m),
            NestListRow(
              title: 'Invite co-parent',
              subtitle: 'Share the load',
              leadingAsset: NestIcons.plus,
              tint: NestTileTint.leaf,
              trailing: settingsChevron(context),
              onTap: () => P16TransientGuard.run(
                () => showNestToast(context, 'Co-parent invite is coming soon'),
              ),
              semanticLabel: 'Invite co-parent',
            ),
          ],
        ),
        const SizedBox(height: NestSpacing.s6),
        const NestSectionLabel(label: 'Children'),
        const SizedBox(height: NestSpacing.s2),
        NestList(
          children: <Widget>[
            for (final c in state.familyRoster) _ChildRow(child: c),
            NestListRow(
              title: 'Add child',
              subtitle: 'Nickname + age band only',
              leadingAsset: NestIcons.plus,
              trailing: settingsChevron(context),
              onTap: () => P16TransientGuard.run(
                () => context.push(FamilyRoutePaths.addChildren),
              ),
            ),
          ],
        ),
        const SizedBox(height: NestSpacing.s6),
        const NestSectionLabel(label: 'Subscription'),
        const SizedBox(height: NestSpacing.s2),
        // `.subcard` pins `border-radius: var(--r-m)` (16) and
        // `padding:14px 16px` (`P16-settings.html:7`); `NestCard.standard`
        // draws 24, so the shared card takes the design's override.
        NestCard(
          radius: NestRadii.m,
          padding: const EdgeInsets.symmetric(
            horizontal: NestSpacing.s4,
            vertical: NestSpacing.gap14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Nestling Annual · £29.99/year',
                style: NestType.body(color: tokens.ink)
                    .copyWith(fontWeight: FontWeight.w700, height: 20 / 16),
              ),
              // `.subcard .b { margin-top: 2px }`
              const SizedBox(height: NestSpacing.gap2),
              Text(
                'Renews 18 Oct 2027 · Covers the whole family',
                style: NestType.caption(color: tokens.ink2),
              ),
              InkWell(
                onTap: () => P16TransientGuard.run(
                  () => context.push(PaywallRoutePaths.paywall),
                ),
                child: Semantics(
                  button: true,
                  label: 'Manage subscription',
                  excludeSemantics: true,
                  onTap: () => P16TransientGuard.run(
                    () => context.push(PaywallRoutePaths.paywall),
                  ),
                  child: SizedBox(
                    // `.linkrow { min-height: 52px }`
                    height: _linkRowMinHeight,
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Manage subscription',
                            style: NestType.bodySmall(color: tokens.leaf)
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        settingsChevron(context),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: NestSpacing.s6),
        const NestSectionLabel(label: 'Time zone'),
        const SizedBox(height: NestSpacing.s2),
        NestList(
          children: <Widget>[
            NestListRow(
              title: 'Time zone',
              subtitle: zoneSummary,
              trailing: settingsChevron(context),
              onTap: () =>
                  P16TransientGuard.run(() => openZonePickerSheet(context)),
            ),
          ],
        ),
        const SizedBox(height: NestSpacing.s6),
        const NestSectionLabel(label: 'Notifications'),
        const SizedBox(height: NestSpacing.s2),
        NestList(
          children: <Widget>[
            NestListRow(
              title: 'Approvals waiting',
              trailing: NestToggle(
                value: settings?.notifApprovals ?? true,
                semanticLabel: 'Approvals waiting notifications',
                onChanged: (v) => P16TransientGuard.run(
                  () => context.read<SettingsBloc>().add(
                    SettingsNotificationsChanged(approvals: v),
                  ),
                ),
              ),
            ),
            NestListRow(
              title: 'Payout day reminder',
              subtitle: 'Friday before Saturday payout',
              trailing: NestToggle(
                value: settings?.notifPayout ?? true,
                semanticLabel: 'Payout day reminder',
                onChanged: (v) => P16TransientGuard.run(
                  () => context.read<SettingsBloc>().add(
                    SettingsNotificationsChanged(payout: v),
                  ),
                ),
              ),
            ),
            NestListRow(
              title: 'Weekly family summary',
              trailing: NestToggle(
                value: settings?.notifSummary ?? true,
                semanticLabel: 'Weekly family summary',
                onChanged: (v) => P16TransientGuard.run(
                  () => context.read<SettingsBloc>().add(
                    SettingsNotificationsChanged(summary: v),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: NestSpacing.s6),
        const NestSectionLabel(label: 'Privacy'),
        const SizedBox(height: NestSpacing.s2),
        NestList(
          children: <Widget>[
            NestListRow(
              title: 'Download our data',
              trailing: settingsChevron(context),
              onTap: () => P16TransientGuard.run(
                () => context.push(PrivacyConsentRoutePaths.privacy),
              ),
            ),
            NestListRow(
              title: 'Privacy Notice',
              trailing: settingsChevron(context),
              onTap: () => P16TransientGuard.run(
                () => context.push(PrivacyConsentRoutePaths.privacy),
              ),
            ),
            SettingsRow(
              title: 'Delete family account',
              titleColor: tokens.danger,
              titleWeight: FontWeight.w700,
              onTap: () => P16TransientGuard.run(() => _confirmDelete(context)),
              semanticLabel: 'Delete family account',
            ),
          ],
        ),
        const SizedBox(height: NestSpacing.s4),
        _LockHint(on: settings?.kidGateEnabled ?? true),
        const SizedBox(height: NestSpacing.s6),
        const NestSectionLabel(label: 'About'),
        const SizedBox(height: NestSpacing.s2),
        NestList(
          children: <Widget>[
            NestListRow(
              title: 'Help & feedback',
              trailing: settingsChevron(context),
              onTap: () => P16TransientGuard.run(
                () => showNestToast(context, 'Help & feedback is coming soon'),
              ),
            ),
            const NestListRow(
              title: 'Version 1.0.0',
              subtitle: 'Made in the UK · No ads, ever',
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final tokens = context.nest;
    final confirmed = await showNestModal<bool>(
      context,
      title: 'Delete family account?',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'This removes the family, all quests and pocket money for good. '
            'This can’t be undone.',
            style: NestType.bodySmall(color: tokens.ink2),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: NestSpacing.s5),
          Row(
            spacing: NestSpacing.s3,
            children: <Widget>[
              Expanded(
                child: NestButton(
                  key: const ValueKey('p16_delete_cancel'),
                  label: 'Cancel',
                  variant: NestButtonVariant.ghost,
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(false),
                ),
              ),
              Expanded(
                child: NestButton(
                  key: const ValueKey('p16_delete_confirm'),
                  label: 'Delete',
                  variant: NestButtonVariant.dangerGhost,
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    P16TransientGuard.suppressShortly();
    if (confirmed == true && context.mounted) {
      // TODO(P16): wire real deletion once the account-deletion flow exists;
      // intentionally a toast only today — never wipe the DB silently.
      showNestToast(context, 'Family account deletion is not available yet');
    }
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member});

  final SettingsMemberEntry member;

  @override
  Widget build(BuildContext context) {
    final isOwner = member.role == 'owner';
    final title = isOwner
        ? '${member.name} — you'
        : '${member.name} — co-parent';
    // DATA OVER MOCKS: the subtitle is the database row, never a literal.
    // The owner shows `members.email`; an invited co-parent has none and shows
    // its invite status instead.
    final email = member.email;
    final subtitle = email != null && email.isNotEmpty
        ? email
        : (member.inviteStatus == 'invited'
              ? 'Invited · awaiting reply'
              : isOwner
              ? 'Owner'
              : 'Active');
    final initial = member.name.isEmpty
        ? '?'
        : member.name.characters.first.toUpperCase();
    return SettingsRow(
      title: title,
      subtitle: subtitle,
      leading: NestAvatar(
        initial: initial,
        size: NestAvatarSize.s32,
        color: isOwner ? NestAvatarColor.leaf : NestAvatarColor.sky,
      ),
    );
  }
}

class _ChildRow extends StatelessWidget {
  const _ChildRow({required this.child});

  final SettingsChildEntry child;

  @override
  Widget build(BuildContext context) {
    final initial = child.nickname.isEmpty
        ? '?'
        : child.nickname.characters.first.toUpperCase();
    return SettingsRow(
      title: '${child.nickname} · ${child.ageBand.replaceAll('-', '–')}',
      subtitle:
          'Pip: ${child.pipStageName} · ${child.coins == 1 ? '1 coin' : '${child.coins} coins'}',
      leading: NestAvatar(
        initial: initial,
        size: NestAvatarSize.s32,
        color: settingsAvatarColor(child.avatarColour),
      ),
      trailing: settingsChevron(context),
      onTap: () => P16TransientGuard.run(
        () => context.push(FamilyRoutePaths.childProfile),
      ),
    );
  }
}

/// One-time "looks like you moved" banner (leaf tint card). The bloc only
/// surfaces `pendingZone` while the device zone differs from the stored
/// family zone and the zone was not dismissed this session.
class _MoveBanner extends StatelessWidget {
  const _MoveBanner({required this.zone});

  final String zone;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final short = shortZoneLabel(zone);
    return Container(
      key: const ValueKey('p16_move_banner'),
      padding: const EdgeInsets.symmetric(
        horizontal: NestSpacing.gap14,
        vertical: NestSpacing.s3,
      ),
      decoration: BoxDecoration(
        color: tokens.leafTint,
        borderRadius: NestRadii.allM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Looks like you’re in $short now. Switch the family time zone? '
            'History keeps London times; future days follow $short.',
            // `.lockhint` metrics: 14/20 (`NestType.chipLabel` carries that
            // line box; only the weight differs — the hint is regular text).
            style: NestType.chipLabel(color: tokens.ink)
                .copyWith(fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: NestSpacing.s3),
          Row(
            spacing: NestSpacing.s2,
            children: <Widget>[
              Expanded(
                child: NestButton(
                  key: const ValueKey('p16_move_switch'),
                  label: 'Switch',
                  onPressed: () => context.read<SettingsBloc>().add(
                    const SettingsMoveConfirmed(),
                  ),
                  minHeight: 48,
                  fontSize: 15,
                ),
              ),
              Expanded(
                child: NestButton(
                  key: const ValueKey('p16_move_not_now'),
                  label: 'Not now',
                  variant: NestButtonVariant.ghost,
                  onPressed: () => context.read<SettingsBloc>().add(
                    SettingsMoveDismissed(zone),
                  ),
                  minHeight: 48,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// `.lockhint` row: kid-gate state, display only (no toggle here).
class _LockHint extends StatelessWidget {
  const _LockHint({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Container(
      // `.lockhint { padding:12px 14px; gap:10px }`
      padding: const EdgeInsets.symmetric(
        horizontal: NestSpacing.gap14,
        vertical: NestSpacing.s3,
      ),
      decoration: BoxDecoration(
        color: tokens.surface2,
        borderRadius: NestRadii.allM,
      ),
      child: Row(
        spacing: NestSpacing.gap10,
        children: <Widget>[
          NestIcon(NestIcons.lock, color: tokens.ink2),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: NestType.chipLabel(color: tokens.ink)
                    .copyWith(fontWeight: FontWeight.w400),
                children: <InlineSpan>[
                  const TextSpan(text: 'Kid mode needs parent gate — '),
                  TextSpan(
                    text: on ? 'On' : 'Off',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

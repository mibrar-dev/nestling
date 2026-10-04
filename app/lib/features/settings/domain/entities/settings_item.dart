import 'package:equatable/equatable.dart';
import 'package:nestling/features/settings/domain/entities/app_settings.dart';

// One settings row (P16). `detail` carries the live value
// ("Nestling Annual · renews 18 Oct 2027", "On", …).
class SettingsItem extends Equatable {
  const new({
    required this.id,
    required this.title,
    required this.detail,
    required this.enabled,
  });

  final String id;
  final String title;
  final String detail;

  /// Toggle state for switch rows; true for plain navigation rows.
  final bool enabled;

  @override
  List<Object?> get props => <Object?>[id, title, detail, enabled];
}

/// Legacy P16 placeholder rows derived from the given [AppSettings]. The
/// repository uses this for `watchItems()` (pinned by the shared
/// `repositories_test` settings group); the view no longer renders these.
List<SettingsItem> settingsItemsFor(AppSettings s) {
  String onOff({required bool value}) => value ? 'On' : 'Off';
  return <SettingsItem>[
    SettingsItem(
      id: 'subscription',
      title: 'Nestling Annual',
      detail: s.subscriptionStatus == 'active'
          ? 'Active · renews yearly'
          : 'Trial · then £29.99/year',
      enabled: true,
    ),
    SettingsItem(
      id: 'notif-approvals',
      title: 'Approvals waiting',
      detail: onOff(value: s.notifApprovals),
      enabled: s.notifApprovals,
    ),
    SettingsItem(
      id: 'notif-payout',
      title: 'Payout day reminder',
      detail: onOff(value: s.notifPayout),
      enabled: s.notifPayout,
    ),
    SettingsItem(
      id: 'notif-summary',
      title: 'Weekly family summary',
      detail: onOff(value: s.notifSummary),
      enabled: s.notifSummary,
    ),
    SettingsItem(
      id: 'kid-gate',
      title: 'Kid mode needs parent gate',
      detail: onOff(value: s.kidGateEnabled),
      enabled: s.kidGateEnabled,
    ),
    const SettingsItem(
      id: 'version',
      title: 'Version 1.0.0',
      detail: 'Help & feedback',
      enabled: true,
    ),
  ];
}

import 'package:equatable/equatable.dart';

// The full settings state (P16): pocket-money config, notification toggles,
// privacy consent and the kid-gate switch.
class AppSettings extends Equatable {
  const new({
    required this.pocketMoneyMode,
    required this.payoutDay,
    required this.coinValuePencePerCoin,
    required this.notifApprovals,
    required this.notifPayout,
    required this.notifSummary,
    required this.crashReportConsent,
    required this.kidGateEnabled,
    required this.subscriptionStatus,
  });

  final String pocketMoneyMode;
  final int payoutDay;
  final int coinValuePencePerCoin;
  final bool notifApprovals;
  final bool notifPayout;
  final bool notifSummary;
  final bool crashReportConsent;
  final bool kidGateEnabled;
  final String subscriptionStatus;

  @override
  List<Object?> get props => <Object?>[
    pocketMoneyMode,
    payoutDay,
    coinValuePencePerCoin,
    notifApprovals,
    notifPayout,
    notifSummary,
    crashReportConsent,
    kidGateEnabled,
    subscriptionStatus,
  ];
}

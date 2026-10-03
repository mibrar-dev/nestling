import 'package:equatable/equatable.dart';

// One child on the P12 ledger. Creation order everywhere (Maya, then Leo —
// never alphabetical); only the fields the ledger needs. The full row stays
// in `PocketMoneySetupChild` (P06) and `AppDatabase` (foundation).
class MoneyChild extends Equatable {
  const new({required this.id, required this.nickname});

  final String id;
  final String nickname;

  @override
  List<Object?> get props => <Object?>[id, nickname];
}

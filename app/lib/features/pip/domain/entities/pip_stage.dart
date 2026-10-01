import 'package:equatable/equatable.dart';

// A wardrobe item for Pip (K06 strip): scarf, sunhat, wellies, crown.
// `title` is the item name; `detail` is "Owned" or "40 coins".
class PipStage extends Equatable {
  const new({
    required this.id,
    required this.title,
    required this.detail,
    required this.owned,
    required this.priceCoins,
  });

  final String id;
  final String title;
  final String detail;
  final bool owned;
  final int priceCoins;

  @override
  List<Object?> get props => <Object?>[id, title, detail, owned, priceCoins];
}

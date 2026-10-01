import 'package:nestling/features/family/data/models/family_member_model.dart';

class FamilyFakeDataSource {
  const new();

  List<FamilyMemberModel> getItems() {
    return const <FamilyMemberModel>[
      FamilyMemberModel(
        id: 'maya',
        title: 'Maya',
        detail: 'Age 9, 120 coins, Pip is a Fledgling',
      ),
      FamilyMemberModel(
        id: 'leo',
        title: 'Leo',
        detail: 'Age 6, 45 coins, Pip is a Hatchling',
      ),
    ];
  }
}

import 'package:nestling/features/family/domain/entities/family_child.dart';
import 'package:nestling/features/family/domain/entities/family_member.dart';

/// Family roster (P05 add-children, P15 child profile, P16 family section),
/// backed by Drift.
abstract class FamilyRepository {
  Future<List<FamilyMember>> getItems();
  Stream<List<FamilyMember>> watchItems();

  Stream<List<FamilyChild>> watchChildren();
  Future<FamilyChild?> getChild(String childId);

  Future<void> addChild({
    required String nickname,
    required String ageBand,
    required String avatarColour,
    int weeklyBasePence = 0,
  });
  Future<void> updateChild(FamilyChild child);
  Future<void> removeChild(String childId);
  Future<void> inviteCoParent(String name);
}

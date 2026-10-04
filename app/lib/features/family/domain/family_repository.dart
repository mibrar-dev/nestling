import 'package:nestling/features/family/domain/entities/child_profile.dart';
import 'package:nestling/features/family/domain/entities/family_child.dart';
import 'package:nestling/features/family/domain/entities/family_member.dart';

/// Family roster (P05 add-children, P15 child profile, P16 family section),
/// backed by Drift.
abstract class FamilyRepository {
  Future<List<FamilyMember>> getItems();
  Stream<List<FamilyMember>> watchItems();

  Stream<List<FamilyChild>> watchChildren();
  Future<FamilyChild?> getChild(String childId);

  /// Persists the selected child for P15's `?childId=` deep link (P15-BUG-1).
  /// Unknown ids are ignored — the profile falls back to the first-created
  /// child instead of persisting a stale selection (P15-BUG-7 class).
  Future<void> selectChild(String childId);

  /// Selected-child profile for P15: resolves `app_state.activeChildId`,
  /// falling back to the first child in creation order, or null when there
  /// are no children.
  Stream<ChildProfile?> watchProfile();

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

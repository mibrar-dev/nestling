import 'package:nestling/features/family/domain/entities/family_member.dart';

abstract class FamilyRepository {
  Future<List<FamilyMember>> getItems();
}

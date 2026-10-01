import 'package:nestling/features/badges/domain/entities/badge.dart';

abstract class BadgesRepository {
  Future<List<Badge>> getItems();
}

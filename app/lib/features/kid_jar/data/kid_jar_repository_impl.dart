import 'package:nestling/features/kid_jar/data/kid_jar_fake_data_source.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_entry.dart';
import 'package:nestling/features/kid_jar/domain/kid_jar_repository.dart';

class KidJarRepositoryImpl implements KidJarRepository {
  const new({required this._dataSource});

  final KidJarFakeDataSource _dataSource;

  @override
  Future<List<JarEntry>> getItems() {
    return Future.value(_dataSource.getItems());
  }
}

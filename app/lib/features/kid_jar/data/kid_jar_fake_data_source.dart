import 'package:nestling/features/kid_jar/data/models/jar_entry_model.dart';

class KidJarFakeDataSource {
  const new();

  List<JarEntryModel> getItems() {
    return const <JarEntryModel>[
      JarEntryModel(
        id: 'owed',
        title: '£4.20 coming on Saturday',
        detail: 'Mum marks it paid in cash',
      ),
      JarEntryModel(
        id: 'lego',
        title: 'Lego Friends set',
        detail: '£15.50 of £24.99, £9.49 to go',
      ),
    ];
  }
}

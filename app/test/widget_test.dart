import 'package:flutter_test/flutter_test.dart';

import 'test_scope.dart';

void main() {
  testWidgets('App launches to the design system gallery', (tester) async {
    // In-memory database: the real file database needs path_provider,
    // which has no test implementation. The gallery is a developer tool
    // reached here through an explicit route (shared/start_route keeps it
    // registered in debug, where tests run).
    await setUpTestScope();

    await pumpAppRoute(tester, '/design-system');
    expect(find.text('Design system'), findsOneWidget);
    await disposeApp(tester);
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'test_scope.dart';

void main() {
  testWidgets('App launches to the design system gallery', (tester) async {
    // In-memory database: the real file database needs path_provider,
    // which has no test implementation. Seed.demo marks onboarding
    // complete so the router keeps the gallery as its initial location.
    await setUpTestScope();

    await pumpAppRoute(tester, '/design-system');
    expect(find.text('Design system'), findsOneWidget);
    await disposeApp(tester);
  });
}
